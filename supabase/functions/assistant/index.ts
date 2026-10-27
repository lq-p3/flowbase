// FlowBase AI secretary.
// The app sends the chat; this function asks Gemini, lets it plan and use tools
// on the user's projects and tasks (several steps per message), and returns the
// answer. The Gemini key lives only here (a Supabase
// secret), and every database call runs as the signed-in user, so Row Level
// Security still limits it to that user's own rows.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

// ---------- Tools Gemini may call ----------
const priority = { type: "string", enum: ["low", "medium", "high", "urgent"] };
const taskFields = {
  title: { type: "string" },
  date: { type: "string", description: "YYYY-MM-DD" },
  time: { type: "string", description: "HH:MM 24-hour, optional" },
  priority,
  description: { type: "string" },
  subtasks: { type: "array", items: { type: "string" }, description: "Small checklist steps inside the task, optional" },
};

const tools = [{
  functionDeclarations: [
    {
      name: "list_spaces_and_projects",
      description: "List the user's spaces and projects with their ids.",
      parameters: { type: "object", properties: {} },
    },
    {
      name: "list_tasks",
      description: "List tasks between two dates (inclusive), optionally only one project's. Use it for 'what do I have today', 'what is overdue' or 'how is project X going'.",
      parameters: {
        type: "object",
        properties: {
          from: { type: "string", description: "YYYY-MM-DD" },
          to: { type: "string", description: "YYYY-MM-DD" },
          project_id: { type: "string" },
          include_done: { type: "boolean" },
        },
        required: ["from", "to"],
      },
    },
    {
      name: "search_tasks",
      description: "Find tasks whose title contains some words, on any date. Use it to find a task's id before changing or deleting it.",
      parameters: {
        type: "object",
        properties: { query: { type: "string" }, include_done: { type: "boolean" } },
        required: ["query"],
      },
    },
    {
      name: "create_task",
      description: "Create one task, optionally with subtasks. If no space fits, use the first space.",
      parameters: {
        type: "object",
        properties: { ...taskFields, space_id: { type: "string" }, project_id: { type: "string" } },
        required: ["title", "date"],
      },
    },
    {
      name: "create_project",
      description: "Create a project for a bigger goal, together with all its planned tasks (each may have subtasks) in one call.",
      parameters: {
        type: "object",
        properties: {
          name: { type: "string" },
          due: { type: "string", description: "YYYY-MM-DD, the deadline of the whole project" },
          notes: { type: "string" },
          space_id: { type: "string" },
          tasks: {
            type: "array",
            items: { type: "object", properties: taskFields, required: ["title", "date"] },
          },
        },
        required: ["name", "due", "tasks"],
      },
    },
    {
      name: "add_subtasks",
      description: "Add checklist steps to an existing task.",
      parameters: {
        type: "object",
        properties: { task_id: { type: "string" }, titles: { type: "array", items: { type: "string" } } },
        required: ["task_id", "titles"],
      },
    },
    {
      name: "update_task",
      description: "Change a task: mark it done, move its date or time, rename it or change its priority.",
      parameters: {
        type: "object",
        properties: {
          id: { type: "string" },
          title: { type: "string" },
          date: { type: "string", description: "YYYY-MM-DD" },
          time: { type: "string", description: "HH:MM 24-hour" },
          priority,
          status: { type: "string", enum: ["todo", "inProgress", "done"] },
        },
        required: ["id"],
      },
    },
    {
      name: "delete_task",
      description: "Delete a task. Only call it after the user clearly said yes to deleting that exact task in their latest message; set confirmed to true then.",
      parameters: {
        type: "object",
        properties: { id: { type: "string" }, confirmed: { type: "boolean" } },
        required: ["id", "confirmed"],
      },
    },
  ],
}];

type Args = Record<string, unknown>;

// deno-lint-ignore no-explicit-any
async function firstSpace(db: any, spaceId?: unknown): Promise<string | undefined> {
  if (spaceId) return spaceId as string;
  const { data } = await db.from("spaces").select("id").order("created_at").limit(1);
  return data?.[0]?.id;
}

// One row for the tasks table, in the same shape the app saves.
const taskRow = (t: Args, spaceId: string, projectId: unknown) => ({
  // The app always sends its own uuid, so don't rely on a column default.
  id: crypto.randomUUID(),
  title: t.title,
  date: t.date,
  time: t.time ?? null,
  space_id: spaceId,
  project_id: projectId ?? null,
  priority: t.priority ?? "medium",
  description: t.description ?? "",
  status: "todo",
  // A task with a time gets the phone reminder, like one added by hand.
  reminder: !!t.time,
});

const subtaskRows = (taskId: string, titles: unknown, start = 0) =>
  ((titles as string[] | undefined) ?? []).map((title, i) => ({
    id: crypto.randomUUID(),
    task_id: taskId,
    title,
    done: false,
    position: start + i,
  }));

// deno-lint-ignore no-explicit-any
async function runTool(db: any, name: string, args: Args): Promise<{ result: unknown; changed: boolean }> {
  switch (name) {
    case "list_spaces_and_projects": {
      const { data: spaces } = await db.from("spaces").select("id, name").order("created_at");
      const { data: projects } = await db.from("projects").select("id, name, space_id, due").order("created_at");
      return { result: { spaces, projects }, changed: false };
    }
    case "list_tasks": {
      let q = db.from("tasks").select("id, title, date, time, priority, status, space_id, project_id, subtasks(title, done)")
        .gte("date", args.from).lte("date", args.to).order("date").limit(100);
      if (args.project_id) q = q.eq("project_id", args.project_id);
      if (!args.include_done) q = q.neq("status", "done");
      const { data, error } = await q;
      return { result: error ? { error: error.message } : data, changed: false };
    }
    case "search_tasks": {
      let q = db.from("tasks").select("id, title, date, time, status, project_id")
        .ilike("title", `%${args.query}%`).order("date").limit(20);
      if (!args.include_done) q = q.neq("status", "done");
      const { data, error } = await q;
      return { result: error ? { error: error.message } : data, changed: false };
    }
    case "create_task": {
      const spaceId = await firstSpace(db, args.space_id);
      if (!spaceId) return { result: { error: "The user has no spaces yet." }, changed: false };
      const row = taskRow(args, spaceId, args.project_id);
      const { data, error } = await db.from("tasks").insert(row).select("id, title, date, time").single();
      if (error) return { result: { error: error.message }, changed: false };
      const subs = subtaskRows(row.id, args.subtasks);
      if (subs.length) await db.from("subtasks").insert(subs);
      return { result: { ...data, subtasks: subs.length }, changed: true };
    }
    case "create_project": {
      const spaceId = await firstSpace(db, args.space_id);
      if (!spaceId) return { result: { error: "The user has no spaces yet." }, changed: false };
      const projectId = crypto.randomUUID();
      const { error } = await db.from("projects").insert({
        id: projectId, space_id: spaceId, name: args.name, due: args.due, notes: args.notes ?? "",
      });
      if (error) return { result: { error: error.message }, changed: false };
      const tasks = ((args.tasks as Args[]) ?? []).slice(0, 30);
      const rows = tasks.map((t) => taskRow(t, spaceId, projectId));
      if (rows.length) {
        const { error: e2 } = await db.from("tasks").insert(rows);
        if (e2) return { result: { project_id: projectId, error: e2.message }, changed: true };
        const subs = rows.flatMap((r, i) => subtaskRows(r.id, tasks[i].subtasks));
        if (subs.length) await db.from("subtasks").insert(subs);
      }
      return {
        result: { project_id: projectId, name: args.name, due: args.due, tasks: rows.map((r) => ({ title: r.title, date: r.date, time: r.time })) },
        changed: true,
      };
    }
    case "add_subtasks": {
      const { count } = await db.from("subtasks").select("id", { count: "exact", head: true }).eq("task_id", args.task_id);
      const subs = subtaskRows(args.task_id as string, args.titles, count ?? 0);
      const { error } = await db.from("subtasks").insert(subs);
      return { result: error ? { error: error.message } : { added: subs.length }, changed: !error };
    }
    case "update_task": {
      const fields: Record<string, unknown> = {};
      for (const k of ["title", "date", "time", "priority", "status"]) if (args[k] !== undefined) fields[k] = args[k];
      const { data, error } = await db.from("tasks").update(fields).eq("id", args.id).select("id, title, date, time, status").single();
      return { result: error ? { error: error.message } : data, changed: !error };
    }
    case "delete_task": {
      if (args.confirmed !== true) return { result: { error: "Ask the user to confirm first." }, changed: false };
      const { data, error } = await db.from("tasks").delete().eq("id", args.id).select("title").single();
      return { result: error ? { error: error.message } : { deleted: data.title }, changed: !error };
    }
    default:
      return { result: { error: `Unknown tool ${name}` }, changed: false };
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const GEMINI_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
  if (!GEMINI_KEY) return json({ error: "GEMINI_API_KEY is not set" }, 500);

  const auth = req.headers.get("Authorization") ?? "";
  const db = createClient(Deno.env.get("SUPABASE_URL")!, (Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY"))!, {
    global: { headers: { Authorization: auth } },
  });
  const { data: { user } } = await db.auth.getUser(auth.replace("Bearer ", ""));
  if (!user) return json({ error: "Not signed in" }, 401);

  const { messages = [], today, now, lang = "ar" } = await req.json();
  const name = user.user_metadata?.full_name ?? "";
  const system = `You are FlowBase's personal secretary for ${name || "the user"}: an agent that plans and acts, not just a chatbot.
Today is ${today}${now ? `, and the time now is ${now}` : ""} (the user's local date and time). Reply in ${lang === "ar" ? "Arabic (friendly Gulf style)" : "English"}, short and clear.

How you work:
- Use the tools to read or change the user's data; never invent tasks or ids. Look up spaces and projects before choosing one.
- Resolve words like "tomorrow" or "next Sunday" to real dates from today.
- A single thing to do or remember: CALL create_task right away (one call per task).
- A bigger goal (a trip, an exam, a launch, "plan my week"...): think it through, then CALL create_project once with
  every step as a task spread over realistic dates up to the deadline, with subtasks where they help. No deadline given:
  pick a sensible one. Check the user's existing tasks on those days first so you do not overload a day.
- "What do I have", "what's late", "how is X going": read with list_tasks or search_tasks, then answer with a short
  summary and one concrete suggestion (what to do first, what to move).
- To change or finish a task you do not have the id for, search_tasks first.
- Do not ask for confirmation for adding or changing things; pick sensible defaults (first matching space, no time if none
  was given, "8 at night" = 20:00, "8 in the morning" = 08:00, "in an hour" = now + 1 hour, rolling over to tomorrow after midnight).
- Deleting is the exception: first tell the user exactly which task you would delete and ask "متأكد؟"; only after they say yes
  in a new message, call delete_task with confirmed=true. Never delete projects or spaces.
- Do not say something was done unless the tool returned it. After acting, list exactly what you did (titles, dates, times).`;

  // deno-lint-ignore no-explicit-any
  const contents: any[] = messages.slice(-20).map((m: { role: string; text: string }) => ({
    role: m.role === "user" ? "user" : "model",
    parts: [{ text: m.text }],
  }));

  let changed = false;
  const actions: string[] = [];
  for (let step = 0; step < 10; step++) {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-goog-api-key": GEMINI_KEY },
        body: JSON.stringify({ systemInstruction: { parts: [{ text: system }] }, contents, tools }),
      },
    );
    if (!res.ok) {
      const detail = await res.text();
      console.error("gemini", res.status, detail.slice(0, 500));
      return json({ error: res.status === 429 ? "Daily free limit reached, try again later." : `Gemini error ${res.status}`, detail }, 502);
    }
    const out = await res.json();
    const parts = out.candidates?.[0]?.content?.parts ?? [];
    // deno-lint-ignore no-explicit-any
    const calls = parts.filter((p: any) => p.functionCall);
    if (calls.length === 0) {
      // deno-lint-ignore no-explicit-any
      const text = parts.map((p: any) => p.text ?? "").join("").trim();
      console.log("reply", step, actions.join(","), text.slice(0, 200));
      return json({ reply: text, changed, actions });
    }
    contents.push({ role: "model", parts });
    // deno-lint-ignore no-explicit-any
    const responses: any[] = [];
    for (const c of calls) {
      const r = await runTool(db, c.functionCall.name, c.functionCall.args ?? {});
      console.log("tool", c.functionCall.name, JSON.stringify(c.functionCall.args), JSON.stringify(r.result).slice(0, 300));
      changed ||= r.changed;
      if (r.changed) actions.push(c.functionCall.name);
      responses.push({ functionResponse: { name: c.functionCall.name, response: { result: r.result } } });
    }
    contents.push({ role: "user", parts: responses });
  }
  return json({ reply: lang === "ar" ? "ما قدرت أكمل الطلب، جرّب تعيد صياغته." : "I couldn't finish that, please rephrase.", changed });
});

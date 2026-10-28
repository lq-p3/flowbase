// The secretary's brain, shared by the app chat (assistant) and the Telegram bot (telegram).
// Gemini decides which tool to use; we run the tool on the database and loop until it answers.
// Every query names the user explicitly, because the Telegram bot runs with the server key
// (no user login), so Row Level Security alone cannot be relied on there.

const MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash";

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

const baseTools = [
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
];

export type Args = Record<string, unknown>;
export type ToolResult = { result: unknown; changed: boolean };
// A tool only one caller offers (for example the Telegram link code in the app chat).
export type ExtraTool = { declaration: Args; run: (args: Args) => Promise<ToolResult> };

// deno-lint-ignore no-explicit-any
type Db = any;

// True when the row with this id belongs to the user.
async function owns(db: Db, uid: string, table: string, id: unknown): Promise<boolean> {
  if (!id) return false;
  const { data } = await db.from(table).select("id").eq("id", id).eq("user_id", uid).maybeSingle();
  return !!data;
}

async function pickSpace(db: Db, uid: string, spaceId?: unknown): Promise<string | undefined> {
  if (spaceId && await owns(db, uid, "spaces", spaceId)) return spaceId as string;
  const { data } = await db.from("spaces").select("id").eq("user_id", uid).order("created_at").limit(1);
  return data?.[0]?.id;
}

// One row for the tasks table, in the same shape the app saves.
const taskRow = (t: Args, uid: string, spaceId: string, projectId: unknown) => ({
  // The app always sends its own uuid, so don't rely on a column default.
  id: crypto.randomUUID(),
  user_id: uid,
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

const subtaskRows = (uid: string, taskId: string, titles: unknown, start = 0) =>
  ((titles as string[] | undefined) ?? []).map((title, i) => ({
    id: crypto.randomUUID(),
    user_id: uid,
    task_id: taskId,
    title,
    done: false,
    position: start + i,
  }));

async function runTool(db: Db, uid: string, name: string, args: Args): Promise<ToolResult> {
  switch (name) {
    case "list_spaces_and_projects": {
      const { data: spaces } = await db.from("spaces").select("id, name").eq("user_id", uid).order("created_at");
      const { data: projects } = await db.from("projects").select("id, name, space_id, due").eq("user_id", uid).order("created_at");
      return { result: { spaces, projects }, changed: false };
    }
    case "list_tasks": {
      let q = db.from("tasks").select("id, title, date, time, priority, status, space_id, project_id, subtasks(title, done)")
        .eq("user_id", uid).gte("date", args.from).lte("date", args.to).order("date").limit(100);
      if (args.project_id) q = q.eq("project_id", args.project_id);
      if (!args.include_done) q = q.neq("status", "done");
      const { data, error } = await q;
      return { result: error ? { error: error.message } : data, changed: false };
    }
    case "search_tasks": {
      let q = db.from("tasks").select("id, title, date, time, status, project_id")
        .eq("user_id", uid).ilike("title", `%${args.query}%`).order("date").limit(20);
      if (!args.include_done) q = q.neq("status", "done");
      const { data, error } = await q;
      return { result: error ? { error: error.message } : data, changed: false };
    }
    case "create_task": {
      const spaceId = await pickSpace(db, uid, args.space_id);
      if (!spaceId) return { result: { error: "The user has no spaces yet." }, changed: false };
      const projectId = await owns(db, uid, "projects", args.project_id) ? args.project_id : null;
      const row = taskRow(args, uid, spaceId, projectId);
      const { data, error } = await db.from("tasks").insert(row).select("id, title, date, time").single();
      if (error) return { result: { error: error.message }, changed: false };
      const subs = subtaskRows(uid, row.id, args.subtasks);
      if (subs.length) await db.from("subtasks").insert(subs);
      return { result: { ...data, subtasks: subs.length }, changed: true };
    }
    case "create_project": {
      const spaceId = await pickSpace(db, uid, args.space_id);
      if (!spaceId) return { result: { error: "The user has no spaces yet." }, changed: false };
      const projectId = crypto.randomUUID();
      const { error } = await db.from("projects").insert({
        id: projectId, user_id: uid, space_id: spaceId, name: args.name, due: args.due, notes: args.notes ?? "",
      });
      if (error) return { result: { error: error.message }, changed: false };
      const tasks = ((args.tasks as Args[]) ?? []).slice(0, 30);
      const rows = tasks.map((t) => taskRow(t, uid, spaceId, projectId));
      if (rows.length) {
        const { error: e2 } = await db.from("tasks").insert(rows);
        if (e2) return { result: { project_id: projectId, error: e2.message }, changed: true };
        const subs = rows.flatMap((r, i) => subtaskRows(uid, r.id, tasks[i].subtasks));
        if (subs.length) await db.from("subtasks").insert(subs);
      }
      return {
        result: { project_id: projectId, name: args.name, due: args.due, tasks: rows.map((r) => ({ title: r.title, date: r.date, time: r.time })) },
        changed: true,
      };
    }
    case "add_subtasks": {
      if (!await owns(db, uid, "tasks", args.task_id)) return { result: { error: "Task not found." }, changed: false };
      const { count } = await db.from("subtasks").select("id", { count: "exact", head: true }).eq("task_id", args.task_id);
      const subs = subtaskRows(uid, args.task_id as string, args.titles, count ?? 0);
      const { error } = await db.from("subtasks").insert(subs);
      return { result: error ? { error: error.message } : { added: subs.length }, changed: !error };
    }
    case "update_task": {
      const fields: Record<string, unknown> = {};
      for (const k of ["title", "date", "time", "priority", "status"]) if (args[k] !== undefined) fields[k] = args[k];
      const { data, error } = await db.from("tasks").update(fields).eq("id", args.id).eq("user_id", uid)
        .select("id, title, date, time, status").single();
      return { result: error ? { error: error.message } : data, changed: !error };
    }
    case "delete_task": {
      if (args.confirmed !== true) return { result: { error: "Ask the user to confirm first." }, changed: false };
      const { data, error } = await db.from("tasks").delete().eq("id", args.id).eq("user_id", uid).select("title").single();
      return { result: error ? { error: error.message } : { deleted: data.title }, changed: !error };
    }
    default:
      return { result: { error: `Unknown tool ${name}` }, changed: false };
  }
}

export type AgentInput = {
  db: Db;
  uid: string;
  name: string;
  messages: { role: string; text: string }[];
  today: string;
  now?: string;
  lang: string;
  // One line about where the user is talking from, added to the instructions.
  channel?: string;
  extraTools?: Record<string, ExtraTool>;
};

export type AgentOutput = { reply?: string; error?: string; status?: number; changed: boolean; actions: string[] };

export async function runAgent(input: AgentInput): Promise<AgentOutput> {
  const GEMINI_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
  if (!GEMINI_KEY) return { error: "GEMINI_API_KEY is not set", status: 500, changed: false, actions: [] };
  const { db, uid, name, messages, today, now, lang, channel, extraTools = {} } = input;

  const system = `You are FlowBase's personal secretary for ${name || "the user"}: an agent that plans and acts, not just a chatbot.
Today is ${today}${now ? `, and the time now is ${now}` : ""} (the user's local date and time). Reply in ${lang === "ar" ? "Arabic (friendly Gulf style)" : "English"}, short and clear.
${channel ?? ""}
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

  const tools = [{ functionDeclarations: [...baseTools, ...Object.values(extraTools).map((t) => t.declaration)] }];

  // deno-lint-ignore no-explicit-any
  const contents: any[] = messages.slice(-20).map((m) => ({
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
      const error = res.status === 429 ? "Daily free limit reached, try again later." : `Gemini error ${res.status}`;
      return { error, status: 502, changed, actions };
    }
    const out = await res.json();
    const parts = out.candidates?.[0]?.content?.parts ?? [];
    // deno-lint-ignore no-explicit-any
    const calls = parts.filter((p: any) => p.functionCall);
    if (calls.length === 0) {
      // deno-lint-ignore no-explicit-any
      const text = parts.map((p: any) => p.text ?? "").join("").trim();
      console.log("reply", step, actions.join(","), text.slice(0, 200));
      return { reply: text, changed, actions };
    }
    contents.push({ role: "model", parts });
    // deno-lint-ignore no-explicit-any
    const responses: any[] = [];
    for (const c of calls) {
      const fn = c.functionCall.name as string;
      const args = c.functionCall.args ?? {};
      const r = extraTools[fn] ? await extraTools[fn].run(args) : await runTool(db, uid, fn, args);
      console.log("tool", fn, JSON.stringify(args), JSON.stringify(r.result).slice(0, 300));
      changed ||= r.changed;
      if (r.changed) actions.push(fn);
      responses.push({ functionResponse: { name: fn, response: { result: r.result } } });
    }
    contents.push({ role: "user", parts: responses });
  }
  const reply = lang === "ar" ? "ما قدرت أكمل الطلب، جرّب تعيد صياغته." : "I couldn't finish that, please rephrase.";
  return { reply, changed, actions };
}

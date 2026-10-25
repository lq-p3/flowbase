// FlowBase AI secretary.
// The app sends the chat; this function asks Gemini, lets it use a few task
// tools, and returns the answer. The Gemini key lives only here (a Supabase
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
const tools = [{
  functionDeclarations: [
    {
      name: "list_spaces_and_projects",
      description: "List the user's spaces and projects with their ids.",
      parameters: { type: "object", properties: {} },
    },
    {
      name: "list_tasks",
      description: "List tasks between two dates (inclusive). Use it to answer questions like 'what do I have today' or 'what is overdue'.",
      parameters: {
        type: "object",
        properties: {
          from: { type: "string", description: "YYYY-MM-DD" },
          to: { type: "string", description: "YYYY-MM-DD" },
          include_done: { type: "boolean" },
        },
        required: ["from", "to"],
      },
    },
    {
      name: "create_task",
      description: "Create a new task. If no space fits, use the first space.",
      parameters: {
        type: "object",
        properties: {
          title: { type: "string" },
          date: { type: "string", description: "YYYY-MM-DD" },
          time: { type: "string", description: "HH:MM 24-hour, optional" },
          space_id: { type: "string" },
          project_id: { type: "string" },
          priority: { type: "string", enum: ["low", "medium", "high", "urgent"] },
          description: { type: "string" },
        },
        required: ["title", "date"],
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
          priority: { type: "string", enum: ["low", "medium", "high", "urgent"] },
          status: { type: "string", enum: ["todo", "inProgress", "done"] },
        },
        required: ["id"],
      },
    },
  ],
}];

// deno-lint-ignore no-explicit-any
async function runTool(db: any, name: string, args: Record<string, unknown>): Promise<{ result: unknown; changed: boolean }> {
  switch (name) {
    case "list_spaces_and_projects": {
      const { data: spaces } = await db.from("spaces").select("id, name").order("created_at");
      const { data: projects } = await db.from("projects").select("id, name, space_id, due").order("created_at");
      return { result: { spaces, projects }, changed: false };
    }
    case "list_tasks": {
      let q = db.from("tasks").select("id, title, date, time, priority, status, space_id, project_id")
        .gte("date", args.from).lte("date", args.to).order("date").limit(100);
      if (!args.include_done) q = q.neq("status", "done");
      const { data, error } = await q;
      return { result: error ? { error: error.message } : data, changed: false };
    }
    case "create_task": {
      let spaceId = args.space_id as string | undefined;
      if (!spaceId) {
        const { data } = await db.from("spaces").select("id").order("created_at").limit(1);
        spaceId = data?.[0]?.id;
      }
      if (!spaceId) return { result: { error: "The user has no spaces yet." }, changed: false };
      const { data, error } = await db.from("tasks").insert({
        title: args.title,
        date: args.date,
        time: args.time ?? null,
        space_id: spaceId,
        project_id: args.project_id ?? null,
        priority: args.priority ?? "medium",
        description: args.description ?? "",
      }).select("id, title, date, time").single();
      return { result: error ? { error: error.message } : data, changed: !error };
    }
    case "update_task": {
      const fields: Record<string, unknown> = {};
      for (const k of ["title", "date", "time", "priority", "status"]) if (args[k] !== undefined) fields[k] = args[k];
      const { data, error } = await db.from("tasks").update(fields).eq("id", args.id).select("id, title, date, time, status").single();
      return { result: error ? { error: error.message } : data, changed: !error };
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

  const { messages = [], today, lang = "ar" } = await req.json();
  const name = user.user_metadata?.full_name ?? "";
  const system = `You are FlowBase's personal secretary for ${name || "the user"}.
Today is ${today} (the user's local date). Reply in ${lang === "ar" ? "Arabic (friendly Gulf style)" : "English"}, short and clear.
Use the tools to read or change the user's tasks; never invent tasks or ids. Look up spaces and projects before choosing one.
Resolve words like "tomorrow" or "next Sunday" to real dates from today.
When the user asks you to add, remind, schedule or plan something, CALL create_task right away (one call per task).
Do not ask for confirmation and do not say a task was added unless the tool returned it; pick sensible defaults
(first matching space, no time if none was given, "8 at night" = 20:00, "8 in the morning" = 08:00).
After changing something, say exactly what you did (title, date, time). Do not delete anything.`;

  // deno-lint-ignore no-explicit-any
  const contents: any[] = messages.slice(-20).map((m: { role: string; text: string }) => ({
    role: m.role === "user" ? "user" : "model",
    parts: [{ text: m.text }],
  }));

  let changed = false;
  const actions: string[] = [];
  for (let step = 0; step < 6; step++) {
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

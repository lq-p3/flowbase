// Morning brief on Telegram.
// pg_cron calls this function every hour (see the morning_brief migration). For every linked user
// whose local time is 8 AM, we send a short summary of today's tasks and the overdue count.
// The message is written here in code, not by Gemini, so it costs none of the free AI quota.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { localNow, tg } from "../_shared/telegram.ts";

const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
const HOUR = "08";

type Task = { title: string; time: string | null; priority: string; assignee: { name: string } | null };

function compose(name: string, today: Task[], overdue: number, teamLate: Record<string, number>): string {
  const lines = [`صباح الخير${name ? " " + name : ""} ☀️`];
  if (today.length === 0) {
    lines.push("ما عندك مهام اليوم، يومك فاضي 👌");
  } else {
    lines.push(`عندك ${today.length} ${today.length === 1 ? "مهمة" : "مهام"} اليوم:`, "");
    for (const t of today) {
      const time = t.time ? t.time.slice(0, 5) + " " : "";
      const flag = t.priority === "high" || t.priority === "urgent" ? " 🔸" : "";
      const who = t.assignee ? ` (${t.assignee.name})` : "";
      lines.push(`• ${time}${t.title}${who}${flag}`);
    }
  }
  if (overdue > 0) lines.push("", `⚠️ وعندك ${overdue} متأخرة. قل لي "رتّبها" وأنقلها لأيام مناسبة.`);
  const late = Object.entries(teamLate);
  if (late.length) lines.push("", `👥 متأخر عند الفريق: ${late.map(([n, c]) => `${n} (${c})`).join("، ")}`);
  return lines.join("\n");
}

async function briefFor(link: { chat_id: number; user_id: string; tz: string }, today: string) {
  const uid = link.user_id;
  const [{ data: tasks }, { count }, { data: { user } }] = await Promise.all([
    db.from("tasks").select("title, time, priority, assignee:team_members(name)").eq("user_id", uid).eq("date", today)
      .neq("status", "done").order("time", { ascending: true, nullsFirst: false }),
    db.from("tasks").select("id", { count: "exact", head: true }).eq("user_id", uid)
      .lt("date", today).neq("status", "done").is("assignee_id", null),
    db.auth.admin.getUserById(uid),
  ]);
  // Overdue tasks of team members, counted per person.
  const { data: late } = await db.from("tasks").select("assignee:team_members(name)").eq("user_id", uid)
    .lt("date", today).neq("status", "done").not("assignee_id", "is", null);
  const teamLate: Record<string, number> = {};
  for (const t of (late ?? []) as unknown as Task[]) if (t.assignee) teamLate[t.assignee.name] = (teamLate[t.assignee.name] ?? 0) + 1;
  const name = (user?.user_metadata?.full_name as string | undefined)?.split(" ")[0] ?? "";
  const text = compose(name, (tasks ?? []) as unknown as Task[], count ?? 0, teamLate);
  await tg("sendMessage", { chat_id: link.chat_id, text });
  // Save it in the chat history, so if the user replies "رتّبها" the secretary knows what they mean.
  await db.from("telegram_messages").insert({ user_id: uid, role: "model", text });
  await db.from("telegram_links").update({ last_brief: today }).eq("chat_id", link.chat_id);
}

Deno.serve(async (req) => {
  // Only pg_cron knows this value: it is stored in the private app_secrets table.
  const { data: secret } = await db.from("app_secrets").select("value").eq("name", "brief").single();
  if (!secret || req.headers.get("x-brief-secret") !== secret.value) {
    return new Response("forbidden", { status: 403 });
  }
  // {"test": true} sends to everyone right now, ignoring the hour and today's earlier brief.
  const test = (await req.json().catch(() => ({})))?.test === true;

  const { data: links } = await db.from("telegram_links").select("chat_id, user_id, tz, last_brief");
  let sent = 0;
  for (const link of links ?? []) {
    const { today, now } = localNow(link.tz ?? "Asia/Riyadh");
    if (!test && (now.slice(0, 2) !== HOUR || link.last_brief === today)) continue;
    try {
      await briefFor(link, today);
      sent++;
    } catch (e) {
      console.error("brief failed", link.chat_id, e);
    }
  }
  return Response.json({ sent });
});

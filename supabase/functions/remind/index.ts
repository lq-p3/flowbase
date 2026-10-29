// Task reminders on Telegram.
// pg_cron calls this function every 5 minutes (see the task_reminders migration). For each linked
// user we find today's open tasks that start in the next 30 minutes and send one message per task
// with two buttons: "done" and "snooze 1 hour". The telegram function handles the button taps.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { localNow, tg } from "../_shared/telegram.ts";

const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
const AHEAD = 30; // minutes

// "09:40" + 30 minutes = "10:10". Past midnight we stop at 23:59, the reminder is for today only.
function addMinutes(hhmm: string, minutes: number): string {
  const [h, m] = hhmm.split(":").map(Number);
  const total = Math.min(h * 60 + m + minutes, 23 * 60 + 59);
  return `${String(Math.floor(total / 60)).padStart(2, "0")}:${String(total % 60).padStart(2, "0")}`;
}

Deno.serve(async (req) => {
  // Only pg_cron knows this value: it is stored in the private app_secrets table.
  const { data: secret } = await db.from("app_secrets").select("value").eq("name", "remind").single();
  if (!secret || req.headers.get("x-cron-secret") !== secret.value) {
    return new Response("forbidden", { status: 403 });
  }

  const { data: links } = await db.from("telegram_links").select("chat_id, user_id, tz");
  let sent = 0;
  for (const link of links ?? []) {
    const { today, now } = localNow(link.tz ?? "Asia/Riyadh");
    const { data: tasks } = await db.from("tasks").select("id, title, time")
      .eq("user_id", link.user_id).eq("date", today).eq("reminder", true).neq("status", "done")
      .is("tg_reminded", null).gte("time", now).lte("time", addMinutes(now, AHEAD));
    for (const t of tasks ?? []) {
      const r = await tg("sendMessage", {
        chat_id: link.chat_id,
        text: `⏰ تذكير: ${t.title}\nالساعة ${t.time.slice(0, 5)}`,
        reply_markup: {
          inline_keyboard: [[
            { text: "✅ خلصت", callback_data: `done:${t.id}` },
            { text: "⏰ أجّل ساعة", callback_data: `snooze:${t.id}` },
          ]],
        },
      });
      if (!r.ok) {
        console.error("remind send failed", link.chat_id, r.description);
        continue;
      }
      await db.from("tasks").update({ tg_reminded: new Date().toISOString() }).eq("id", t.id);
      sent++;
    }
  }
  return Response.json({ sent });
});

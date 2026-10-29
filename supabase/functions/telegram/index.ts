// FlowBase secretary on Telegram.
// Telegram calls this function (a webhook) for every message sent to the bot. We find which
// FlowBase user owns the chat, run the same agent as the app (../_shared/agent.ts) and send the
// reply back. Opening the function URL with ?setup=1 points the bot's webhook here.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { runAgent } from "../_shared/agent.ts";
import { botToken, localNow, tg, webhookSecret } from "../_shared/telegram.ts";

const url = Deno.env.get("SUPABASE_URL")!;
// The server key: there is no user login here, so the agent filters every query by user_id itself.
const db = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

const say = (chatId: number, text: string) =>
  tg("sendMessage", { chat_id: chatId, text: text.slice(0, 4000) || "…" });

const HELP = "أهلاً 👋 أنا سكرتير FlowBase.\n" +
  "عشان أعرفك: افتح تطبيق FlowBase، وقل للسكرتير ✨ \"اربط تيليجرام\"، واضغط الرابط اللي يعطيك.";

// A tap on a reminder button ("done:<task id>" or "snooze:<task id>", sent by the remind function).
// deno-lint-ignore no-explicit-any
async function handleButton(cb: any) {
  const chatId: number = cb.message?.chat?.id;
  const answer = (text: string) => tg("answerCallbackQuery", { callback_query_id: cb.id, text });
  const { data: link } = await db.from("telegram_links").select("user_id").eq("chat_id", chatId).maybeSingle();
  const [action, taskId] = String(cb.data ?? "").split(":");
  // Only a task of the user who owns this chat, so a forged button cannot touch someone else's task.
  const { data: task } = link && taskId
    ? await db.from("tasks").select("id, title, date, time").eq("id", taskId).eq("user_id", link.user_id).maybeSingle()
    : { data: null };
  if (!task) return void await answer("المهمة ما عادت موجودة");

  let text: string;
  if (action === "done") {
    await db.from("tasks").update({ status: "done" }).eq("id", task.id);
    text = `✅ خلصت: ${task.title}`;
  } else if (action === "snooze") {
    // One hour later; past midnight it moves to the next day. The date and time are local, so we do
    // the sum as if they were UTC, which never shifts them.
    const later = new Date(new Date(`${task.date}T${task.time ?? "09:00:00"}Z`).getTime() + 60 * 60 * 1000);
    const date = later.toISOString().slice(0, 10), time = later.toISOString().slice(11, 16);
    await db.from("tasks").update({ date, time }).eq("id", task.id);
    text = `⏰ أجّلت "${task.title}" للساعة ${time}${date !== task.date ? " بكرة" : ""}`;
  } else {
    return void await answer("");
  }
  await answer(text);
  // Replace the reminder with the result, so the buttons cannot be tapped twice.
  await tg("editMessageText", { chat_id: chatId, message_id: cb.message.message_id, text });
}

async function handle(update: Record<string, unknown>) {
  if (update.callback_query) return void await handleButton(update.callback_query);
  // deno-lint-ignore no-explicit-any
  const msg = update.message as any;
  if (!msg?.text || msg.chat?.type !== "private") return;
  const chatId: number = msg.chat.id;
  const text: string = msg.text.trim();

  // "/start CODE" comes from the link the app chat gave out.
  if (text.startsWith("/start")) {
    const code = text.split(" ")[1];
    if (!code) return void await say(chatId, HELP);
    const { data: row } = await db.from("telegram_link_codes").select("user_id, expires_at").eq("code", code).maybeSingle();
    if (!row || new Date(row.expires_at) < new Date()) {
      return void await say(chatId, "الرابط انتهى أو غلط. اطلب رابط جديد من السكرتير في التطبيق.");
    }
    await db.from("telegram_link_codes").delete().eq("user_id", row.user_id);
    // One chat per user: drop any older link first.
    await db.from("telegram_links").delete().or(`user_id.eq.${row.user_id},chat_id.eq.${chatId}`);
    await db.from("telegram_links").insert({ chat_id: chatId, user_id: row.user_id });
    return void await say(chatId, "تم الربط ✅ الحين تقدر تكلّمني هنا مثل التطبيق بالضبط. جرّب: \"وش عندي اليوم؟\"");
  }

  const { data: link } = await db.from("telegram_links").select("user_id, tz").eq("chat_id", chatId).maybeSingle();
  if (!link) return void await say(chatId, HELP);
  const uid = link.user_id as string;

  if (text === "/unlink") {
    await db.from("telegram_links").delete().eq("chat_id", chatId);
    await db.from("telegram_messages").delete().eq("user_id", uid);
    return void await say(chatId, "فصلت تيليجرام عن حسابك 👋");
  }

  await tg("sendChatAction", { chat_id: chatId, action: "typing" });
  await db.from("telegram_messages").insert({ user_id: uid, role: "user", text });
  const { data: history } = await db.from("telegram_messages").select("role, text").eq("user_id", uid)
    .order("id", { ascending: false }).limit(20);
  const { data: { user } } = await db.auth.admin.getUserById(uid);
  const { today, now } = localNow(link.tz);

  const out = await runAgent({
    db, uid, name: user?.user_metadata?.full_name ?? "", messages: (history ?? []).reverse(), today, now, lang: "ar",
    channel: "The user is writing from Telegram: plain text only, no Markdown.",
  });
  const reply = out.reply ?? (out.status === 502 && out.error?.startsWith("Daily")
    ? "خلص الحد المجاني اليوم، جرّب بعدين 🙏"
    : "الذكاء الاصطناعي مشغول الحين، جرّب بعد دقيقة 🙏");
  // Save the reply even when it is an error, so the next message knows this one was answered.
  await db.from("telegram_messages").insert({ user_id: uid, role: "model", text: reply });
  await say(chatId, reply);
}

Deno.serve(async (req) => {
  if (!botToken()) return new Response("TELEGRAM_BOT_TOKEN is not set", { status: 500 });
  const secret = await webhookSecret();

  if (new URL(req.url).searchParams.get("setup") === "1") {
    const r = await tg("setWebhook", {
      url: `${url}/functions/v1/telegram`, secret_token: secret, allowed_updates: ["message", "callback_query"], drop_pending_updates: true,
    });
    return new Response(JSON.stringify(r), { headers: { "Content-Type": "application/json" } });
  }

  if (req.headers.get("X-Telegram-Bot-Api-Secret-Token") !== secret) return new Response("forbidden", { status: 403 });
  const update = await req.json();
  // Answer Telegram right away and do the work in the background, so a slow reply is not sent twice.
  EdgeRuntime.waitUntil(handle(update).catch((e) => console.error("telegram", e)));
  return new Response("ok");
});

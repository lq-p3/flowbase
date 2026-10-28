// FlowBase AI secretary, the in-app chat.
// The app sends the chat; the shared agent (../_shared/agent.ts) asks Gemini, lets it plan and
// use tools on the user's projects and tasks, and returns the answer. The Gemini key lives only
// here (a Supabase secret), and every database call runs as the signed-in user, so Row Level
// Security still limits it to that user's own rows.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { runAgent } from "../_shared/agent.ts";
import { botToken, tg } from "../_shared/telegram.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const auth = req.headers.get("Authorization") ?? "";
  const url = Deno.env.get("SUPABASE_URL")!;
  const db = createClient(url, (Deno.env.get("SUPABASE_ANON_KEY") ?? Deno.env.get("SUPABASE_PUBLISHABLE_KEY"))!, {
    global: { headers: { Authorization: auth } },
  });
  const { data: { user } } = await db.auth.getUser(auth.replace("Bearer ", ""));
  if (!user) return json({ error: "Not signed in" }, 401);

  const { messages = [], today, now, lang = "ar" } = await req.json();

  // Linking Telegram: the app chat hands out a one-time code, and the user opens the bot with it.
  const linkTelegram = {
    declaration: {
      name: "telegram_link_code",
      description: "Give the user a link that connects their Telegram to this secretary. Use it when they ask to connect, link or use Telegram.",
      parameters: { type: "object", properties: {} },
    },
    run: async () => {
      if (!botToken()) return { result: { error: "The Telegram bot is not set up yet." }, changed: false };
      const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
      const code = crypto.randomUUID().replaceAll("-", "").slice(0, 16);
      const { error } = await admin.from("telegram_link_codes").insert({
        code, user_id: user.id, expires_at: new Date(Date.now() + 15 * 60_000).toISOString(),
      });
      if (error) return { result: { error: error.message }, changed: false };
      const me = await tg("getMe", {});
      const link = `https://t.me/${me.result?.username}?start=${code}`;
      return { result: { link, note: "Valid for 15 minutes. Tell the user to open it and press Start." }, changed: false };
    },
  };

  const out = await runAgent({
    db, uid: user.id, name: user.user_metadata?.full_name ?? "", messages, today, now, lang,
    extraTools: { telegram_link_code: linkTelegram },
  });
  if (out.error) return json({ error: out.error }, out.status ?? 500);
  return json({ reply: out.reply, changed: out.changed, actions: out.actions });
});

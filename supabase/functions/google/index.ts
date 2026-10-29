// Google sign-in callback. The secretary gives the user a Google link (google_link tool); after they
// allow access, Google sends them back here with a one-time code, and we save their calendar link.
// Supabase serves function pages as plain text (no HTML on its own domain), so the answer is plain text.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { finishLink } from "../_shared/google.ts";

const say = (text: string) => new Response(text, { headers: { "Content-Type": "text/plain; charset=utf-8" } });

Deno.serve(async (req) => {
  const q = new URL(req.url).searchParams;
  const state = q.get("state"), code = q.get("code");
  if (q.get("error") || !state || !code) return say("ما تم الربط ❌ رجعت بدون موافقة. اطلب رابط جديد من السكرتير.");
  return say(await finishLink(state, code)
    ? "تم ربط تقويم Google ✅\n\nارجع لـ FlowBase أو تيليجرام، واسأل السكرتير: وش مواعيدي بكرة؟"
    : "الرابط انتهى ❌ اطلب رابط جديد من السكرتير وجرّب مرة ثانية.");
});

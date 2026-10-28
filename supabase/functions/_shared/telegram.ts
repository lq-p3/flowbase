// Small helpers for the Telegram Bot API. The bot token is the Supabase secret TELEGRAM_BOT_TOKEN.

export const botToken = () => Deno.env.get("TELEGRAM_BOT_TOKEN") ?? "";

// deno-lint-ignore no-explicit-any
export async function tg(method: string, body: Record<string, unknown>): Promise<any> {
  const res = await fetch(`https://api.telegram.org/bot${botToken()}/${method}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  return await res.json();
}

// Telegram sends this value back in a header on every webhook call, so we know the call is really
// from Telegram. It is derived from the bot token, so it needs no extra secret.
export async function webhookSecret(): Promise<string> {
  const hash = await crypto.subtle.digest("SHA-256", new TextEncoder().encode("flowbase-webhook:" + botToken()));
  return Array.from(new Uint8Array(hash)).map((b) => b.toString(16).padStart(2, "0")).join("").slice(0, 48);
}

// Today's date and the time now in a time zone, like the app sends them.
export function localNow(tz: string): { today: string; now: string } {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat("en-CA", {
      timeZone: tz, year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", hourCycle: "h23",
    }).formatToParts(new Date()).map((p) => [p.type, p.value]),
  );
  return { today: `${parts.year}-${parts.month}-${parts.day}`, now: `${parts.hour}:${parts.minute}` };
}

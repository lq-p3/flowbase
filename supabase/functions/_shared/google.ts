// Google Calendar for the secretary. The OAuth client (GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET) is
// created by the app owner in Google Cloud and stored as Supabase secrets. Each user links their own
// Google account once; we keep only their refresh token, in a table the app cannot read.
import { createClient } from "npm:@supabase/supabase-js@2";

const URL_ = Deno.env.get("SUPABASE_URL")!;
const admin = createClient(URL_, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
const CLIENT_ID = Deno.env.get("GOOGLE_CLIENT_ID") ?? "";
const CLIENT_SECRET = Deno.env.get("GOOGLE_CLIENT_SECRET") ?? "";
export const REDIRECT_URI = `${URL_}/functions/v1/google`;
const SCOPE = "https://www.googleapis.com/auth/calendar.events openid email";

export const googleReady = () => !!CLIENT_ID && !!CLIENT_SECRET;

// A Google sign-in link for this user, valid for 15 minutes.
export async function linkUrl(uid: string): Promise<string> {
  const state = crypto.randomUUID().replaceAll("-", "");
  await admin.from("google_link_states").insert({ state, user_id: uid, expires_at: new Date(Date.now() + 15 * 60_000).toISOString() });
  const q = new URLSearchParams({
    client_id: CLIENT_ID, redirect_uri: REDIRECT_URI, response_type: "code", scope: SCOPE,
    // offline + consent: Google gives a refresh token, so we can keep working without the user.
    access_type: "offline", prompt: "consent", state,
  });
  return `https://accounts.google.com/o/oauth2/v2/auth?${q}`;
}

// The callback: trade the one-time code for tokens and save the refresh token.
export async function finishLink(state: string, code: string): Promise<boolean> {
  const { data: row } = await admin.from("google_link_states").select("user_id, expires_at").eq("state", state).maybeSingle();
  if (!row || new Date(row.expires_at) < new Date()) return false;
  await admin.from("google_link_states").delete().eq("state", state);
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    body: new URLSearchParams({ code, client_id: CLIENT_ID, client_secret: CLIENT_SECRET, redirect_uri: REDIRECT_URI, grant_type: "authorization_code" }),
  });
  const tok = await res.json();
  if (!tok.refresh_token) {
    console.error("google token", res.status, JSON.stringify(tok).slice(0, 300));
    return false;
  }
  // The id_token is a signed JWT straight from Google; we only read the email out of it for display.
  let email: string | null = null;
  try {
    email = JSON.parse(atob(tok.id_token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/"))).email ?? null;
  } catch { /* no email, fine */ }
  await admin.from("google_links").upsert({ user_id: row.user_id, refresh_token: tok.refresh_token, email });
  return true;
}

async function accessToken(uid: string): Promise<string | null> {
  const { data: link } = await admin.from("google_links").select("refresh_token").eq("user_id", uid).maybeSingle();
  if (!link) return null;
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    body: new URLSearchParams({ refresh_token: link.refresh_token, client_id: CLIENT_ID, client_secret: CLIENT_SECRET, grant_type: "refresh_token" }),
  });
  const tok = await res.json();
  if (!tok.access_token) console.error("google refresh", res.status, tok.error);
  return tok.access_token ?? null;
}

const NOT_LINKED = { error: "Google Calendar is not linked. Offer the user the google_link tool." };

// Events whose start falls between two local dates (inclusive), in the user's time zone.
export async function listEvents(uid: string, from: string, to: string, tz: string) {
  const token = await accessToken(uid);
  if (!token) return NOT_LINKED;
  // Ask a day wider on each side in UTC, then keep the ones that start on the wanted local dates.
  const day = 86_400_000;
  const q = new URLSearchParams({
    timeMin: new Date(Date.parse(`${from}T00:00:00Z`) - day).toISOString(),
    timeMax: new Date(Date.parse(`${to}T23:59:59Z`) + day).toISOString(),
    singleEvents: "true", orderBy: "startTime", timeZone: tz, maxResults: "100",
  });
  const res = await fetch(`https://www.googleapis.com/calendar/v3/calendars/primary/events?${q}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const out = await res.json();
  if (!res.ok) return { error: out.error?.message ?? `Google error ${res.status}` };
  // deno-lint-ignore no-explicit-any
  return (out.items ?? []).map((e: any) => ({
    title: e.summary ?? "(no title)",
    start: e.start?.dateTime?.slice(0, 16) ?? e.start?.date,
    end: e.end?.dateTime?.slice(0, 16) ?? e.end?.date,
    all_day: !e.start?.dateTime,
    location: e.location,
  // deno-lint-ignore no-explicit-any
  })).filter((e: any) => e.start.slice(0, 10) >= from && e.start.slice(0, 10) <= to);
}

// Add an event to the user's main calendar. date YYYY-MM-DD, time HH:MM local.
export async function createEvent(uid: string, tz: string, a: Record<string, unknown>) {
  const token = await accessToken(uid);
  if (!token) return NOT_LINKED;
  const minutes = Number(a.minutes ?? 60);
  const start = `${a.date}T${String(a.time).slice(0, 5)}:00`;
  // Local date and time plus minutes, done in UTC so it never shifts.
  const end = new Date(Date.parse(`${start}Z`) + minutes * 60_000).toISOString().slice(0, 19);
  const res = await fetch("https://www.googleapis.com/calendar/v3/calendars/primary/events", {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      summary: a.title, description: a.description ?? "", location: a.location ?? undefined,
      start: { dateTime: start, timeZone: tz }, end: { dateTime: end, timeZone: tz },
    }),
  });
  const out = await res.json();
  if (!res.ok) return { error: out.error?.message ?? `Google error ${res.status}` };
  return { created: out.summary, start: out.start?.dateTime, end: out.end?.dateTime, link: out.htmlLink };
}

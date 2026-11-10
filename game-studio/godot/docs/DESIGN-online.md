# Design: Online layer (accounts, Hall of Fame, absence pressure)

Status: design proposal for VU's approval. Nothing here is implemented. Date: 2026-11-10.

## 1. Goals (from VU)
1. Many players; each day's answers and results are saved to an **achievement board**.
2. **Employee of the Month** and rankings between players, a "Wall of Fame".
3. If a player stops logging in ("skips work"), the game sends a **notification** with warnings: fines, lost reputation, risk of being "let go" unless there is a valid reason, in a mix of scolding and humor, to bring them back and keep their streak.

## 2. Key design choice: asynchronous, seeded, server-verified
The simulation is already deterministic by seed. So:
- **Daily shared scenario**: the server publishes one seed per calendar day (UTC). Every player faces the same boss question and news that day (fair ranking, shared talk about "today's market").
- **Players send inputs, not results**: the client submits the day's choices (pinned evidence uids, tool uses, forecast, confidence, actions, submit time, life choices summary). The server **re-simulates** with the same code (Godot headless or a port) and computes the score itself. Client-reported scores are never trusted (anti-cheat), and hidden truth stays on the server until the day closes (it is not shipped in advance in any answer table).
- Consequence: the client must not contain the day's answers before the day ends. Today `WorldGame` computes the truth locally. For online mode the truth moves to the server: the client receives the public news feed, sends its report, then receives the review. This is a real change to the architecture (see phases).

## 3. Accounts and data
- Login: email magic link or OAuth (Google/Apple), plus a **pseudonymous display name** (the only thing other players see). Never show email or real name. Name moderation: blocklist + report button.
- Stored per account: account id, display name, consent flags, per-day results (day id, seed id, score parts, rank, tags like LATE), streak, vitals/wallet summary, achievements, notification token(s) and preferences.
- Data minimization: no location, no contacts, no device identifiers beyond a push token. Provide **export and delete my data**. Treat as personal data under GDPR (CLAUDE.md section 6 rule: consult CNIL or a lawyer; this is engineering guidance, not legal advice). Parental/age gating decision needed if minors may play (store policy).

## 4. Boards and ranking
- **Daily board**: score of the day among players who finished.
- **Monthly board** and **Employee of the Month**: sum of best N days (e.g. best 20 of the month) plus tie-breakers (accuracy, trust gain, fewer LATE reports). Winner gets a permanent plaque on the **Wall of Fame** (a scene in the office: framed photos of past winners' pixel avatars with their display name, month, a title).
- **All-time hall**: longest streak, highest rank reached (Director), best single day, "Most Honest Analyst" (accuracy with high confidence), "Never Late".
- **Friends/office leagues**: optional private groups ("departments") with their own board, so small groups can compete.
- Leagues by rank tier so beginners are not crushed by veterans (Intern/Junior league up to Senior/Director league), plus promotion/relegation by month.
- Anti-abuse: server re-simulation, rate limits, one run per day per account, reports/shadow-ban for cheating, no real-money rewards.

## 5. Absence mechanics ("skipping work")
A server-side **attendance ladder** per account, counted in missed calendar days since last finished day. It only changes **in-game** values (pay, bonus, reputation, rank); never real money or purchases.

| Missed days | Effect | Message tone |
|---|---|---|
| 1 | Reminder, no penalty | Friendly nudge |
| 2 | Verbal warning in the next review, small bonus loss | Teasing |
| 3 | Fine (percentage of in-game wallet, capped), reputation -x | Scolding with humor |
| 5 | Formal warning, rank at risk | Dramatic |
| 7 | "Termination notice" (HR letter) | Over-the-top |
| 8+ | Employment ends **only if** no leave covers it; account is never deleted: the player "is rehired" next login as an Intern with their history kept | Comedy |

Fairness valves (important so it feels fun, not punishing):
- **Leave days**: a monthly allowance (e.g. 3 days) plus "Request leave" in advance (sick day, vacation, "valid reason" picker). Covered days cost nothing and do not break the streak.
- **Streak freeze** item earned from performance.
- Penalties are capped so a returning player is never in a hopeless hole; a **"Welcome back" bonus** softens the return.
- Penalties never touch hidden fairness of the daily score.

## 6. Notifications
- **Opt-in** at first run with a clear explanation; separate toggles for reminders, warnings, leaderboard news; global off switch in settings; quiet hours (default 21:00 to 08:00 local); frequency cap (max 1 per day; escalation within the ladder only).
- Channels by platform: desktop (Windows toast through a tiny companion or OS API), mobile push (FCM/APNs) if there is a mobile build, email digest as a fallback. Needs a platform decision (see section 9).
- No manipulative tricks: no fake urgency about real money, no guilt about real-life obligations, no shaming other players; humor must be about the fictional boss and company. The reminder lines come from the boss and colleagues, never from "the game" threatening the person.
- Sample lines (English, original):
  - Day 1: "Ms. Hanh: Your chair is feeling lonely. It asked me to ask you where you are."
  - Day 2: "Khoi: I covered your desk plant. It says it's not your coworker, it's your responsibility."
  - Day 3: "HR: You have been absent for 3 days. A fine of $X was deducted. The coffee machine misses you more than the bank does."
  - Day 5: "Ms. Hanh: Official warning. Your market forecast today was 'I don't know' by not submitting. Bold choice."
  - Day 7: "HR: Dear employee, this is a termination notice. Unless you have a valid reason: like a cat on the keyboard. Cat on keyboard counts."
  - Return: "Welcome back! Khoi says you owe him a coffee for the cover story."
- Personalization only from public in-game data (streak, last rank, favorite shop). No sensitive content.

## 7. Architecture options (server side)
| Option | What | Pros | Cons |
|---|---|---|---|
| A. Managed backend (e.g. a BaaS with auth, database, functions, push) | Hosted auth + DB + serverless functions that run the verifier | Fast to build, push/email built in, low ops | Vendor lock-in, per-use cost, need to port the simulation to the function runtime or call a Godot headless worker |
| B. Small custom server (Godot headless re-simulator + REST + Postgres) | One service reusing the same GDScript | Exact same simulation code, full control | More ops, security, hosting cost, scaling is on us |
| C. Fully offline + local boards | Local Hall of Fame, no server | Free, private | No real online play |

Recommendation: **A or B with a Godot headless verifier**, preceded by phase 0 (offline).

## 8. Phases
0. **Offline groundwork (can start now, no server)**: local Hall of Fame and Wall of Fame scene, Employee of the Month from local runs, achievements, attendance ladder simulated from real dates with leave days, humorous warning messages shown on game start ("while you were away"). Refactor so the daily seed and the review truth can come from an interface (`DaySource`) with a local implementation. Add the input-log format for runs.
1. **Server skeleton**: accounts, daily seed publish, submit inputs, verify and store, daily/monthly boards, display names. Staging only.
2. **Social and retention**: Wall of Fame sync, leagues, leave requests, notifications (opt-in), email digests.
3. **Hardening**: anti-cheat, moderation, privacy tooling (export/delete), load tests, store compliance, analytics with consent (aggregate only).

## 9. Decisions needed from VU before building beyond phase 0
1. Target platforms: Windows/PC only, plus web, plus mobile? (decides notification channel and store rules)
2. OK to choose a hosted backend and pay for it (monthly cost, account creation)? I cannot create accounts or spend money; you do that.
3. Who may play: age limit/minors? Languages besides English?
4. Notification wording intensity (mild/medium/spicy) and whether fines also cut the "Employee of the Month" score.
5. Legal review (GDPR/CNIL) before any public launch with accounts and notifications.

## 10. What I will not do without approval
Create hosted accounts, send any real notification, collect real player data, push anything to GitHub, spend money, or publish the game publicly.

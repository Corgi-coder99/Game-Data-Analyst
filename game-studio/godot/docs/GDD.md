# GDD: Data Corp (working title)

Version 0.2, 2026-11-10. Owner: Claude (design). Figures match `data/config.json` after T-012 (sections 3, 4, 6, 7, 8, 10 updated). The real values always come from `data/`; when they differ, `data/` is right.

## 1. Summary

A light strategy game, single player, card plus dashboard format. The player is the Lead Data Analyst of a startup that is running out of money. Each week they read the dashboard, find the root cause of the problems, and use decision cards to handle them. Survive and grow over 30 weeks.

Audience: IT people, data analysts, marketers, economics students. A run lasts 10 to 15 minutes (10 weeks for the demo).

Learning goals: tell symptoms from causes, read LTV/CAC, churn and conversion, trust data to the right degree.

## 2. Gameplay loop (each week)

1. **Report:** the dashboard shows the metrics and 1 chart (funnel, cohort or time series).
2. **Event:** 1 random event that may cause noise (competitor discount, server outage, trend shift).
3. **Draw cards:** draw 4 cards from the deck. There are 3 Data Energy per week to play cards.
4. **Choose actions:** playing a card costs Budget and Energy.
5. **Result:** simulate 1 week, update the metrics, show the difference compared with the prediction.

## 3. Metrics

| Metric | Meaning | Starting value |
|---|---|---|
| Cash | Cash on hand. Reaching 0 means losing | 18,000 |
| Users | Active users | 1,000 |
| ARPU | Revenue per user per week | 24 |
| Conversion | Share of users who pay (cap 8%) | 1% |
| Retention | Share kept each week, Churn = 1 - Retention (cap 95%) | 85% |
| CAC | Cost of acquiring 1 new user | 80 |
| LTV | ARPU x average lifetime (1 / Churn) | computed |
| LTV/CAC | Target of 3 or more | computed |
| Data Integrity | Data reliability, 0 to 100 | 80 |

When Data Integrity is low, charts show noisy numbers (the error grows as the level falls). The Clean Data card restores this metric.

## 4. Weekly economic model

```
new_users   = ad_spend / effective_CAC
churned     = Users x (1 - Retention)
Users'      = max(0, Users - churned + new_users)
revenue     = Users' x Conversion x ARPU
Cash'       = Cash - spending + revenue
```

- `effective_CAC = CAC x (1 + 0.01 x (ad_spend / 1000))`: the more is spent on ads, the more expensive it gets (diminishing returns).
- Fixed weekly cost (salaries, servers): 200, plus 0.05 per user.
- At the starting values, if you do nothing the company loses very slightly and shrinks slowly (about 850 users remain in week 1). Upgrade cards (Onboarding, Fix Checkout, Support, SEO) lose half their effectiveness each time they are replayed, so they do not stack infinitely.
- All coefficients live in `data/` (JSON), not hard-coded.

## 5. Decision cards (first version: 12 cards, each with Budget and Energy)

**Analysis:** SQL Deep-Dive (shows Retention per cohort), A/B Test (gives a prediction close to the next card's effect), Funnel Report (shows the leaking step), Clean Data (raises Data Integrity).

**Optimization:** Fix Checkout Bug (Conversion rises), Onboarding Redesign (Retention rises), Support Automation (lowers fixed cost).

**Growth:** Ads Campaign (buy users), Influencer Campaign (many users, Retention drops if Onboarding is not yet optimized), Loyalty Program (Retention rises, steady Budget cost), SEO Content (CAC falls slowly).

**Risk:** Discount (Conversion rises but ARPU falls).

The specific effect of each card is determined by `data/cards.json`.

## 6. Events (first version: 8 events)

Each event has a hidden **root cause** and a **symptom** shown on the dashboard. The player must tell the two apart.

Example: Retention drops. The cause may be an app bug (shown in one cohort), a competitor discount (shown in the price-sensitive group), or a faulty log (low Data Integrity, in reality nothing happened). The right analysis card helps reveal the cause. **A remedy card only removes an event once its cause has been revealed.** Playing a remedy card by "guessing" still has the card's own effect, but the event remains and does not count toward the handled-event score.

## 7. Winning and losing

- **Lose:** Cash reaches 0, or LTV/CAC is below 1 for 4 consecutive weeks while Cash is below 2,000.
- **Win:** get through all the weeks of the run and keep the company. Demo (10 weeks): Cash of at least 9,500, LTV/CAC of at least 2, and Users of at least 750 (75% of the starting number). Full game (30 weeks): Cash of at least 15,000, LTV/CAC of at least 2, Users of at least 750.
- **Score:** a winning run = 1,000 + 0.1 x Cash + 100 x min(LTV/CAC, 5) + 100 x correctly handled events. A losing run scores at most 900 (based on weeks survived and correctly handled events), so it is always below any winning run.

## 8. Difficulty

The weekly event probability rises by phase: weeks 1 to 10 are 45%, weeks 11 to 20 are 55%, weeks 21 to 30 are 70%. Data Integrity declines from week 11 (1 point per week), and from week 21 (2 points per week), so data gets noisier later.

## 9. Interface and art

- 640x360 screen, integer scaling, nearest filter (configured in `project.godot`).
- A dark company-dashboard theme, following the style bible at `shared/style-bible` (not available yet; until it exists, use a small temporary palette and record it for later palette locking).
- Charts are drawn in code in Godot (line, bar, funnel), with no external images.
- Sound: key clicks, data beeps. Only self-made or licensed audio.

## 10. Technical notes (for Codex)

- Godot 4, GDScript. Data in `data/*.json` (config, cards, events), loaded through `scripts/data.gd`.
- The simulation core is pure logic in `scripts/sim/` (no node dependency) so it can run headless.
- `tests/balance_sim.gd`: runs thousands of games with a few strategies (random, ads only, optimization only, balanced) and prints the win rate and the Cash distribution.
- Balance targets (measured on the 10-week demo, 2,000 runs per strategy): ads-only does not win (at most 10%), random at most 20%, the balanced strategy wins 35 to 55%, the analysis strategy (reveal the cause, then handle it) wins at least 10 percentage points more than balanced. Results measured after T-012: random 18.9%, balanced 43.05%, analysis 55.5%, ads-only and optimization-only 0%. These figures are measured on simulated bots and need real human playtests to confirm.

## 11. Demo scope (10 weeks)

6 cards, 4 events, 1 funnel chart and 1 line chart. No save progress, no leaderboard.

## 12. Out of scope (not done yet)

Online leaderboard, 5 different companies, Sandbox mode, a real SQL-typing screen. Only put them on the advertising website once the game really has them.

## 13. Open questions

- The official name, and whether to keep "Data Corp" (a name-collision check is needed before release).
- The first release platform: web (WebAssembly) or Windows.

# GDD v2 (concept): Data Corp, an analyst in a crisis

Version 0.1 concept, 2026-11-10. Owner: Claude (design). Pending approval from the project owner before programming tasks are created. Keeps the core of `docs/GDD.md` v0.2 (metrics, cards, events with hidden root causes, data that can be wrong) but changes the gameplay and setting.

## 1. One-sentence summary

You are a data analyst at a small company during a difficult economic period. Each day you sit at your desk in a pixel-art office, read the "internet" on your computer screen (world financial news, prices, stocks, rumors), check which stories are trustworthy, then write a forecast report with recommended actions for your boss. If the report is right, the company survives and you get a bonus and a promotion; if it is wrong, you are penalized, demoted, or fired.

Genre: indie, office and analysis simulation, single player, 640x360 pixel art. A demo run is 10 working days; the full game is 30 days.

## 2. What stays, what changes

| Existing core (already has code and tests) | In v2 |
|---|---|
| 7 dashboard metrics (Users, Retention, Conversion, CAC, ARPU, LTV/CAC, Data Integrity) | The company dashboard on the computer screen. "Users" are active customers. Data Integrity becomes the **reliability of internal data** (dirty data makes dashboard numbers noisy) |
| Cash, win/lose, score | Cash is the company's money. When the company runs out of money it goes bankrupt (game over) |
| 8 events with a symptom and a hidden root cause | **Market shocks**: news is the symptom; the real cause (interest rates, raw-material prices, exchange rate, competitor, fake news) stays hidden until you verify it |
| Analysis cards (SQL Deep-Dive, A/B Test, Funnel Report, Clean Data) | **Analysis tools** used on the computer: query historical data, test hypotheses, cash-flow report, clean data and filter noisy sources. They cost Energy (focus) and Budget |
| Action cards (Fix Checkout, Onboarding, Ads, Loyalty, SEO, Support, Influencer, Discount) | **Actions you recommend to the boss** in the report (renamed to fit the context: tighten receivables collection, retain customers, marketing spend, promotions, cut operating costs, etc.). The boss decides whether to act |
| Remedy cards only remove an event once its cause is revealed (T-011) | A recommended action is only effective if you identified the shock's cause correctly |
| "Truth versus what you saw" end screen | **End-of-day review meeting**: the boss reveals the truth and compares it with your forecast |

## 3. Daily loop

1. **Arrive at the office (pixel scene).** The character walks into the office, greets colleagues, and sits at the desk. The boss (the Chief Financial Officer) sends a **question of the day**, for example: "Will raw-material prices keep rising? Should we order more stock?"
2. **Computer screen (the main block of the game).** Windows inside a simulated "internet":
   - **World financial news:** macro news (interest rates, inflation, exchange rates), commodity markets, stocks.
   - **Price board:** fictional stock and commodity tickers, daily price charts.
   - **Social media and forums:** rumors, personal opinions, "internal" screenshots.
   - **Official reports:** press releases, statistics (reliable but often late).
   - **Company dashboard:** the existing metrics.

   Each item has a **source**, a **posting time**, and a **self-declared confidence**. The player reads, pins evidence, and discards noise.
3. **Analysis tools.** Each day has 3 Energy. Use tools to verify: query price history, cross-check two sources, test a hypothesis, clean data. Result: the item is confirmed, refuted, or there is not enough evidence.
4. **Write the report for the boss.** Choose: (a) a forecast for the question of the day (up, down, flat), (b) a confidence level (low, medium, high), (c) the pinned evidence, (d) up to 2 recommended actions. Submit the report.
5. **The boss decides.** The boss's trust level determines how many recommendations are carried out. The company runs a simulated week using the existing economy (T-012), plus the real market shock that was predetermined.
6. **End-of-day review meeting.** The truth is revealed: which news was right and what the real cause was. You get an accuracy score, a change in Trust, and a bonus or penalty.

## 4. World simulation model

Each run generates a **world scenario** from a seed (reproducible):

- A sequence of **hidden true states** per day: interest rate, raw-material price, exchange rate, market sentiment, a few stocks, and the shock currently happening (taken from the 8 existing events, extended to the macro setting).
- A **news generator** that uses the templates in `data/news.json`. Each item has: source and credibility level, content, direction of impact, time offset relative to the real event, and a **hidden truth label**: true, false, partly true, or outdated.
- News noise depends on source credibility: mainstream press is rarely wrong but late, social media is fast but noisy, "internal" tips are often traps.

All companies, tickers, agencies, characters and figures are **fictional**. No real company names, brands, events or figures are used.

## 5. News item data (sample)

```
id, source{id,tier:"chinh_thuc|bao_chi|mang_xa_hoi|noi_bo"}, topic, headline,
direction("tang|giam|ngang"), claimed_magnitude, published_at (hour of day),
truth("dung|sai|mot_phan|cu") [hidden], verified_by[tool ids], links_to_event
```

The identifier values such as `chinh_thuc`, `tang` and `dung` are data keys and are kept as is. Meaning: tier = official, press, social media, internal; direction = up, down, flat; truth = true, false, partly true, outdated.

## 6. Reports and scoring

| Component | How it is computed |
|---|---|
| Forecast accuracy | How correct the forecast is in direction and in magnitude |
| Confidence calibration | High confidence and wrong is penalized heavily; low confidence and right is rewarded little (encourages honesty about uncertainty) |
| Evidence quality | Relying on verified sources adds points; relying on unverified rumors subtracts points, even when the forecast happens to be right |
| Impact on the company | Change in Cash caused by recommendations the boss carried out |

## 7. Career, rewards and penalties

Rank ladder: Intern, Analyst, Senior Analyst, Team Lead, Director of Analytics. The **Boss Trust** metric runs from 0 to 100 and starts at 50 (a starting value, to be tuned by balance simulation).

- Good report: Trust rises and you receive a cash bonus. When the conditions are met (high Trust and several correct reports in a row) you are promoted, get new duties and the right to recommend more actions.
- Bad report: Trust drops. A severe or repeated error leads to a warning, a pay cut, or a demotion. If Trust reaches 0, or you are demoted twice, you are **fired** (game over).
- Company bankruptcy (Cash reaches 0) also ends the run, with a recap of the reports that led to it.
- Win: the run ends with the company alive and a higher rank than at the start. The total score combines rank, Trust, Cash and the number of shocks handled correctly.

## 8. Art and sound

- 640x360, integer scaling, nearest filter (already configured). Pixel-art style, side-view office, limited palette (proposal: at most 32 colors; to be locked in the new style bible).
- Scenes: open-plan office, the player's desk, the boss's office, the meeting room. Switch to the computer screen by "sitting down at the desk". The day changes with the window light.
- The computer screen is an interface with draggable windows, tabs, and a simulated taskbar (but not a real operating system or browser).
- Sound: key clicks, a notification chime, light background music. Only self-made or clearly licensed audio.

## 9. Demo scope (10 days)

3 basic news sources, about 40 news templates, 6 market topics, 8 shocks (from the 8 existing events), 3 rank levels, 1 boss, 3 decorative colleagues, 1 desk. Not included: multiple companies, save progress, leaderboards, multiple languages.

## 10. Code reuse plan

Keep `scripts/sim/` (company economy, cards, events, score) unchanged as the "company simulation". Add a new layer `scripts/world/` (hidden world state, news generator, reports and scoring, career) that calls into the company simulation. The new UI (office and computer screen) replaces `scenes/game.tscn`; the current dashboard scene becomes one window on the computer screen. All existing tests must keep passing.

## 11. Honesty and compliance

- All names, figures and events in the game are fictional. State this clearly in the game and on the landing page: "Figures in this game are fictional simulations, not real market data and not investment advice."
- Do not sell or suggest how to trade for real; there is no real money in the game.
- Do not use copyrighted brands, characters, images or music. Assets must have a clear license or be created by us.
- Disclose AI-assisted content when a platform requires it.
- The current landing page (T-007) describes the old game: it must be rewritten after this direction is approved, and may only say what the new version actually has.

## 12. Proposed roadmap (phases)

| Phase | Content | Owner |
|---|---|---|
| A | New style bible and content bible (news templates, sources, topics, characters) | Claude |
| B | World layer: world scenario, news generator, reports, scoring, career, with a headless balance simulation | Codex per spec |
| C | UI: office scene, computer screen and windows, report flow, end-of-day meeting (temporary art) | Codex per spec |
| D | Pixel art and sound pass | Needs a decision on the asset source (section 13) |
| E | QA, playtest, update the landing page and video for the new version | Claude |

## 13. Open questions

1. **Pixel art source: DECIDED (owner, 2026-11-10): code-written sprites.** Simple sprites generated by code (an image-generating script or drawn inside Godot) with a limited palette; the project owns the copyright. They can be replaced with nicer hand-drawn art later. The style bible (T-016) must describe sprites at a simple level that is feasible in code (characters about 16x24, desk, computer, UI windows).
2. **Does v2 replace the current dashboard version or coexist with it?** Default proposal: keep the current version on `master` as a milestone (tagged), develop v2 on a separate branch, and replace only when the demo is reached. Not yet confirmed by the owner.
3. **Game name:** default is to keep "Data Corp (working title)", with a name-collision check before release. Not yet confirmed by the owner.
4. **Fictional macro setting:** default is a generic "credit crisis" in a fictional world not tied to any real country or event. Not yet confirmed by the owner.

# How to play the v2 demo (branch `v2`)

Status: a 10-day demo that is playable from the title screen to the ending. The art is code-written sprites (simple) with Godot's default font. All figures and names in the game are fictional.

## Run

Requires Godot 4.7. From the project folder:

```bash
Godot_v4.7.2-stable_win64.exe --path game-studio/godot res://scenes/v2/main_v2.tscn
```

Add `-- --seed=7` to fix the scenario. You can also open the `game-studio/godot` folder in the Godot editor and run the scene `scenes/v2/main_v2.tscn`. (The old dashboard version is still the project's default scene, tagged `demo-dashboard-v1` on `master`.)

Git branch: `v2`. Not yet merged into `master`.

## How to play

1. **Each day** the boss (Ms. Hanh) asks one question, for example whether a raw-material price will rise, fall, or stay flat.
2. **Computer screen:**
   - **News** window: read the news. The chip color shows the source type (official, press, social media, internal). Any source can be right or wrong.
   - **Verification tools** window: pick a news item and press "Use". Each day has 3 analysis Energy and each use costs 1, so you cannot verify everything. Result: confirmed, refuted, not enough evidence, or the item is outdated.
   - Click the flag to **pin up to 3 items** as evidence.
   - **Company** window: Cash and the 7 metrics (which can be noisy when data is dirty).
   - **Report** tab: choose a forecast, a confidence level, and recommended actions (up to the limit of your rank), then Submit.
3. **End-of-day meeting:** the truth is revealed: which news was true, false, outdated, or noise, the real cause of the shock, whether the boss followed the recommendations, and any bonus, promotion, warning, demotion, or dismissal.
4. The run ends after 10 days, or earlier if you are fired or the company runs out of money.

Tip: high confidence and wrong is penalized heavily; low confidence and right is rewarded little. Citing unverified or refuted news as evidence costs points.

## Working with data (Files, Sheet, Charts)

Every day the inbox holds 1 to 3 raw files (1 on days 1-2, 2 on days 3-5, 3 from day 6). **Exactly one of them answers the boss's question**; the others are secondary. Doing the analysis well is worth more than reading news alone, but it takes most of the day, and a sloppy analysis is worse than none.

**Which file answers which question**

| Boss question | File to open | Metric (last 7 days against the 7 days before) | How to read it |
|---|---|---|---|
| Imported materials prices | Market prices with the series "Raw material", or the Competitor scrape | mean quote / mean price | up 2%+ = rise, down 2%+ = fall, else flat |
| Business loan rates | Market prices with the series "Policy rate" | mean quote | same |
| Household spending | Sales export, or Web funnel | mean order value (units x price in USD) / purchases per day | same |
| Rival's discount: threat or advertising | Competitor scrape | mean price | down 2%+ = real threat, else advertising |
| Partner bank safe | Loan book | mean days past due | days past due up 2%+ = credit is falling, down 2%+ = rising |
| Report figures reliable | Web funnel | purchases per day | up 5%+ with no demand reason = duplicate logs, not reliable |
| Failing-bank rumor | Loan book | mean days past due | up 10%+ = act now, else no action |

The data shows today's situation, and it is right about four days in five when it is cleaned properly. It says nothing certain about tomorrow, so keep reading the news for "will it..." questions.

**Workflow**: open the relevant file in Files, clean it in Sheet (remove repeated header and TOTAL rows, duplicates and test accounts; handle missing values: drop rows with a missing number, fill a missing label with `unknown`; fix category spellings; convert VND to USD at 24,000 and text numbers such as `1.2k`; parse dates into one format; drop a partial last day; remove entry-error outliers), build one honest chart in Charts and pin it, attach it and choose your findings in Mail > Analysis, then send the report.

**Time costs (the report is on time until 15:00; the day starts at 08:30)**

| Action | Minutes |
|---|---|
| Open a file (first time) | 90 |
| Clean a file (charged once, with the first step; more steps and edits are free) | 120 |
| Pin a chart, table or KPI tile | 60 each |
| Write findings (charged once per day, with the first finding) | 75 |
| Verify a news item | 20 to 45, by tool |

One file, cleaned, with one chart, findings and one verified news item takes 365 to 390 minutes and ends between 14:35 and 15:00. Opening every file, or spending all 3 Energy on verification on top of the analysis, makes the report late (reward cut, the market may have moved).

**Scoring**: the analysis grade is 40% cleaning, 40% findings, 20% chart. A grade of 0.6 or more adds up to +2 Trust; a grade under 0.5 with findings attached costs 7 Trust; each chart quality flag (truncated bar axis, too many categories, unsorted bars, missing unit...) costs 0.5 Trust (at most 1.5). No analysis attached changes nothing.

**Hints**: the Hint button gives three levels per case (problem type, method card, operation families). Each level costs 1 analysis Energy (the same pool as verification) and no time.

**Skills**: five skills grow with practice. Levels at 0 / 20 / 55 / 110 / 180 XP. With careful play expect level 2 after about 5 days and level 4 after 25 to 30 days. XP: 1 per defect type fully fixed, 4 per clean attached chart (1 if flagged), 5 per correct finding (2 if close), up to 5 for a calibrated confidence.

## Keys

- The mouse is the main input. **Enter or Space** advances dialogs, the end-of-day meeting and the title; **Esc** skips animations; **up and down arrows** select news, Enter picks.

## Tests

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path game-studio/godot -s res://tests/test_v2_flow.gd
Godot_v4.7.2-stable_win64_console.exe --path game-studio/godot -s res://tests/test_v2_screens_render.gd
```

(The `*_render` layout tests do **not** run headless because they need real size measurements.)

## Not yet available

Sound, a pixel font, multiple companies, the 30-day run in the UI (the core already supports it), save progress, leaderboards, advanced effects (T-019d).

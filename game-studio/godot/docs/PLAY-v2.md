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

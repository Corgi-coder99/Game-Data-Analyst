# Spec T-021: Guided desktop, Mail report composer, visual news, tutorial

Owner: Claude subagent (replaces Codex). Reviewer: Claude. Base: `v2` (includes T-020). Worktree `D:\Dev\ai-company-codex`, branch `codex/T-021`.

## Playtest feedback this fixes (VU)
- Game is "pure reading": news has no imagery.
- New players do not know how to write the report; the Submit button is not found (Report is a small taskbar tab, 240x320 panel).
- Picking evidence cannot be redone or edited.
- No tutorial.
(Art overhaul and palette v3 are T-022; timed-report penalties are T-023. Not in this task.)

## Goals

### 1. Desktop home with app icons
Desktop shows a wallpaper area with clickable icons (label under each): **Browser** (news feed), **Mail** (report composer), **Insight BI** (company dashboard: the current Company window), **Code Pad** (verification tools: current Tools window), **Help** (?). Click opens the window (or focuses it); windows can be closed/minimised. Generic fictional names, no real brands/logos. A taskbar still lists open windows. Keep keyboard support (arrows, Enter, Esc) working.

### 2. Mail = the report composer (replaces the hidden Report tab)
- Opening Mail shows a compose form in a larger window (>= 320x260 logical px): To: Ms. Hanh, Subject (today's question), body fields: **Forecast** (up/down/flat chips), **Confidence** (low/medium/high), **Evidence** (up to 3 slots, each shows the headline, its verification stamp, and a clear "x" remove button), **Recommended actions** (limited by rank), and a big always-visible **Send** button at the bottom of the window with a short checklist beside it showing what is still missing ("Pick a forecast", "Pick confidence", "Add evidence (optional but recommended)").
- Everything stays **editable until Send**: re-pick forecast/confidence/actions freely, add or remove evidence at any time (also from Browser via a pin button), and an "Undo/Clear all" button. Send asks for confirmation ("Send to Ms. Hanh? You cannot edit afterwards") with Send / Keep editing.
- A persistent **Evidence tray** along the bottom of the desktop (3 slots) shows pinned news as small icon cards; click a slot to unpin or jump to that article.
- Draft state survives opening/closing windows within the day.
- Keep the existing `submit_requested` signal/API (`WorldGame.submit_report`) and rules (rank action cap, 3 evidence max). Do not change balance.

### 3. Visual news (Browser)
- Each article gets a **pictogram thumbnail** (pixel icon drawn in code) by topic: exchange rate, interest rate, materials/prices, consumer spending, stock market, credit/banking (check `data/news.json` for topic fields; add a `topic` mapping if needed, public-safe).
- Source tier is shown as a badge with icon + color (already chips; add a small crest icon per tier).
- A **claim arrow** (up/down/flat) and a bold short figure badge when the headline states a number (e.g. "-1.0%"), derived from the visible headline text only. Show a **mini sparkline-style bar** only if built purely from public headline numbers; otherwise omit. Never reveal truth, reliability, or kind (`signal/trap/stale/noise`) before review.
- Layout: card = thumbnail + headline (max 2 lines) + badges; fewer words per screen; "Read more" expands the body.
- Day-start "headline ticker" strip scrolling the day's headlines (decorative, uses public headline text).

### 4. Tutorial (Day 1) and Help
- Day 1 first-run guided steps as coach-marks (highlight box + arrow + text bubble from Ms. Hanh, Enter/click to continue, Skip button): 1 Read the question; 2 Open Browser, read news, source badges; 3 Select an article, use a tool in Code Pad (explain Energy); 4 Pin evidence; 5 Open Mail, choose forecast/confidence; 6 Send. Steps advance when the player actually does the action where possible, else on Continue.
- A **goal checklist** widget (Read news / Verify / Pin evidence / Write report / Send) persists on screen on days 1-2 (collapsible), and a "?" Help icon reopens the tutorial any time. Skippable and remembered per run (use a simple in-memory flag; no save files).
- Short glossary tooltips: Trust, Energy, Source tiers.

## Constraints
- 32-color palette only (`data/palette_v2.json`); `tools/check_palette.gd` PASS; regenerate sprites with `tools/gen_sprites.gd`.
- All text English. No hidden-truth leaks (leak probe must still pass; new UI reads only public APIs).
- No change to simulation/balance (`balance_sim`, `balance_world` outputs identical).
- Do not edit CLAUDE.md, `shared/`, `scripts/ui/`, `cards.json`, `events.json`, `config.json`.
- No network, no push, no merge; small commits in the worktree.

## Tests
- Keep all existing tests green; update affected ones (list each).
- New tests: icons open/close windows; Mail Send disabled until forecast+confidence set, enabled after; evidence add/remove/re-add works until Send and after reopen; actions editable until Send; Send confirm/cancel; Send emits correct input; tray mirrors pins; tutorial steps advance on real actions and can be skipped/reopened; news card has thumbnail and no truth fields in any displayed text (reuse leak probe).
- **Mouse-driven** tests in non-headless mode: simulate real `InputEventMouseButton` clicks on icons, chips, Send, pin, unpin and verify results (previous tests only used signals).
- Non-headless layout tests (`test_v2_layout_render`, `test_v2_screens_render`) with new screens: nothing clipped/overlapping, Send button fully inside the viewport (640x360).
- Capture screenshots: desktop home, Browser with thumbnails, Mail empty/filled, tutorial step, evidence tray.

## Handoff
`TASKS.md`: files, test counts, changed checks, screenshot paths, limitations.

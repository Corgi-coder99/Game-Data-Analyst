# Spec T-038: Content expansion (news templates, boss questions, sources) and coaching polish

Owner: Codex. Reviewer: Claude. Base `v2`. Worktree `D:\Dev\ai-company-codex`, branch `codex/T-038`. Read `AGENTS.md`, `docs/collaboration.md`, `TASKS.md` (T-038 row), then `docs/CONTENT-BIBLE-v2.md`, `docs/SPEC-T-018.md` (news kinds and fields), `docs/HANDOFF-T-036.md` (question-aware file plan), `data/news.json`, `data/questions.json`, `data/datasets.json`, `data/coaching.json`.

## Why
The game repeats itself quickly: only 41 news templates and 7 boss questions. Players see the same headlines within a few runs. Coaching lines were assembled from fragments and read formulaic.

## Do (data and text only; no gameplay code changes unless a test requires a tiny mapping addition)
1. **News templates**: grow `data/news.json` from 41 to at least **110** templates, keeping the exact schema and the same value sets (`topic`, `source_id`, `source_tier`, `kind` signal/trap/partial/stale/noise, `truth`, `link`, `verify_with`, `state_direction`, `exaggerates`, `magnitude_pct`, placeholders such as `{pct}`). Keep the existing 41 unchanged (ids stable). Keep the **same proportions** per topic x kind x source tier as today within +/- 3 percentage points (compute the current distribution first and print before/after tables), so balance is disturbed as little as possible. Headlines: original, fictional (Tan Lac world, fictional companies and tickers), varied voice per source tier (official: dry; press: measured; social: rumor-like, emoji-free; insider: hushed), 2 lines max at the current card width (<= 90 characters), English only, no real brands/people/countries' real institutions, no investment advice.
2. **Sources**: add 4-6 fictional sources across tiers with reliability/delay consistent with their tier (again keep tier averages within +/- 0.02 of today) and use them in new templates.
3. **Boss questions**: grow `data/questions.json` from 7 to at least **18**, same schema (`id`, `text`, `variable`, `window_days`, `answer_rule` from the existing rule set only; do not invent new rules), covering all six variables evenly, with varied business framing (pricing, hiring, inventory, loans, marketing spend, expansion). For **every new question id** add the mapping required by the T-036 question-aware file plan (see `docs/HANDOFF-T-036.md` and `data/datasets.json`) so each question still gets a relevant data file; if that mapping lives in code, add the minimal table entries and say which file you edited.
4. **Coaching polish**: rewrite `data/coaching.json` lines so each of the 31 traps x 3 outcomes x 3 voices reads naturally and distinctly (Ms. Hanh: direct and businesslike; Khoi: jokey colleague; Dr. Linh: calm teacher), keeping ids/keys/counts identical, 1-2 sentences each (<= 160 characters), accurate to the method (do not change the statistical meaning), friendly, no shaming.
5. Update `docs/CONTENT-BIBLE-v2.md` with the new sources and a short style guide for headlines.

## Constraints
- Do not edit CLAUDE.md, `scripts/ui/`, `scripts/sim/`, `cards.json`, `events.json`, `config.json`, `world.json` numbers. No UI or art changes. No network.
- Hidden-truth rules unchanged; headlines must not state their own truth/kind.
- Your tooling kills commands after about 180 s. Run only fast checks yourself: `python -X utf8 -I tools/validate_content.py`, a JSON schema/distribution script you write (`tools/check_news.py`: schema, unique ids, proportions before/after, headline length, English-only, placeholder validity, every question mapped), and these headless tests one at a time with a 170 s timeout: test_t031_english, test_v2_t021, test_t035_logic, `balance_world -- --games=200 --days=10` (print the table). **Do not run** test_world, test_t036_balance, test_t033_data or the 2000-game balance: the reviewer runs the long tests and the balance targets. If a fast check fails twice after fixes, stop and report (guard rule).

## Acceptance (reviewer will verify)
`balance_world` 2000 games (10 and 30 days) still meets the T-018b targets (random fired >= 50%, verifier >= official_only + 15 points at 10 days and + 10 at 30 days, etc.), `test_world`, `test_t036_balance` (relevance >= 75%) and all UI layout tests pass with the longer headline set (nothing clipped).

## Handoff
In `TASKS.md` under T-038 (Vietnamese, short): counts before/after, distribution tables, files changed, checks run, anything you are unsure about. Do not commit, push or merge.

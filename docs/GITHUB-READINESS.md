# GitHub readiness: language audit and handoff (T-025)

Status: work done on branch `codex/T-025`, nothing pushed. Date 2026-11-10.

Audit method: every tracked text file (except `CLAUDE.md`, `TASKS.md`, `.claude/`) was scanned for the regex `[À-ỹ]` plus common unaccented Vietnamese words. Note that `[À-ỹ]` also matches non-Vietnamese Latin letters and symbols (for example the multiplication sign), so each hit was checked by hand.

## 1. Files that contained Vietnamese

Action values: translated (done in T-025), leave, translate-later (optional), needs-VU (owner decision). "Player-facing" means the player sees the text in the game or on the website.

| File | Kind | Player-facing | Action |
|---|---|---|---|
| `game-studio/godot/docs/GDD-v2-concept.md` | design doc | no | translated |
| `game-studio/godot/docs/CONTENT-BIBLE-v2.md` | design doc | no | translated |
| `game-studio/godot/docs/PLAY-v2.md` | play guide | no | translated |
| `game-studio/godot/docs/GDD.md` | design doc (v1) | no | translated |
| `shared/style-bible/pixel-office-v2.md` | style bible | no | translated |
| `AGENTS.md` | contributor/agent instructions | no | translated (handoff-note language rule kept as "Vietnamese, short"; see section 3) |
| `docs/collaboration.md` | workflow doc | no | translated |
| `game-studio/godot/docs/SPEC-T-004.md`, `SPEC-T-005.md`, `SPEC-T-005-split.md`, `SPEC-T-006.md`, `SPEC-T-009.md`, `SPEC-T-011.md`, `SPEC-T-012.md`, `SPEC-T-013.md`, `SPEC-T-018.md`, `SPEC-T-018b.md`, `SPEC-T-018c.md`, `SPEC-T-019a.md`, `SPEC-T-019b.md`, `SPEC-T-019c.md` | internal task specs | no | translate-later (internal specs, optionally translate; about 110 KB in total, not done for lack of time) |
| `media-marketing/web/SPEC-T-007.md` | internal spec for the old landing page | no | translate-later, or delete-needs-VU (describes the v1 game) |
| `game-studio/godot/data/strings.json` | v1 UI strings | yes (v1 only) | leave, see section 2 |
| `game-studio/godot/data/events.json` | v1 event text (symptom, root cause) | yes (v1 only) | leave, see section 2 |
| `game-studio/godot/data/cards.json` | v1 card data (one name: "Giảm giá") | yes (v1 only) | leave, see section 2 |
| `game-studio/godot/tests/test_ui.gd` | v1 UI test (asserts Vietnamese strings) | no | leave, tied to `strings.json` |
| `game-studio/godot/tests/test_v2_popups.gd` | v2 test (the regex `[À-ỹ]` only) | no | leave, this is the check that v2 player-facing data has no Vietnamese |
| `media-marketing/web/index.html` | landing page for the v1 game | yes | needs-VU, see section 2 |
| `media-marketing/web/check_web.py` | check script, asserts Vietnamese page text | no | leave until the page is rewritten |
| `game-studio/godot/docs/SPEC-T-020.md`, `SPEC-T-025.md` | specs (only mention the regex) | no | leave |
| `.claude/skills/**` | third-party analysis skills | no | leave. Hits are false positives (symbols and accented Latin letters in English text); the spec excludes `.claude/` |
| `CLAUDE.md`, `TASKS.md` | internal project instructions and task board | no | excluded by the spec; see section 3 |

Clean already (English only, no action): `game-studio/godot/data/strings_v2.json`, `news.json`, `questions.json`, `world.json`, `config.json`, `palette_v2.json`, all GDScript under `scripts/` and `tools/`, `style.css`, `shared/style-bible/palette-v2.json`, and SPEC-T-021 to SPEC-T-024.

JSON note fields: the only prose notes (`note`, `schema_note` in `data/news.json`) are already English, so nothing needed translating there. Data ids such as `lai_suat`, `chinh_thuc`, `mot_phan` are keys and are intentionally unchanged.

## 2. Items that cannot be fixed by editing in this task, and proposals

1. **`data/events.json` and `data/cards.json` (v1 game data, Vietnamese).** The v1 dashboard logic and tests (`test_sim.gd`, `test_ui.gd`, `balance_sim.gd`) load them, and `test_ui.gd` asserts Vietnamese text. Proposal: a separate task "T-0xx: English v1 data" that translates `events.json` (symptom, root_cause), the one card name in `cards.json`, and `strings.json`, together with the matching assertions in `test_ui.gd` (including its Vietnamese character-set check), run in one commit with the full test suite. Alternative: add `strings_en.json` and a language switch so Vietnamese stays available. Alternative 2: remove v1 from the public repo and publish only v2 (v2 data is already English); the owner decides.
2. **`data/strings.json` (v1 UI, Vietnamese).** Same task as above. Player-facing in v1 only; v2 uses `strings_v2.json`.
3. **`media-marketing/web/index.html` (landing page for the old v1 game).** Player-facing. The v2 design doc already says it must be rewritten for v2. Proposal: rewrite it in English as part of the v2 launch task, then update `check_web.py` to match. Until then either do not publish `media-marketing/web/` or accept it as a known gap. Needs the owner's decision.
4. **`landing_page_web_demo_game_data_corp.html`** is not in this worktree or in the tracked file list (it exists only in the main checkout, if at all). Proposal: if it is wanted in the public repo, translate or replace it with the rewritten landing page above; otherwise keep it out of the repo (add it to `.gitignore` or delete it, with the owner's approval).
5. **`Web advertisement.html`** is an untracked file in the main checkout, not ours; it was not touched. Proposal: keep it out of the repository (add to `.gitignore` locally or move outside the repo) since its origin and rights are unclear.
6. **Git history.** Old commits and their bodies may contain Vietnamese; subjects scanned in this worktree (110 commits) have no accented characters. Rewriting history is destructive and is not done here. Proposal: either accept the history as is, or publish from a fresh squashed history (a new orphan branch with a single English commit) if the owner wants a fully English public history. This must be decided before the first push because published history cannot be changed safely later.
7. **Internal specs (SPEC-T-004 to SPEC-T-019c, SPEC-T-007).** Left in Vietnamese because of the size. Proposal: a follow-up translation task, or move them to a `docs/archive/` folder, or leave them out of the public repo, since they are internal task briefs for finished work.
8. **Fonts and the in-game language of v1.** The v2 style bible mentions a pixel font with Vietnamese diacritic support; if the game becomes English-only this requirement can be relaxed. Not blocking.

## 3. Other things the owner should decide before publishing

- **`CLAUDE.md`, `TASKS.md`, `.claude/`** are internal, Vietnamese project-management files (they also contain the owner's working names and paths). Proposal: keep them out of the public repo (a separate private branch, or add to `.gitignore` and remove from the index with `git rm --cached` in a later task), or translate them. Not touched here as instructed.
- **`AGENTS.md`** was translated, but it keeps the rule that agent handoff notes are written in Vietnamese for the owner. Decide whether that rule should stay.
- **License:** no license was chosen. `README.md` says "TBD by owner". Add a `LICENSE` file only after the owner picks one (a code license and an asset license can differ). No LICENSE file was created.
- **Third-party content:** `.claude/skills/` and `skills-lock.json` come from third-party skill packages; check their licenses before publishing, or exclude them.
- **Game name:** "Data Corp" is a working title; run a name-collision check before release.
- **Secrets and personal data:** a scan of the new files found none; the README uses "the maintainers" style wording and no personal names or emails. Re-scan the full history before the first push.

## 4. Files added or changed by T-025

Added: `README.md`, `CONTRIBUTING.md`, `docs/COMMIT-CONVENTIONS.md`, `docs/GITHUB-READINESS.md`.
Changed: `.gitignore` (Godot rules added, existing rules kept; `*.import` and `.godot/` stay ignored, so a fresh clone needs `godot --headless --import` once), plus the translated documents listed in section 1.
Not changed: `CLAUDE.md`, `TASKS.md`, game code, `data/*.json`, tests.

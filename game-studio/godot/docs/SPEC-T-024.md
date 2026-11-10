# Spec T-024: After-work life (spend your money)

Owner: Claude subagent. Reviewer: Claude. Base `v2`. Worktree `D:\Dev\ai-company-t024`, branch `codex/T-024`.

## Idea (VU)
After work the player decides what to do with the money: buy a house, land, hoard gold, or just buy street food as a treat.

## Guard rules
2-attempt rule (same failing test after 2 fixes: stop and report). Conflicts: stop and report. About 75 minutes. Godot with timeout <= 5 min/command.

## Goals
1. **Evening scene** after each day's review (before the next day): a screen with the player's wallet (`personal_pay` from public status), a stylized city evening backdrop (simple for now; T-022 will restyle), and a menu of choices. Skippable. Choices are editable until "Go home".
2. **Spending options** (config in new `data/life.json`, fictional currency shown as `$`):
   - **Street food** (cheap, several vendors): instant mood boost shown as the happy emote + small "+Mood" meter; a mood value (0-100) affects nothing in grading, only visuals/ending flavor and a tiny cosmetic.
   - **Gold**: buy/sell units; price follows a seeded series that tends to rise when the public company state is weak (use only public values, never hidden truth); can also fall.
   - **Savings**: fixed small interest per day.
   - **Land** and **House**: expensive, one purchase each at most (or tiers); slow appreciation plus (house) rent income per day; illiquid: selling costs a fee.
   - Optional **Splurge** (e.g. gadget/holiday): pure mood, no financial return.
3. **Net worth**: wallet + gold + land + house + savings, shown in the Evening screen, the review/ending ("Net worth", "Mood"), and an extra line in the ending summary. Do **not** change the score formula (keep `status().score` identical); show net worth as a separate stat.
4. **Fines**: the sim currently has no money fine so `-$` popups never show. Add small cash events in the evening (e.g. street-vendor price hike, lost wallet, market crash on gold) driven by the seeded series only, so negative popups and the sad emote appear in real games. Use the existing popup/emote stage (`scripts/v2/reaction_stage.gd`).
5. Everything deterministic by seed. A bot test plays random spending 1000 games and asserts invariants: wallet never negative, net worth consistent with transactions, no crashes.

## Constraints
- Keep all simulation/world logic untouched: `balance_sim`, `balance_world`, `test_world` identical; the life module is a separate script (`scripts/life/life_game.gd`) that only reads public status. Hidden-truth leak probe must pass.
- Palette: existing 32 colors (T-022 extends later). English text only. Do not edit CLAUDE.md, `scripts/ui/`, `scripts/world/`, `scripts/sim/`, `cards.json`, `events.json`, `config.json`.
- Another task (T-022) is editing office/art/palette; T-023 is editing Mail/clock. Keep your edits to new files plus a minimal hook in `scripts/v2/game_flow.gd` (insert the evening step) and `data/strings_v2.json` (append a new `life` section only).
- Handoff goes to `game-studio/godot/docs/HANDOFF-T-024.md`, not TASKS.md. No network/push/merge; small commits.

## Tests
- Existing tests pass (list changed checks). New: purchases/sales/fees arithmetic; one-purchase limits; seeded price series determinism; evening skip; popups for gains and losses; full flow test with evening step; mouse test through the Evening scene; render layout test (nothing clipped, 640x360); screenshots viewed.

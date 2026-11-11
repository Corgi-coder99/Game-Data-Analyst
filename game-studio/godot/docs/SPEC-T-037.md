# Spec T-037: Procedural audio (sound effects and ambient music generated in code) and settings

Owner: Codex. Reviewer: Claude. Base `v2`. Worktree `D:\Dev\ai-company-codex`, branch `codex/T-037`. Read `AGENTS.md`, `docs/collaboration.md`, `TASKS.md` (T-037 row), then `docs/HANDOFF-T-030.md` (profile/settings) and `scripts/v2/game_flow.gd` (state machine).

## Goal
The game has no sound. Add audio **without any external assets or downloads**: all sound effects and a soft lo-fi ambient music loop are synthesized in code (AudioStreamWAV built from generated samples), cozy and unobtrusive.

## Build
1. `scripts/audio/synth.gd`: small synthesis helpers (sine/triangle/square/noise, ADSR envelope, low-pass, pitch glide, simple reverb/echo, mixing) producing `AudioStreamWAV` (16-bit mono, 22050 or 44100 Hz) deterministically (no randomness without a fixed seed).
2. `scripts/audio/sfx_bank.gd`: at least 20 effects built at startup or lazily and cached: UI click, hover tick (very quiet), confirm, cancel/error, select, toggle on/off, coin gain (+$), coin spend (-$), notification toast, achievement/level-up jingle, success chime (correct report), fail buzz (wrong report), warning, keyboard slam (coworker), door open, footstep, car passing (optional), bus horn (optional), page turn, typing burst, alarm clock, coffee pour, cash register, deadline tick (soft), sick-day sound, promotion fanfare, firing sad trombone-like (original, short, non-infringing).
3. `scripts/audio/music.gd`: procedural lo-fi loop generator: chord progression (e.g. Imaj7-vi7-ii7-V7 variations), soft electric-piano-like plucks, vinyl crackle, light drum pattern, 70-85 BPM, 60-90 s loop length built once; at least 4 moods selected by game state: Home (morning, warm), Street (day, brighter and bouncier), Work (calm, focus, minimal drums), Evening (mellow), Crisis variant (minor, slower, subdued) chosen from public values (day number, trust) only; crossfade between moods (1.5 s). Original compositions only; no copyrighted melodies.
4. `scripts/audio/audio_manager.gd` (a Node, one instance added by `game_flow.gd` or the main scene): buses (Master, Music, SFX), volumes, mute, `play_sfx(id)`, `play_music(mood)`, ducking music while a jingle plays, polyphony limit (max 8 concurrent SFX, drop oldest), safe when no audio device exists (headless Godot uses the dummy driver: must not error).
5. **Zero-touch hooks**: `scripts/audio/audio_hooks.gd` connects to the scene tree's `node_added` signal and auto-connects every `Button.pressed` to the click sound and mouse-enter to the quiet tick (respecting disabled and a meta `no_sound`); other hooks are minimal edits in `game_flow.gd` (state changes choose music, review steps choose success/fail/promotion/fired jingles via public status only), `reaction_stage.gd` (coin and emote popups), `tutorial_panel.gd` (step done), `scripts/life/*` (purchase coin sounds). Keep hooks to one-liners calling `AudioManager`; no behavior change.
6. **Settings** (extend the T-030 settings screen): Master/Music/SFX sliders (0-100, default Master 70, Music 40, SFX 70), Mute toggle, "Sound test" button; values saved in the local profile (additive fields, backward compatible with existing profile files).

## Constraints
- No external audio files or downloads; no network. No change to simulation, world, life or balance; score and `balance_*` identical.
- English only; palette untouched; do not edit CLAUDE.md, `scripts/ui/`, `scripts/sim/`, `scripts/world/`, cards/events/config json.
- Another task (T-034, data UI, Claude subagent) is editing `scripts/v2/desktop.gd`, `windows/*`, Mail, review scene and tests in a different worktree. **Do not edit those files**; use zero-touch hooks, and for the few unavoidable hooks make one-line edits only in `game_flow.gd`, `reaction_stage.gd`, `tutorial_panel.gd` and `scripts/life/*`. Merge conflicts will be resolved by the reviewer.
- Concurrent Godot processes can crash (exit code 139): if a Godot command crashes without a test failure message, retry once; run only one Godot process yourself at a time.

## Tests (headless unless stated)
- Synth: sample counts, determinism (same input gives byte-identical wave), no NaN, peak <= 1.0 (no clipping), loudness (RMS) within a target range per effect, effect durations in expected ranges; each SFX id exists and is non-silent; music loops are seamless (first and last samples within a small difference), loop length in range, each mood differs.
- Manager: volume math, mute, polyphony limit, ducking, safe with no audio device (dummy driver), settings persist and load defaults from an old profile file.
- Hooks: a new Button in the tree triggers the click sound once; disabled and `no_sound` buttons do not; the flow states choose the expected mood (including crisis variant by trust/day) and review outcomes pick jingles.
- All existing tests still pass (test_sim, test_ui, test_world, test_life, test_vitals, test_daily_flow, test_t027, test_t030_*, test_t031_english, test_t033_*, test_v2_*), plus non-headless layout tests for the settings screen sliders (nothing clipped at 640x360), one at a time. `balance_sim` output identical.

## Handoff
In `TASKS.md` under T-037 (Vietnamese, short, per AGENTS.md): files changed, test counts, how to verify by ear (command to open the sound test), limitations. Do not push or merge; the reviewer commits on your behalf if git add is blocked.

## Scope amendment (2026-11-11, reviewer decision after Codex's blocker)
`scripts/meta/profile.gd` drops unknown `settings` keys on load, so audio settings would be erased. You may therefore also edit `scripts/meta/profile.gd` (additive: extend the default `settings` with `audio` fields master/music/sfx/mute and keep unknown-key sanitizing for others; backward compatible with old profile files) and `tests/test_t030_meta.gd` (add checks only; do not relax any). Note: another task (T-035, learning layer) will add skill-progress fields to the same profile file later; keep your edit small and additive to ease merging.

## Performance amendment (2026-11-11, after Codex's first run timed out; reviewer measured test_t037_synth > 500 s)
Cause: pure-GDScript synthesis is ~100x slower than native. `music.gd` builds 96 beats (~72 s at 22050 Hz = 1.6M samples) and recomputes a 2.8 s pluck plus echo for each of 96 chord notes, ~50M interpreted operations per mood. Fix requirements:
1. **Loop length 8 bars (32 beats, about 24-30 s)** instead of 24 bars; chord notes repeat so **cache each unique pluck+echo waveform per (mood, note)** and mix cached copies; mix with a **tight loop over precomputed arrays** (avoid per-sample function calls, avoid `sin()` per sample where a precomputed table or a recurrence works; precompute a 1024-entry sine table, use `RATE = 16000` for music and 22050 for SFX).
2. **Never block the game**: build music loops in a `Thread` at startup (low priority) one mood at a time, play a short silence or SFX only until ready, and expose `is_ready(mood)`; SFX are small (<= 0.6 s) and may be built lazily on first use and cached.
3. **Budget**: building one mood loop must take < 3 s in headless Godot on this machine, all 27 SFX < 5 s total. Add a timing test that fails above 3x these budgets.
4. **Tests must each finish in < 60 s** (the tooling kills commands after 180 s): split test files, test one mood fully (determinism and seamless loop) and the others by structural properties (length, non-silent, differ from each other) using a smaller `loop_bars` parameter if needed; do not generate all 5 moods x2 in one test.
5. If it is still too slow after one optimization pass, stop and report the measured timings (guard rule).

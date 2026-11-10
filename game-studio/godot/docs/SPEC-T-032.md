# Spec T-032: English landing page for the v2 game

Owner: Claude subagent. Reviewer: Claude. Base `v2`. Worktree `D:\Dev\ai-company-t032`, branch `codex/T-032`. Files: `media-marketing/web/*`, `media-marketing/web/SPEC-T-007.md` (rewrite as English), `media-marketing/web/check_web.py`, assets for the page. Do not touch game code.

## Goal
`media-marketing/web/index.html` is Vietnamese and describes the old v1 dashboard game. Rewrite it in **English** as the marketing page for the current v2 game ("Data Corp", working title): you are a data analyst in a pixel-art company during a financial crisis; read a simulated internet (news with source tiers), verify rumors, report to the boss, get bonuses or get fired; also a cozy daily-life loop (commute, shops, mood and stamina) and a Wall of Fame.

## Rules
- Honesty (CLAUDE.md section 5): no fabricated reviews, testimonials, download counts, awards or statistics; no claims of features that do not exist (no multiplayer yet; state "online leaderboard: planned"); mark all in-game data as fictional; no real brands or logos; say "working title" and "early demo". Release/platform claims only what is true: a Godot 4.7 PC demo, not yet published.
- Use only original art: capture screenshots from the game (use `docs/screenshots-T-029/after`, `docs/screenshots-T-030`, `docs/screenshots-T-028/after`, optimize copies into `media-marketing/web/assets/`; keep file sizes modest; do not use the third-party reference image). Pixel-perfect rendering (`image-rendering: pixelated`).
- Style: cozy-modern pixel look consistent with palette v4 colors (read `shared/style-bible/pixel-cozy-v4.md`); responsive (mobile and desktop), accessible (alt text, contrast, keyboard focus, `prefers-reduced-motion`), no external fonts/CDNs/trackers (self-contained, system fonts), no cookies, no forms that send data. A "Download demo" button must not link to anything fake: use a disabled "Demo coming soon" state or a link to the README section "How to run".
- Sections: hero with tagline and screenshot, how it works (3 steps: read, verify, report), a day in the life, features, screenshot gallery, FAQ (honest), footer with "fictional data, early demo, working title" and AI-content note if applicable.
- Update `check_web.py` for the new page (UTF-8 safe, run with `python -X utf8 -I`): checks for no external requests, alt texts, valid local asset paths, forbidden claim words (e.g. "award-winning", "millions", "#1"), file size budget, English only (no Vietnamese diacritics). Fix the T-008 encoding issue while there.
- Do not publish or deploy anything; no network.

## Guard rules
Same failing check after 2 fix attempts: stop and report root cause. About 60 minutes. Commit small steps. No push/merge. Handoff in `media-marketing/web/HANDOFF-T-032.md` with screenshots of the page (render with the built-in browser tools or a headless approach available locally; if no browser is available say so honestly) at desktop and mobile widths and the `check_web.py` output.

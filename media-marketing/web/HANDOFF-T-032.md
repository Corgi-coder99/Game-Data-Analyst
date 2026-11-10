# Handoff T-032: English landing page

Branch `codex/T-032`. Files: `index.html`, `style.css`, `check_web.py`, `SPEC-T-007.md` (rewritten), `assets/` (7 optimized PNGs from the game's own screenshots in `docs/screenshots-T-029/after` and `docs/screenshots-T-030`; the old v1 dashboard image was removed), `preview/`.

## Page contents
Hero (tagline, early-demo badge, disabled "Demo coming soon" button, screenshot), How it works (Read, Verify, Report), A day in the life (commute, evening, end-of-day review), Features (6 cards plus "online leaderboard: planned"), Gallery (4 screenshots), FAQ (7 honest answers), footer (fictional data, early demo, working title, AI assistance).

## Previews
Rendered in the built-in browser via a local `python -m http.server` (stopped afterwards). Mobile 375px: no horizontal overflow (scrollWidth 375). Desktop 1280px: no overflow, all images loaded at 640px natural width.
- `preview/desktop-1280.jpg` (small: pane-scaled capture)
- `preview/mobile-375.jpg` (top of page only; the page was verified below the fold by script, not by full-page capture)

## check_web.py output
```
PASS 1 Self-contained
PASS 2 Sections and anchors
PASS 3 Images and alt text
PASS 4 No unused assets
PASS 5 Size budget: total=143984B
PASS 6 Forbidden claims
PASS 7 Required honesty notes
PASS 8 Demo button honest
PASS 9 English only
PASS 10 Metadata
PASS 11 Accessibility
11/11 checks passed
```

## Limitations
No full-page screenshots; contrast was chosen by eye, not measured. Screenshots are 640x360 originals, shown up to about 2x. Run command for the check: `python -X utf8 -I media-marketing/web/check_web.py`.

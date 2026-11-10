# Spec T-007 (rewritten by T-032): Honest landing page for Data Corp (working title)

Rewritten in English for the v2 game. Content rules: `CLAUDE.md` section 5 (no fabricated figures, reviews or testimonials; no impersonation; advertising must be honest and verifiable).

## Goal
A static single page that describes the current v2 demo accurately. It opens directly from `index.html`: no server, no external libraries, fonts, CDNs or trackers, no cookies.

## Facts the page may state (verifiable sources)
| Claim | Source |
|---|---|
| You are a data analyst in a pixel-art company during a credit crisis; read news, verify, report to the boss | `README.md`, `game-studio/godot/docs/GDD-v2-concept.md` |
| News comes from sources of different reliability; any source type can be true or false | `README.md`, `CONTENT-BIBLE-v2.md` |
| Reports are scored on accuracy, calibrated confidence and evidence quality | `README.md` |
| Career ladder with trust, bonuses, warnings, demotion, dismissal; bankruptcy possible | `README.md` |
| Cozy daily loop: commute, shops, treats, mood and stamina | T-028 and T-029 specs, screenshots |
| Wall of Fame (local) | T-030 spec, screenshots |
| Godot 4.7 PC build, early demo, not published, working title | actual status |
| Online leaderboard: planned, not built. No multiplayer | actual status |
| Data is fictional; part of content and code was created with AI assistance | `README.md` |

## Forbidden
Subscriber, player or download counts, star ratings, testimonials, player names, awards, rankings ("#1", "award-winning", "millions"), countdowns, "play now" or "download now" while no release exists, store badges, real brands or logos, "All rights reserved" notices, forms that collect data, external requests. Images must come from the game itself (no third-party reference art).

## Sections (in order, ids checked by `check_web.py`)
`top` (header and nav), `hero` (tagline, screenshot, "Demo coming soon" disabled state), `how` (Read, Verify, Report), `day` (a day in the life), `features`, `gallery`, `faq`, plus a footer stating: working title, early demo, fictional data, AI assistance.

## Quality bar
Responsive (no horizontal scroll at 375px), alt text on every image, keyboard focus styles, skip link, `prefers-reduced-motion`, `image-rendering: pixelated` for art, English only, size budget enforced by the check script.

## Check
`python -X utf8 -I media-marketing/web/check_web.py` must print PASS for every check.

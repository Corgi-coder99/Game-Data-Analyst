# Input log format (version 1)

One record per finished game day. Written by `scripts/meta/input_log.gd` through the `ScoreSink`, stored in the local profile (`history` array of `user://profile.json`). It is also the payload a future server would receive to re-simulate and verify a day (see `docs/DESIGN-online.md` section 2). A client never sends a score as truth; the server recomputes it.

Only public data is stored: what the player chose, and the result parts the review screen already shows after the day. The hidden answer, the news truth labels, the scenario and root causes are never part of a record (the leak probe in `tests/test_t030_meta.gd` checks this).

## Record

```json
{
  "v": 1,
  "day_id": "daily:2026-11-10:1",
  "mode": "daily",
  "date": "2026-11-10",
  "seed": 482110,
  "day_index": 1,
  "inputs": {
    "question_id": "interest_rate_1",
    "forecast": "tang",
    "confidence": "vua",
    "evidence": ["d1-n3", "d1-n5"],
    "actions": ["ad_campaign"],
    "submit_minutes": 585
  },
  "context": { "focus_bonus": 0, "late_minutes": 5 },
  "result": {
    "accuracy": 1.0,
    "evidence_quality": 0.5,
    "trust_delta": 4.0,
    "timing": "on_time",
    "pay": 100,
    "bonus": 0,
    "rank": "thuc_tap",
    "trust": 50,
    "day_score": 125
  }
}
```

| Field | Meaning |
| --- | --- |
| `v` | Format version (1). |
| `day_id` | Unique id. Daily Shift: `daily:<date>:<day index>` (shared by everyone on that date). Normal run: `run:<seed>:<day index>`. A record with an existing `day_id` is not stored twice. |
| `mode` | `daily` or `run`. |
| `date` | Calendar date (local clock, `YYYY-MM-DD`) on which the day was finished. |
| `seed` | World seed of the run. For `daily` it is derived from the date (`LocalDaySource.seed_for_date`). |
| `day_index` | 1-based game day inside the run (1 to 10). |
| `inputs.question_id`, `forecast`, `confidence`, `evidence`, `actions` | The report exactly as submitted (`Report.validate` format). |
| `inputs.submit_minutes` | Minutes since midnight on the game clock when the report was sent (verification and waiting move the clock). |
| `context.focus_bonus` | Analysis Energy bonus from the life loop that day (needed to re-simulate Energy). |
| `context.late_minutes` | Minutes the player arrived late from the commute (shifts the work clock). |
| `result.*` | Public result parts: accuracy 0 / 0.4 / 1, evidence quality, trust change, timing tag (`on_time`, `late`, `missed`), pay, bonus, rank id and trust after the day, and the meta `day_score`. |

`day_score` = `100 * accuracy + 5 * trust_delta + 10 if a bonus was paid` minus 5 for a late report or 25 for a missed one (weights in `data/meta.json`). It feeds reputation (score / 10), Employee of the Month and the Best Single Day plaque. It is not the game's `status().score`, which is untouched.

JSON turns numbers into floats; `InputLog.normalize` restores the integer fields so a record round-trips exactly (`to_line` / `from_line`, one JSON object per line).

## Known gaps for server verification (phase 1)
- The individual verification tool uses (which tool on which news uid, in which order) are not recorded; only the resulting `submit_minutes`. A server that wants to re-run the day must add a `tools` list in a version 2 record. The client already knows these calls (`WorldGame.verify`).
- Life choices other than `focus_bonus` and `late_minutes` (transport, shops) are not included; they never change the score.

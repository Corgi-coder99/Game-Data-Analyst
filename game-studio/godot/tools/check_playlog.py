"""Validate schema-v1 local playlogs, using only the standard library.

Usage: python -X utf8 -I tools/check_playlog.py FILE.jsonl [--self-test]
No network, profile reads, or writes. Input must be synthetic or knowingly exported.
"""
import argparse
import datetime
import json
import math
import re
import sys
import unittest
from pathlib import Path

COMMON = {"v", "pid", "run_id", "t", "e", "src"}
FIELDS = {
    "session_start": "date build mode",
    "consent": "value",
    "run_start": "mode seed horizon tutorial learn_level",
    "day_start": "day rank trust energy_max question_id news_count",
    "verify": "day tool ok error energy_left minutes band source_tier topic",
    "wait": "day waited_minutes app_minutes",
    "hint": "day energy_left",
    "report_submit": "day minutes band answer n_actions n_evidence has_analysis free_text_len_class",
    "day_end": "day timing label delta acc ev trust rank adopted executed shifted",
    "run_end": "ending won score days_played rank trust warnings demotions",
    "quit": "state day",
}
FIELDS = {key: set(value.split()) for key, value in FIELDS.items()}
FORBIDDEN = {"name", "display_name", "path", "text", "headline", "uid", "ip",
             "_scenario", "_late_plan", "root_cause", "states", "shocks"}
INTS = set("seed horizon learn_level day energy_max news_count energy_left minutes "
           "waited_minutes app_minutes n_actions n_evidence adopted executed "
           "days_played warnings demotions".split())
BOOLS = {"value", "ok", "has_analysis", "shifted", "won"}
NUMBERS = {"trust", "delta", "acc", "ev", "score"}


def validate(row):
    """Return errors for one object, without accepting arbitrary extra strings."""
    errors = []
    if not isinstance(row, dict):
        return ["event must be an object"]
    missing = COMMON - row.keys()
    if missing:
        errors.append("missing common fields: " + ", ".join(sorted(missing)))
    event = row.get("e")
    if not isinstance(event, str) or event not in FIELDS:
        return errors + ["unknown event"]
    unknown = row.keys() - COMMON - FIELDS[event]
    if unknown:
        errors.append("unknown fields: " + ", ".join(sorted(unknown)))
    if type(row.get("v")) is not int or row["v"] != 1:
        errors.append("v must be integer 1")
    if type(row.get("t")) is not int or row["t"] < 0:
        errors.append("t must be a nonnegative integer")
    if row.get("src") not in ("human", "bot"):
        errors.append("invalid src")
    pid = row.get("pid", "")
    pattern = r"bot-[a-z0-9_]+" if row.get("src") == "bot" else r"[0-9a-f]{32}"
    if not isinstance(pid, str) or not re.fullmatch(pattern, pid):
        errors.append("invalid pid")
    run_id = row.get("run_id", "")
    if not isinstance(run_id, str) or (run_id != "" and not re.fullmatch(r"[0-9a-f]{16}", run_id)):
        errors.append("invalid run_id")
    if event not in ("session_start", "consent") and not run_id:
        errors.append("run event requires run_id")
    if event in ("session_start", "consent") and run_id:
        errors.append("session event must be outside a run")
    for key, value in row.items():
        if key in FORBIDDEN:
            errors.append("forbidden key: " + key)
        if value is None or isinstance(value, (dict, list)):
            errors.append("only scalar non-null values allowed: " + key)
        if isinstance(value, str) and len(value) > 40:
            errors.append("string longer than 40: " + key)
        if key in INTS and type(value) is not int:
            errors.append("must be integer: " + key)
        if key in BOOLS and type(value) is not bool:
            errors.append("must be boolean: " + key)
        if key in NUMBERS:
            if type(value) not in (float, int) or not math.isfinite(value):
                errors.append("must be finite number: " + key)
            elif abs(value - round(value, 2)) > 1e-8:
                errors.append("more than two decimals: " + key)
        if key in FIELDS[event] - INTS - BOOLS - NUMBERS and not isinstance(value, str):
            errors.append("must be string: " + key)
    if "date" in row:
        try:
            if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", row["date"]):
                raise ValueError()
            datetime.date.fromisoformat(row["date"])
        except (ValueError, TypeError):
            errors.append("invalid UTC date")
    if event == "consent" and row.get("value") is not True:
        errors.append("only opt-in consent can be retained")
    choices = {"mode": ("none", "run", "daily", "practice"), "band": ("on_time", "late", "missed"),
               "timing": ("on_time", "late", "missed"), "free_text_len_class": ("0", "1-40", "41+")}
    for key, allowed in choices.items():
        if key in row and row[key] not in allowed:
            errors.append("invalid " + key)
    return errors


def check_file(path):
    count = 0
    errors = []
    opened = {}
    with path.open(encoding="utf-8") as stream:
        for number, line in enumerate(stream, 1):
            try:
                row = json.loads(line, parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))
                problems = validate(row)
                if not problems:
                    key = (row["pid"], row["run_id"])
                    if row["e"] == "day_start":
                        if key in opened:
                            problems.append("previous day still open")
                        opened[key] = row.get("day")
                    elif row["e"] == "day_end":
                        if opened.get(key) != row.get("day"):
                            problems.append("day_end must follow its day_start")
                        opened.pop(key, None)
                    elif row["e"] in ("quit", "run_end"):
                        if row["e"] == "run_end" and key in opened:
                            problems.append("run_end before day_end")
                        opened.pop(key, None)
                errors.extend(f"line {number}: {problem}" for problem in problems)
                count += 1
            except (ValueError, TypeError) as exc:
                errors.append(f"line {number}: invalid JSON ({exc})")
    return count, errors


class ValidatorTests(unittest.TestCase):
    def setUp(self):
        self.row = dict(v=1, pid="a" * 32, run_id="b" * 16, t=0, e="day_start", src="human", day=1)

    def test_valid(self):
        self.assertEqual(validate(self.row), [])

    def test_rejects_privacy_and_schema_errors(self):
        cases = [{"e": "mystery"}, {"v": 2}, {"v": True}, {"t": 0.1}, {"t": True},
                 {"t": -1}, {"pid": "my name"}, {"src": "other"}, {"rank": "a" * 41},
                 {"trust": float("nan")}, {"trust": 1.234}, {"day": 1.0}, {"day": None},
                 {"run_id": ""}, {"payload": {"headline": "secret"}}]
        cases += [{key: "secret"} for key in FORBIDDEN]
        for change in cases:
            with self.subTest(change=change):
                self.assertTrue(validate(self.row | change))
        for key in COMMON:
            with self.subTest(missing=key):
                self.assertTrue(validate({k: v for k, v in self.row.items() if k != key}))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", type=Path, nargs="?")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        result = unittest.TextTestRunner().run(unittest.defaultTestLoader.loadTestsFromTestCase(ValidatorTests))
        return 0 if result.wasSuccessful() else 1
    if args.file is None:
        parser.error("provide a .jsonl file or --self-test")
    try:
        count, errors = check_file(args.file)
    except (OSError, UnicodeError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1
    for error in errors:
        print("FAIL: " + error, file=sys.stderr)
    print(f"{count} events, {len(errors)} failures")
    return int(bool(errors))


if __name__ == "__main__":
    sys.exit(main())

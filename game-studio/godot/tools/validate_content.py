#!/usr/bin/env python
"""Validate T-035a content. Run: python -X utf8 -I tools/validate_content.py
Exit code 0 when all checks pass."""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = ["data/cases.json", "data/handbook.json", "data/coaching.json",
         "docs/CASE-CATALOG.md", "docs/HANDBOOK.md", "docs/TUTORIAL-CASES.md"]

SKILLS = {"data_cleaning", "charts", "statistics", "causality", "communication"}
METHODS = {"data-quality-audit", "programmatic-eda", "root-cause-investigation", "funnel-analysis",
           "cohort-analysis", "segmentation-analysis", "ab-test-analysis", "time-series-analysis",
           "visualization-builder", "analysis-planning"}
DATASETS = {"sales_export", "market_prices", "web_funnel", "loan_book", "ab_test_log",
            "support_tickets", "competitor_scrape"}
DIRT = {"duplicates", "missing_values", "zero_as_null", "mixed_units", "mixed_currency", "mixed_dates",
        "timezone_shift", "category_typos", "entry_outliers", "repeated_headers", "subtotal_rows",
        "negative_values", "test_accounts", "survivorship", "late_arriving", "join_mismatch",
        "truncated_export"}
REQUIRED_TRAPS = ["duplicates", "missing_as_zero", "mixed_units_currency", "date_timezone", "category_typos",
                  "outlier_entry_error", "seasonality_vs_trend", "simpsons_paradox", "small_sample_noise",
                  "correlation_vs_causation", "base_rate", "survivorship_bias", "cherry_picking",
                  "misleading_axis", "double_counting", "late_arriving_data", "ab_significance", "ab_peeking",
                  "ab_sample_size", "funnel_dropoff", "cohort_retention", "segmentation",
                  "root_cause_drilldown", "regression_to_mean", "join_mismatch", "test_accounts"]
CASE_FIELDS = ["id", "title", "skill", "method", "dataset_type", "boss_question", "trap", "dirt",
               "reference_steps", "truth_statement_templates", "wrong_paths", "difficulty", "unlock_day",
               "handbook_card_ids"]
CARD_FIELDS = ["id", "title", "skill", "what", "when_to_use", "common_mistakes", "example", "how_in_game",
               "see_also"]
KINDS = ["praise", "miss", "wrong_fix"]
VOICES = {"hanh", "khoi", "linh"}
MIN_CASES, MIN_CARDS = 24, 30

# Vietnamese-specific letters (letters with diacritics that do not occur in plain English)
VN = re.compile("[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ"
                "ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]")

fails = 0


def ok(msg):
    print("PASS " + msg)


def bad(msg):
    global fails
    fails += 1
    print("FAIL " + msg)


def check(cond, msg):
    ok(msg) if cond else bad(msg)


def load(rel):
    try:
        with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
            data = json.load(f)
        ok(f"valid JSON: {rel}")
        return data
    except Exception as e:  # noqa
        bad(f"valid JSON: {rel} ({e})")
        return None


def nonempty_str(x):
    return isinstance(x, str) and x.strip() != ""


def nonempty_list_of_str(x):
    return isinstance(x, list) and len(x) > 0 and all(nonempty_str(i) for i in x)


def main():
    cases = load("data/cases.json")
    hb = load("data/handbook.json")
    co = load("data/coaching.json")

    # ---- handbook
    card_ids = set()
    if hb:
        cards = hb.get("cards", [])
        check(len(cards) >= MIN_CARDS, f"handbook has >= {MIN_CARDS} cards (found {len(cards)})")
        ids = [c.get("id") for c in cards]
        check(len(ids) == len(set(ids)), "handbook ids unique")
        card_ids = set(ids)
        problems = []
        for c in cards:
            for k in CARD_FIELDS:
                if k not in c or (isinstance(c[k], str) and not c[k].strip()):
                    problems.append(f"{c.get('id')}: missing {k}")
            if c.get("skill") not in SKILLS:
                problems.append(f"{c.get('id')}: bad skill {c.get('skill')}")
            cm = c.get("common_mistakes", [])
            if not (isinstance(cm, list) and 2 <= len(cm) <= 4 and all(nonempty_str(m) for m in cm)):
                problems.append(f"{c.get('id')}: common_mistakes must have 2 to 4 items")
            if not nonempty_list_of_str(c.get("see_also", [])):
                problems.append(f"{c.get('id')}: see_also empty")
            for s in c.get("see_also", []):
                if s not in card_ids:
                    problems.append(f"{c.get('id')}: see_also unknown id {s}")
            if not re.search(r"\d", c.get("example", "")):
                problems.append(f"{c.get('id')}: example has no numbers")
            sentences = len([s for s in re.split(r"(?<=[.!?])\s+", c.get("what", "").strip()) if s])
            if not 2 <= sentences <= 4:
                problems.append(f"{c.get('id')}: what has {sentences} sentences (want 2 to 3)")
        check(not problems, "handbook fields, skills, mistakes, see_also, examples" + ("" if not problems else ": " + "; ".join(problems[:10])))
        check(SKILLS <= {c.get("skill") for c in cards}, "handbook covers all 5 skills")

    # ---- cases
    if cases:
        cs = cases.get("cases", [])
        check(len(cs) >= MIN_CASES, f"catalog has >= {MIN_CASES} cases (found {len(cs)})")
        ids = [c.get("id") for c in cs]
        check(len(ids) == len(set(ids)), "case ids unique")
        problems = []
        for c in cs:
            cid = c.get("id")
            for k in CASE_FIELDS:
                if k not in c:
                    problems.append(f"{cid}: missing {k}")
            if c.get("skill") not in SKILLS:
                problems.append(f"{cid}: bad skill")
            if c.get("method") not in METHODS:
                problems.append(f"{cid}: bad method {c.get('method')}")
            if c.get("dataset_type") not in DATASETS:
                problems.append(f"{cid}: bad dataset_type {c.get('dataset_type')}")
            d = c.get("difficulty")
            if not (isinstance(d, int) and 1 <= d <= 5):
                problems.append(f"{cid}: difficulty out of 1..5")
            ud = c.get("unlock_day")
            if not (isinstance(ud, int) and ud >= 1):
                problems.append(f"{cid}: unlock_day must be int >= 1")
            for dt in c.get("dirt", []):
                if dt not in DIRT:
                    problems.append(f"{cid}: unknown dirt {dt}")
            for k in ("reference_steps", "truth_statement_templates"):
                if not nonempty_list_of_str(c.get(k, [])):
                    problems.append(f"{cid}: {k} empty")
            wp = c.get("wrong_paths", [])
            if not (isinstance(wp, list) and len(wp) >= 1 and all(nonempty_str(w.get("path")) and nonempty_str(w.get("why")) for w in wp)):
                problems.append(f"{cid}: wrong_paths needs path and why")
            for h in c.get("handbook_card_ids", []):
                if h not in card_ids:
                    problems.append(f"{cid}: unknown handbook id {h}")
            if not c.get("handbook_card_ids"):
                problems.append(f"{cid}: no handbook cards")
            for x in c.get("forecast_directions", []):
                if x not in ("up", "down", "flat"):
                    problems.append(f"{cid}: bad forecast direction")
            if not nonempty_str(c.get("trap")) or not nonempty_str(c.get("boss_question")):
                problems.append(f"{cid}: trap or boss_question empty")
        check(not problems, "case fields, enums, ranges, cross-references" + ("" if not problems else ": " + "; ".join(problems[:12])))
        covered = {c.get("trap_id") for c in cs}
        missing = [t for t in REQUIRED_TRAPS if t not in covered]
        check(not missing, "all required traps covered" + ("" if not missing else ": missing " + ", ".join(missing)))
        check(DATASETS <= {c.get("dataset_type") for c in cs}, "all dataset types used")
        check(SKILLS <= {c.get("skill") for c in cs}, "all 5 skills have cases")
        check(METHODS <= {c.get("method") for c in cs}, "all 10 methods used")
        check(any(c.get("unlock_day") == 1 for c in cs), "a case is available on day 1")
        # every card used by at least one case or tutorial (soft)
        used = {h for c in cs for h in c.get("handbook_card_ids", [])}
        unused = sorted(card_ids - used)
        print("INFO handbook cards not linked from any case: " + (", ".join(unused) if unused else "none"))

        if co:
            traps = co.get("traps", {})
            case_traps = {c.get("trap_id") for c in cs}
            problems = []
            for t in sorted(case_traps | set(REQUIRED_TRAPS)):
                if t not in traps:
                    problems.append(f"no coaching for trap {t}")
                    continue
                for kind in KINDS:
                    lines = traps[t].get(kind, [])
                    if not (2 <= len(lines) <= 3):
                        problems.append(f"{t}.{kind}: needs 2 to 3 variants")
                    for ln in lines:
                        if ln.get("voice") not in VOICES or not nonempty_str(ln.get("text")):
                            problems.append(f"{t}.{kind}: bad line")
                    texts = [ln.get("text") for ln in lines]
                    if len(texts) != len(set(texts)):
                        problems.append(f"{t}.{kind}: duplicate variants")
                    if len({ln.get("voice") for ln in lines}) < 2:
                        problems.append(f"{t}.{kind}: fewer than 2 voices")
            for t in traps:
                if t not in case_traps:
                    problems.append(f"coaching trap {t} has no case")
            check(not problems, "coaching covers every trap (praise, miss, wrong_fix; 2-3 variants; voices)" + ("" if not problems else ": " + "; ".join(problems[:12])))
            used_v = {ln["voice"] for t in traps.values() for k in KINDS for ln in t.get(k, [])}
            check(used_v == VOICES, "coaching uses all three voices")

    # ---- English only + files exist
    problems = []
    for rel in FILES:
        p = os.path.join(ROOT, rel)
        if not os.path.exists(p):
            problems.append(f"missing file {rel}")
            continue
        with open(p, encoding="utf-8") as f:
            for n, line in enumerate(f, 1):
                m = VN.search(line)
                if m:
                    problems.append(f"{rel}:{n} non-English character {m.group(0)!r}")
    check(not problems, "all content files exist and are English-only (no Vietnamese diacritics)" + ("" if not problems else ": " + "; ".join(problems[:8])))

    # ---- tutorial sanity
    p = os.path.join(ROOT, "docs/TUTORIAL-CASES.md")
    if os.path.exists(p):
        text = open(p, encoding="utf-8").read()
        days = re.findall(r"^## Day (\d)", text, re.M)
        check(days == ["1", "2", "3", "4", "5"], "tutorial has Day 1 to Day 5")
        blocks = re.findall(r"```csv\n(.*?)\n```", text, re.S)
        sizes = [len(b.strip().split("\n")) - 1 for b in blocks]
        check(len(blocks) == 5 and all(10 <= s <= 30 for s in sizes), f"tutorial has 5 CSV datasets with 10-30 rows (rows: {sizes})")

    print("RESULT: " + ("PASS" if fails == 0 else f"FAIL ({fails} failing checks)"))
    return 0 if fails == 0 else 1


if __name__ == "__main__":
    sys.exit(main())

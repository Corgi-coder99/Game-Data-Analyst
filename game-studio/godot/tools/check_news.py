"""Validate T-038 content against the committed pre-expansion baseline, offline."""
import collections
import json
from pathlib import Path
import re
import string
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "game-studio/godot/"
ERRORS = []


def check(condition, message):
    if not condition:
        ERRORS.append(message)


def load(name, baseline=False):
    if baseline:
        result = subprocess.run(
            ["git", "show", f"HEAD:{PREFIX}{name}"], cwd=ROOT,
            capture_output=True, check=True, encoding="utf-8")
        return json.loads(result.stdout)
    return json.loads((ROOT / name).read_text(encoding="utf-8-sig"))


def counts(items, fields):
    return collections.Counter(tuple(item[f] for f in fields) for item in items)


def distribution(before, after, fields):
    a, b = counts(before, fields), counts(after, fields)
    print("\n| " + " x ".join(fields) + " | Before | After | Before % | After % | Delta pp |")
    print("|---|---:|---:|---:|---:|---:|")
    for key in sorted(a.keys() | b.keys()):
        old, new = 100 * a[key] / len(before), 100 * b[key] / len(after)
        print(f"| {' / '.join(key)} | {a[key]} | {b[key]} | {old:.3f} | {new:.3f} | {new-old:+.3f} |")
        check(abs(new - old) <= 3.000001, f"distribution drift: {fields} {key}")


def english(text, context):
    # ASCII excludes Vietnamese diacritics and emojis; editorial English is reviewed manually.
    check(isinstance(text, str) and bool(text.strip()) and text.isascii(), f"English/ASCII: {context}")


def main():
    old, news = load("data/news.json", True), load("data/news.json")
    oq, questions = load("data/questions.json", True), load("data/questions.json")
    od, datasets = load("data/datasets.json", True), load("data/datasets.json")
    oc, coaching = load("data/coaching.json", True), load("data/coaching.json")
    a, b = old["news"], news["news"]
    print(f"Counts: news {len(a)} -> {len(b)}; sources {len(old['sources'])} -> {len(news['sources'])}; questions {len(oq['questions'])} -> {len(questions['questions'])}")
    check(len(b) >= 110, "at least 110 news templates")
    check(4 <= len(news["sources"]) - len(old["sources"]) <= 6, "4-6 new sources")
    for field in ("news", "sources"):
        current = {item["id"]: item for item in news[field]}
        check(len(current) == len(news[field]), f"unique {field} ids")
        for item in old[field]:
            check(current.get(item["id"]) == item, f"unchanged original {field}: {item['id']}")
    check({k: v for k, v in old.items() if k not in ("news", "sources")} ==
          {k: v for k, v in news.items() if k not in ("news", "sources")}, "news metadata unchanged")
    for fields in (("topic",), ("kind",), ("source_tier",), ("topic", "kind", "source_tier")):
        distribution(a, b, fields)
    sources = {s["id"]: s for s in news["sources"]}
    print("\n| Tier | Reliability before/after | Delay before/after |")
    print("|---|---:|---:|")
    for tier in old["tiers"]:
        values = []
        for group in (old["sources"], news["sources"]):
            rows = [s for s in group if s["tier"] == tier]
            values.append(tuple(sum(s[f] for s in rows) / len(rows) for f in ("reliability", "delay_days")))
        print(f"| {tier} | {values[0][0]:.6f} / {values[1][0]:.6f} | {values[0][1]:.6f} / {values[1][1]:.6f} |")
        for i in range(2):
            check(abs(values[1][i] - values[0][i]) <= .020001, f"tier average {tier} {i}")
    used = {item["source_id"] for item in b}
    for source in news["sources"]:
        check(set(source) == set(old["sources"][0]), f"source schema: {source['id']}")
        check(source["tier"] in old["tiers"] and 0 <= source["reliability"] <= 1 and
              type(source["delay_days"]) is int and source["delay_days"] >= 0, f"source values: {source['id']}")
        english(source["name"], source["id"])
        check(source["id"] in used, f"source used: {source['id']}")
    allowed_shapes = {frozenset(item) for item in a}
    enums = {f: {json.dumps(item[f], sort_keys=True) for item in a} for f in
             ("topic", "source_tier", "direction", "kind", "truth", "link", "state_direction", "exaggerates", "verify_with")}
    truths = {item["kind"]: item["truth"] for item in a}
    for item in b:
        label = item["id"]
        check(frozenset(item) in allowed_shapes, f"news schema: {label}")
        for field, values in enums.items():
            check(json.dumps(item.get(field), sort_keys=True) in values, f"news enum {field}: {label}")
        check(item["truth"] == truths[item["kind"]], f"truth/kind: {label}")
        check(item["source_id"] in sources and sources[item["source_id"]]["tier"] == item["source_tier"], f"source tier: {label}")
        headline = item["headline"]
        english(headline, label)
        check(len(headline) <= 90 and "\n" not in headline and "\r" not in headline, f"headline length: {label}")
        fields = [field for _, field, spec, conversion in string.Formatter().parse(headline) if field is not None]
        check(all(field == "pct" for field in fields), f"placeholders: {label}")
        check(not fields or "magnitude_pct" in item, f"placeholder magnitude: {label}")
        if "magnitude_pct" in item:
            mag = item["magnitude_pct"]
            check(set(mag) == {"low", "mid", "high"} and all(type(v) in (int, float) and v >= 0 for v in mag.values()), f"magnitude schema: {label}")
        check(not re.search(r"\b(signal|trap|partial|stale|noise|truth|false news)\b", headline, re.I), f"hidden labels in headline: {label}")
    check(len({i["headline"] for i in b}) == len(b), "unique headlines")
    qs = questions["questions"]
    check(set(questions) == set(oq) and len(qs) >= 18, "question schema/count")
    check(len({q["id"] for q in qs}) == len(qs), "unique question ids")
    qm = {q["id"]: q for q in qs}
    for q in oq["questions"]:
        check(qm.get(q["id"]) == q, f"original question unchanged: {q['id']}")
    rules = {q["answer_rule"] for q in oq["questions"]}
    variables = {i["link"].split(":")[1] for i in a if str(i["link"]).startswith("state:")}
    qc = collections.Counter(q["variable"] for q in qs if q["variable"] in variables)
    print("\n| Question variable | Before | After |\n|---|---:|---:|")
    for var in sorted({q["variable"] for q in qs}):
        print(f"| {var} | {sum(q['variable'] == var for q in oq['questions'])} | {sum(q['variable'] == var for q in qs)} |")
    check(set(qc) == variables and max(qc.values()) - min(qc.values()) <= 1, "even coverage of six variables")
    for q in qs:
        check(set(q) == set(oq["questions"][0]) and q["answer_rule"] in rules and
              type(q["window_days"]) is int and q["window_days"] >= 0, f"question fields: {q['id']}")
        english(q["text"], q["id"])
        entries = datasets["relevance"]["map"].get(q["id"], [])
        check(bool(entries), f"question mapped: {q['id']}")
        for entry in entries:
            spec = datasets["datasets"].get(entry["dataset"], {})
            check(bool(spec), f"mapped dataset exists: {q['id']}")
            if q["id"] not in {oldq["id"] for oldq in oq["questions"]}:
                matching = spec.get("variable") == q["variable"] or any(
                    s["variable"] == q["variable"] and s["name"] == entry.get("series") for s in spec.get("series", []))
                check(matching, f"question dataset relevance: {q['id']}")
    for key, value in od["relevance"]["map"].items():
        check(datasets["relevance"]["map"].get(key) == value, f"original mapping unchanged: {key}")
    datasets["relevance"]["map"] = od["relevance"]["map"]
    check(datasets == od, "datasets changes limited to question map")
    check(set(coaching) == set(oc) and set(coaching["traps"]) == set(oc["traps"]), "coaching keys unchanged")
    for k in oc.keys() - {"traps"}:
        check(coaching[k] == oc[k], f"coaching metadata unchanged: {k}")
    total = 0
    for trap, entry in coaching["traps"].items():
        previous = oc["traps"][trap]
        check(set(entry) == set(previous) and entry["name"] == previous["name"], f"coaching trap keys: {trap}")
        for outcome in ("praise", "miss", "wrong_fix"):
            lines = entry[outcome]
            check(len(lines) == len(previous[outcome]) == 3, f"coaching count: {trap}.{outcome}")
            check({line["voice"] for line in lines} == {"hanh", "khoi", "linh"}, f"coaching voices: {trap}.{outcome}")
            for line, prior in zip(lines, previous[outcome]):
                total += 1
                text = line["text"]
                english(text, f"{trap}.{outcome}.{line['voice']}")
                check(set(line) == set(prior) and line["voice"] == prior["voice"] and text != prior["text"], f"coaching rewritten: {trap}.{outcome}")
                check(len(text) <= 160 and 1 <= len(re.split(r"(?<=[.!?])\s+", text)) <= 2, f"coaching length/sentences: {trap}.{outcome}.{line['voice']}")
    check(total == 279 and len(coaching["traps"]) == 31, "31 traps / 279 coaching lines")
    print(f"\nCoaching: {len(oc['traps'])} -> {len(coaching['traps'])} traps; 279 -> {total} lines")
    for error in ERRORS:
        print("FAIL " + error)
    print(f"RESULT: {'FAIL' if ERRORS else 'PASS'} ({len(ERRORS)} errors)")
    return bool(ERRORS)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, KeyError, TypeError, OSError, subprocess.CalledProcessError) as exc:
        print(f"FAIL {type(exc).__name__}: {exc}")
        sys.exit(1)

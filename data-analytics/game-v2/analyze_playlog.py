"""T-043: tổng hợp playlog bot -> bảng CSV + in kết quả. Chạy:
  .venv\\Scripts\\python.exe -X utf8 -I data-analytics/game-v2/analyze_playlog.py <playlog.jsonl> <thư mục output>
"""
import json
import sys
from pathlib import Path

import pandas as pd

src, out = Path(sys.argv[1]), Path(sys.argv[2])
out.mkdir(parents=True, exist_ok=True)
rows = [json.loads(line) for line in src.read_text(encoding="utf-8").splitlines() if line.strip()]
df = pd.DataFrame(rows)
df["bot"] = df["pid"].str.replace("bot-", "", regex=False)

# --- 1. Chất lượng dữ liệu ---
quality = {
    "events": len(df),
    "runs": int(df.loc[df.e == "run_start", "run_id"].nunique()),
    "dup_run_start": int(df[df.e == "run_start"].run_id.duplicated().sum()),
    "runs_without_end": int(len(set(df[df.e == "run_start"].run_id) - set(df[df.e == "run_end"].run_id))),
    "src_values": sorted(df.src.unique().tolist()),
    "event_counts": df.e.value_counts().to_dict(),
}
de = df[df.e == "day_end"]
quality["acc_out_of_range"] = int(((de.acc < 0) | (de.acc > 1)).sum())
per_run = df[df.e == "day_start"].groupby("run_id").size()
quality["runs_day_start_not_10"] = int((per_run != 10).sum())
print("QUALITY", json.dumps(quality, indent=1, default=str))
(out / "quality.json").write_text(json.dumps(quality, indent=1, default=str), encoding="utf-8")

# --- 2. Funnel theo ngày: bao nhiêu run đạt ngày d, theo bot ---
ds = df[df.e == "day_start"]
funnel = ds.groupby(["bot", "day"]).run_id.nunique().unstack(fill_value=0)
funnel.to_csv(out / "funnel_by_day.csv")
ends = df[df.e == "run_end"].groupby(["bot", "ending"]).size().unstack(fill_value=0)
ends.to_csv(out / "endings_by_bot.csv")
print("\nFUNNEL\n", funnel, "\nENDINGS\n", ends)

# --- 3. Chiến lược: verify-first vs submit-early (ghép cặp theo seed) ---
runs = df[df.e == "run_start"][["run_id", "bot", "seed"]]
rend = df[df.e == "run_end"][["run_id", "score", "won", "trust", "rank"]]
r = runs.merge(rend, on="run_id")
acc = de.groupby("run_id").agg(acc=("acc", "mean"), ev=("ev", "mean"))
r = r.merge(acc, left_on="run_id", right_index=True)
strategy = r.groupby("bot").agg(runs=("run_id", "count"), win_rate=("won", "mean"), score=("score", "mean"),
                                trust=("trust", "mean"), acc=("acc", "mean"), ev=("ev", "mean")).round(3)
strategy.to_csv(out / "strategy_summary.csv")
print("\nSTRATEGY\n", strategy)
pair = r[r.bot.isin(["analyst_verify_first", "analyst_submit_early"])].pivot(index="seed", columns="bot", values=["acc", "ev", "score"])
if not pair.empty:
    diff = pd.DataFrame({m: pair[m]["analyst_verify_first"] - pair[m]["analyst_submit_early"] for m in ["acc", "ev", "score"]})
    summ = diff.agg(["mean", "std", "count"]).T
    summ["se"] = summ["std"] / summ["count"] ** 0.5
    summ["ci95_lo"] = summ["mean"] - 1.96 * summ["se"]
    summ["ci95_hi"] = summ["mean"] + 1.96 * summ["se"]
    summ.round(3).to_csv(out / "verify_first_vs_submit_early_paired.csv")
    print("\nPAIRED verify_first - submit_early\n", summ.round(3))
# --- 3b. Đối chứng: một lần verify (analyst_clean) vs không verify (analyst_no_verify), ghép cặp theo seed ---
if "analyst_no_verify" in set(r.bot):
    r["won_i"] = r.won.astype(int)
    pv = r[r.bot.isin(["analyst_clean", "analyst_no_verify"])].pivot(index="seed", columns="bot", values=["acc", "ev", "score", "trust", "won_i"])
    d2 = pd.DataFrame({m: pv[m]["analyst_clean"] - pv[m]["analyst_no_verify"] for m in ["acc", "ev", "score", "trust", "won_i"]})
    s2 = d2.agg(["mean", "std", "count"]).T
    s2["se"] = s2["std"] / s2["count"] ** 0.5
    s2["ci95_lo"] = s2["mean"] - 1.96 * s2["se"]
    s2["ci95_hi"] = s2["mean"] + 1.96 * s2["se"]
    s2.round(3).to_csv(out / "verify_vs_no_verify_paired.csv")
    print("\nPAIRED one-verify - no-verify\n", s2.round(3))
    nv = df[(df.e == "report_submit") & (df.bot == "analyst_no_verify")]
    cv = df[(df.e == "report_submit") & (df.bot == "analyst_clean")]
    print("minutes mean: no_verify %.1f clean %.1f" % (nv.minutes.mean(), cv.minutes.mean()))

vf = df[(df.e == "verify") & df.bot.isin(["analyst_verify_first", "analyst_submit_early"])]
print("\nVERIFY events per bot\n", vf.groupby("bot").size())

# --- 4. Áp lực thời gian: timing theo ngày ---
timing = de.groupby(["day", "timing"]).size().unstack(fill_value=0)
timing = timing.div(timing.sum(axis=1), axis=0).round(3)
timing.to_csv(out / "timing_by_day.csv")
print("\nTIMING by day\n", timing)
rs = df[df.e == "report_submit"].groupby("band").size()
print("\nSUBMIT by band\n", rs)

# --- 5. Độ khó câu hỏi ---
dstart = ds[["run_id", "day", "question_id"]]
q = de[["run_id", "day", "acc", "ev", "label", "bot"]].merge(dstart, on=["run_id", "day"])
qdiff = q.groupby("question_id").agg(n=("acc", "count"), acc=("acc", "mean"), ev=("ev", "mean")).round(3)
qdiff["wrong_label_share"] = q.groupby("question_id").label.apply(lambda s: (s != "correct").mean()).round(3) if "correct" in set(q.label) else None
qdiff.to_csv(out / "question_difficulty.csv")
print("\nQUESTION difficulty\n", qdiff.sort_values("acc"))
print("\nLABELS\n", q.label.value_counts())

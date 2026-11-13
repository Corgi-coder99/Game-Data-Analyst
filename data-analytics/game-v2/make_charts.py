"""T-043: 3 biểu đồ cho report.md từ tables/*.csv. Chạy: .venv\Scripts\python.exe -X utf8 -I data-analytics/game-v2/make_charts.py"""
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

T, OUT = Path(__file__).parent / "tables", Path(__file__).parent / "charts"
SURF, INK, INK2, GRID = "#fcfcfb", "#0b0b0b", "#52514e", "#e6e5e1"
BLUE, ORANGE, AQUA, VIOLET = "#2a78d6", "#eb6834", "#1baf7a", "#6250d6"
plt.rcParams.update({"font.family": "DejaVu Sans", "axes.facecolor": SURF, "figure.facecolor": SURF,
                     "axes.edgecolor": GRID, "axes.labelcolor": INK2, "xtick.color": INK2, "ytick.color": INK2,
                     "axes.spines.top": False, "axes.spines.right": False})

# 1. Phễu: số run còn sống theo ngày (60 run mỗi bot)
f = pd.read_csv(T / "funnel_by_day.csv", index_col=0)
lines = [("analyst_clean", "Analyst (clean)", BLUE), ("verifier", "Verifier", AQUA),
         ("official_only", "Official only", ORANGE), ("rumor_follower", "Rumor follower", VIOLET)]
fig, ax = plt.subplots(figsize=(8, 4.2))
ax.yaxis.grid(True, color=GRID, lw=1); ax.set_axisbelow(True)
for key, label, color in lines:
    y = f.loc[key].astype(int); x = [int(c) for c in f.columns]
    ax.plot(x, y, color=color, lw=2)
    ax.plot(x[-1], y.iloc[-1], "o", color=color, ms=8, mec=SURF, mew=2)
    ax.annotate(f"{label} ({y.iloc[-1]})", (x[-1], y.iloc[-1]), xytext=(8, 0), textcoords="offset points", va="center", color=INK, fontsize=9)
ax.set_xlim(1, 12.6); ax.set_ylim(0, 62); ax.set_xticks(range(1, 11))
ax.set_xlabel("Day"); ax.set_ylabel("Runs still active (of 60)")
ax.set_title("Weak strategies get fired early; careful ones reach day 10", loc="left", color=INK, fontsize=12)
fig.tight_layout(); fig.savefig(OUT / "1_funnel_by_day.png", dpi=160); plt.close(fig)

# 2. Verify vs no verify: chênh lệch ghép cặp với 95% CI, mỗi chỉ số một ô (thang khác nhau)
d = pd.read_csv(T / "verify_vs_no_verify_paired.csv", index_col=0)
names = {"ev": "Evidence quality (ev)", "trust": "Trust", "acc": "Accuracy", "score": "Score", "won_i": "Win rate"}
fig, axes = plt.subplots(5, 1, figsize=(8.5, 5.2))
for ax, k in zip(axes, names):
    m, lo, hi = d.loc[k, "mean"], d.loc[k, "ci95_lo"], d.loc[k, "ci95_hi"]
    sig = lo > 0 or hi < 0
    c = BLUE if sig else INK2
    ax.axvline(0, color=GRID, lw=1.5)
    ax.plot([lo, hi], [0, 0], color=c, lw=2); ax.plot(m, 0, "o", color=c, ms=9, mec=SURF, mew=2)
    pad = (hi - lo) * 0.8; ax.set_xlim(min(lo, 0) - pad, max(hi, 0) + pad); ax.set_ylim(-1, 1); ax.set_yticks([])
    ax.set_ylabel(names[k], rotation=0, ha="right", va="center", fontsize=9, color=INK)
    ax.text(1.02, 0.5, f"{m:+.3g}  [{lo:+.3g}, {hi:+.3g}]" + ("" if sig else "  covers 0"), transform=ax.transAxes, fontsize=8.5, color=INK2, va="center")
    ax.tick_params(labelsize=8)
fig.suptitle("One verification vs none, paired on 60 seeds (95% CI; blue = excludes 0)", x=0.01, ha="left", fontsize=11, color=INK)
fig.subplots_adjust(left=0.2, right=0.68, top=0.9, bottom=0.07, hspace=0.9)
fig.savefig(OUT / "2_verify_vs_no_verify.png", dpi=160); plt.close(fig)

# 3. Độ khó câu hỏi: acc trung bình theo question_id
q = pd.read_csv(T / "question_difficulty.csv").sort_values("acc")
fig, ax = plt.subplots(figsize=(7, 5.4))
cols = [ORANGE if a >= 0.85 else BLUE for a in q.acc]
ax.barh(q.question_id, q.acc, color=cols, height=0.62)
ax.xaxis.grid(True, color=GRID, lw=1); ax.set_axisbelow(True)
for y, a in zip(q.question_id, q.acc): ax.text(a + 0.008, y, f"{a:.2f}", va="center", fontsize=8.5, color=INK)
ax.set_xlim(0, 1); ax.set_xlabel("Mean accuracy (all bots)")
ax.set_title("q5 and q9 are clearly easier than the rest (orange)", loc="left", color=INK, fontsize=12)
fig.tight_layout(); fig.savefig(OUT / "3_question_difficulty.png", dpi=160); plt.close(fig)
print("ok")

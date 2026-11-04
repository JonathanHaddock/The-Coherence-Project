"""Selectivity: how exclusively each entity engages one force.

S = 1 - H(p) / ln 3, with p = v / sum(v) the share of the entity's
interaction strength on each force (EM, weak, strong) and H the Shannon
entropy. S = 1: engages a single force only. S = 0: all three equally.
Uses the four variants (scale, weak definition) from strengths.py.
"""
import sys
from math import log
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
from strengths import SCALES, entities  # noqa: E402

OUT = Path(__file__).parent / "results"


def selectivity(v):
    p = v / v.sum()
    h = -sum(x * log(x) for x in p if x > 0)
    return 1 - h / log(3)


rows, lines = [], ["SELECTIVITY S = 1 - H/ln3 (1 = one force only, 0 = all equally)", ""]
for scale, c in SCALES.items():
    for with_w in (False, True):
        tag = f"{scale}, weak = Z{' + W' if with_w else ''}"
        lines.append(tag)
        for ent, v in entities(c["alpha"], c["alpha_s"], with_w).items():
            rows.append((tag, ent, selectivity(v)))
            lines.append(f"  {ent:<16} S = {selectivity(v):.3f}")
        lines.append("")
text = "\n".join(lines)
print(text)
(OUT / "selectivity.txt").write_text(text + "\n")

ents = ["neutrinos", "charged leptons", "quarks (bound)"]
tags = list(dict.fromkeys(t for t, _, _ in rows))
fig, ax = plt.subplots(figsize=(10, 5))
width = 0.8 / len(tags)
for k, tag in enumerate(tags):
    vals = [s for t, e, s in rows if t == tag]
    xs = np.arange(len(ents)) + (k - (len(tags) - 1) / 2) * width
    ax.bar(xs, vals, width * 0.92, color=["#2a78d6", "#86b6ef", "#184f95", "#b7d3f6"][k], label=tag)
    for x, v in zip(xs, vals):
        ax.annotate(f"{v:.2f}", (x, v), xytext=(0, 3), textcoords="offset points", ha="center", fontsize=8)
ax.set_xticks(range(len(ents)), ["neutrinos\n(select one force)", "charged leptons\n(engage two)", "quarks, bound\n(strong dominates)"])
ax.set_ylim(0, 1.12)
ax.set_ylabel("selectivity (1 = one force only)")
ax.set_title("Selectivity: which forces each entity engages")
ax.legend(loc="upper center", fontsize=9, ncol=2)
cs.footer(fig, "S = 1 - H(p)/ln 3, p = share of interaction strength on (EM, weak, strong) per particle. PDG 2024 couplings.")
cs.save(fig, OUT / "7-selectivity.png")

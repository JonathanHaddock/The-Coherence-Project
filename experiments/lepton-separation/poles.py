"""Do the poles have no projection? Off-axis share of each interaction vector.

off = 1 - (largest component)^2 / |v|^2: the share of the vector projected
onto axes other than its dominant one. 0 = sits purely on one axis (a pole
with no projection); larger = spread across forces.
Uses the interaction-strength vectors from strengths.py, all four variants.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
from strengths import SCALES, entities  # noqa: E402

OUT = Path(__file__).parent / "results"
FORCES = ["EM", "weak", "strong"]


def off_axis(v):
    return 1 - v.max() ** 2 / (v ** 2).sum()


rows, lines = [], ["OFF-AXIS PROJECTION (0 = pure pole, no projection)", ""]
for scale, c in SCALES.items():
    for with_w in (False, True):
        tag = f"{scale}, weak = Z{' + W' if with_w else ''}"
        lines.append(tag)
        for ent, v in entities(c["alpha"], c["alpha_s"], with_w).items():
            rows.append((tag, ent, off_axis(v)))
            lines.append(f"  {ent:<16} dominant axis {FORCES[int(np.argmax(v))]:<6} off-axis share {off_axis(v):.4f}")
        lines.append("")
text = "\n".join(lines)
(OUT / "poles.txt").write_text(text + "\n")
print(text)

ents = ["neutrinos", "charged leptons", "quarks (bound)"]
tags = list(dict.fromkeys(t for t, _, _ in rows))
fig, ax = plt.subplots(figsize=(10, 5))
width = 0.8 / len(tags)
shades = ["#2a78d6", "#86b6ef", "#184f95", "#b7d3f6"]
for k, tag in enumerate(tags):
    vals = [o for t, e, o in rows if t == tag]
    xs = np.arange(len(ents)) + (k - (len(tags) - 1) / 2) * width
    ax.bar(xs, vals, width * 0.92, color=shades[k], label=tag)
    for x, v in zip(xs, vals):
        ax.annotate(f"{v:.3f}", (x, v), xytext=(0, 3), textcoords="offset points", ha="center", fontsize=8)
ax.set_xticks(range(len(ents)), ["neutrinos\n(pole)", "charged leptons\n(between)", "quarks, bound\n(pole)"])
ax.set_ylim(0, 0.5)
ax.set_ylabel("off-axis share of interaction vector")
ax.set_title("Projection lives in the charged leptons, not the poles")
ax.legend(loc="upper right", fontsize=9)
cs.footer(fig, "off = 1 - max(v)^2/|v|^2, v = (EM, weak, strong) strengths per particle. 0 = vector lies on a single force axis.")
cs.save(fig, OUT / "6-pole-projection.png")

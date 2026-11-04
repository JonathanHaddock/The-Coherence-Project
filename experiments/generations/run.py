"""Mass within an entity: tau prediction chart and a look-elsewhere test for 2/9.

Values match `origin generations`. The look-elsewhere test asks how often a
random delta, measured to the same precision, lands within 2 sigma of some
"simple" number: fractions p/q with q <= 12, and the same fractions times pi.
"""
import sys
from fractions import Fraction
from math import pi
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

DELTA, DELTA_ERR = 0.2222248, 0.0000063
KOIDE_TAU = 1776.9690
TAU = [("PDG 2024 average", 1776.93, 0.09), ("Belle II (2023)", 1777.09, 0.136), ("BESIII (2014)", 1776.91, 0.165)]

# delta is defined modulo 2 pi / 3.
period = 2 * pi / 3
targets = sorted({float(Fraction(p, q)) for q in range(1, 13) for p in range(0, 3 * q) if Fraction(p, q) < period}
                 | {float(Fraction(p, q)) * pi for q in range(1, 13) for p in range(0, q) if Fraction(p, q) * pi < period})
targets = np.array(targets)
rng = np.random.default_rng(9)
d = rng.uniform(0, period, 200_000)
dist = np.abs(d[:, None] - targets[None, :]).min(axis=1) if False else None
# Vectorised nearest-target distance via searchsorted.
idx = np.clip(np.searchsorted(targets, d), 1, len(targets) - 1)
near = np.minimum(np.abs(d - targets[idx - 1]), np.abs(d - targets[idx]))
p_chance = np.mean(near <= 2 * DELTA_ERR)

lines = [f"delta = {DELTA} +- {DELTA_ERR}; 2/9 = {2/9:.7f}; pull {(DELTA - 2/9) / DELTA_ERR:.2f} sigma",
         f"simple targets in [0, 2pi/3): {len(targets)} (p/q and p/q * pi, q <= 12)",
         f"chance a random delta lands within 2 sigma of one: {p_chance:.4f} ({100 * p_chance:.2f}%)",
         "", "Koide tau prediction 1776.969 MeV vs measurements:"]
lines += [f"  {n:<18} {v:.3f} +- {e:.3f}  pull {(v - KOIDE_TAU) / e:+.2f} sigma" for n, v, e in TAU]
text = "\n".join(lines)
print(text)
(Path(__file__).parent / "summary.txt").write_text(text + "\n")

fig, ax = plt.subplots(figsize=(10, 4.5))
ax.grid(axis="y", visible=False)
for i, (n, v, e) in enumerate(TAU):
    ax.errorbar(v, i, xerr=e, fmt="o", ms=9, color="#2a78d6", capsize=5, mec=cs.SURFACE, mew=1.5)
    ax.annotate(f"{v:.2f} +- {e:.2f}", (v, i), xytext=(0, 10), textcoords="offset points", ha="center", fontsize=9,
                bbox=dict(boxstyle="round,pad=0.15", fc=cs.SURFACE, ec="none"))
ax.axvline(KOIDE_TAU, color="#eb6834", lw=1.5, ls="--")
ax.annotate("Koide prediction from e and mu: 1776.969 MeV", (KOIDE_TAU, len(TAU) - 0.4), xytext=(6, 0),
            textcoords="offset points", fontsize=9, color="#eb6834")
ax.set_yticks(range(len(TAU)), [t[0] for t in TAU])
ax.set_ylim(-0.6, len(TAU) - 0.1)
ax.set_xlim(1776.5, 1777.5)
ax.set_xlabel("tau mass (MeV)")
ax.set_title("The tau mass against Koide's prediction")
cs.footer(fig, f"Prediction uses only the electron and muon masses. Brannen delta = 2/9 holds to 0.4 sigma; chance of such a match {100 * p_chance:.1f}%.")
cs.save(fig, Path(__file__).parent / "tau-prediction.png")

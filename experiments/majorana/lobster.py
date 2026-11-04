"""Chart: effective Majorana mass band vs lightest neutrino mass.

Same formulas and inputs as `origin majorana` (origin/src/analysis/majorana.zig):
PDG 2024 mixing (sin^2 t12 = 0.307, sin^2 t13 = 0.0219), NuFIT 6.0 splittings
(7.49e-5, 2.513e-3 eV^2). Bands span all Majorana phases.
"""
import sys
from math import sqrt
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

S12, S13 = 0.307, 0.0219
DM21, DM31 = 7.49e-5, 2.513e-3
W = np.array([(1 - S12) * (1 - S13), S12 * (1 - S13), S13])


def masses(l, inverted):
    if inverted:
        dm32 = DM31 - DM21
        return np.array([sqrt(l * l + dm32 - DM21), sqrt(l * l + dm32), l])
    return np.array([l, sqrt(l * l + DM21), sqrt(l * l + DM31)])


def band(l, inverted):
    t = W * masses(l, inverted)
    return max(0.0, 2 * t.max() - t.sum()), t.sum()


ls = np.geomspace(1e-4, 0.3, 600)
fig, ax = plt.subplots(figsize=cs.FIGSIZE)
ax.set_xscale("log")
ax.set_yscale("log")
for inverted, colour, name in [(False, "#2a78d6", "normal ordering"), (True, "#eb6834", "inverted ordering")]:
    lo, hi = zip(*[band(l, inverted) for l in ls])
    lo = np.maximum(np.array(lo), 1e-5)
    ax.fill_between(ls, lo, hi, color=colour, alpha=0.35, lw=0, label=name)
for name, a, b, colour in [("KamLAND-Zen 800 limit", 0.028, 0.122, "#6b6a64"), ("LEGEND-1000 reach", 0.009, 0.024, "#1baf7a"),
                           ("nEXO reach", 0.0047, 0.0203, "#4a3aa7")]:
    ax.axhspan(a, b, color=colour, alpha=0.12, lw=0)
    ax.axhline(a, color=colour, lw=1.2, ls="--")
ax.annotate("excluded by KamLAND-Zen (above 28-122 meV)", (1.2e-4, 0.16), fontsize=9, color=cs.INK_2)
ax.annotate("LEGEND-1000 reach 9-24 meV", (1.2e-4, 0.0095), xytext=(0, -12), textcoords="offset points", fontsize=9, color="#1baf7a")
ax.annotate("nEXO reach 4.7-20 meV", (1.2e-4, 0.0049), xytext=(0, -12), textcoords="offset points", fontsize=9, color="#4a3aa7")
ax.annotate("normal ordering can cancel to zero:\nMajorana neutrinos could hide here", (6.5e-3, 2.5e-4), xytext=(40, 30),
            textcoords="offset points", fontsize=9, ha="left", arrowprops=dict(arrowstyle="-", color=cs.INK_2, lw=0.8))
ax.set_xlim(1e-4, 0.3)
ax.set_ylim(1e-4, 0.5)
ax.set_xlabel("lightest neutrino mass (eV)")
ax.set_ylabel("effective Majorana mass m_bb (eV)")
ax.set_title("Where a Majorana signal could appear")
ax.legend(loc="lower right")
cs.footer(fig, "Bands span all Majorana phases. PDG 2024 mixing, NuFIT 6.0 splittings. Experiment ranges reflect nuclear-model uncertainty.")
cs.save(fig, Path(__file__).parent / "lobster.png")

"""Chart: the Identity-Differentiation Triangle's neutrino prediction window.

Neutrino D against total neutrino mass for both orderings. The hypothesis
(neutrinos are identity, D <= 0.1) needs the curve inside the shaded band;
cosmology excludes totals above its limit. The overlap is the window.
"""
import sys
from math import sqrt
from pathlib import Path

import numpy as np
from scipy.optimize import brentq

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

DM21, DM31 = 7.49e-5, 2.513e-3
D_IDENTITY = 0.1
DESI, PLANCK = 0.072, 0.12
NORMAL, INVERTED = "#2a78d6", "#eb6834"


def normal(m):
    return np.array([m, sqrt(m * m + DM21), sqrt(m * m + DM31)])


def inverted(m):
    return np.array([sqrt(m * m + DM31 - 2 * DM21), sqrt(m * m + DM31 - DM21), m])


def d_of(masses):
    return 1.5 * (masses.sum() / np.sqrt(masses).sum() ** 2 - 1 / 3)


lightest = np.r_[0, np.geomspace(1e-5, 0.1, 400)]
fig, ax = plt.subplots(figsize=cs.FIGSIZE)
x_max = 0.2

# Regions.
ax.axhspan(0, D_IDENTITY, color="#1baf7a", alpha=0.12, lw=0)
ax.annotate("hypothesis: neutrinos are identity (D <= 0.1)", (0.2 - 0.002, D_IDENTITY), xytext=(0, -14),
            textcoords="offset points", ha="right", fontsize=9, color=cs.INK)
ax.axvspan(DESI, x_max, color=cs.INVALID, alpha=0.35, lw=0)
ax.axvline(DESI, color=cs.INK_2, lw=1.2, ls="--")
ax.annotate("excluded by DESI 2024\n(requires total < 0.072 eV)", (DESI, 0.20), xytext=(6, 0), textcoords="offset points",
            fontsize=9, color=cs.INK)
ax.axvline(PLANCK, color=cs.INK_2, lw=1, ls=":")
ax.annotate("Planck 2018 limit 0.12", (PLANCK, 0.33), xytext=(6, 0), textcoords="offset points", fontsize=9,
            color=cs.INK_2)

for name, f, colour, marker in [("normal ordering", normal, NORMAL, "o"), ("inverted ordering", inverted, INVERTED, "s")]:
    sums = np.array([f(m).sum() for m in lightest])
    ds = np.array([d_of(f(m)) for m in lightest])
    ax.plot(sums, ds, color=colour, lw=2.5, label=name)
    ax.scatter(sums[0], ds[0], s=70, color=colour, marker=marker, ec=cs.SURFACE, lw=1.5, zorder=3)
    ax.annotate(f"{name}\n(lightest = 0)", (sums[0], ds[0]), xytext=(8, 4), textcoords="offset points",
                fontsize=9, color=cs.INK)
    edge = brentq(lambda m: d_of(f(m)) - D_IDENTITY, 1e-9, 1)
    ax.scatter(f(edge).sum(), D_IDENTITY, s=60, color=colour, marker=marker, ec=cs.SURFACE, zorder=4)

# The window: normal ordering, D <= 0.1, below DESI.
low = normal(brentq(lambda m: d_of(normal(m)) - D_IDENTITY, 1e-9, 1)).sum()
ax.axvspan(low, DESI, ymax=D_IDENTITY / 0.45, color="#1baf7a", alpha=0.45, lw=0)
ax.annotate(f"PREDICTION WINDOW\n{low:.3f} - {DESI:.3f} eV", ((low + DESI) / 2, D_IDENTITY / 2), xytext=(70, 60),
            textcoords="offset points", ha="left", fontsize=10, fontweight="bold",
            arrowprops=dict(arrowstyle="-", color=cs.INK, lw=1))

ax.set_xlim(0.05, x_max)
ax.set_ylim(0, 0.45)
ax.set_xlabel("total neutrino mass, sum of m (eV)")
ax.set_ylabel("neutrino D  (0 = identity)")
ax.set_title("Where the triangle hypothesis puts neutrinos")
ax.legend(loc="upper right")
cs.footer(fig, "NuFIT 6.0 splittings. Curves trace the unknown lightest mass from 0 upward. Inverted ordering reaches D <= 0.1 only at 0.102 eV.")
cs.save(fig, Path(__file__).parent / "prediction-window.png")

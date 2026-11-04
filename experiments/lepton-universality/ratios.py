"""Chart: lepton universality from three independent tests.

Values match `origin universality` (origin/src/analysis/universality.zig).
Each point is a ratio expected to be exactly 1 if leptons are identical by
force. LEP tau/e error combines the two widths in quadrature (uncorrelated
approximation).
"""
import sys
from math import hypot
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

ee_peak, ee_err, mm_peak, mm_err = 90.799, 0.080, 90.817, 0.037
points = [
    ("ORIGIN: Z peak, e / mu (CMS open data)", ee_peak / mm_peak, hypot(ee_err / ee_peak, mm_err / mm_peak)),
    ("CMS: sigma x B, ee / mumu (2010, eff.-corrected)", 1.0248, 0.035),
    ("LEP: Gamma(mumu) / Gamma(ee)", 1.0009, 0.0028),
    ("LEP: Gamma(tautau) / Gamma(ee)", 84.05 / 83.90, (84.05 / 83.90) * hypot(0.22 / 84.05, 0.12 / 83.90)),
]
fig, ax = plt.subplots(figsize=(10, 4.8))
ax.grid(axis="y", visible=False)
for i, (name, v, e) in enumerate(points):
    ax.errorbar(v, i, xerr=e, fmt="o", ms=9, color="#2a78d6", ecolor="#2a78d6", capsize=5, mec=cs.SURFACE, mew=1.5)
    ax.annotate(f"{v:.4f} +- {e:.4f}", (v, i), xytext=(0, 10), textcoords="offset points", ha="center", fontsize=9,
                bbox=dict(boxstyle="round,pad=0.15", fc=cs.SURFACE, ec="none"))
ax.axvline(1, color="#eb6834", lw=1.5, ls="--")
ax.annotate("identical by force (ratio = 1)", (1, len(points) - 0.4), xytext=(6, 0), textcoords="offset points",
            fontsize=9, color="#eb6834")
ax.set_yticks(range(len(points)), [p[0] for p in points], fontsize=9)
ax.set_ylim(-0.6, len(points) - 0.1)
ax.set_xlim(0.95, 1.08)
ax.set_xlabel("ratio between lepton flavours")
ax.set_title("Electrons, muons and taus: identical by force")
cs.footer(fig, "Sources: ORIGIN (CMS Run2011A open data), CMS arXiv:1107.4789, LEP partial widths (PDG). Errors: 1 sigma.")
cs.save(fig, Path(__file__).parent / "universality.png")

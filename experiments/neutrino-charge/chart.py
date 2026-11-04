"""Chart: how tightly each measurement bounds the charge shift eps.

Values match `origin charge` (origin/src/analysis/charge.zig). The selection
framework predicts eps = 0 exactly; the Standard Model with right-handed
neutrinos leaves eps free.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

rows = [  # name, central, 1 sigma, source
    ("neutrino charge, reactor (GEMMA)", 0.0, 0.75e-12, "arXiv:1411.2279"),
    ("neutrino charge, lab neutrality", -0.6e-21, 3.2e-21, "arXiv:2406.19129"),
    ("neutron charge", -0.4e-21, 1.1e-21, "arXiv:2406.19129"),
]

fig, ax = plt.subplots(figsize=(10, 4.8))
ax.set_xscale("log")
for i, (name, c, e, src) in enumerate(rows):
    bound = abs(c) + 2 * e
    ax.barh(i, bound, color="#86b6ef", height=0.55, left=1e-24)
    ax.annotate(f"|eps| < {bound:.1e} e   ({src})", (bound, i), xytext=(6, 0), textcoords="offset points",
                va="center", fontsize=9)
ax.set_yticks(range(len(rows)), [r[0] for r in rows])
ax.set_xlim(1e-24, 1e-4)
ax.set_ylim(-0.6, 3.0)
ax.set_xlabel("2-sigma upper bound on |eps| (units of electron charge, log scale)")
ax.set_title("How close measurements are to the framework's eps = 0")
ax.annotate("framework: eps = 0 exactly (off the left edge of a log axis)", (1.5e-24, 2.6),
            fontsize=9, color="#eb6834")
cs.footer(fig, "eps shifts all charges along B - L; hydrogen stays neutral for any eps, so matter neutrality gives no bound. Bars start at 1e-24.")
cs.save(fig, Path(__file__).parent / "eps-bounds.png")

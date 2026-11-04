"""Chart: families on the identity-differentiation axis, with and without mass.

Values come from `origin project` and `origin koide` (ORIGIN v0.4+).
Follows experiments/prime-oscillators/CHART_RULES.md.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

LEPTON, NEUTRINO, DOWN, UP = "#2a78d6", "#1baf7a", "#eda100", "#eb6834"

# (name, D, colour, marker, label offset in points). Points that coincide
# share one label.
rows = [
    ("Mass (Koide, v = sqrt m)", [
        ("charged leptons", 0.500, LEPTON, "o", 14),
        ("down quarks", 0.597, DOWN, "D", -20),
        ("up quarks", 0.773, UP, "s", 14),
    ]),
    ("No mass: PMNS mixing", [
        ("nu2", 0.001, NEUTRINO, "^", -20), ("tau", 0.008, LEPTON, "o", 14),
        ("mu", 0.057, LEPTON, "o", -20), ("nu1", 0.083, NEUTRINO, "^", 14),
        ("nu3", 0.129, NEUTRINO, "^", -20), ("e", 0.150, LEPTON, "o", 14),
    ]),
    ("No mass: CKM mixing", [
        ("c", 0.475, UP, "s", None), ("s", 0.476, DOWN, "D", -20),
        ("u", 0.536, UP, "s", None), ("d", 0.528, DOWN, "D", -20),
        ("t", 0.864, UP, "s", None), ("b", 0.874, DOWN, "D", -20),
    ]),
    ("No mass: sector mean", [
        ("lepton sector (PMNS)", 0.071, NEUTRINO, "^", 14),
        ("quark sector (CKM)", 0.626, UP, "s", 14),
    ]),
]
merged = {"s": "c, s", "d": "u, d", "b": "t, b"}

fig, ax = plt.subplots(figsize=(11, 6.5))
ax.grid(axis="y", visible=False)
ys = [3, 2, 1, 0]
for y, (title, points) in zip(ys, rows):
    ax.axhline(y, color=cs.GRID, lw=1, zorder=0)
    for name, d, colour, marker, offset in points:
        ax.scatter(d, y, s=110, color=colour, marker=marker, ec=cs.SURFACE, lw=1.5, zorder=3)
        if offset is not None:
            ax.annotate(merged.get(name, name), (d, y), xytext=(0, offset), textcoords="offset points",
                        ha="center", fontsize=9, color=cs.INK)

# Neutrino masses are unmeasured: show the allowed range instead of a point.
ax.plot([0.0, 0.378], [3, 3], color=NEUTRINO, lw=6, alpha=0.35, solid_capstyle="round", zorder=1)
ax.annotate("neutrinos: anywhere here\n(masses unmeasured)", (0.19, 3), xytext=(0, -30), textcoords="offset points",
            ha="center", fontsize=9, color=cs.INK)

ax.axvline(0.5, color=cs.INK_2, lw=1, ls="--")
ax.annotate("D = 1/2  equilibrium (Q = 2/3)", (0.5, 3.45), xytext=(4, 0), textcoords="offset points", fontsize=9, color=cs.INK_2)
ax.set_xlim(0, 1)
ax.set_ylim(-0.6, 3.6)
ax.set_yticks(ys, [r[0] for r in rows])
ax.set_xlabel("organizational coordinate D   (0 = identity / democratic,  1 = differentiation)")
ax.set_title("Families on the identity-differentiation axis: with mass and without")
handles = [plt.Line2D([], [], color=c, marker=m, ls="", ms=9, label=l) for l, c, m in
           [("charged leptons", LEPTON, "o"), ("neutrinos", NEUTRINO, "^"), ("down quarks", DOWN, "D"), ("up quarks", UP, "s")]]
ax.legend(handles=handles, loc="upper right", ncol=4, bbox_to_anchor=(1, -0.13))
cs.footer(fig, "Masses PDG 2024. Mixing: CKM PDG 2024 fit; PMNS PDG 2024 normal-ordering angles. Amplitudes |U|, |V| projected onto P1 = J/3.")
fig.tight_layout(rect=(0, 0.05, 1, 1))
fig.savefig(Path(__file__).parent / "families-on-D.png", dpi=cs.DPI)

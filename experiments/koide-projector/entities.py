"""Chart: the three entities on the D axis, quarks treated as one bound entity.

Neutrinos, charged leptons and quarks (each generation's up and down partner
merged, since quarks are confined). Values from `origin koide` and
`origin project`.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

NEUTRINO, LEPTON, QUARK = "#1baf7a", "#2a78d6", "#eb6834"

fig, ax = plt.subplots(figsize=(11, 5))
ax.grid(axis="y", visible=False)
ys = {"mass": 1, "mixing": 0}
for y in ys.values():
    ax.axhline(y, color=cs.GRID, lw=1, zorder=0)

# Mass row. Neutrino masses are unmeasured: an allowed range, not a point.
ax.plot([0.0, 0.378], [1, 1], color=NEUTRINO, lw=8, alpha=0.4, solid_capstyle="round", zorder=1)
ax.annotate("neutrinos: D 0 to 0.38\n(masses unmeasured)", (0.19, 1), xytext=(0, -32), textcoords="offset points",
            ha="center", fontsize=9)
ax.scatter(0.500, 1, s=150, color=LEPTON, marker="o", ec=cs.SURFACE, lw=1.5, zorder=3)
ax.annotate("charged leptons 0.50", (0.5, 1), xytext=(0, 14), textcoords="offset points", ha="center", fontsize=9)
# Bound quarks: two ways of merging generations, shown as a short range.
ax.plot([0.746, 0.763], [1, 1], color=QUARK, lw=8, solid_capstyle="round", zorder=2)
ax.scatter(0.755, 1, s=150, color=QUARK, marker="s", ec=cs.SURFACE, lw=1.5, zorder=3)
ax.annotate("quarks, bound 0.75", (0.755, 1), xytext=(0, 14), textcoords="offset points", ha="center", fontsize=9)

# Mixing row: PMNS is shared by neutrinos and charged leptons; CKM is internal
# to the bound quark entity.
ax.scatter(0.071, 0, s=150, color=NEUTRINO, marker="^", ec=cs.SURFACE, lw=1.5, zorder=3)
ax.annotate("leptons (PMNS) 0.07\nneutrinos + charged leptons together", (0.071, 0), xytext=(6, -32),
            textcoords="offset points", ha="left", fontsize=9)
ax.scatter(0.626, 0, s=150, color=QUARK, marker="s", ec=cs.SURFACE, lw=1.5, zorder=3)
ax.annotate("quarks (CKM) 0.63", (0.626, 0), xytext=(0, 14), textcoords="offset points", ha="center", fontsize=9)

ax.axvline(0.5, color=cs.INK_2, lw=1, ls="--")
ax.annotate("D = 1/2", (0.5, 1.45), xytext=(4, 0), textcoords="offset points", fontsize=9, color=cs.INK_2)
ax.set_xlim(0, 1)
ax.set_ylim(-0.7, 1.6)
ax.set_yticks([1, 0], ["Mass (sqrt m)", "Mixing (no mass)"])
ax.set_xlabel("organizational coordinate D   (0 = identity,  1 = differentiation)")
ax.set_title("Three entities: neutrinos, charged leptons, quarks as one bound entity")
cs.footer(fig, "Bound quarks: generations merged as (u+d, c+s, t+b); bar spans adding masses (0.763) vs adding roots (0.746). PDG 2024, NuFIT 6.0.")
fig.tight_layout(rect=(0, 0.04, 1, 1))
fig.savefig(Path(__file__).parent / "three-entities.png", dpi=cs.DPI)

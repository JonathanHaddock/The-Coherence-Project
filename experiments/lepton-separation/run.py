"""What separates charged leptons from neutrinos without using mass?

Part A: per-generation measurements that do not use mass, projected onto the
identity/differentiation split exactly as in `origin project`.
Part B: entity-level properties (charges, forces, helicity states), to find
which ones distinguish charged leptons from neutrinos.

Values: PDG 2024 unless noted. Outputs in results/.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

OUT = Path(__file__).parent / "results"
OUT.mkdir(exist_ok=True)


def D(v):
    v = np.asarray(v, float)
    q = (v ** 2).sum() / v.sum() ** 2
    return 1.5 * (q - 1 / 3)


# ---------------------------------------------------------------- Part A
# Each row: (quantity, entity, values per generation or None, note)
per_generation = [
    ("Z -> l l branching (%)", "charged leptons", [3.3632, 3.3662, 3.3696], "LEP; e, mu, tau"),
    ("Weak coupling ratios (tau decays)", "charged leptons", [1.0, 1.0018, 1.0029], "HFLAV: g_mu/g_e, g_tau/g_e"),
    ("Anomalous magnetic moment a", "charged leptons", None, "a_e, a_mu measured; a_tau only bounded"),
    ("Electric charge", "charged leptons", [1, 1, 1], "|Q| = 1 for e, mu, tau"),
    ("Electric charge", "neutrinos", None, "0 for all three: no direction to project"),
    ("Z -> nu nu per flavour", "neutrinos", None, "only the total is measured (N_nu = 2.996)"),
    ("Weak isospin |T3|", "neutrinos", [0.5, 0.5, 0.5], "same for every generation"),
    ("Weak isospin |T3|", "charged leptons", [0.5, 0.5, 0.5], "same for every generation"),
]

lines = ["PART A: per-generation, mass-free quantities", ""]
for name, entity, v, note in per_generation:
    if v is None:
        lines.append(f"  {name:<36} {entity:<16} not measurable per generation ({note})")
    else:
        lines.append(f"  {name:<36} {entity:<16} D = {D(v):.2e}   ({note})")
lines.append("")
lines.append("  Every measured per-generation quantity gives D ~ 0 (lepton universality):")
lines.append("  the generations are identical once mass and mixing are removed. Projected")
lines.append("  this way, charged leptons are pure identity too, the same as neutrinos.")

# ---------------------------------------------------------------- Part B
properties = [
    # name, neutrino, charged lepton, quark (bound), unit/note
    ("electric charge |Q|", 0, 1, "2/3, 1/3", "e"),
    ("feels electromagnetism", 0, 1, 1, "yes = 1"),
    ("feels the weak force", 1, 1, 1, "yes = 1"),
    ("feels the strong force", 0, 0, 1, "yes = 1"),
    ("helicity states observed", 1, 2, 2, "per particle"),
    ("colour states", 1, 1, 3, ""),
    ("free / observable directly", "free, barely", "free", "confined", ""),
    ("forces felt (count)", 1, 2, 3, "EM, weak, strong"),
]
lines += ["", "PART B: entity-level properties", "",
          f"  {'property':<28} {'neutrinos':>12} {'charged lep.':>13} {'quarks':>10}   separates l from nu?"]
for name, nu, lep, q, _ in properties:
    sep = "YES" if str(nu) != str(lep) else "no"
    lines.append(f"  {name:<28} {str(nu):>12} {str(lep):>13} {str(q):>10}   {sep}")

text = "\n".join(lines)
(OUT / "summary.txt").write_text(text + "\n")
print(text)

# ---------------------------------------------------------------- Charts
NU, LEP, Q = "#1baf7a", "#2a78d6", "#eb6834"

# Chart 1: per-generation quantities on D (all at ~0).
fig, ax = plt.subplots(figsize=(10, 4.8))
ax.grid(axis="y", visible=False)
measured = [(n, e, v) for n, e, v, _ in per_generation if v is not None]
for i, (name, entity, v) in enumerate(measured):
    colour, marker = (LEP, "o") if entity == "charged leptons" else (NU, "^")
    ax.scatter(D(v), i, s=120, color=colour, marker=marker, ec=cs.SURFACE, lw=1.5, zorder=3)
    ax.annotate(f"D = {D(v):.1e}", (D(v), i), xytext=(12, -4), textcoords="offset points", fontsize=9)
ax.set_yticks(range(len(measured)), [f"{n}  ({e})" for n, e, _ in measured])
ax.set_xlim(0, 1)
ax.set_ylim(-0.7, len(measured) - 0.3)
ax.axvspan(0, 0.1, color=NU, alpha=0.12, lw=0)
ax.set_xlabel("D   (0 = identity, 1 = differentiation)")
ax.set_title("Per generation, no mass: all identity")
handles = [plt.Line2D([], [], color=LEP, marker="o", ls="", ms=9, label="charged leptons"),
           plt.Line2D([], [], color=NU, marker="^", ls="", ms=9, label="neutrinos")]
ax.legend(handles=handles, loc="lower right")
cs.footer(fig, "PDG 2024, HFLAV. Neutrino per-flavour values are mostly unmeasurable; those that exist are identical by construction.")
cs.save(fig, OUT / "1-per-generation.png")

# Chart 2: entity-level property map.
numeric = [(n, nu, lep, q) for n, nu, lep, q, _ in properties if all(isinstance(x, (int, float)) for x in (nu, lep, q))]
fig, ax = plt.subplots(figsize=(10, 5.6))
ax.grid(False)
grid = np.array([[nu, lep, q] for _, nu, lep, q in numeric], float)
norm = grid / grid.max(axis=1, keepdims=True)
cmap = plt.matplotlib.colors.LinearSegmentedColormap.from_list("blue", ["#f3f2ee", "#86b6ef", "#2a78d6"])
ax.imshow(norm, cmap=cmap, vmin=0, vmax=1, aspect="auto")
for r, (name, nu, lep, q) in enumerate(numeric):
    for c, val in enumerate((nu, lep, q)):
        ax.text(c, r, f"{val:g}", ha="center", va="center", fontsize=12, color=cs.INK)
    if nu != lep:
        ax.annotate("separates", (2.55, r), xytext=(0, 0), textcoords="offset points", va="center",
                    fontsize=10, color=LEP, fontweight="bold", annotation_clip=False)
ax.set_xticks([0, 1, 2], ["neutrinos", "charged leptons", "quarks (bound)"])
ax.set_yticks(range(len(numeric)), [n for n, *_ in numeric])
ax.set_title("Entity-level properties: what tells charged leptons from neutrinos")
cs.footer(fig, "Shading is relative within each row. 'separates' marks rows where charged leptons differ from neutrinos.")
cs.save(fig, OUT / "2-entity-properties.png")

# Chart 3: forces felt, the clean separator, as a 1-2-3 ladder.
fig, ax = plt.subplots(figsize=(10, 4.2))
ax.grid(axis="y", visible=False)
for x, name, colour, marker, forces in [(1, "neutrinos", NU, "^", "weak"),
                                         (2, "charged leptons", LEP, "o", "weak + EM"),
                                         (3, "quarks (bound)", Q, "s", "weak + EM + strong")]:
    ax.scatter(x, 0, s=260, color=colour, marker=marker, ec=cs.SURFACE, lw=2, zorder=3)
    ax.annotate(f"{name}\n{forces}", (x, 0), xytext=(0, 22), textcoords="offset points", ha="center", fontsize=11)
ax.plot([1, 3], [0, 0], color=cs.GRID, lw=2, zorder=1)
ax.set_xlim(0.5, 3.5)
ax.set_ylim(-0.6, 1)
ax.set_yticks([])
ax.set_xticks([1, 2, 3], ["1", "2", "3"])
ax.set_xlabel("number of forces felt (besides gravity)")
ax.set_title("A mass-free ladder: identity (1) -> frame (2) -> differentiation (3)")
cs.footer(fig, "Gravity omitted (felt by all). Higgs coupling omitted: it is the mass, which this analysis excludes.")
cs.save(fig, OUT / "3-forces-ladder.png")

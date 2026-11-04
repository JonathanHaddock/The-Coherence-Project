"""Interaction-strength vectors: the 1-2-3 force ladder made quantitative.

Each entity gets v = (EM, weak, strong) strengths per particle:
  EM     = Q^2 * alpha_em
  weak   = alpha_Z * (gL^2 + gR^2), Z couplings gL = T3 - Q s2w, gR = -Q s2w
           (variant: + alpha_W / 2 for the W, the same for every fermion)
  strong = alpha_s * C_F, C_F = 4/3 for quarks, 0 for leptons
Bound quarks average up and down types. The vector is then split by the same
identity/differentiation projectors as `origin project`, and its effective
number of interactions is the participation ratio PR = (sum v)^2 / sum v^2
(1 = one force dominates, 3 = all three equal).
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

OUT = Path(__file__).parent / "results"
S2W = 0.23122  # sin^2 theta_W (MS-bar, m_Z), PDG 2024

SCALES = {
    "m_Z (91 GeV)": dict(alpha=1 / 127.95, alpha_s=0.1180),
    "low energy (~2 GeV)": dict(alpha=1 / 133.5, alpha_s=0.30),
}
FERMIONS = {  # (Q, T3)
    "nu": (0.0, 0.5), "e": (-1.0, -0.5), "u": (2 / 3, 0.5), "d": (-1 / 3, -0.5),
}


def vector(name, alpha, alpha_s, with_w):
    q, t3 = FERMIONS[name]
    alpha_z = alpha / (S2W * (1 - S2W))
    gl, gr = t3 - q * S2W, -q * S2W
    weak = alpha_z * (gl ** 2 + gr ** 2) + (alpha / S2W / 2 if with_w else 0)
    strong = alpha_s * 4 / 3 if name in ("u", "d") else 0.0
    return np.array([q ** 2 * alpha, weak, strong])


def entities(alpha, alpha_s, with_w):
    v = lambda n: vector(n, alpha, alpha_s, with_w)  # noqa: E731
    return {"neutrinos": v("nu"), "charged leptons": v("e"), "quarks (bound)": (v("u") + v("d")) / 2}


def D(v):
    q = (v ** 2).sum() / v.sum() ** 2
    return 1.5 * (q - 1 / 3)


def PR(v):
    return v.sum() ** 2 / (v ** 2).sum()


rows, lines = [], ["INTERACTION-STRENGTH VECTORS (EM, weak, strong)", ""]
for scale, c in SCALES.items():
    for with_w in (False, True):
        tag = f"{scale}, weak = Z{' + W' if with_w else ''}"
        lines.append(tag)
        for ent, v in entities(c["alpha"], c["alpha_s"], with_w).items():
            rows.append((tag, ent, v))
            lines.append(f"  {ent:<16} v = ({v[0]:.5f}, {v[1]:.5f}, {v[2]:.5f})   D = {D(v):.3f}   forces effectively = {PR(v):.2f}")
        lines.append("")
text = "\n".join(lines)
(OUT / "strengths.txt").write_text(text + "\n")
print(text)

COL = {"neutrinos": ("#1baf7a", "^"), "charged leptons": ("#2a78d6", "o"), "quarks (bound)": ("#eb6834", "s")}
main_tag = "m_Z (91 GeV), weak = Z"

# Chart 1: the triangle with corners EM, weak, strong.
fig, ax = plt.subplots(figsize=(9.5, 9))
ax.set_aspect("equal")
ax.axis("off")
C = np.array([[0, 0], [1, 0], [0.5, np.sqrt(3) / 2]])  # EM, weak, strong
ax.fill(*C.T, color="#f3f2ee", zorder=0)
ax.plot(*np.vstack([C, C[:1]]).T, color=cs.INK_2, lw=1)
for (x, y), name, ha, dy in zip(C, ["electromagnetic", "weak", "strong"], ["right", "left", "center"], [-20, -20, 10]):
    ax.annotate(name, (x, y), xytext=(0, dy), textcoords="offset points", ha=ha, fontsize=12, fontweight="bold")
centre = C.mean(0)
ax.scatter(*centre, marker="+", s=120, color=cs.INK)
ax.annotate("all forces equal", centre, xytext=(0, -18), textcoords="offset points", ha="center", fontsize=9, color=cs.INK_2)
placed = {"neutrinos": (14, 10), "charged leptons": (0, 16), "quarks (bound)": (14, -6)}
for tag, ent, v in rows:
    colour, marker = COL[ent]
    xy = (v / v.sum()) @ C
    main = tag == main_tag
    ax.scatter(*xy, s=200 if main else 40, color=colour, marker=marker, ec=cs.SURFACE, lw=1.5,
               alpha=1 if main else 0.45, zorder=3 if main else 2)
    if main:
        ox, oy = placed[ent]
        ax.annotate(f"{ent}\nD = {D(v):.2f}, forces = {PR(v):.2f}", xy, xytext=(ox, oy), textcoords="offset points",
                    ha="left" if ox > 0 else "center", fontsize=10)
ax.set_title("Where each entity's interactions point", pad=30)
handles = [plt.Line2D([], [], color=c, marker=m, ls="", ms=10, label=e) for e, (c, m) in COL.items()]
handles.append(plt.Line2D([], [], color=cs.INK_2, marker="o", ls="", ms=5, alpha=0.45, label="same entity, other scale / weak definition"))
ax.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.5, 0.0), ncol=2)
cs.footer(fig, "v = (Q^2 alpha, Z coupling, alpha_s C_F) per particle at m_Z. Faint points: low-energy couplings and/or W included. PDG 2024.")
cs.save(fig, OUT / "4-interaction-triangle.png")

# Chart 2: effective number of forces, the quantitative ladder.
fig, ax = plt.subplots(figsize=(10, 5))
ents = list(COL)
tags = list(dict.fromkeys(t for t, _, _ in rows))
width = 0.8 / len(tags)
for k, tag in enumerate(tags):
    vals = [PR(v) for t, e, v in rows if t == tag]
    xs = np.arange(len(ents)) + (k - (len(tags) - 1) / 2) * width
    shade = ["#2a78d6", "#86b6ef", "#184f95", "#b7d3f6"][k]
    ax.bar(xs, vals, width * 0.92, color=shade, label=tag)
for i, ent in enumerate(ents):
    v = [v for t, e, v in rows if t == main_tag and e == ent][0]
    x_main = i + (tags.index(main_tag) - (len(tags) - 1) / 2) * width
    ax.annotate(f"{PR(v):.2f}", (x_main, PR(v)), xytext=(0, 4), textcoords="offset points", ha="center", fontsize=10, fontweight="bold")
ax.plot([-0.5, 2.5], [1, 1], color=cs.INK_2, lw=1, ls="--")
ax.set_xticks(range(len(ents)), ents)
ax.set_ylim(0, 3)
ax.set_ylabel("effective number of forces (1 to 3)")
ax.set_title("Counting gave 1, 2, 3. Weighting by strength does not.")
ax.legend(loc="upper right", fontsize=9)
cs.footer(fig, "Participation ratio (sum v)^2 / sum v^2: 1 = one force dominates, 3 = all equal. Bold labels: m_Z, Z only.")
cs.save(fig, OUT / "5-effective-forces.png")

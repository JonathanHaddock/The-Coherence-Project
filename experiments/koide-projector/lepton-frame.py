"""Chart: entities in the charged-lepton triangle.

The triangle's corners are the three charged leptons e, mu, tau: each
entity's generations 1, 2, 3 are mapped to them. An entity is a point at its
normalised sqrt-mass vector, so the centre is identity (all generations
equal) and a corner is one generation dominating.

Also measures each entity's projection onto the charged-lepton direction,
P_l v = (l . v) l, with l the unit sqrt-mass vector of (e, mu, tau):
cos^2 of the angle between them, 1 = fully aligned with the lepton frame.
"""
import sys
from math import sqrt
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

NEUTRINO, LEPTON, QUARK = "#1baf7a", "#2a78d6", "#eb6834"
e, mu, tau = 0.51099895, 105.6583755, 1776.93
u, c, t, d, s, b = 2.16, 1273, 172570, 4.70, 93.5, 4183
DM21, DM31 = 7.49e-5, 2.513e-3

lepton = np.sqrt([e, mu, tau])
quarks = np.sqrt([u + d, c + s, t + b])
lepton_unit = lepton / np.linalg.norm(lepton)


def neutrinos(m1):
    return np.sqrt([m1, sqrt(m1 ** 2 + DM21), sqrt(m1 ** 2 + DM31)])


def xy(v):
    corners = np.array([[0, 0], [1, 0], [0.5, sqrt(3) / 2]])  # e, mu, tau
    return (np.asarray(v) / np.sum(v)) @ corners


def d_of(v):
    x = np.asarray(v) / np.sum(v)
    return 1.5 * (np.sum(x ** 2) - 1 / 3)


def lepton_projection(v):
    v = np.asarray(v) / np.linalg.norm(v)
    return float(v @ lepton_unit) ** 2


fig, ax = plt.subplots(figsize=(9.5, 9))
ax.set_aspect("equal")
ax.axis("off")
tri = np.array([[0, 0], [1, 0], [0.5, sqrt(3) / 2]])
ax.fill(*tri.T, color="#f3f2ee", zorder=0)
ax.plot(*np.vstack([tri, tri[:1]]).T, color=cs.INK_2, lw=1)
for (x, y), name, ha, dy in zip(tri, ["e  (generation 1)", "mu  (generation 2)", "tau  (generation 3)"],
                                ["right", "left", "center"], [-18, -18, 10]):
    ax.annotate(name, (x, y), xytext=(0, dy), textcoords="offset points", ha=ha, fontsize=11, fontweight="bold",
                color=LEPTON)
centre = tri.mean(0)
ax.scatter(*centre, marker="+", s=120, color=cs.INK, zorder=4)
ax.annotate("identity", centre, xytext=(8, -14), textcoords="offset points", fontsize=9, color=cs.INK_2)

# Neutrino path as the unknown lightest mass grows from 0 to 0.1 eV.
m1s = np.r_[0, np.geomspace(1e-4, 0.1, 200)]
path = np.array([xy(neutrinos(m)) for m in m1s])
ax.plot(*path.T, color=NEUTRINO, lw=4, alpha=0.6, solid_capstyle="round", zorder=2)
for m, label in [(0.0, "m1 = 0"), (0.01, "m1 = 0.01 eV"), (0.1, "m1 = 0.1 eV")]:
    p = xy(neutrinos(m))
    ax.scatter(*p, s=60, color=NEUTRINO, marker="^", ec=cs.SURFACE, zorder=3)
    ax.annotate(label, p, xytext=(10, 0), textcoords="offset points", fontsize=9, va="center")

for name, v, colour, marker, off in [("charged leptons", lepton, LEPTON, "o", (12, 0)),
                                     ("quarks, bound", quarks, QUARK, "s", (-12, 0))]:
    p = xy(v)
    ax.scatter(*p, s=160, color=colour, marker=marker, ec=cs.SURFACE, lw=1.5, zorder=5)
    ax.annotate(f"{name}\nD={d_of(v):.2f}, lepton projection {lepton_projection(v):.3f}", p, xytext=off,
                textcoords="offset points", ha="left" if off[0] > 0 else "right", va="center", fontsize=9)

handles = [plt.Line2D([], [], color=NEUTRINO, lw=4, alpha=0.6, label="neutrinos (path as lightest mass grows)"),
           plt.Line2D([], [], color=LEPTON, marker="o", ls="", ms=9, label="charged leptons"),
           plt.Line2D([], [], color=QUARK, marker="s", ls="", ms=9, label="quarks, bound (u+d, c+s, t+b)")]
ax.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.5, 0.02), ncol=1)
ax.set_title("Entities in the charged-lepton frame", pad=30)
cs.footer(fig, "Point = sqrt-mass vector scaled to sum 1, generations mapped to e, mu, tau corners. Lepton projection = cos^2 to the (e,mu,tau) direction.")
fig.tight_layout(rect=(0, 0.03, 1, 1))
fig.savefig(Path(__file__).parent / "lepton-frame.png", dpi=cs.DPI)

print(f"{'entity':<26} {'D':>6} {'lepton projection':>18}")
print(f"{'charged leptons':<26} {d_of(lepton):6.3f} {lepton_projection(lepton):18.4f}")
print(f"{'quarks, bound':<26} {d_of(quarks):6.3f} {lepton_projection(quarks):18.4f}")
for m in (0, 0.001, 0.01, 0.1):
    v = neutrinos(m)
    print(f"{'neutrinos m1=' + str(m):<26} {d_of(v):6.3f} {lepton_projection(v):18.4f}")
print(f"{'identity (1,1,1)':<26} {0:6.3f} {lepton_projection(np.ones(3)):18.4f}")

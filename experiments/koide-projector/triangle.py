"""Chart: families as points in the identity-differentiation triangle.

Any 3-vector v scaled to sum 1 is a point in a triangle (ternary plot).
The centre (1/3,1/3,1/3) is the identity projector's direction (D = 0);
the corners are pure differentiation (D = 1). D = 1.5 * r^2, where r is the
distance from the centre in these coordinates, so rings of constant D are
circles around the centre.
"""
import sys
from math import sqrt
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

LEPTON, NEUTRINO, DOWN, UP = "#2a78d6", "#1baf7a", "#eda100", "#eb6834"

# PMNS |U| (rows e, mu, tau; columns nu1..3) and CKM |V| from `origin project`.
PMNS = np.array([[0.8233, 0.5480, 0.1480], [0.2968, 0.6051, 0.7388], [0.4838, 0.5776, 0.6575]])
CKM = np.array([[0.97435, 0.22501, 0.003732], [0.22487, 0.97349, 0.04183], [0.00858, 0.04111, 0.999118]])


def corner_xy(x):
    """Barycentric (x1, x2, x3), summing to 1, to 2D triangle coordinates."""
    corners = np.array([[0, 0], [1, 0], [0.5, sqrt(3) / 2]])
    return np.asarray(x) @ corners


def point(v):
    v = np.asarray(v, float)
    return corner_xy(v / v.sum())


def d_of(v):
    x = np.asarray(v, float) / np.sum(v)
    return 1.5 * (np.sum(x ** 2) - 1 / 3)


fig, ax = plt.subplots(figsize=(9.5, 9.5))
ax.set_aspect("equal")
ax.axis("off")

# Triangle and rings of constant D.
tri = corner_xy(np.eye(3))
ax.fill(*tri.T, color="#f3f2ee", zorder=0)
ax.plot(*np.vstack([tri, tri[:1]]).T, color=cs.INK_2, lw=1)
centre = corner_xy([1 / 3] * 3)
# Radius in 2D for a given D: barycentric r^2 = 2D/3, and the triangle map
# scales barycentric distance by 1/sqrt(2).
for d in (0.1, 0.25, 0.5, 0.75):
    r = sqrt(2 * d / 3) / sqrt(2)
    t = np.linspace(0, 2 * np.pi, 400)
    circle = centre + r * np.c_[np.cos(t), np.sin(t)]
    # Keep only the part inside the triangle.
    inside = np.array([np.all(np.linalg.solve(np.c_[tri.T, [0, 0]].T[:2].T if False else np.vstack([tri.T, np.ones(3)]), np.r_[p, 1]) >= -1e-9) for p in circle])
    circle[~inside] = np.nan
    style = dict(color=cs.INK_2, lw=1.2, ls="--") if d == 0.5 else dict(color=cs.GRID, lw=1)
    ax.plot(*circle.T, **style, zorder=1)
    label_at = centre + r * np.array([np.cos(np.radians(200)), np.sin(np.radians(200))])
    ax.annotate(f"D = {d}", label_at, fontsize=8, color=cs.INK_2, ha="right")
ax.scatter(*centre, marker="+", s=120, color=cs.INK, zorder=4)
ax.annotate("IDENTITY\n(1/3, 1/3, 1/3)", centre, xytext=(-10, -30), textcoords="offset points", fontsize=9, color=cs.INK, ha="right")
for (x, y), name, align in zip(tri, ["state 1", "state 2", "state 3"], [("right", "top"), ("left", "top"), ("center", "bottom")]):
    ax.annotate(name + "\npure differentiation", (x, y), ha=align[0], va=align[1], fontsize=9, color=cs.INK_2,
                xytext=(0, 6 if align[1] == "bottom" else -6), textcoords="offset points")

points = []
for i, n in enumerate(["e", "mu", "tau"]):
    points.append((f"{n} (PMNS row)", PMNS[i], LEPTON, "o"))
for i in range(3):
    points.append((f"nu{i + 1} (PMNS col)", PMNS[:, i], NEUTRINO, "^"))
for i, n in enumerate(["u", "c", "t"]):
    points.append((f"{n} (CKM row)", CKM[i], UP, "s"))
for i, n in enumerate(["d", "s", "b"]):
    points.append((f"{n} (CKM col)", CKM[:, i], DOWN, "D"))

offsets = {"e": (10, 4), "mu": (-10, 10), "tau": (-10, 10), "nu1": (-10, -4), "nu2": (10, -2), "nu3": (10, 2),
           "u": (8, 10), "c": (-8, 14), "t": (14, -4), "d": (8, -14), "s": (10, -12), "b": (-14, -8)}
for name, v, colour, marker in points:
    xy = point(v)
    ax.scatter(*xy, s=120, color=colour, marker=marker, ec=cs.SURFACE, lw=1.5, zorder=5)
    key = name.split(" ")[0]
    ox, oy = offsets[key]
    ax.annotate(f"{key}  D={d_of(v):.2f}", xy, xytext=(ox, oy), textcoords="offset points", fontsize=9,
                ha="left" if ox > 0 else "right", color=cs.INK)

handles = [plt.Line2D([], [], color=c, marker=m, ls="", ms=9, label=l) for l, c, m in
           [("charged leptons (PMNS rows)", LEPTON, "o"), ("neutrinos (PMNS columns)", NEUTRINO, "^"),
            ("up quarks (CKM rows)", UP, "s"), ("down quarks (CKM columns)", DOWN, "D")]]
ax.legend(handles=handles, loc="upper center", bbox_to_anchor=(0.5, 0.02), ncol=2)
ax.set_title("The identity-differentiation triangle (mixing amplitudes, no mass)", pad=40)
cs.footer(fig, "Each point is a row or column of |U| (PMNS) or |V| (CKM), scaled to sum 1. D = 1.5 r^2; dashed ring D = 1/2. PDG 2024.")
fig.tight_layout(rect=(0, 0.03, 1, 1))
fig.savefig(Path(__file__).parent / "triangle.png", dpi=cs.DPI)

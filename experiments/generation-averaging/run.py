"""Can averaging over the three generations explain the 1/3?

The identity projector P1 = J/3 has trace 1 in a 3-dimensional generation
space, so an evenly spread quantity puts 1/3 in the identity mode. A 1/3
charged-lepton projection is equivalent to weak^2 / EM^2 = 1/2, which equals
dim(identity) / dim(differentiation) = 1 / (N_gen - 1). Three tests:

1. Data: the measured weak^2/EM^2 for charged leptons, and for comparison
   the other charged fermions.
2. Mechanism: does the number of generations change sin^2(theta_W)? Use
   one-loop grand-unification running with N_gen = 1..5.
3. Random averaging: how sharp is a 1/3 that comes from averaging three
   random directions?
"""
import sys
from math import log, pi, sqrt
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

OUT = Path(__file__).parent
S2, S2_ERR = 0.23129, 0.00004
lines = []


def weak_over_em_sq(q, t3, s=S2):
    """(Z strength / EM strength)^2 for one fermion: ((gL^2+gR^2)/(s c^2 Q^2))^2."""
    gl, gr = t3 - q * s, -q * s
    return ((gl * gl + gr * gr) / (s * (1 - s) * q * q)) ** 2


# 1. Data.
lep = weak_over_em_sq(-1, -0.5)
lep_err = abs(weak_over_em_sq(-1, -0.5, S2 + S2_ERR) - lep)
lines += ["1. MEASURED weak^2 / EM^2 (MS-bar, m_Z)",
          f"  charged leptons  {lep:.4f} +- {lep_err:.4f}   (1/(N_gen - 1) = 0.5 for N_gen = 3)",
          f"  up quarks        {weak_over_em_sq(2/3, 0.5):.2f}",
          f"  down quarks      {weak_over_em_sq(-1/3, -0.5):.2f}",
          f"  pull of charged leptons from 1/2: {(lep - 0.5) / lep_err:+.1f} sigma", ""]

# 2. Mechanism: grand unification at one loop with N_gen generations.
# b_i = gauge + Higgs + (4/3) N_gen in GUT normalisation (U(1) scaled by 5/3).
ALPHA, ALPHA_S, MZ = 1 / 127.95, 0.1180, 91.1880
lines.append("2. GRAND-UNIFICATION PREDICTION of sin^2(theta_W) at m_Z vs N_gen")
predictions = []
for ng in range(1, 6):
    b1, b2, b3 = 1 / 10 + 4 / 3 * ng, -43 / 6 + 4 / 3 * ng, -11 + 4 / 3 * ng
    # Unify alpha_2 and alpha_3 to find the scale, then predict alpha_1 there.
    # 1/a_i(mu) = 1/a_i(MZ) - b_i/(2 pi) ln(mu/MZ)
    inv_a3 = 1 / ALPHA_S
    # s^2 = 3/8 - (5/8) alpha (b1 - b2)/(2 pi) L,  with L from a2 = a3 and a2 = alpha / s^2
    # Solve the two conditions numerically.
    def residual(s2):
        inv_a2 = s2 / ALPHA
        L = (inv_a2 - inv_a3) / ((b2 - b3) / (2 * pi))
        inv_a1 = (3 / 5) * (1 - s2) / ALPHA
        return (inv_a1 - b1 / (2 * pi) * L) - (inv_a2 - b2 / (2 * pi) * L)
    lo, hi = 0.15, 0.30
    for _ in range(100):
        mid = (lo + hi) / 2
        if residual(lo) * residual(mid) <= 0:
            hi = mid
        else:
            lo = mid
    pred = (lo + hi) / 2
    predictions.append(pred)
    lines.append(f"  N_gen = {ng}   b1 - b2 = {b1 - b2:.3f}   b2 - b3 = {b2 - b3:.3f}   sin^2(theta_W) = {pred:.5f}")
lines += ["  The number of generations cancels: complete generations shift every b_i",
          "  equally, so the predicted angle is the same for any N_gen. (The one-loop",
          "  non-supersymmetric value, about 0.207, also misses the measured 0.23129.)", ""]

# 3. Random averaging.
rng = np.random.default_rng(3)
n = 200_000
v = rng.normal(size=(n, 3))
v /= np.linalg.norm(v, axis=1, keepdims=True)
single = v[:, 0] ** 2  # share on one axis, one random direction
avg3 = (rng.normal(size=(n, 3, 3)) ** 2)
avg3 = (avg3[:, :, 0] / avg3.sum(axis=2)).mean(axis=1)  # averaged over three generations
lines += ["3. RANDOM AVERAGING (share of a random direction on one axis)",
          f"  one direction:              mean {single.mean():.4f}, spread (sd) {single.std():.4f}",
          f"  averaged over 3 directions: mean {avg3.mean():.4f}, spread (sd) {avg3.std():.4f}",
          f"  measured charged-lepton share: 0.3333, precise to about 0.0001",
          f"  -> random averaging gives 1/3 on average but scatters by about {avg3.std():.2f};",
          "     a 1/3 this sharp needs an exact symmetry, not averaging.", ""]

text = "\n".join(lines)
print(text)
(OUT / "summary.txt").write_text(text + "\n")

# Chart: two panels, one y-axis each.
fig, (a, b) = plt.subplots(1, 2, figsize=(12, 5))
ns = np.arange(2, 6)
a.plot(ns, 1 / (ns - 1), color=cs.INK_2, lw=1.5, ls="--", marker="o", ms=6, label="1 / (N_gen - 1)")
a.errorbar([3], [lep], yerr=[lep_err], fmt="o", ms=11, color="#2a78d6", mec=cs.SURFACE, capsize=5, label="charged leptons, measured", zorder=3)
a.annotate(f"measured {lep:.4f}", (3, lep), xytext=(14, 6), textcoords="offset points", fontsize=10, fontweight="bold")
a.set_xticks(ns)
a.set_xlabel("number of generations N_gen")
a.set_ylabel("weak^2 / EM^2 for charged leptons")
a.set_title("Data: the ratio sits on 1/(N_gen - 1)", fontsize=12)
a.legend(loc="upper right")
b.plot(range(1, 6), predictions, color="#eb6834", lw=2, marker="s", ms=8, label="grand-unification prediction")
b.axhline(S2, color="#2a78d6", lw=1.5, label=f"measured {S2}")
b.set_ylim(0.19, 0.24)
b.set_xticks(range(1, 6))
b.set_xlabel("number of generations N_gen")
b.set_ylabel("sin^2(theta_W) at m_Z")
b.set_title("Mechanism: generations cancel out", fontsize=12)
b.legend(loc="center right")
cs.footer(fig, "Left: MS-bar at m_Z, PDG 2024. Right: one-loop non-SUSY grand unification of alpha_2 and alpha_3; complete generations shift all running equally.")
cs.save(fig, OUT / "generation-averaging.png")

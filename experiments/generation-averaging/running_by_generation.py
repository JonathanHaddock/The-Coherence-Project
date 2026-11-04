"""How much each generation moves the weak angle between m_Z and low energy.

One-loop MS-bar running below m_W (W integrated out). Each active fermion f
(colour factor N, charge Q, isospin T3) contributes, per unit ln(mu),

    d alpha / d ln mu = (2 alpha^2 / 3 pi) N Q^2
    d s^2  / d ln mu  = (2 alpha   / 3 pi) N Q (Q s^2 - T3 / 2)

so each fermion pulls s^2 toward its own fixed point lambda = T3 / (2 Q).
Between m_Z and m_W the full SM slope (with W loops) is used. Fermions
decouple below their mass; light-quark thresholds are uncertain because
the hadronic region is non-perturbative, so they are varied as a range.
Quark loops include the leading QCD factor (1 + alpha_s/pi).
"""
import sys
from math import log, pi
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

OUT = Path(__file__).parent
MZ, MW = 91.1880, 80.37
S2_MZ, ALPHA_MZ = 0.23129, 1 / 127.95
S2_ZERO = 0.23873  # SM prediction at Q -> 0 (PDG 2024 Table 10.2)
SLOPE_ABOVE_MW = 0.00499  # d s^2 / d ln mu between m_W and m_Z (full SM, from which_scale.py)


def fermions(light_threshold):
    # name, generation, N, Q, T3, threshold (GeV), is_quark
    lt = light_threshold
    return [
        ("e", 1, 1, -1, -0.5, 0.000511, False), ("u", 1, 3, 2 / 3, 0.5, lt, True), ("d", 1, 3, -1 / 3, -0.5, lt, True),
        ("mu", 2, 1, -1, -0.5, 0.10566, False), ("c", 2, 3, 2 / 3, 0.5, 1.27, True), ("s", 2, 3, -1 / 3, -0.5, max(lt, 0.4), True),
        ("tau", 3, 1, -1, -0.5, 1.777, False), ("b", 3, 3, -1 / 3, -0.5, 4.18, True),
        # top (172.6 GeV) is above m_Z: inactive throughout.
    ]


def alpha_s(mu):
    # Rough one-loop strong coupling for the QCD factor, frozen below 1 GeV.
    mu = max(mu, 1.0)
    return 0.1180 / (1 + 0.1180 * (23 / 6) / (2 * pi) * 2 * log(mu / MZ)) if mu < MZ else 0.1180


def run(light_threshold, steps=200_000):
    s2 = S2_MZ - SLOPE_ABOVE_MW * log(MZ / MW)  # down to m_W with W loops
    above_mw = s2 - S2_MZ
    alpha = ALPHA_MZ
    fs = fermions(light_threshold)
    contrib = {f[0]: 0.0 for f in fs}
    lnmu = np.linspace(log(MW), log(1e-4), steps)  # down to 0.1 MeV: effectively Q -> 0
    d = lnmu[1] - lnmu[0]  # negative step
    for x in lnmu[:-1]:
        mu = np.exp(x)
        a_s = alpha_s(mu)
        dalpha = 0.0
        ds2 = 0.0
        for name, g, n, q, t3, m, quark in fs:
            if mu < m:
                continue
            k = n * (1 + a_s / pi if quark else 1)
            dalpha += 2 * alpha ** 2 / (3 * pi) * k * q * q * d
            step = 2 * alpha / (3 * pi) * k * q * (q * s2 - t3 / 2) * d
            contrib[name] += step
            ds2 += step
        alpha += dalpha
        s2 += ds2
    return s2, above_mw, contrib, fs


lines = []
results = {}
for lt in (0.2, 0.3, 0.5):
    s2_zero, above, contrib, fs = run(lt)
    results[lt] = (s2_zero, above, contrib, fs)
    lines.append(f"light-quark threshold {lt} GeV: s^2(0) = {s2_zero:.5f}   (SM prediction {S2_ZERO})")
s2_zero, above, contrib, fs = results[0.3]
total = s2_zero - S2_MZ

lines += ["", "FIXED POINT each fermion pulls toward, lambda = T3/(2Q):",
          "  charged lepton 0.250, up quark 0.375, down quark 0.750",
          "  one complete generation (sum N Q T3 / 2 sum N Q^2): 3/8 = 0.375, the grand-unification value", "",
          f"SHIFT m_Z -> 0 (light-quark threshold 0.3 GeV): {total:+.5f}   (SM: {S2_ZERO - S2_MZ:+.5f})",
          f"  m_Z -> m_W, W loops            {above:+.5f}"]
gen_tot = {1: 0.0, 2: 0.0, 3: 0.0}
lep_tot = {1: 0.0, 2: 0.0, 3: 0.0}
for name, g, *_ in fs:
    gen_tot[g] += contrib[name]
for name, g, n, q, t3, m, quark in fs:
    lines.append(f"  {name:<4} generation {g}          {contrib[name]:+.5f}")
    if not quark:
        lep_tot[g] += contrib[name]
lines.append("")
fermion_total = sum(gen_tot.values())
for g in (1, 2, 3):
    lines.append(f"  generation {g}: {gen_tot[g]:+.5f}  = {100 * gen_tot[g] / fermion_total:5.1f}% of the fermion shift"
                 f"   (its charged lepton: {100 * lep_tot[g] / gen_tot[g]:5.1f}% of the generation)")
lep_all = sum(lep_tot.values())
lines.append(f"  all charged leptons: {100 * lep_all / fermion_total:.1f}% of the fermion shift; quarks {100 * (1 - lep_all / fermion_total):.1f}%")
lines.append("")
spread = max(r[0] for r in results.values()) - min(r[0] for r in results.values())
lines.append(f"Uncertainty from light-quark thresholds: s^2(0) varies by {spread:.5f}.")

text = "\n".join(lines)
print(text)
(OUT / "running_by_generation.txt").write_text(text + "\n")

# Chart: stacked contributions by generation, charged lepton vs quarks.
fig, ax = plt.subplots(figsize=cs.FIGSIZE)
gens = [1, 2, 3]
lep_vals = [lep_tot[g] * 1e3 for g in gens]
q_vals = [(gen_tot[g] - lep_tot[g]) * 1e3 for g in gens]
ax.bar(gens, lep_vals, color="#2a78d6", width=0.55, label="charged lepton", edgecolor=cs.SURFACE, lw=2)
ax.bar(gens, q_vals, bottom=lep_vals, color="#eb6834", width=0.55, label="quarks", edgecolor=cs.SURFACE, lw=2)
for g in gens:
    ax.annotate(f"{gen_tot[g] * 1e3:.2f}  ({100 * gen_tot[g] / fermion_total:.0f}%)", (g, gen_tot[g] * 1e3),
                xytext=(0, 5), textcoords="offset points", ha="center", fontsize=10, fontweight="bold")
ax.set_xticks(gens, ["generation 1\n(e, u, d)", "generation 2\n(mu, c, s)", "generation 3\n(tau, b)"])
ax.set_ylabel("shift in sin^2(theta_W) from m_Z to zero energy (x 1/1000)")
ax.set_title("Each generation's share of the weak angle's low-energy shift")
ax.legend(loc="upper right")
cs.footer(fig, f"One-loop MS-bar, W integrated out below m_W; light-quark threshold 0.3 GeV (range 0.2-0.5 moves s^2(0) by {spread:.4f}). Top inactive below m_Z.")
cs.save(fig, OUT / "running-by-generation.png")

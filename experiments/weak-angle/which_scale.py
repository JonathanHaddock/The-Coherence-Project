"""At which energy is the charged-lepton projection exactly 1/3?

Runs sin^2(theta_W) (MS-bar) away from m_Z with one-loop Standard Model
running of the U(1) and SU(2) couplings (b' = 41/6, b2 = -19/6; thresholds
ignored, so this is approximate over this short range), then evaluates the
charged-lepton projection share at physically meaningful scales.
"""
import sys
from math import exp, log, pi
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402

MZ, S2_MZ, S2_ERR, ALPHA_MZ = 91.1880, 0.23129, 0.00004, 1 / 127.95
A0 = 1 / (ALPHA_MZ / (1 - S2_MZ))  # 1/alpha' (hypercharge)
B0 = 1 / (ALPHA_MZ / S2_MZ)  # 1/alpha_2
DA, DB = -(41 / 6) / (2 * pi), (19 / 6) / (2 * pi)


def s2(mu):
    t = log(mu / MZ)
    a, b = A0 + DA * t, B0 + DB * t
    return b / (a + b)


def share(s):
    r = (0.25 - s + 2 * s * s) / (s * (1 - s))
    lo, hi = min(r, 1), max(r, 1)
    return lo * lo / (lo * lo + hi * hi)


RULE = 0.231246
slope = (s2(MZ * 1.001) - s2(MZ)) / log(1.001)
mu_star = MZ * exp((RULE - S2_MZ) / slope)
mu_err = mu_star * S2_ERR / slope

scales = [("W mass", 80.37), ("Z mass", MZ), ("Higgs mass", 125.2), ("top mass", 172.6), ("Higgs field (v)", 246.2)]
lines = [f"d sin^2 / d ln(mu) near m_Z = {slope:.5f}",
         f"share = 1/3 at mu = {mu_star:.1f} +- {mu_err:.1f} GeV", "",
         f"{'scale':<18} {'mu (GeV)':>9} {'sin^2':>9} {'share':>8} {'pull from rule':>15}"]
for name, mu in scales:
    v = s2(mu)
    lines.append(f"{name:<18} {mu:>9.2f} {v:>9.5f} {share(v):>8.4f} {(RULE - v) / S2_ERR:>14.1f}s")
text = "\n".join(lines)
print(text)
(Path(__file__).parent / "which_scale.txt").write_text(text + "\n")

fig, ax = plt.subplots(figsize=cs.FIGSIZE)
ax.set_xscale("log")
mus = np.geomspace(60, 400, 300)
ax.plot(mus, [share(s2(m)) for m in mus], color="#2a78d6", lw=2.5)
ax.axhline(1 / 3, color="#eb6834", lw=1.5, ls="--")
ax.axvspan(mu_star - mu_err, mu_star + mu_err, color="#eb6834", alpha=0.15, lw=0)
ax.annotate(f"share = 1/3 at {mu_star:.1f} +- {mu_err:.1f} GeV", (mu_star, 1 / 3), xytext=(12, 30), textcoords="offset points",
            fontsize=10, fontweight="bold", arrowprops=dict(arrowstyle="-", color=cs.INK_2, lw=0.8))
for i, (name, mu) in enumerate(scales):
    ax.axvline(mu, color=cs.INK_2, lw=0.8, ls=":")
    ax.annotate(name, (mu, ax.get_ylim()[0]), xytext=(3, 8 + 14 * (i % 2)), textcoords="offset points", fontsize=9, color=cs.INK_2)
ax.set_xlabel("energy scale mu (GeV)")
ax.set_ylabel("charged-lepton projection share")
ax.set_title("Where the charged-lepton projection equals 1/3")
cs.footer(fig, "One-loop SM running of sin^2(theta_W) from its m_Z value (PDG 2024 0.23129 +- 0.00004); thresholds ignored, approximate.")
cs.save(fig, Path(__file__).parent / "which-scale.png")

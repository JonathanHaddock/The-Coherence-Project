"""Is the 1/3 a signal? A look-elsewhere test.

The charged lepton's division between EM and the weak force at m_Z can be
measured in many reasonable ways. For each, find the nearest "simple" number
and its pull given the measured precision of sin^2(theta_W). Then ask how
often, for a random angle, at least one measure lands on a simple number:
the chance that a match like the 1/3 appears by coincidence.
"""
import sys
from fractions import Fraction
from math import sqrt
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

S2, ERR = 0.23129, 0.00004


def measures(s):
    c = 1 - s
    gl, gr = -0.5 + s, s
    gv, ga = (gl + gr) / 2, (gl - gr) / 2
    z = (gl * gl + gr * gr) / (s * c)  # Z strength / EM strength, charged lepton
    zw = z + 1 / (2 * s)  # adding the W
    nu = 0.25 / (s * c)
    return {
        "weak/EM strength": z,
        "(weak/EM)^2": z * z,
        "weak share, linear": z / (1 + z),
        "weak share, squared (the 1/3)": z * z / (1 + z * z),
        "EM share, linear": 1 / (1 + z),
        "weak+W / EM": zw,
        "weak+W share, linear": zw / (1 + zw),
        "weak+W share, squared": zw * zw / (1 + zw * zw),
        "lepton / neutrino Z strength": z / nu,
        "vector / axial coupling": abs(gv / ga),
        "left-right asymmetry A_l": 2 * abs(gv * ga) / (gv * gv + ga * ga),
        "gR^2 / gL^2": gr * gr / (gl * gl),
        "sin^2": s,
        "cos^2": c,
        "tan^2": s / c,
        "EM / (EM + neutrino Z)": 1 / (1 + nu),
    }


# Simple targets: fractions p/q in (0, 2) with q <= 6, plus common roots.
targets = {str(Fraction(p, q)): p / q for q in range(1, 7) for p in range(1, 2 * q) if Fraction(p, q).denominator == q}
targets.update({"1/sqrt2": 1 / sqrt(2), "1/sqrt3": 1 / sqrt(3), "sqrt(2/3)": sqrt(2 / 3), "sqrt2/3": sqrt(2) / 3})
tvals = np.array(list(targets.values()))
tnames = list(targets)


def pulls(s, err=ERR):
    out = {}
    m0 = measures(s)
    m1 = measures(s + 1e-6)
    for k, v in m0.items():
        sigma = abs(m1[k] - v) / 1e-6 * err
        i = int(np.argmin(np.abs(tvals - v)))
        out[k] = (v, tnames[i], (v - tvals[i]) / sigma if sigma > 0 else np.inf)
    return out


lines = ["MEASURES OF THE CHARGED LEPTON'S DIVISION AT m_Z (sin^2 = 0.23129 +- 0.00004)", "",
         f"  {'measure':<34} {'value':>9} {'nearest simple':>15} {'pull':>9}"]
actual = pulls(S2)
hits = []
for k, (v, t, p) in actual.items():
    flag = "  <- hit" if abs(p) <= 2 else ""
    lines.append(f"  {k:<34} {v:>9.5f} {t:>15} {p:>8.1f}s{flag}")
    if abs(p) <= 2:
        hits.append(k)
lines.append("")
lines.append(f"  {len(hits)} of {len(actual)} measures within 2 sigma of a simple number: {', '.join(hits)}")

# Chance: random angle in a plausible range, same precision.
rng = np.random.default_rng(5)
trials = 20000
ss = rng.uniform(0.20, 0.26, trials)
any_hit = np.array([any(abs(p) <= 2 for _, _, p in pulls(s).values()) for s in ss])
count = np.array([sum(abs(p) <= 2 for _, _, p in pulls(s).values()) for s in ss[:4000]])
lines += ["", "CHANCE OF A COINCIDENCE",
          f"  random sin^2 in [0.20, 0.26], same precision, {trials} trials:",
          f"  at least one of {len(actual)} measures hits a simple number in {100 * any_hit.mean():.1f}% of trials",
          f"  -> p-value for 'some measure matches something' ~ {any_hit.mean():.2f}"]

# Structure: does the tree-level 1/sqrt2 relate to s = 1/4?
s14 = measures(0.25)
lines += ["", "STRUCTURE CHECK",
          f"  at sin^2 = 1/4 (vector coupling of leptons vanishes): weak/EM = {s14['weak/EM strength']:.5f}, "
          f"squared share = {s14['weak share, squared (the 1/3)']:.5f}",
          f"  lepton/neutrino Z strength at 1/4 = {s14['lepton / neutrino Z strength']:.5f} (exactly 1/2)",
          f"  measured: lepton/neutrino = {actual['lepton / neutrino Z strength'][0]:.5f}, pull from 1/2 = {actual['lepton / neutrino Z strength'][2]:.0f} sigma"]
text = "\n".join(lines)
print(text)
(Path(__file__).parent / "why_one_third.txt").write_text(text + "\n")

# Chart: pull of each measure from its nearest simple number.
fig, ax = plt.subplots(figsize=(10, 6.5))
names = list(actual)
ps = [actual[k][2] for k in names]
cols = ["#eb6834" if abs(p) <= 2 else "#86b6ef" for p in ps]
y = np.arange(len(names))
ax.barh(y, np.clip(ps, -30, 30), color=cols, height=0.65)
ax.axvspan(-2, 2, color="#1baf7a", alpha=0.15, lw=0)
for i, k in enumerate(names):
    v, t, p = actual[k]
    # All value labels in one column right of the plot, clear of the row names.
    ax.annotate(f"{v:.4f} vs {t} ({p:+.1f}s)" if abs(p) < 100 else f"{v:.4f} vs {t}", (33, i),
                va="center", ha="left", fontsize=8)
ax.set_yticks(y, names, fontsize=9)
ax.set_xlim(-32, 58)
ax.set_xticks([-30, -20, -10, 0, 10, 20, 30])
ax.set_xlabel("pull from nearest simple number (sigma, clipped at 30)")
ax.set_title("Which measures land on a simple number?")
cs.footer(fig, f"Green band: within 2 sigma. Random angles produce at least one such hit in {100 * any_hit.mean():.0f}% of cases.")
cs.save(fig, Path(__file__).parent / "why-one-third.png")

"""Measured weak mixing angle at different energies (MS-bar scheme).

Values: PDG 2024 Review "Electroweak Model and Constraints on New Physics"
(Sections 10.3 and 10.5, Table 10.2). Energy is the typical momentum
transfer of each measurement.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

RULE = 0.231246  # charged-lepton projection exactly 1/3 (origin weak)

measurements = [
    # name, energy (GeV), value, error, note
    ("Cs atomic parity violation", 0.0024, 0.2349, 0.0018, "APV, Boulder"),
    ("Qweak (e-p scattering)", 0.157, 0.2382, 0.0011, "Jefferson Lab"),
    ("E158 (e-e scattering)", 0.161, 0.2403, 0.0013, "SLAC"),
    ("Z pole, global fit", 91.1880, 0.23129, 0.00004, "LEP, SLD, Tevatron, LHC"),
]
sm_low = ("SM prediction, low-energy limit", 0.23873, 0.00005)

lines = [f"{'Measurement':<30} {'Energy (GeV)':>13} {'sin^2 theta_W':>15}",
         *[f"{n:<30} {e:>13g} {v:>9.5f} +- {err:.5f}" for n, e, v, err, _ in measurements],
         f"{sm_low[0]:<30} {'-> 0':>13} {sm_low[1]:>9.5f} +- {sm_low[2]:.5f}"]
print("\n".join(lines))
(Path(__file__).parent / "running.txt").write_text("\n".join(lines) + "\n")

fig, ax = plt.subplots(figsize=cs.FIGSIZE)
ax.set_xscale("log")
for name, e, v, err, note in measurements:
    ax.errorbar(e, v, yerr=err, fmt="o", ms=8, color="#2a78d6", ecolor="#2a78d6", capsize=4, mec=cs.SURFACE, mew=1.5, zorder=3)
offsets = {"Cs atomic parity violation": (10, -4), "Qweak (e-p scattering)": (-10, -16),
           "E158 (e-e scattering)": (10, 6), "Z pole, global fit": (-10, 10)}
for name, e, v, err, note in measurements:
    ox, oy = offsets[name]
    ax.annotate(f"{name}\n{v:.5f} +- {err:.5f}", (e, v), xytext=(ox, oy), textcoords="offset points",
                ha="left" if ox > 0 else "right", fontsize=9)
ax.axhline(sm_low[1], color=cs.INK_2, lw=1, ls=":")
ax.annotate("Standard Model, low-energy limit 0.23873", (2.0, sm_low[1]), xytext=(4, 4), textcoords="offset points", fontsize=9, color=cs.INK_2)
ax.axhline(RULE, color="#eb6834", lw=1.5, ls="--")
ax.annotate("1/3 rule 0.231246", (2e-3, RULE), xytext=(4, -12), textcoords="offset points", fontsize=9, color="#eb6834")
ax.set_xlim(1e-3, 1e3)
ax.set_ylim(0.226, 0.246)
ax.set_xlabel("energy (momentum transfer), GeV")
ax.set_ylabel("sin^2(theta_W), MS-bar")
ax.set_title("The weak mixing angle changes with energy")
cs.footer(fig, "PDG 2024. LHC and Tevatron values are measured at the Z mass, so they add to the Z-pole point. Rule line: 1/3 charged-lepton projection.")
cs.save(fig, Path(__file__).parent / "running.png")

"""Chart and uncertainty: Z -> ee vs Z -> mumu in the same detector.

Reads ORIGIN's export (origin/datasets/), so run `origin export` first.
Peak position uncertainty by bootstrap: resample the events, re-find the
peak (mean-shift, as ORIGIN does), repeat.
"""
import csv
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent.parent / "prime-oscillators"))
import chartstyle as cs  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402

DS = Path(__file__).parent.parent.parent / "origin" / "datasets"
masses = {"electron": [], "muon": []}
with open(DS / "dilepton-events.csv") as f:
    for row in csv.DictReader(f):
        if row["dataset"] in ("Zee", "Zmumu") and row["q1"] != row["q2"]:
            masses[row["lepton"]].append(float(row["mass"]))
masses = {k: np.sort(np.array(v)) for k, v in masses.items()}


def peak(m, nominal=91.19, rel=0.04):
    h = nominal * rel
    c = nominal
    for _ in range(50):
        sel = m[(m > c - h) & (m < c + h)]
        new = sel.mean()
        if abs(new - c) < 1e-6:
            break
        c = new
    return c


rng = np.random.default_rng(11)
res = {}
for k, m in masses.items():
    boots = [peak(np.sort(rng.choice(m, m.size))) for _ in range(300)]
    res[k] = (peak(m), np.std(boots), m.size)
diff = res["electron"][0] - res["muon"][0]
diff_err = np.hypot(res["electron"][1], res["muon"][1])
lines = [f"{k:<9} peak {p:.3f} +- {e:.3f} GeV  ({n} events)" for k, (p, e, n) in res.items()]
lines.append(f"difference e - mu: {diff:+.3f} +- {diff_err:.3f} GeV  ({diff / diff_err:+.1f} sigma, statistical only)")
text = "\n".join(lines)
print(text)
(Path(__file__).parent / "z_ee_mumu.txt").write_text(text + "\n")

fig, ax = plt.subplots(figsize=cs.FIGSIZE)
bins = np.arange(60, 120.5, 0.5)
for k, colour in [("muon", "#2a78d6"), ("electron", "#eb6834")]:
    h, edges = np.histogram(masses[k], bins=bins)
    ax.step(edges[:-1], h / h.sum(), where="post", color=colour, lw=2, label=f"Z -> {'ee' if k == 'electron' else 'mumu'} ({res[k][2]} events)")
    ax.axvline(res[k][0], color=colour, lw=1, ls="--")
ax.annotate(f"peaks: e {res['electron'][0]:.2f}, mu {res['muon'][0]:.2f} GeV\ndifference {diff:+.3f} +- {diff_err:.3f} GeV",
            (100, ax.get_ylim()[1] * 0.75), fontsize=10)
ax.set_xlim(60, 120)
ax.set_xlabel("dilepton invariant mass (GeV)")
ax.set_ylabel("fraction of events per 0.5 GeV")
ax.set_title("Z -> ee and Z -> mumu in the same detector (CMS 2011)")
ax.legend(loc="upper left")
cs.footer(fig, "Normalised to unit area. Electrons: calorimeter; muons: tracker + muon chambers, so widths differ by resolution. Errors statistical only.")
cs.save(fig, Path(__file__).parent / "z-ee-vs-mumu.png")

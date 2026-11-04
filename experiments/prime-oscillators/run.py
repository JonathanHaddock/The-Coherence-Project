"""Prime Oscillator Experiment: do prime frequency ratios hold coherence better?

Model: harmonically coupled phase oscillators (model.py), where locking
depends on frequency ratios. Every set gets 1% static mistuning and phase
noise, so coherence must be maintained by the coupling.

Coherence is measured at each pair's OWN natural ratio, and only counts while
the oscillators keep running within 5% of their natural frequencies (see
CHART_RULES.md, rules 7 and 10).

Outputs in results/:
  1-coupling-sweep.png   coherence and frequency distortion vs coupling
  2-prime-pairs.png      locking of each prime pair at its own ratio
  summary.txt            the numbers behind the charts
Population charts (all integer sets, random sets) come from population.py.
"""

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

import chartstyle as cs
from model import M, distortion, locking_at, natural_ratios, simulate

OUT = Path(__file__).parent / "results"
OUT.mkdir(exist_ok=True)
RNG = np.random.default_rng(2026)

D = 0.01  # phase noise
MISTUNE = 0.01  # static frequency mistuning (fraction)
T = 100.0
RUNS = 6
KS = [0.0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.5, 0.7, 1.0]
CONDITIONS = f"Noise D={D}, mistuning {MISTUNE:.0%}, T={T:.0f}, {RUNS} runs per point, harmonics up to {M}."

PRIMES = [2, 3, 5, 7, 11]
SETS = {
    "primes": PRIMES,
    "primes+0.5": [p + 0.5 for p in PRIMES],
    "primes_x1.1": [p * 1.1 for p in PRIMES],
    "harmonic": [1, 2, 3, 4, 5],
    "composites": [4, 6, 8, 9, 10],
}


def measure(freq_sets, K, runs=1):
    """Per-run natural-ratio coherence (pair mean), per-pair locking, distortion."""
    base = np.repeat(np.asarray(freq_sets, float), runs, axis=0)
    om = base * (1 + MISTUNE * RNG.standard_normal(base.shape))
    samples, observed = simulate(om, K, D, T=T, rng=RNG)
    # Ratios come from the nominal set, so mistuning cannot change the target.
    plv = locking_at(samples, natural_ratios(base))
    return plv.mean(1), plv, distortion(observed, om)


def coupling_sweep(lines):
    randoms = np.sort(RNG.uniform(2, 13, size=(RUNS, 5)), axis=1)
    stats = {name: {"mean": [], "sd": [], "dist": []} for name in [*SETS, "random"]}
    for K in KS:
        coh, _, dist = measure(list(SETS.values()), K, RUNS)
        for n, name in enumerate(SETS):
            c = coh[n * RUNS:(n + 1) * RUNS]
            stats[name]["mean"].append(c.mean())
            stats[name]["sd"].append(c.std())
            stats[name]["dist"].append(dist[n * RUNS:(n + 1) * RUNS].mean())
        rc, _, rd = measure(randoms, K)
        stats["random"]["mean"].append(rc.mean())
        stats["random"]["sd"].append(rc.std())
        stats["random"]["dist"].append(rd.mean())
        print(f"  K={K}", flush=True)

    baseline = np.mean([s["mean"][0] for s in stats.values()])
    fig, (top, bottom) = plt.subplots(2, 1, figsize=(10, 9), sharex=True, gridspec_kw={"height_ratios": [3, 2]})
    for name, s in stats.items():
        style = cs.ENTITIES[name]
        mean, sd, dist = map(np.array, (s["mean"], s["sd"], s["dist"]))
        valid = dist <= cs.DISTORTION_MAX
        lw = 2.5 if name == "primes" else 1.8
        top.plot(KS, mean, color=style["color"], lw=lw, alpha=0.35)
        top.plot(np.where(valid, KS, np.nan), np.where(valid, mean, np.nan), color=style["color"], lw=lw,
                 marker=style["marker"], ms=8, mec=cs.SURFACE, mew=1.5, label=style["label"])
        top.scatter(np.array(KS)[~valid], mean[~valid], color=cs.INVALID, marker=style["marker"], s=50, zorder=3)
        top.fill_between(KS, mean - sd, mean + sd, color=style["color"], alpha=0.08, lw=0)
        bottom.plot(KS, 100 * dist, color=style["color"], lw=lw, marker=style["marker"], ms=7, mec=cs.SURFACE)
    top.scatter([], [], color=cs.INVALID, marker="o", label="invalid: frequencies shifted > 5%")
    cs.k_axis(top)
    cs.coherence_axis(top, baseline)
    top.set_title("Coherence vs coupling (valid regime coloured)")
    top.legend(loc="upper left")
    bottom.axhline(100 * cs.DISTORTION_MAX, color=cs.INK_2, lw=1, ls="--")
    bottom.annotate("5% validity limit", (0, 100 * cs.DISTORTION_MAX), xytext=(4, 4), textcoords="offset points",
                    fontsize=9, color=cs.INK_2)
    bottom.set_ylim(0, 100)
    bottom.set_ylabel("frequency shift from natural (%)")
    cs.k_axis(bottom)
    bottom.set_title("Frequency distortion (100% = oscillators stopped)", fontsize=12)
    cs.footer(fig, CONDITIONS + " Bands: +/- 1 sd. Random reals: one run each of 6 sets.")
    cs.save(fig, OUT / "1-coupling-sweep.png")

    lines.append("1. COUPLING SWEEP  K = " + " ".join(f"{k:>5}" for k in KS))
    for name, s in stats.items():
        lines.append(f"  {name:<12} coherence " + " ".join(f"{v:5.2f}" for v in s["mean"]))
        lines.append(f"  {'':<12} distort % " + " ".join(f"{100 * v:5.1f}" for v in s["dist"]))
    lines.append(f"  no-coupling baseline: {baseline:.3f}")

    # Strongest valid coupling for primes, used for the pair chart. A 20%
    # margin keeps it valid when re-run with fresh noise.
    p = stats["primes"]
    valid_ks = [k for k, d in zip(KS, p["dist"]) if d <= 0.8 * cs.DISTORTION_MAX]
    return max(valid_ks), baseline


def prime_pairs(K, baseline, lines):
    _, plv, dist = measure([PRIMES], K, RUNS)
    mean = plv.mean(0)
    n = len(PRIMES)
    grid = np.full((n, n), np.nan)
    pairs = [(i, j) for i in range(n) for j in range(i + 1, n)]
    for k, (i, j) in enumerate(pairs):
        grid[j, i] = mean[k]

    fig, ax = plt.subplots(figsize=(7.5, 6.5))
    ax.grid(False)
    cmap = plt.matplotlib.colors.LinearSegmentedColormap.from_list("blue", ["#cde2fb", "#3987e5", "#0d366b"])
    im = ax.imshow(grid, cmap=cmap, vmin=0, vmax=1)
    for k, (i, j) in enumerate(pairs):
        ax.text(i, j, f"{mean[k]:.2f}\n{PRIMES[j]}:{PRIMES[i]}", ha="center", va="center", fontsize=10,
                color="#ffffff" if mean[k] > 0.55 else cs.INK)
    ax.set_xticks(range(n), PRIMES)
    ax.set_yticks(range(n), PRIMES)
    ax.set_xlabel("oscillator frequency")
    ax.set_ylabel("oscillator frequency")
    ax.set_title(f"Prime pairs: locking at their own ratio, K = {K}")
    cb = fig.colorbar(im, ax=ax, fraction=0.046)
    cb.set_label(cs.COHERENCE_LABEL, color=cs.INK_2)
    cb.outline.set_visible(False)
    cs.footer(fig, f"{RUNS} runs. Frequency shift {100 * dist.mean():.1f}%. Baseline {baseline:.2f}.")
    cs.save(fig, OUT / "2-prime-pairs.png")

    lines.append(f"\n2. PRIME PAIRS at K={K} (largest valid coupling), distortion {100 * dist.mean():.1f}%")
    for k, (i, j) in enumerate(pairs):
        lines.append(f"  {PRIMES[j]:>2}:{PRIMES[i]:<2} locking {mean[k]:.2f}")


if __name__ == "__main__":
    lines = [f"Prime Oscillator Experiment. {CONDITIONS}\n"]
    print("coupling sweep", flush=True)
    k_valid, baseline = coupling_sweep(lines)
    print("prime pairs", flush=True)
    prime_pairs(k_valid, baseline, lines)
    (OUT / "summary.txt").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))

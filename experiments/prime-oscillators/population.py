"""Population test: is the prime set special among all comparable sets?

For every 5-set of integers 2..13 (792 sets) and 200 random real-valued sets,
measures coherence at each pair's natural ratio for couplings in the valid
regime, and keeps each set's best valid coherence (frequency shift <= 5%).

Outputs in results/:
  3-all-integer-sets.png  best valid coherence vs ratio simplicity
  4-random-reals.png      primes vs random real-valued sets
  population.txt          the numbers behind them
"""

from itertools import combinations
from math import gcd
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np

import chartstyle as cs
from run import CONDITIONS, PRIMES, measure

OUT = Path(__file__).parent / "results"
KS = [0.1, 0.2, 0.3]  # inside the valid regime for most sets (see chart 1)


def ratio_complexity(freqs):
    """Mean p+q of each pair's reduced ratio: 2:1 -> 3, 11:7 -> 18."""
    vals = []
    for a, b in combinations(freqs, 2):
        g = gcd(int(a), int(b))
        vals.append(a // g + b // g)
    return np.mean(vals)


def best_valid(freq_sets):
    best = np.zeros(len(freq_sets))
    for K in KS:
        coh, _, dist = measure(freq_sets, K)
        ok = dist <= cs.DISTORTION_MAX
        best = np.where(ok & (coh > best), coh, best)
        print(f"  K={K}", flush=True)
    return best


if __name__ == "__main__":
    ints = list(combinations(range(2, 14), 5))
    rng = np.random.default_rng(11)
    reals = np.sort(rng.uniform(2, 13, size=(200, 5)), axis=1)
    reps = 10
    batch = [list(s) for s in ints] + reals.tolist() + [PRIMES] * reps
    best = best_valid(batch)
    bi, br, bp = best[:len(ints)], best[len(ints):len(ints) + len(reals)], best[-reps:]
    prime_score = bp.mean()
    cx = np.array([ratio_complexity(s) for s in ints])
    r = np.corrcoef(cx, bi)[0, 1]
    pct_int = 100 * np.mean(bi < prime_score)
    pct_real = 100 * np.mean(br < prime_score)
    order = np.argsort(-bi)

    fig, ax = plt.subplots(figsize=cs.FIGSIZE)
    ax.scatter(cx, bi, s=14, color=cs.POPULATION, alpha=0.8, lw=0, label=f"Every 5-set of integers 2..13 ({len(ints)})")
    pi = ints.index(tuple(PRIMES))
    style = cs.ENTITIES["primes"]
    ax.scatter([cx[pi]], [prime_score], s=150, color=style["color"], marker=style["marker"], ec=cs.SURFACE, lw=2,
               zorder=3, label=f"{style['label']} (mean of {reps})")
    ax.annotate(f"Primes beat {pct_int:.0f}% of integer sets", (cx[pi], prime_score), xytext=(12, 10),
                textcoords="offset points", fontsize=11, fontweight="bold")
    top = order[0]
    ax.annotate(f"Best: {','.join(map(str, ints[top]))}", (cx[top], bi[top]), xytext=(10, -4),
                textcoords="offset points", fontsize=10)
    cs.coherence_axis(ax)
    ax.set_xlabel("ratio complexity (mean p+q of each pair's reduced ratio; lower = simpler)")
    ax.set_title("Simpler ratios hold coherence better; primes are not special")
    ax.legend(loc="upper right")
    cs.footer(fig, f"Best valid coherence over K = {KS}. {CONDITIONS.split(' 6 runs')[0]} r = {r:.2f}.")
    cs.save(fig, OUT / "3-all-integer-sets.png")

    fig, ax = plt.subplots(figsize=cs.FIGSIZE)
    ax.hist(br, bins=np.linspace(0, 1, 41), color=cs.POPULATION, ec=cs.SURFACE, lw=2, label=f"{len(reals)} random real-valued sets, 2..13")
    ax.axvline(prime_score, color=style["color"], lw=2.5, label=f"{style['label']} (mean of {reps})")
    ax.annotate(f"Primes beat {pct_real:.0f}%", (prime_score, ax.get_ylim()[1] * 0.8), xytext=(8, 0),
                textcoords="offset points", fontsize=11, fontweight="bold")
    ax.set_xlim(0, 1)  # rule 1: coherence axis fixed 0-1
    ax.set_xlabel(cs.COHERENCE_LABEL)
    ax.set_ylabel("number of sets")
    ax.set_title("Primes vs random frequencies")
    ax.legend(loc="upper right")
    cs.footer(fig, f"Best valid coherence over K = {KS}. {CONDITIONS.split(' 6 runs')[0]}")
    cs.save(fig, OUT / "4-random-reals.png")

    lines = [
        f"POPULATION TEST. Best valid coherence over K={KS}.",
        f"primes: {prime_score:.3f} (sd {bp.std():.3f} over {reps} runs)",
        f"integer sets: mean {bi.mean():.3f}; primes beat {pct_int:.1f}%",
        f"correlation with ratio complexity: r = {r:.3f}",
        "top 5: " + "; ".join(f"{','.join(map(str, ints[i]))} ({bi[i]:.2f})" for i in order[:5]),
        f"random reals: mean {br.mean():.3f}; primes beat {pct_real:.1f}%",
    ]
    (OUT / "population.txt").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))

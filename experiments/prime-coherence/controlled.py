"""Controlled test of the Prime Quantum Coherence hypothesis.

Hypothesis (from "Prime Quantum Coherence Experiment"): prime frequency
networks (2:3:5:7:11) preserve coherence better than arbitrary ones.

The original script compares the prime set against ONE hand-picked random
set. This script keeps the same physics (5-node chain, H_ii = f_i, nearest-
neighbour coupling 0.2, start on node 0, same time grid) and adds controls:

  1. 2000 random frequency sets from the same range -> where does prime rank?
  2. Shifted primes (every f + 0.5): same gaps, no longer primes.
  3. Scaled primes (every f * 1.1): same ratios, not integers.
  4. Non-prime integer sets.
  5. Which property actually predicts the result: primality or gaps?

Metrics are the original ones, averaged over the last 100 steps:
  coherence = sum_ij |psi_i psi_j*|  (= (sum_i |psi_i|)^2, 1 when localised)
  entropy   = -sum_i p_i log p_i
Both measure how far the state has SPREAD from node 0, so they rise together.
"""

import numpy as np
from scipy.linalg import expm

TIME_STEPS = 500
DT = 0.05
COUPLING = 0.2
RNG = np.random.default_rng(seed=2026)

PRIMES = np.array([2, 3, 5, 7, 11], dtype=float)


def run_system(freqs, coupling=COUPLING):
    n = len(freqs)
    H = np.diag(freqs) + coupling * (np.eye(n, k=1) + np.eye(n, k=-1))
    U = expm(-1j * H * DT)  # constant H: compute once, not every step
    psi = np.zeros(n, dtype=complex)
    psi[0] = 1.0
    coh, ent = [], []
    for _ in range(TIME_STEPS):
        psi = U @ psi
        p = np.abs(psi) ** 2
        ent.append(-np.sum(p * np.log(p + 1e-12)))
        coh.append(np.sum(np.abs(psi)) ** 2)
    return np.mean(coh[-100:]), np.mean(ent[-100:])


def percentile(value, population):
    return 100.0 * np.mean(population < value)


def main():
    p_coh, p_ent = run_system(PRIMES)
    print("=" * 64)
    print("PRIME QUANTUM COHERENCE: CONTROLLED TEST")
    print("=" * 64)
    print(f"\nPrime 2,3,5,7,11        coherence {p_coh:.4f}   entropy {p_ent:.4f}")

    # 1. Original single comparison.
    r_coh, r_ent = run_system(np.array([2.7, 4.9, 8.2, 10.8, 13.3]))
    print(f"Original random set     coherence {r_coh:.4f}   entropy {r_ent:.4f}")

    # 2-4. Structural controls.
    print("\nSTRUCTURAL CONTROLS")
    controls = {
        "Primes + 0.5 (not prime)": PRIMES + 0.5,
        "Primes + 100 (not prime)": PRIMES + 100,
        "Primes x 1.1 (not integer)": PRIMES * 1.1,
        "Integers 2,3,4,5,6": np.array([2, 3, 4, 5, 6.0]),
        "Integers 4,6,8,9,10": np.array([4, 6, 8, 9, 10.0]),
        "Integers 2,3,5,7,12": np.array([2, 3, 5, 7, 12.0]),
        "Same gaps as primes, reversed": np.cumsum([2, 4, 2, 2, 1.0]),
    }
    for name, f in controls.items():
        c, e = run_system(f)
        print(f"  {name:<30} coherence {c:.4f}   entropy {e:.4f}")

    # 1. Random population.
    n_random = 2000
    sets = np.sort(RNG.uniform(2, 13.3, size=(n_random, 5)), axis=1)
    results = np.array([run_system(f) for f in sets])
    print(f"\nRANDOM POPULATION ({n_random} sets, uniform 2-13.3, sorted)")
    print(f"  coherence: mean {results[:, 0].mean():.4f}, prime is at percentile {percentile(p_coh, results[:, 0]):.1f}")
    print(f"  entropy:   mean {results[:, 1].mean():.4f}, prime is at percentile {percentile(p_ent, results[:, 1]):.1f}")
    both = np.mean((results[:, 0] >= p_coh) & (results[:, 1] <= p_ent))
    print(f"  random sets beating prime on BOTH criteria: {100 * both:.1f}%")

    # 5. What predicts the outcome? The first gap controls how much amplitude
    # leaves node 0 (coupling / detuning), so test that directly.
    first_gap = sets[:, 1] - sets[:, 0]
    weak_coupling = (COUPLING / first_gap) ** 2
    r_gap = np.corrcoef(np.log(weak_coupling), results[:, 1])[0, 1]
    print("\nWHAT DRIVES THE RESULT")
    print(f"  correlation of entropy with log(coupling/first_gap)^2: r = {r_gap:.3f}")
    print(f"  prime first gap = {PRIMES[1] - PRIMES[0]:.1f}; original random first gap = {4.9 - 2.7:.1f}")

    # Coupling sweep: does the prime advantage hold at other strengths?
    print("\nCOUPLING SWEEP (prime percentile among 300 random sets, entropy)")
    sub = sets[:300]
    for g in [0.05, 0.1, 0.2, 0.5, 1.0, 2.0]:
        pe = run_system(PRIMES, g)[1]
        re = np.array([run_system(f, g)[1] for f in sub])
        print(f"  coupling {g:<5} prime entropy {pe:.4f}   percentile {percentile(pe, re):5.1f}")

    return results


if __name__ == "__main__":
    main()

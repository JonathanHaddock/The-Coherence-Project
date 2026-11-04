"""Harmonically coupled phase oscillators (generalised Kuramoto model).

Each oscillator i has phase theta_i and natural frequency omega_i. Pairs
interact through every harmonic resonance p:q up to order M, derived from
the potential

    V = -K sum_{i<j} sum_{p,q<=M} a_p a_q cos(p theta_j - q theta_i),
    a_p = p ** -ALPHA,

so higher-order resonances are weaker, as in real nonlinear oscillators.
A term is slowly varying (and can lock) only when p omega_j ~ q omega_i,
so unlike the original 5-node chain this model depends on frequency RATIOS.

Because the weights factorise, the force on oscillator i is

    dtheta_i/dt = omega_i + K sum_q q a_q [cos(q theta_i) S_i - sin(q theta_i) C_i]
    S_i = sum_{j!=i} sum_p a_p sin(p theta_j),  C_i = (same with cos)

plus phase noise sqrt(2 D) dW. Cost is O(N M) per step, and a whole batch
of independent systems is integrated at once.
"""

from math import gcd

import numpy as np

M = 12  # highest harmonic; 11:7 needs harmonics 11 and 7
ALPHA = 1.5  # harmonic weight decay
HARMONICS = np.arange(1, M + 1)
WEIGHTS = HARMONICS ** -ALPHA


def simulate(omegas, K, D, T=200.0, dt=0.002, transient=0.25, sample_every=25, rng=None):
    """Integrate a batch of systems.

    omegas: (B, N) natural frequencies. Returns sampled phases (S, B, N) after
    the transient, and the mean observed frequencies (B, N).
    """
    rng = rng or np.random.default_rng()
    omegas = np.asarray(omegas, dtype=float)
    # K may be a scalar or one value per system in the batch.
    K = np.broadcast_to(np.asarray(K, dtype=float), (omegas.shape[0],))[:, None]
    B, N = omegas.shape
    theta = rng.uniform(0, 2 * np.pi, size=(B, N))
    steps = int(T / dt)
    start = int(steps * transient)
    noise = np.sqrt(2 * D * dt)
    samples = []
    theta_start = None

    def velocity(th):
        ph = th[..., None] * HARMONICS  # (B, N, M)
        s, c = np.sin(ph), np.cos(ph)
        s_tot = (s * WEIGHTS).sum(-1)  # (B, N)
        c_tot = (c * WEIGHTS).sum(-1)
        S = s_tot.sum(1, keepdims=True) - s_tot  # exclude self
        C = c_tot.sum(1, keepdims=True) - c_tot
        qa = HARMONICS * WEIGHTS
        force = ((c * qa).sum(-1) * S) - ((s * qa).sum(-1) * C)
        return omegas + K * force

    for step in range(steps):
        # Heun (stochastic RK2): accurate for the fast high-harmonic terms.
        dW = noise * rng.standard_normal(theta.shape)
        v1 = velocity(theta)
        guess = theta + v1 * dt + dW
        theta = theta + 0.5 * (v1 + velocity(guess)) * dt + dW
        if step == start:
            theta_start = theta.copy()
        if step >= start and (step - start) % sample_every == 0:
            samples.append(theta.copy())

    observed = (theta - theta_start) / ((steps - 1 - start) * dt)
    return np.array(samples), observed


COPRIME = [(p, q) for p in range(1, M + 1) for q in range(1, M + 1) if gcd(p, q) == 1]


def locking(samples):
    """Phase-locking value for every pair: max over coprime p:q <= M of
    |<exp(i (p theta_j - q theta_i))>|. 1 = perfectly locked, ~0 = drifting.
    Returns (B, pairs) array and the best (p, q) per pair."""
    S, B, N = samples.shape
    pairs = [(i, j) for i in range(N) for j in range(i + 1, N)]
    plv = np.zeros((B, len(pairs)))
    best = np.zeros((B, len(pairs), 2), dtype=int)
    for k, (i, j) in enumerate(pairs):
        for p, q in COPRIME:
            v = np.abs(np.exp(1j * (p * samples[:, :, j] - q * samples[:, :, i])).mean(0))
            better = v > plv[:, k]
            plv[better, k] = v[better]
            best[better, k] = (p, q)
    return plv, best


def natural_ratios(omegas):
    """For each system and pair (i<j), the coprime p:q <= M that best matches
    the natural frequencies (p omega_j ~ q omega_i). Shape (B, pairs, 2)."""
    omegas = np.asarray(omegas, float)
    B, N = omegas.shape
    pairs = [(i, j) for i in range(N) for j in range(i + 1, N)]
    cand = np.array(COPRIME, float)  # (C, 2) as (p, q)
    out = np.zeros((B, len(pairs), 2), dtype=int)
    for k, (i, j) in enumerate(pairs):
        target = omegas[:, j] / omegas[:, i]  # = q / p
        err = np.abs(cand[None, :, 1] / cand[None, :, 0] - target[:, None])
        out[:, k] = np.array(COPRIME)[np.argmin(err, axis=1)]
    return out


def locking_at(samples, ratios):
    """Phase-locking value of each pair at a GIVEN p:q (from natural_ratios),
    so a pair only scores if it holds its own ratio. Shape (B, pairs)."""
    S, B, N = samples.shape
    pairs = [(i, j) for i in range(N) for j in range(i + 1, N)]
    plv = np.zeros((B, len(pairs)))
    for k, (i, j) in enumerate(pairs):
        p = ratios[:, k, 0][None, :]
        q = ratios[:, k, 1][None, :]
        plv[:, k] = np.abs(np.exp(1j * (p * samples[:, :, j] - q * samples[:, :, i])).mean(0))
    return plv


def distortion(observed, omegas):
    """Mean relative shift of running frequency from natural frequency.
    Large values mean the coupling has dragged or stopped the oscillators
    (oscillator death), so locking there is not ratio-preserving coherence."""
    omegas = np.asarray(omegas, float)
    return np.mean(np.abs(observed - omegas) / omegas, axis=1)

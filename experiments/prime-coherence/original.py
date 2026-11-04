import numpy as np
import matplotlib.pyplot as plt
from scipy.linalg import expm

# ===================================================
# SETTINGS
# ===================================================

TIME_STEPS = 500

DT = 0.05

# Prime frequency architecture
prime_freqs = np.array([
    2,
    3,
    5,
    7,
    11
])

# Random architecture
random_freqs = np.array([
    2.7,
    4.9,
    8.2,
    10.8,
    13.3
])

# ===================================================
# BUILD HAMILTONIAN
# ===================================================

def build_hamiltonian(freqs):

    n = len(freqs)

    H = np.zeros((n,n))

    for i in range(n):

        H[i,i] = freqs[i]

    coupling = 0.2

    for i in range(n-1):

        H[i,i+1] = coupling
        H[i+1,i] = coupling

    return H

# ===================================================
# EVOLVE SYSTEM
# ===================================================

def run_system(freqs):

    H = build_hamiltonian(freqs)

    n = len(freqs)

    psi = np.zeros(n,dtype=complex)

    psi[0] = 1.0

    coherence_history = []

    entropy_history = []

    for step in range(TIME_STEPS):

        U = expm(-1j * H * DT)

        psi = U @ psi

        probabilities = np.abs(psi)**2

        entropy = -np.sum(
            probabilities *
            np.log(probabilities + 1e-12)
        )

        coherence = np.sum(
            np.abs(np.outer(psi, np.conj(psi)))
        )

        entropy_history.append(entropy)

        coherence_history.append(coherence)

    return (
        np.array(coherence_history),
        np.array(entropy_history)
    )

# ===================================================
# RUN
# ===================================================

prime_coh, prime_ent = run_system(
    prime_freqs
)

rand_coh, rand_ent = run_system(
    random_freqs
)

# ===================================================
# PLOTS
# ===================================================

plt.figure(figsize=(12,5))

plt.subplot(1,2,1)

plt.plot(
    prime_coh,
    label="Prime"
)

plt.plot(
    rand_coh,
    label="Random"
)

plt.title("Quantum Coherence")

plt.legend()

# -----------------------------------

plt.subplot(1,2,2)

plt.plot(
    prime_ent,
    label="Prime"
)

plt.plot(
    rand_ent,
    label="Random"
)

plt.title("Entropy")

plt.legend()

plt.tight_layout()

plt.show()

# ===================================================
# RESULTS
# ===================================================

print()

print("Prime coherence:",
      np.mean(prime_coh[-100:]))

print("Random coherence:",
      np.mean(rand_coh[-100:]))

print()

print("Prime entropy:",
      np.mean(prime_ent[-100:]))

print("Random entropy:",
      np.mean(rand_ent[-100:]))

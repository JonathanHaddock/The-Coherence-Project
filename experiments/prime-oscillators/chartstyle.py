"""Shared chart rules for every experiment chart. See CHART_RULES.md."""

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

# Surfaces and ink (light mode).
SURFACE, INK, INK_2, GRID = "#fcfcfb", "#1f1f1e", "#6b6a64", "#e6e5e0"
POPULATION = "#86b6ef"  # background distributions (random / all-sets populations)
INVALID = "#c3c2b7"  # results outside the valid regime

# Rule 3: each frequency set keeps one colour and marker on every chart.
# Validated categorical palette, assigned in fixed order.
ENTITIES = {
    "primes": dict(label="Primes 2,3,5,7,11", color="#2a78d6", marker="o"),
    "primes+0.5": dict(label="Primes + 0.5 (same gaps)", color="#eb6834", marker="s"),
    "primes_x1.1": dict(label="Primes x 1.1 (same ratios)", color="#1baf7a", marker="^"),
    "harmonic": dict(label="Harmonic 1,2,3,4,5", color="#eda100", marker="D"),
    "composites": dict(label="Composites 4,6,8,9,10", color="#e87ba4", marker="v"),
    "random": dict(label="Random reals", color="#008300", marker="P"),
}

# Rule 1 and 2: fixed axes.
COHERENCE_LIM = (0, 1.0)
COHERENCE_LABEL = "coherence at natural ratio (0 drifting, 1 locked)"
K_LIM = (0, 1.0)
K_LABEL = "coupling strength K"
DISTORTION_MAX = 0.05  # Rule 7: valid only if frequencies stay within 5%

plt.rcParams.update({
    "figure.facecolor": SURFACE, "axes.facecolor": SURFACE, "savefig.facecolor": SURFACE,
    "axes.edgecolor": GRID, "axes.labelcolor": INK_2, "xtick.color": INK_2, "ytick.color": INK_2,
    "text.color": INK, "axes.grid": True, "grid.color": GRID, "grid.linewidth": 0.8,
    "axes.spines.top": False, "axes.spines.right": False, "font.size": 11,
    "axes.titlesize": 14, "axes.titleweight": "bold", "axes.titlelocation": "left",
    "legend.frameon": False, "legend.fontsize": 10,
})

FIGSIZE = (10, 6)
DPI = 110


def coherence_axis(ax, baseline=None):
    """Rule 1 and 8: coherence always 0-1, with the no-coupling baseline drawn."""
    ax.set_ylim(*COHERENCE_LIM)
    ax.set_ylabel(COHERENCE_LABEL)
    if baseline is not None:
        ax.axhline(baseline, color=INK_2, lw=1, ls="--")
        ax.annotate("no-coupling baseline", (ax.get_xlim()[0], baseline), xytext=(4, 4),
                    textcoords="offset points", fontsize=9, color=INK_2)


def k_axis(ax):
    ax.set_xlim(*K_LIM)
    ax.set_xlabel(K_LABEL)


def footer(fig, conditions):
    """Rule 6: every chart states its run conditions."""
    fig.text(0.01, 0.01, conditions, fontsize=9, color=INK_2)


def save(fig, path):
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    fig.savefig(path, dpi=DPI)
    plt.close(fig)

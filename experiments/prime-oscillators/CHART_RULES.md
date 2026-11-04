# Chart rules

Every chart in this experiment follows these rules so charts can be compared
side by side. They are implemented in `chartstyle.py`; import it rather than
styling charts by hand.

1. **Coherence is always on a fixed 0 to 1 axis.** Never auto-scale it, or a
   0.02 difference looks like a large effect.
2. **Coupling K is always on a fixed 0 to 1 axis** when it is the x-axis.
3. **Each frequency set keeps one colour and one marker everywhere**
   (`ENTITIES`). Primes are always blue circles. Colour follows the set, never
   its rank, and is never reused for another set.
4. **Populations (all integer sets, random sets) are light blue in the
   background**, and the set under test is drawn on top in its own colour.
5. **One y-axis per chart.** Two measures (coherence, frequency distortion)
   go in two panels sharing the x-axis, never a second y-scale.
6. **Every chart's footer states its conditions:** noise D, mistuning, run
   time T, runs per point, and the metric.
7. **Valid regime only.** Coherence counts only if the oscillators keep
   running within 5% of their natural frequencies. Beyond that, strong
   coupling drags or stops them (oscillator death), which looks like perfect
   locking but is not. Points outside the valid regime are drawn in grey.
8. **Draw the no-coupling baseline** as a dashed line. The coherence measure
   is not exactly 0 for drifting oscillators, so the baseline is the real floor.
9. **Averages state n and show spread** (a band of plus or minus one standard
   deviation across runs).
10. **Measure each pair at its own natural ratio.** Coherence means a pair
    holds the ratio of its natural frequencies (for primes 2 and 7, 7:2), not
    whichever ratio happens to lock.
11. **Every chart can be read without colour:** a legend, distinct markers,
    and direct labels for the set under test.
12. **Output:** numbered PNG files in `results/`, 10 x 6 inches at 110 dpi,
    with the numbers behind them in `results/summary.txt`.
13. **Text never overlaps text or marks.** Every mark and label reserves a
    box; each new label tries positions around its point (right, left, above,
    below, diagonals), stepping outward until it finds free space, and gets a
    leader line if it lands away from its point. Labels carry a halo in the
    background colour so lines pass behind them. Implemented in ORIGIN as
    `origin/src/visualization/labels.zig` (and the same algorithm in the app);
    `zig build test` fails if any standard chart has a label clash.

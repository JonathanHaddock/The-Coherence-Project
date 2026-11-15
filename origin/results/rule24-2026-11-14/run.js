// Rule 24 runs: flashing, swaps, and where the core's pixels end up.
// node run.js display update motion(on|off) channels(on|off) seed ticks
const { Engine, N, RAD } = require("../../viewer/engine.js");
const [display, update, mo, ch, seed, ticks] = process.argv.slice(2);
const e = new Engine({ display, update, core: 8, motion: mo === "on", channels: ch === "on", seed: BigInt(seed) });
const T = +ticks, out = [];
for (let t = 0; t < T; t++) {
  const f = e.tickLattice();
  if ((t + 1) % 50) continue;
  let r = 0, k = 0, rAll = 0, far = 0;
  for (let i = 0; i < N; i++) { const h = e.home[i]; if (RAD[h] <= 8) { r += RAD[i]; k++; if (RAD[i] > 8) far++; } }
  out.push([display, update, mo, ch, seed, t + 1, (f / N).toFixed(4), e.swaps, (r / k).toFixed(3), (far / k).toFixed(4)].join("\t"));
}
console.log(out.join("\n"));

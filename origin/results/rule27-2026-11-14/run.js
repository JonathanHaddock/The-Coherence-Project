// Rule 27 runs (hearing conserves), on the one-pixel field (pixel-model.js).
// node run.js display update excite(on|off) em(on|off) sun(on|off) edge(open|closed) seed ticks
// Motion (24) on in every run, core 0. Sun and open edge are outside conditions (experiments/sun).
// energy = memory + carrier in the box (rule 27 conserves it except at the box edge).
const { Field } = require("../../viewer/pixel-model.js");
const [display, update, ex, em, sun, edge, seed, ticks] = process.argv.slice(2);
const f = new Field({ display, update, core: 0, motion: true, conserve: true, excite: ex === "on", em: em === "on", seed: BigInt(seed) });
if (sun === "on") { f.forced[f.kick] = 1; for (let q = 0; q < 6; q++) f.forced[f.nb[f.kick * 6 + q]] = 1; }
f.openEdge = edge === "open";
const out = [];
for (let t = 1; t <= +ticks; t++) {
  const c = f.tick();
  if (t % 100) continue;
  let mem = 0, car = 0; for (const p of f.px) { mem += p.memory; car += p.carrier; }
  out.push([display, update, ex, em, sun, edge, seed, t, (c / f.N).toFixed(5), f.swaps, (mem / f.N).toFixed(3), (car / f.N).toFixed(3)].join("\t"));
}
console.log(out.join("\n"));

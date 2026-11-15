// Does a sun, an open edge, or both keep the world going with EM on?
// node run.js sun(on|off) edge(open|closed) em(on|off) seed ticks
// Outside conditions only (no new rule):
//   sun  = the centre site and its 6 neighbours are forced to flash every tick.
//   edge = open: carrier (and phi) lost at the box edge each tick is fed back in, spread evenly
//          over every site on the box surface. closed = lost, as in rule 5.
// Always: one_cell, sync, core 0, motion (rule 24) on, default seed offset.
const { Field } = require("../../origin/viewer/pixel-model.js");
const [sun, edge, em, seed, ticks] = process.argv.slice(2);
const f = new Field({ display: "one_cell", update: "sync", core: 0, motion: true, em: em === "on", seed: BigInt(seed) });
if (sun === "on") { f.forced[f.kick] = 1; for (let q = 0; q < 6; q++) f.forced[f.nb[f.kick * 6 + q]] = 1; }
f.openEdge = edge === "open";
const out = [];
for (let t = 1; t <= +ticks; t++) {
  const c = f.tick();
  if (t % 100) continue;
  let car = 0; for (const p of f.px) car += p.carrier;
  out.push([sun, edge, em, seed, t, (c / f.N).toFixed(5), f.swaps, car.toFixed(1)].join("\t"));
}
console.log(out.join("\n"));

// Why do ready pixels stop flashing? After 100 ticks, classify every ready pixel.
const path = require("path"), { Engine, N } = require(path.join(__dirname, "../../viewer/engine.js"));
const e = new Engine({ mode: "lattice", display: "one_cell", update: "sync", five: true, colour: true, conserve: true, excite: true, motion: process.argv[2] === "motion", core: 0, seed: 20261110n });
for (let t = 0; t < 100; t++) e.tick();
const reasons = new Map(), add = k => reasons.set(k, (reasons.get(k) || 0) + 1);
let ready = 0, memTot = 0;
for (let i = 0; i < N; i++) { let m = 0; for (let k = 0; k < 5; k++) m += e.cs5[i * 5 + k]; memTot += m; if (m < 5) continue; ready++;
  const k = e.pick5(i), p = e.p5[i], nc = Engine.ncol(p), u = (p >> 3) & 1, d = (p >> 4) & 1;
  if (k < 0) { add("no cell with a positive surplus"); continue; }
  const pl = e.plan5(i);
  if (!pl) { add(k < 3 ? `wants a colour change but has ${nc} colour cells (needs 1 or 2)` : `wants u<->d but has u=${u}, d=${d}`); continue; }
  add(k < 3 ? "colour change possible, but no neighbour can take the opposite change" : "u<->d possible, but no neighbour can take the opposite change"); }
console.log(`after 100 ticks (${process.argv[2] === "motion" ? "motion on" : "no motion"}): ${ready} pixels ready (memory >= 5); memory per pixel ${(memTot / N).toFixed(2)}`);
for (const [k, v] of [...reasons.entries()].sort((a, b) => b[1] - a[1])) console.log(`  ${String(v).padStart(5)}  ${k}`);

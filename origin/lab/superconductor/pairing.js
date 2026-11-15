// Pairing signatures, coupling on vs the g = 0 control, at a set of temperatures.
// node pairing.js g T seed [ne steps lattice]
const { Lab2D } = require("./sim.js");
const { PairMeasures } = require("./measures.js");
const [g, T, seed, ne = 30, steps = 150000, lattice = "square"] = process.argv.slice(2);
const L = new Lab2D({ g: +g, T: +T, seed: +seed, ne: +ne, lattice });
const M = new PairMeasures(L);
for (let s = 0; s < +steps; s++) { L.step(); if (s >= 10000) M.tick(); }
const r = M.result();
let lam = 0; for (const v of L.coupling()) lam += v; lam /= L.ne;
console.log([lattice, g, T, seed, ne, lam.toFixed(4), ...r.wake.map(v => v.toFixed(4)), r.oppCos.toFixed(5), r.oppN].join("\t"));

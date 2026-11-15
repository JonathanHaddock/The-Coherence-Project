// Layer-1 runner: two (or more) electrons in the lattice; how often are they close, versus chance?
// node run.js key=value ...   (any DEFAULTS parameter from sim.js, plus steps=, burn=, every=)
// Prints one TSV row: parameters, then
//   near1_ratio / near2_ratio: share of time electron pairs are within 1 / 2 bond lengths,
//   divided by what random positions give (pi r^2 / area). 1 = chance; above 1 = they attract.
//   mean_r: mean pair distance; pair_lifetime: mean time a pair stays within 2 bonds once it gets there.
const { Lab2D, DEFAULTS } = require("./sim.js");
const a = Object.fromEntries(process.argv.slice(2).map(s => s.split("=")));
const params = {};
for (const k of Object.keys(DEFAULTS)) if (a[k] !== undefined) params[k] = typeof DEFAULTS[k] === "number" ? +a[k] : typeof DEFAULTS[k] === "boolean" ? a[k] === "true" : a[k];
const steps = +(a.steps || 200000), burn = +(a.burn || 20000), every = +(a.every || 10);
const L = new Lab2D(params);
let n = 0, near1 = 0, near2 = 0, sumr = 0, inPair = false, start = 0, lifetimes = [];
for (let s = 0; s < steps; s++) {
  L.step();
  if (s < burn || s % every) continue;
  const ds = L.pairDistances();
  for (const r of ds) { n++; sumr += r; if (r < 1) near1++; if (r < 2) near2++; }
  if (L.ne === 2) { const r = ds[0]; if (r < 2 && !inPair) { inPair = true; start = L.t; } else if (r >= 2 && inPair) { inPair = false; lifetimes.push(L.t - start); } }
}
const A = L.Lx * L.Ly, p = L.p;
const row = { lattice: p.lattice, M: p.M, k0: p.k0, k1: p.k1, g: p.g, sigma: p.sigma, U: p.U, ne: p.ne, vF: p.vF, T: p.T, vacancy: p.vacancy, seed: p.seed,
  near1_ratio: (near1 / n) / (Math.PI * 1 / A), near2_ratio: (near2 / n) / (Math.PI * 4 / A), mean_r: sumr / n,
  pair_lifetime: lifetimes.length ? lifetimes.reduce((x, y) => x + y, 0) / lifetimes.length : 0, pairings: lifetimes.length };
if (a.header === "1") console.log(Object.keys(row).join("\t"));
console.log(Object.values(row).map(v => typeof v === "number" && !Number.isInteger(v) ? v.toFixed(4) : v).join("\t"));

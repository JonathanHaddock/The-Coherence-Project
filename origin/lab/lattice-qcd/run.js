// Runner. node run.js Ns=8 Nt=8 beta=5.7 therm=300 meas=100 every=5 [loops=3] [header=1]
// Prints one TSV row: parameters, plaquette (mean, error), |Polyakov| and its mean phase share per Z3 sector,
// Wilson loops W(R,T) for R,T <= loops (time direction for T if Nt allows, else spatial), Creutz ratios.
// Errors are standard errors over measurements; measurements `every` sweeps apart are treated as independent
// (check this by changing `every`).
const { Lattice, DEFAULTS, creutz } = require("./su3.js");
const a = Object.fromEntries(process.argv.slice(2).map(s => s.split("=")));
const prm = {};
for (const k of Object.keys(DEFAULTS)) if (a[k] !== undefined) prm[k] = typeof DEFAULTS[k] === "number" ? +a[k] : a[k];
const therm = +(a.therm ?? 300), meas = +(a.meas ?? 100), every = +(a.every ?? 5), LMAX = +(a.loops ?? 3);
const L = new Lattice(prm), p = L.p;
const t0 = Date.now();
for (let s = 0; s < therm; s++) L.sweep();
const timeLike = p.Nt >= 2 * LMAX;
const keys = []; for (let r = 1; r <= LMAX; r++) for (let t = 1; t <= LMAX; t++) if (t <= r && t >= r - 1) keys.push([r, t]);
const acc = { plaq: [], poly: [], polyRe: [], polyIm: [] }; for (const [r, t] of keys) acc[`${r},${t}`] = [];
for (let m = 0; m < meas; m++) {
  for (let s = 0; s < every; s++) L.sweep();
  acc.plaq.push(L.plaquette());
  const [re, im] = L.polyakov(); acc.poly.push(Math.hypot(re, im)); acc.polyRe.push(re); acc.polyIm.push(im);
  for (const [r, t] of keys) acc[`${r},${t}`].push(timeLike ? L.wilson(r, t) : L.wilsonSpatial(r, t));
}
const mean = v => v.reduce((x, y) => x + y, 0) / v.length;
const err = v => { const m = mean(v); return Math.sqrt(v.reduce((s, x) => s + (x - m) ** 2, 0) / (v.length * (v.length - 1))); };
const W = {}; for (const [r, t] of keys) { W[`${r},${t}`] = mean(acc[`${r},${t}`]); W[`${t},${r}`] = W[`${r},${t}`]; }
const row = { Ns: p.Ns, Nt: p.Nt, beta: p.beta, start: p.start, seed: p.seed, therm, meas, every, acceptance: L.acceptance(),
  plaquette: mean(acc.plaq), plaquette_err: err(acc.plaq), polyakov_abs: mean(acc.poly), polyakov_abs_err: err(acc.poly),
  polyakov_re: mean(acc.polyRe), polyakov_im: mean(acc.polyIm), loops: timeLike ? "time" : "spatial" };
for (const [r, t] of keys) { row[`W${r}x${t}`] = W[`${r},${t}`]; row[`W${r}x${t}_err`] = err(acc[`${r},${t}`]); }
for (let r = 2; r <= LMAX; r++) row[`chi${r}`] = creutz(W, r);
row.seconds = (Date.now() - t0) / 1000;
if (a.header === "1") console.log(Object.keys(row).join("\t"));
console.log(Object.values(row).map(v => typeof v === "number" && !Number.isInteger(v) ? (Math.abs(v) < 1e-3 && v !== 0 ? v.toExponential(3) : v.toFixed(5)) : v).join("\t"));

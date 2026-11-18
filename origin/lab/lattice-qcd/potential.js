// Static quark-antiquark potential with smoothing.
// node potential.js Ns=12 Nt=12 beta=6.0 therm=400 meas=40 every=10 smear=20 alpha=0.5 Rmax=6 Tmax=6 [out=file.json]
// Each measurement: APE-smear the spatial links (time links untouched), measure time-like W(R,T).
// a V(R) = ln[W(R,T)/W(R,T+1)] for every T (it should level off as T grows), then a Cornell fit
// V(R) = V0 + sigma R - e/R at the largest T with a clean signal, and a second fit with e fixed at pi/12. Errors by jackknife over measurements.
const { Lattice, DEFAULTS, potential, cornellFit, luscherFit } = require("./su3.js");
const fs = require("fs");
const a = Object.fromEntries(process.argv.slice(2).map(s => s.split("=")));
const prm = {}; for (const k of Object.keys(DEFAULTS)) if (a[k] !== undefined) prm[k] = typeof DEFAULTS[k] === "number" ? +a[k] : a[k];
const therm = +(a.therm ?? 400), meas = +(a.meas ?? 40), every = +(a.every ?? 10), smear = +(a.smear ?? 20), alpha = +(a.alpha ?? 0.5);
const L = new Lattice(prm), p = L.p, Rmax = +(a.Rmax ?? Math.floor(p.Ns / 2)), Tmax = +(a.Tmax ?? Math.floor(p.Nt / 2)), Rmin = +(a.Rmin ?? 2);
const t0 = Date.now(), log = s => process.stderr.write(`[${((Date.now() - t0) / 1000).toFixed(0)}s] ${s}\n`);
for (let s = 0; s < therm; s++) { L.sweep(); if (s % 100 === 99) log(`therm ${s + 1}/${therm} plaq ${L.plaquette().toFixed(4)}`); }
const samples = [], plaqs = [];
for (let m = 0; m < meas; m++) {
  for (let s = 0; s < every; s++) L.sweep();
  plaqs.push(L.plaquette());
  samples.push(L.loops(Rmax, Tmax, 3, smear ? L.ape([0, 1, 2], alpha, smear) : L.U));
  log(`meas ${m + 1}/${meas}`);
}
const avg = list => { const o = {}; for (const k in list[0]) o[k] = list.reduce((s, w) => s + w[k], 0) / list.length; return o; };
const jack = f => { // value and jackknife error of f(average W)
  const n = samples.length, full = f(avg(samples)), vals = [];
  for (let i = 0; i < n; i++) vals.push(f(avg(samples.filter((_, j) => j !== i))));
  const m = vals.reduce((s, v) => s + v, 0) / n;
  return [full, Math.sqrt((n - 1) / n * vals.reduce((s, v) => s + (v - m) ** 2, 0))];
};
const W = avg(samples), table = {};
for (let T = 1; T < Tmax; T++) table[T] = Array.from({ length: Rmax }, (_, k) => jack(w => potential(w, Rmax, T)[k]));
// pick the largest T where every V(R) has relative error under 10%
let Tfit = 1; for (let T = 1; T < Tmax; T++) if (table[T].every(([v, e]) => isFinite(v) && e < 0.1 * Math.abs(v))) Tfit = T;
const fit = jack(w => cornellFit(potential(w, Rmax, Tfit), Rmin).sigma), fitFull = cornellFit(potential(W, Rmax, Tfit), Rmin);
const lfit = jack(w => luscherFit(potential(w, Rmax, Tfit), Rmin).sigma);
const res = { Ns: p.Ns, Nt: p.Nt, beta: p.beta, seed: p.seed, therm, meas, every, smear, alpha, Rmax, Tmax, Rmin,
  plaquette: plaqs.reduce((s, v) => s + v, 0) / plaqs.length, acceptance: L.acceptance(), W,
  V: Object.fromEntries(Object.entries(table).map(([T, arr]) => [T, arr.map(([v, e]) => [+v.toFixed(5), +e.toFixed(5)])])),
  Tfit, fit: { V0: fitFull.V0, sigma: fit[0], sigma_err: fit[1], e: fitFull.e }, fit_luscher: { sigma: lfit[0], sigma_err: lfit[1], e: Math.PI / 12 }, seconds: (Date.now() - t0) / 1000 };
const out = JSON.stringify(res, null, 1);
if (a.out) fs.writeFileSync(a.out, out + "\n");
console.log(`beta ${p.beta}  ${p.Ns}^3x${p.Nt}  smear ${smear}  plaquette ${res.plaquette.toFixed(5)}`);
for (const T in res.V) console.log(`T ${T}->${+T + 1}  V(R) = ${res.V[T].map(([v, e]) => `${v.toFixed(3)}(${Math.round(e * 1000)})`).join("  ")}`);
console.log(`Cornell fit at T ${Tfit}, R >= ${Rmin}: sigma a^2 = ${fit[0].toFixed(4)} +- ${fit[1].toFixed(4)}, e = ${fitFull.e.toFixed(3)}, V0 = ${fitFull.V0.toFixed(3)}  (${res.seconds.toFixed(0)} s)`);
console.log(`Luscher fit (e fixed at pi/12):         sigma a^2 = ${lfit[0].toFixed(4)} +- ${lfit[1].toFixed(4)}`);

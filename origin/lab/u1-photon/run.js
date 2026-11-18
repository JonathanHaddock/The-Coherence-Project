// Experiments. node run.js scan   -> plaquette vs beta, cold and hot starts (the phase transition)
//              node run.js pot beta=1.1 L=10 -> static potential, Cornell fit (sigma = string tension, e = Coulomb strength)
const { U1 } = require("./u1.js");
const [mode, ...rest] = process.argv.slice(2), a = Object.fromEntries(rest.map(s => s.split("=")));
const mean = v => v.reduce((x, y) => x + y, 0) / v.length;
const blockErr = v => { const B = 10, bs = Math.floor(v.length / B), m = mean(v), bm = []; for (let b = 0; b < B; b++) bm.push(mean(v.slice(b * bs, (b + 1) * bs))); return Math.sqrt(bm.reduce((s, x) => s + (x - m) ** 2, 0) / (B * (B - 1))); };
function fit3(V, Rmin) { // V0 + sigma R - e/R least squares, plus 2-parameter pure Coulomb V0 - e/R
  const rows = V.map((v, k) => [k + 1, v]).filter(([R, v]) => R >= Rmin && isFinite(v));
  const solve = (basis) => { const n = basis(1).length, M = Array.from({ length: n }, () => new Array(n).fill(0)), y = new Array(n).fill(0);
    for (const [R, v] of rows) { const b = basis(R); for (let i = 0; i < n; i++) { y[i] += b[i] * v; for (let j = 0; j < n; j++) M[i][j] += b[i] * b[j]; } }
    for (let c = 0; c < n; c++) for (let r = 0; r < n; r++) if (r !== c) { const f = M[r][c] / M[c][c]; for (let k = 0; k < n; k++) M[r][k] -= f * M[c][k]; y[r] -= f * y[c]; }
    return y.map((v, i) => v / M[i][i]); };
  const [V0, sigma, e] = solve(R => [1, R, -1 / R]), [W0, e2] = solve(R => [1, -1 / R]);
  return { V0, sigma, e, coulomb: { V0: W0, e: e2 } };
}
if (mode === "scan") {
  const L = +(a.L ?? 6), betas = (a.betas ?? "0.90,0.95,0.98,1.00,1.01,1.02,1.04,1.07,1.10").split(",").map(Number);
  console.log("beta\tstart\tplaquette\terr");
  for (const b of betas) for (const start of ["cold", "hot"]) {
    const U = new U1({ d: 4, L, beta: b, start, seed: 11 }); for (let s = 0; s < +(a.therm ?? 400); s++) U.sweep();
    const v = []; for (let k = 0; k < +(a.meas ?? 400); k++) { U.sweep(); v.push(U.plaquette()); }
    console.log([b, start, mean(v).toFixed(5), blockErr(v).toFixed(5)].join("\t"));
  }
} else if (mode === "pot") {
  const b = +(a.beta ?? 1.1), L = +(a.L ?? 10), Rmax = +(a.Rmax ?? L / 2), Tmax = +(a.Tmax ?? 4), smear = +(a.smear ?? 10), meas = +(a.meas ?? 60), every = +(a.every ?? 5);
  const U = new U1({ d: 4, L, beta: b, start: a.start ?? "cold", seed: +(a.seed ?? 21) }); for (let s = 0; s < +(a.therm ?? 500); s++) U.sweep();
  const samples = [], pl = [];
  for (let m = 0; m < meas; m++) { for (let s = 0; s < every; s++) U.sweep(); pl.push(U.plaquette()); samples.push(U.loops(Rmax, Tmax, 3, smear ? U.ape([0, 1, 2], 0.5, smear) : U.th)); }
  const avg = list => { const o = {}; for (const k in list[0]) o[k] = mean(list.map(w => w[k])); return o; };
  const pot = (W, T) => Array.from({ length: Rmax }, (_, k) => Math.log(W[(k + 1) + "," + T] / W[(k + 1) + "," + (T + 1)]));
  const jack = f => { const n = samples.length, full = f(avg(samples)), v = []; for (let i = 0; i < n; i++) v.push(f(avg(samples.filter((_, j) => j !== i)))); const m = mean(v); return [full, Math.sqrt((n - 1) / n * v.reduce((s, x) => s + (x - m) ** 2, 0))]; };
  console.log(`beta ${b}  L ${L}  smear ${smear}  plaquette ${mean(pl).toFixed(5)}`);
  const T = +(a.T ?? 2);
  for (let t = 1; t < Tmax; t++) console.log(`T ${t}->${t + 1}  V(R) = ` + Array.from({ length: Rmax }, (_, k) => jack(W => pot(W, t)[k])).map(([v, e]) => `${v.toFixed(4)}(${Math.round(e * 1e4)})`).join("  "));
  const sg = jack(W => fit3(pot(W, T), 1).sigma), ee = jack(W => fit3(pot(W, T), 1).e), ce = jack(W => fit3(pot(W, T), 1).coulomb.e);
  console.log(`fit T ${T}, R >= 1: Cornell sigma a^2 = ${sg[0].toFixed(4)} ± ${sg[1].toFixed(4)}, e = ${ee[0].toFixed(4)} ± ${ee[1].toFixed(4)};  pure Coulomb e = ${ce[0].toFixed(4)} ± ${ce[1].toFixed(4)};  tree-level 1/(4 pi beta) = ${(1 / (4 * Math.PI * b)).toFixed(4)}`);
}

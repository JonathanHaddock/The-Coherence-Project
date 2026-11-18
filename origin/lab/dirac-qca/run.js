// ORIGIN lab: the Dirac equation from a local update rule (quantum cellular automaton).
// Standard physics, separate from origin's pixel rules. Bisio, D'Ariano, Perinotti et al. (arXiv 1306.1934,
// 1601.04832): demand only unitarity, locality, homogeneity and isotropy, and the simplest automaton that fits is
// the Weyl / Dirac automaton. Relativity is not put in; it should come out at low momentum.
//
// 1D rule (each pixel holds two complex numbers, R and L; one tick):
//   R'(x) = n R(x-1) + i m L(x)
//   L'(x) = i m R(x) + n L(x+1)          with n^2 + m^2 = 1  (m = mass in lattice units)
// In momentum space D_k = [[n e^-ik, i m], [i m, n e^ik]], so cos(omega) = n cos k (the paper's dispersion).
// 3D Weyl automaton on the BCC lattice: cos(omega) = cx cy cz -+ sx sy sz, ci = cos(ki/sqrt3), si = sin(ki/sqrt3).
//
// node run.js   -> all checks and results (a few seconds)
let fail = 0; const ok = (n, c, d) => { console.log(`${c ? "PASS" : "FAIL"}  ${n}  ${d}`); if (!c) fail++; };
const N = 4096; // ring of sites (periodic)
function step(s, n, m) { // s = { Rr, Ri, Lr, Li } Float64Arrays; returns new state
  const o = { Rr: new Float64Array(N), Ri: new Float64Array(N), Lr: new Float64Array(N), Li: new Float64Array(N) };
  for (let x = 0; x < N; x++) {
    const xm = (x - 1 + N) % N, xp = (x + 1) % N;
    // i m L = i m (Lr + i Li) = -m Li + i m Lr
    o.Rr[x] = n * s.Rr[xm] - m * s.Li[x]; o.Ri[x] = n * s.Ri[xm] + m * s.Lr[x];
    o.Lr[x] = -m * s.Ri[x] + n * s.Lr[xp]; o.Li[x] = m * s.Rr[x] + n * s.Li[xp];
  }
  return o;
}
const norm = s => { let t = 0; for (let x = 0; x < N; x++) t += s.Rr[x] ** 2 + s.Ri[x] ** 2 + s.Lr[x] ** 2 + s.Li[x] ** 2; return t; };
const empty = () => ({ Rr: new Float64Array(N), Ri: new Float64Array(N), Lr: new Float64Array(N), Li: new Float64Array(N) });
const omega = (k, m) => Math.acos(Math.sqrt(1 - m * m) * Math.cos(k));
const vgroup = (k, m) => { const n = Math.sqrt(1 - m * m), w = omega(k, m); return n * Math.sin(k) / Math.sin(w); };

// ---- check 1: unitarity and the strict light cone ----
{
  const m = 0.3, n = Math.sqrt(1 - m * m); let s = empty(); s.Rr[N / 2] = 1; let worst = 0, cone = true;
  for (let t = 1; t <= 500; t++) { s = step(s, n, m); worst = Math.max(worst, Math.abs(norm(s) - 1));
    for (let x = 0; x < N; x++) if (Math.abs(x - N / 2) > t && (s.Rr[x] || s.Ri[x] || s.Lr[x] || s.Li[x])) cone = false; }
  ok("unitarity", worst < 1e-12, `norm stays 1 to ${worst.toExponential(2)} over 500 ticks`);
  ok("strict light cone", cone, "after t ticks nothing is ever found more than t sites from the start");
}
// ---- check 2: a plane wave evolves with exactly the paper's dispersion cos(omega) = n cos k ----
{
  let worst = 0;
  for (const m of [0, 0.1, 0.5]) for (const kk of [5, 100, 700, 1500]) {
    const k = 2 * Math.PI * kk / N, n = Math.sqrt(1 - m * m);
    // positive-energy eigenvector of D_k: D v = e^{-i w} v. Solve (n e^-ik - e^-iw) a + i m b = 0
    const w = omega(k, m); // components: a = i m, b = e^-iw - n e^-ik
    const a = [0, m], b = [Math.cos(w) - n * Math.cos(k), -Math.sin(w) + n * Math.sin(k)];
    let s = empty(); for (let x = 0; x < N; x++) { const c = Math.cos(k * x), d = Math.sin(k * x);
      s.Rr[x] = a[0] * c - a[1] * d; s.Ri[x] = a[0] * d + a[1] * c; s.Lr[x] = b[0] * c - b[1] * d; s.Li[x] = b[0] * d + b[1] * c; }
    const s0 = s; s = step(s, n, m);
    // the new state should be e^{-i w} times the old one, everywhere (or e^{+i w} if we picked the other branch)
    let best = Infinity; for (const sg of [-1, 1]) { const c = Math.cos(sg * w), d = Math.sin(sg * w); let err = 0;
      for (const [r, i] of [["Rr", "Ri"], ["Lr", "Li"]]) for (let x = 0; x < N; x += 97) { const er = c * s0[r][x] - d * s0[i][x], ei = c * s0[i][x] + d * s0[r][x]; err = Math.max(err, Math.abs(er - s[r][x]), Math.abs(ei - s[i][x])); }
      best = Math.min(best, err); }
    if (m > 0 || kk) worst = Math.max(worst, best);
  }
  ok("dispersion is exactly cos(omega) = n cos k", worst < 1e-10, `plane waves for m 0, 0.1, 0.5 and four k: largest mismatch ${worst.toExponential(2)}`);
}
// ---- results ----
console.log("\nRESULT 1: low momentum = relativity. Compare the automaton's omega(k) with sqrt(k^2 + m^2):");
console.log("  m      k      automaton   relativistic   rel. difference");
for (const m of [0.01, 0.05]) for (const k of [0.01, 0.05, 0.2, 0.5, 1.0, 2.0]) {
  const w = omega(k, m), r = Math.sqrt(k * k + m * m); console.log(`  ${m.toFixed(2)}   ${k.toFixed(2)}   ${w.toFixed(6)}    ${r.toFixed(6)}     ${((w - r) / r * 100).toFixed(3)}%`);
}
// group velocity: measured from a moving Gaussian packet vs formula, and the maximum over all k
console.log("\nRESULT 2: wave packets move at the group velocity and never faster than light");
{
  const m = 0.2, n = Math.sqrt(1 - m * m), tick = 600;
  for (const k0 of [0.1, 0.4, 1.0, 2.0]) {
    const w = omega(k0, m), a = [0, m], b = [Math.cos(w) - n * Math.cos(k0), -Math.sin(w) + n * Math.sin(k0)], nb = Math.hypot(...a, ...b);
    let s = empty(); const x0 = N / 4, sig = 40;
    for (let x = 0; x < N; x++) { const g = Math.exp(-((x - x0) ** 2) / (2 * sig * sig)), c = Math.cos(k0 * x) * g, d = Math.sin(k0 * x) * g;
      s.Rr[x] = (a[0] * c - a[1] * d) / nb; s.Ri[x] = (a[0] * d + a[1] * c) / nb; s.Lr[x] = (b[0] * c - b[1] * d) / nb; s.Li[x] = (b[0] * d + b[1] * c) / nb; }
    const centre = st => { let t = 0, xs = 0; for (let x = 0; x < N; x++) { const p = st.Rr[x] ** 2 + st.Ri[x] ** 2 + st.Lr[x] ** 2 + st.Li[x] ** 2; t += p; xs += p * x; } return xs / t; };
    const c0 = centre(s); for (let t = 0; t < tick; t++) s = step(s, n, m); const v = (centre(s) - c0) / tick;
    const rel = k0 / Math.sqrt(k0 * k0 + m * m);
    ok(`packet k ${k0}, m ${m}: measured speed = automaton group velocity`, Math.abs(v - vgroup(k0, m)) < 0.01, `measured ${v.toFixed(4)}, automaton ${vgroup(k0, m).toFixed(4)}, relativity ${rel.toFixed(4)}`);
  }
  let vmax = 0, kmax = 0; for (let i = 1; i < 10000; i++) { const k = Math.PI * i / 10000, v = vgroup(k, m); if (v > vmax) { vmax = v; kmax = k; } }
  ok("no faster-than-light motion", vmax <= 1 + 1e-12, `largest group velocity at m ${m}: ${vmax.toFixed(6)} (at k = ${kmax.toFixed(3)}); light speed = 1 site per tick`);
}
// Zitterbewegung: a packet made of both energy branches jitters at frequency 2 omega
console.log("\nRESULT 3: Zitterbewegung (a Dirac-equation hallmark) appears unprompted");
{
  const m = 0.3, n = Math.sqrt(1 - m * m); let s = empty(); const x0 = N / 2, sig = 30;
  for (let x = 0; x < N; x++) s.Rr[x] = Math.exp(-((x - x0) ** 2) / (2 * sig * sig)); // only R: a mix of both branches
  const nn = Math.sqrt(norm(s)); for (const key of ["Rr"]) for (let x = 0; x < N; x++) s[key][x] /= nn;
  const xs = []; for (let t = 0; t < 200; t++) { let tt = 0, xx = 0; for (let x = 0; x < N; x++) { const p = s.Rr[x] ** 2 + s.Ri[x] ** 2 + s.Lr[x] ** 2 + s.Li[x] ** 2; tt += p; xx += p * x; } xs.push(xx / tt - x0); s = step(s, n, m); }
  // remove the smooth drift, find the dominant oscillation frequency
  const d = xs.map((v, t) => v - (xs[xs.length - 1] - xs[0]) * t / (xs.length - 1)); let best = 0, fbest = 0;
  for (let f = 0.05; f < Math.PI; f += 0.0005) { let c = 0, sn = 0; d.forEach((v, t) => { c += v * Math.cos(f * t); sn += v * Math.sin(f * t); }); const p = c * c + sn * sn; if (p > best) { best = p; fbest = f; } }
  const pred = 2 * omega(0, m);
  ok("jitter frequency = 2 omega(k = 0)", Math.abs(fbest - pred) < 0.02, `measured ${fbest.toFixed(4)}, predicted 2 arccos(n) = ${pred.toFixed(4)} (relativistic 2m = ${(2 * m).toFixed(4)})`);
}
// 3D Weyl automaton on the BCC lattice: isotropy only at low k
console.log("\nRESULT 4: 3D Weyl automaton (BCC lattice). omega should be |k|/sqrt3 in every direction at small k.");
{
  const w3 = (kx, ky, kz, sg) => { const c = [kx, ky, kz].map(k => Math.cos(k / Math.sqrt(3))), s = [kx, ky, kz].map(k => Math.sin(k / Math.sqrt(3)));
    return Math.acos(c[0] * c[1] * c[2] - sg * s[0] * s[1] * s[2]); };
  const dirs = { "(1,0,0)": [1, 0, 0], "(1,1,0)": [1, 1, 0], "(1,1,1)": [1, 1, 1], "(1,-1,1)": [1, -1, 1], "(1,2,3)": [1, 2, 3] };
  console.log("  |k|     " + Object.keys(dirs).join("    ") + "   spread/mean");
  const spreads = [];
  for (const K of [0.01, 0.03, 0.1, 0.3, 1.0]) {
    const ws = Object.values(dirs).map(d => { const l = Math.hypot(...d); return w3(K * d[0] / l, K * d[1] / l, K * d[2] / l, 1) / (K / Math.sqrt(3)); });
    const mean = ws.reduce((a, b) => a + b, 0) / ws.length, spread = Math.max(...ws) - Math.min(...ws); spreads.push([K, spread / mean]);
    console.log(`  ${K.toFixed(2)}   ` + ws.map(v => v.toFixed(6)).join("  ") + `   ${(spread / mean).toExponential(2)}`);
  }
  const p = Math.log(spreads[2][1] / spreads[1][1]) / Math.log(0.1 / 0.03), p2 = Math.log(spreads[1][1] / spreads[0][1]) / Math.log(0.03 / 0.01);
  console.log(`  (omega / (|k|/sqrt3) for each direction; 1 = exactly relativistic)`);
  console.log(`  anisotropy grows as |k|^${p2.toFixed(2)} (0.01 -> 0.03) and |k|^${p.toFixed(2)} (0.03 -> 0.1)`);
  ok("3D Weyl automaton becomes isotropic as k -> 0", spreads[0][1] < 3e-3 && Math.abs(p2 - 1) < 0.05, `spread shrinks linearly: ${spreads[0][1].toExponential(2)} at |k| 0.01`);
  // analytic expansion of the paper's formula: omega^2 = |k|^2/3 + 2 sg a_x a_y a_z + O(k^4), a_i = k_i/sqrt3
  let worst = 0; const rnd = (() => { let a = 7; return () => (a = (a * 16807) % 2147483647) / 2147483647; })();
  for (let t = 0; t < 200; t++) { const d = [rnd() - .5, rnd() - .5, rnd() - .5], l = Math.hypot(...d), K = 0.01, k = d.map(v => K * v / l), aa = k.map(v => v / Math.sqrt(3));
    for (const sg of [1, -1]) { const pred = Math.sqrt(K * K / 3 + 2 * sg * aa[0] * aa[1] * aa[2]); worst = Math.max(worst, Math.abs(w3(...k, sg) - pred) / pred); } }
  ok("leading anisotropy = 2 a_x a_y a_z in omega^2, opposite sign for the two chiralities", worst < 1e-4, `200 random directions at |k| 0.01, both chiralities: largest relative residual ${worst.toExponential(2)} (next order is k^2 ~ 1e-4)`);
}
console.log(fail ? `\n${fail} check(s) failed` : "\nall checks passed"); process.exitCode = fail ? 1 : 0;

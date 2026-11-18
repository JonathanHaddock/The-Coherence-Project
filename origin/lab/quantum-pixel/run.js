// Experiments with the quantum pixel. node run.js  (about a minute)
const { pc, hop, basis, nAt, casimirApply, hamiltonian, ground, TABLES, NAMES } = require("./qpixel.js");
let fail = 0; const ok = (n, c, d) => { console.log(`${c ? "PASS" : "FAIL"}  ${n}  ${d}`); if (!c) fail++; };
const frac = x => { const r = Math.round(x * 3); return r % 3 === 0 ? String(r / 3) : `${r}/3`; };
// dense symmetric eigenvalues (Jacobi; blocks here are at most a few hundred states)
function eig(M) { const n = M.length, A = M.map(r => Float64Array.from(r)); for (let sw = 0; sw < 80; sw++) { let off = 0; for (let i = 0; i < n; i++) for (let j = i + 1; j < n; j++) off += A[i][j] ** 2; if (off < 1e-24) break;
    for (let p = 0; p < n; p++) for (let q = p + 1; q < n; q++) { if (Math.abs(A[p][q]) < 1e-16) continue; const th = 0.5 * Math.atan2(2 * A[p][q], A[q][q] - A[p][p]), c = Math.cos(th), s = Math.sin(th);
      for (let k = 0; k < n; k++) { const x = A[k][p], y = A[k][q]; A[k][p] = c * x - s * y; A[k][q] = s * x + c * y; } for (let k = 0; k < n; k++) { const x = A[p][k], y = A[q][k]; A[p][k] = c * x - s * y; A[q][k] = s * x + c * y; } } }
  return A.map((r, i) => r[i]).sort((a, b) => a - b); }
// all states with a given filled count per pixel (the colour states of one arrangement of kinds)
function block(tuple) { let out = [0]; tuple.forEach((n, x) => { const opts = []; for (let b = 0; b < 8; b++) if (pc(b) === n) opts.push(b); const nx = []; for (const s of out) for (const b of opts) nx.push(s | (b << (3 * x))); out = nx; }); return out; }
// colour-field energy (t = 0) on a block: sum over links 0..L-1 of (g2/2) C2(prefix), as a dense matrix
function colourMatrix(tuple, g2, upto = tuple.length) { const st = block(tuple), idx = new Map(st.map((s, i) => [s, i])), M = st.map(() => new Float64Array(st.length));
  st.forEach((s, i) => { const out = new Map(); for (let l = 0; l < upto; l++) casimirApply(s, l, out, g2 / 2); for (const [k, v] of out) M[i][idx.get(k)] += v; }); return M; }

// ---- check: Lanczos ground state = dense ----
{ const H = hamiltonian({ L: 3, N: 3, g2: 1, e2: 0.1, t: 1, table: "furey", motion: "cells" }), n = H.B.length;
  const M = H.B.map((_, i) => H.apply(Float64Array.from({ length: n }, (_, j) => i === j ? 1 : 0))), d = eig(M)[0], g = ground(H.apply, n).E;
  ok("Lanczos ground state = dense diagonalisation", Math.abs(d - g) < 1e-9, `L 3, N 3 (${n} states): ${d.toFixed(10)} vs ${g.toFixed(10)}`); }

// ---- RESULT 1: which electric charges can a colour-neutral object have? ----
console.log("\nRESULT 1: every arrangement of kinds on up to 4 pixels; count the colour-singlet states and their electric charge.");
for (const table of ["furey", "origin"]) {
  const charges = new Map(), examples = new Map();
  for (let L = 1; L <= 4; L++) { const tuples = []; (function rec(t) { if (t.length === L) { if (t.some(n => n > 0)) tuples.push(t.slice()); return; } for (let n = 0; n < 4; n++) { t.push(n); rec(t); t.pop(); } })([]);
    for (const tu of tuples) { if (tu[0] === 0 || tu[tu.length - 1] === 0) continue; // count each arrangement once (no empty pixels at the ends)
      const ev = eig(colourMatrix(tu, 2, tu.length).map(r => Array.from(r)).map((r, i, M) => r)); // total-charge Casimir appears on the last link
      // singlets: states with zero colour charge in total: eigenvalues of C2(all pixels) alone
      const st = block(tu), idx = new Map(st.map((s, i) => [s, i])), C = st.map(() => new Float64Array(st.length));
      st.forEach((s, i) => { const out = new Map(); casimirApply(s, tu.length - 1, out, 1); for (const [k, v] of out) C[i][idx.get(k)] += v; });
      const zeros = eig(C.map(r => Array.from(r))).filter(x => Math.abs(x) < 1e-9).length; if (!zeros) continue;
      const Q = tu.reduce((s, n) => s + TABLES[table][n], 0), key = frac(Q); charges.set(key, (charges.get(key) || 0) + zeros);
      if (!examples.has(key)) examples.set(key, tu.filter(n => n).map(n => NAMES[table][n]).join(" + ")); } }
  const list = [...charges.entries()].sort((a, b) => eval(a[0]) - eval(b[0]));
  console.log(`  ${table.toUpperCase()} table: colour-neutral objects come with charge ` + list.map(([q, n]) => `${q} (${n} states, e.g. ${examples.get(q)})`).join(";  "));
  const fractional = list.filter(([q]) => q.includes("/"));
  if (table === "furey") ok("Furey table: every colour-neutral object has whole-number charge", fractional.length === 0, "as in nature: no free fractional charge has ever been seen");
  else ok("origin table: colour-neutral objects with fractional charge exist", fractional.length > 0, `e.g. ${fractional.map(([q]) => `${q}: ${examples.get(q)}`).join("; ")}`);
}

// ---- RESULT 2: confinement (static, no motion, colour field only) ----
console.log("\nRESULT 2: energy of the colour field, g2 = 1, no motion. Theory for flux of a triplet: (g2/2)(4/3) = 2/3 per link.");
{ const rows = [];
  for (const r of [1, 2, 3, 4, 5, 6]) { const tu = [1, ...Array(r - 1).fill(0), 2]; const E = eig(colourMatrix(tu, 1).map(x => Array.from(x)))[0]; rows.push([r, E]); }
  console.log("  quark + antiquark r apart: " + rows.map(([r, E]) => `r ${r}: ${E.toFixed(4)}`).join("  "));
  ok("quark-antiquark energy rises linearly: 2/3 per link (a string)", rows.every(([r, E]) => Math.abs(E - 2 * r / 3) < 1e-9), "exactly (g2/2) C2(triplet) x distance");
  const lone = [2, 3, 4, 5, 6].map(L => [L, eig(colourMatrix([1, ...Array(L - 1).fill(0)], 1).map(x => Array.from(x)))[0]]);
  console.log("  one quark alone in a box of L pixels (its flux runs out to infinity): " + lone.map(([L, E]) => `L ${L}: ${E.toFixed(4)}`).join("  "));
  ok("a lone quark costs energy growing with the size of the world", lone.every(([L, E]) => Math.abs(E - 2 * L / 3) < 1e-9), "unbounded as L grows: a free quark cannot exist");
  const bar = [1, 2, 3].map(r => { const tu = [1, ...Array(r - 1).fill(0), 1, ...Array(r - 1).fill(0), 1]; return [r, eig(colourMatrix(tu, 1).map(x => Array.from(x)))[0]]; });
  console.log("  three quarks r apart (a baryon): " + bar.map(([r, E]) => `r ${r}: ${E.toFixed(4)}`).join("  "));
  ok("three quarks bind into a colour singlet with linear strings", bar.every(([r, E]) => Math.abs(E - 4 * r / 3) < 1e-9), "two string segments of length r, 2/3 per link each");
}

// ---- RESULT 3: put it in motion. Ground state of 3 filled cells on 6 pixels ----
console.log("\nRESULT 3: three filled cells on 6 pixels, t = 1, e2 = 0.1. Ground-state composition by kinds present.");
for (const motion of ["cells", "pixels"]) for (const table of ["furey", "origin"]) {
  for (const g2 of [0, 0.5, 2, 8]) {
    const H = hamiltonian({ L: 6, N: 3, g2, e2: 0.1, t: 1, table, motion });
    let res;
    if (motion === "cells") res = ground(H.apply, H.B.length);
    else { // pixels keep their kind: diagonalise each set of kinds separately and take the lowest
      res = null; for (const content of ["3", "2,1", "1,1,1"]) { const want = content.split(",").map(Number).sort().join(); const keep = H.B.map((s, i) => [s, i]).filter(([s]) => { const ks = []; for (let x = 0; x < 6; x++) if (nAt(s, x)) ks.push(nAt(s, x)); return ks.sort().join() === want; });
        const sub = keep.map(([, i]) => i), pos = new Map(sub.map((i, k) => [i, k])), app = v => { const full = new Float64Array(H.B.length); sub.forEach((i, k) => full[i] = v[k]); const o = H.apply(full); return Float64Array.from(sub, i => o[i]); };
        const g = ground(app, sub.length); const vec = new Float64Array(H.B.length); sub.forEach((i, k) => vec[i] = g.vec[k]); if (!res || g.E < res.E) res = { E: g.E, vec, content }; } }
    const comp = new Map(); let c2 = 0;
    H.B.forEach((s, i) => { const p = res.vec[i] ** 2; if (p < 1e-14) return; const ks = []; for (let x = 0; x < 6; x++) if (nAt(s, x)) ks.push(nAt(s, x)); const key = ks.sort((a, b) => b - a).map(n => NAMES[table][n]).join("+"); comp.set(key, (comp.get(key) || 0) + p); });
    { const out = new Map(); H.B.forEach((s, i) => { if (res.vec[i] ** 2 < 1e-14) return; const o = new Map(); casimirApply(s, 5, o, 1); for (const [k, v] of o) out.set(k, (out.get(k) || 0) + v * res.vec[i]); }); H.B.forEach((s, i) => c2 += res.vec[i] * (out.get(s) || 0)); }
    const top = [...comp.entries()].sort((a, b) => b[1] - a[1]).slice(0, 3).map(([k, p]) => `${k} ${(100 * p).toFixed(0)}%`).join(", ");
    console.log(`  ${motion.padEnd(6)} move, ${table.padEnd(6)} table, g2 ${String(g2).padEnd(3)}: E0 ${res.E.toFixed(4)}, total colour C2 ${c2.toFixed(3)}  | ${top}`);
  }
}
console.log(fail ? `\n${fail} check(s) failed` : "\nall checks passed"); process.exitCode = fail ? 1 : 0;

// ---- RESULT 4: in the cells-move design, how much quark content does the electron keep as the colour force grows? ----
console.log("\nRESULT 4: cells move, origin table, 6 pixels, t = 1: share of the ground state that is NOT a single electron pixel.");
{ const pts = [];
  for (const g2 of [8, 16, 32, 64, 128]) { const H = hamiltonian({ L: 6, N: 3, g2, e2: 0.1, t: 1, table: "origin", motion: "cells" }), g = ground(H.apply, H.B.length);
    let pe = 0; H.B.forEach((s, i) => { for (let x = 0; x < 6; x++) if (nAt(s, x) === 3) pe += g.vec[i] ** 2; }); pts.push([g2, 1 - pe]);
    console.log(`  g2 ${String(g2).padEnd(4)}: not-an-electron share ${(1 - pe).toExponential(3)}`); }
  const slope = Math.log(pts[4][1] / pts[2][1]) / Math.log(pts[4][0] / pts[2][0]);
  console.log(`  falls as g2^${slope.toFixed(2)} (from g2 32 to 128)`);
  ok("quark content of the electron falls as the colour force grows, but never reaches zero", pts.every(([, p], i) => i === 0 || p < pts[i - 1][1]) && pts[4][1] > 0, `at g2 128 still ${pts[4][1].toExponential(2)}`);
}
console.log(fail ? `\n${fail} check(s) failed` : "\nall checks passed (result 4)"); process.exitCode = fail ? 1 : 0;

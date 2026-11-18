// node run.js   -> checks and results in one pass (it is all exact algebra; about a second)
const { Pauli, Torus, exchangePhase } = require("./stringnet.js");
let fail = 0; const ok = (n, c, d) => { console.log(`${c ? "PASS" : "FAIL"}  ${n}  ${d}`); if (!c) fail++; };
const sign = ph => ph === 0 ? "+1 (boson)" : ph === 2 ? "-1 (fermion)" : `i^${ph}`;

// ---- checks on the machinery ----
{ const n = 3, X = Pauli.X(n, [0]), Z = Pauli.Z(n, [0]), XZ = X.mul(Z), ZX = Z.mul(X);
  ok("Pauli algebra: XZ = -ZX", XZ.sameUpToPhase(ZX) && (XZ.ph - ZX.ph + 4) % 4 === 2, "");
  const Y = Pauli.X(n, [1]).mul(Pauli.Z(n, [1])); const YY = Y.mul(Y); ok("Pauli algebra: (XZ)^2 = -1", YY.x.every(v => !v) && YY.z.every(v => !v) && YY.ph === 2, "");
  const P = Pauli.X(n, [0, 2]).mul(Pauli.Z(n, [0, 1])); const PP = P.mul(P.dag()); ok("Pauli algebra: P P^dag = 1", PP.x.every(v => !v) && PP.z.every(v => !v) && PP.ph === 0, ""); }
for (const L of [2, 3, 4, 5]) {
  const T = new Torus(L); let allCommute = true; for (const a of T.A) for (const b of T.B) if (!a.commutes(b)) allCommute = false;
  const deg = 2 ** (T.n - T.stabilizerRank());
  ok(`L ${L}: every A_v commutes with every B_p; ground-state degeneracy`, allCommute && deg === 4, `${deg} (expected 4 on a torus: topological order)`);
}
// brute-force exact diagonalisation for L = 2 (256 states) as an independent check of the degeneracy and gap
{
  const T = new Torus(2), n = T.n, D = 1 << n, H = Array.from({ length: D }, () => new Float64Array(D));
  const act = (P, s) => { let t = s, ph = P.ph; for (let k = 0; k < n; k++) { if (P.z[k] && ((s >> k) & 1)) ph += 2; if (P.x[k]) t ^= 1 << k; } return [t, ph % 4]; }; // Z then X on |s>: P = X^x Z^z
  for (const P of [...T.A, ...T.B]) for (let s = 0; s < D; s++) { const [t, ph] = act(P, s); H[t][s] -= ph === 0 ? 1 : -1; }
  // Jacobi eigenvalues
  const A = H.map(r => Float64Array.from(r));
  for (let sw = 0; sw < 30; sw++) { let off = 0; for (let i = 0; i < D; i++) for (let j = i + 1; j < D; j++) off += A[i][j] ** 2; if (off < 1e-18) break;
    for (let p = 0; p < D; p++) for (let q = p + 1; q < D; q++) { if (Math.abs(A[p][q]) < 1e-14) continue; const th = 0.5 * Math.atan2(2 * A[p][q], A[q][q] - A[p][p]), c = Math.cos(th), s = Math.sin(th);
      for (let k = 0; k < D; k++) { const a = A[k][p], b = A[k][q]; A[k][p] = c * a - s * b; A[k][q] = s * a + c * b; } for (let k = 0; k < D; k++) { const a = A[p][k], b = A[q][k]; A[p][k] = c * a - s * b; A[q][k] = s * a + c * b; } } }
  const ev = A.map((r, i) => r[i]).sort((a, b) => a - b), E0 = ev[0], nGS = ev.filter(e => Math.abs(e - E0) < 1e-9).length, gap = ev.find(e => e > E0 + 1e-9) - E0;
  ok("L 2 brute-force diagonalisation", nGS === 4 && Math.abs(E0 + 8) < 1e-9 && Math.abs(gap - 4) < 1e-9, `E0 ${E0.toFixed(6)} (expected -8), degeneracy ${nGS}, gap ${gap.toFixed(6)} (expected 4: two excitations of cost 2)`);
}
// ---- results ----
const T = new Torus(6), n = T.n;
// 1. string ends: an open string of any length creates exactly two excitations (energy 4), at its ends only
{
  const lens = [1, 2, 3, 4, 5], out = [];
  let good = true;
  for (const k of lens) { const Zs = Pauli.Z(n, Array.from({ length: k }, (_, j) => T.ex(j, 0))), v = T.violations(Zs);
    out.push(`length ${k}: e at ${v.e.join(",")}`); if (v.e.length !== 2 || v.m.length !== 0 || !v.e.includes(T.v(0, 0)) || !v.e.includes(T.v(k, 0))) good = false; }
  const loop = Pauli.Z(n, [T.ex(0, 0), T.ex(1, 0), T.ey(2, 0), T.ex(1, 1), T.ex(0, 1), T.ey(0, 0)]), vl = T.violations(loop);
  ok("open strings: excitations only at the two ends, whatever the length (deconfined)", good, out.join("; "));
  ok("closed strings cost nothing", vl.e.length === 0 && vl.m.length === 0, "a closed 2x1 loop of Z flips no stabilizer");
}
// 2. exchange statistics by the T-junction test, for several junctions and leg lengths
const leg = (kind, x, y, dir, len) => { // move from the end of a leg of `len` steps into the centre (x,y)
  let P = new Pauli(n);
  for (let s = 0; s < len; s++) {
    if (dir === "E") P = P.mul(T.hop(kind, x + s, y, "E")); else if (dir === "N") P = P.mul(T.hop(kind, x, y + s, "N"));
    else if (dir === "W") P = P.mul(T.hop(kind, x - 1 - s, y, "E")); else P = P.mul(T.hop(kind, x, y - 1 - s, "N"));
  }
  return P;
};
const junctions = [["E", "N", "W"], ["N", "W", "S"], ["W", "S", "E"], ["S", "E", "N"], ["E", "N", "S"]];
const stats = {};
for (const kind of ["e", "m", "eps"]) {
  const phases = [];
  for (const len of [1, 2]) for (const [d1, d2, d3] of junctions) phases.push(exchangePhase(leg(kind, 2, 2, d1, len), leg(kind, 2, 2, d2, len), leg(kind, 2, 2, d3, len)));
  stats[kind] = phases;
  for (const len of [1, 2]) for (const dir of ["E", "N", "W", "S"]) { const v = T.violations(leg(kind, 2, 2, dir, len));
    const want = kind === "e" ? [2, 0] : kind === "m" ? [0, 2] : [2, 2]; if (v.e.length !== want[0] || v.m.length !== want[1]) { console.log(`FAIL  leg ${kind} ${dir} ${len} makes ${v.e.length} e and ${v.m.length} m`); fail++; } }
  const allSame = phases.every(p => p === phases[0]);
  ok(`exchange statistics of ${kind}: same in all ${phases.length} junctions`, allSame, `e^{i theta} = ${sign(phases[0])}`);
}
ok("e and m are bosons, e x m is a fermion", stats.e[0] === 0 && stats.m[0] === 0 && stats.eps[0] === 2, "built only from qubits (bosons) with local rules");
// 3. mutual statistics: carrying e once around a plaquette holding m gives -1
{
  const mString = Pauli.X(n, [T.ey(3, 3)]);                 // creates m on the plaquettes either side of link ey(3,3)
  const vm = T.violations(mString), p = vm.m[0];
  const loop = T.B[p];                                       // e carried around plaquette p = product of Z around it = B_p
  ok("mutual statistics: e around m", !loop.commutes(mString), `the loop operator anticommutes with the string that made m: phase -1 (Aharonov-Bohm with flux pi)`);
}
// 4. control: the fermion should not depend on which corner m is bound to
{
  // m bound to the plaquette SW of the vertex: lower-left corner (x-1, y-1). Moving east it crosses that plaquette's
  // right edge ey(x, y-1); moving north it crosses its top edge ex(x-1, y).
  const hop2 = (x, y, dir) => { const el = dir === "E" ? T.ex(x, y) : T.ey(x, y), ml = dir === "E" ? T.ey(x, y - 1) : T.ex(x - 1, y); return Pauli.Z(n, [el]).mul(Pauli.X(n, [ml])); };
  const leg2 = (x, y, dir) => dir === "E" ? hop2(x, y, "E") : dir === "N" ? hop2(x, y, "N") : dir === "W" ? hop2(x - 1, y, "E") : hop2(x, y - 1, "N");
  const legs = [leg2(2, 2, "E"), leg2(2, 2, "N"), leg2(2, 2, "W")], valid = legs.every(P => { const v = T.violations(P); return v.e.length === 2 && v.m.length === 2; });
  const ph = exchangePhase(...legs);
  ok("e x m bound on the opposite corner is still a fermion", valid && ph === 2, `legs valid (2 e + 2 m each): ${valid}; e^{i theta} = ${sign(ph)}`);
}
console.log(fail ? `${fail} check(s) failed` : "all checks passed"); process.exitCode = fail ? 1 : 0;

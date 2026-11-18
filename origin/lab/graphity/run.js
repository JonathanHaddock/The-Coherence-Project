// ORIGIN lab: geometry from cooling (a classical version of quantum graphity).
// Konopka, Markopoulou & Smolin (hep-th/0611197): start with every node able to link to every other (no space at
// all), give links an energy that prefers a fixed valence and closed loops of a set length, cool, and space is
// supposed to appear as a regular lattice. The paper argues this but says it can't prove it. This lab tests a
// classical simplification with valence v0 = 4 (the square lattice's) and loop length 4.
//
// Model A ("valence + loops"):   degree capped at 4 (a hard constraint),
//     E_A = gv sum_i (4 - deg_i)^2 - r * (number of 4-cycles) + t3 * (number of triangles)
// Model B ("+ manifold"):         E_B = E_A + m * sum_edges (s_e - 2)^2,  s_e = number of 4-cycles through edge e.
//     In any surface tiled by squares every edge borders exactly two squares; B rewards that.
// An earlier version without the degree cap was unbounded below (dense blobs win); see README.
//
// node run.js   -> checks and results
let fail = 0; const ok = (n, c, d) => { console.log(`${c ? "PASS" : "FAIL"}  ${n}  ${d}`); if (!c) fail++; };
function rng(seed) { let a = seed >>> 0 || 1; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
const VMAX = 4;

class Graph {
  constructor(N, R, P) { this.N = N; this.R = R; this.P = P; this.A = Array.from({ length: N }, () => new Uint8Array(N)); this.nb = Array.from({ length: N }, () => new Set()); this.E = 0; }
  has(i, j) { return this.A[i][j] === 1; }
  set(i, j, on) { if (on) { this.A[i][j] = this.A[j][i] = 1; this.nb[i].add(j); this.nb[j].add(i); this.E++; } else { this.A[i][j] = this.A[j][i] = 0; this.nb[i].delete(j); this.nb[j].delete(i); this.E--; } }
  c4through(i, j) { let c = 0; for (const k of this.nb[i]) { if (k === j) continue; for (const l of this.nb[k]) if (l !== i && l !== j && this.A[l][j]) c++; } return c; }
  c3through(i, j) { let c = 0; for (const k of this.nb[i]) if (k !== j && this.A[k][j]) c++; return c; }
  // squares through (i,j) as lists of their other three edges
  squaresThrough(i, j) { const out = []; for (const k of this.nb[i]) { if (k === j) continue; for (const l of this.nb[k]) if (l !== i && l !== j && this.A[l][j]) out.push([[i, k], [k, l], [l, j]]); } return out; }
  edgeTerm(i, j) { return this.has(i, j) ? this.P.m * (this.c4through(i, j) - 2) ** 2 : 0; }
  // energy change of toggling (i, j): valence and loop terms directly, manifold term by local recomputation
  dE(i, j) {
    const P = this.P, on = this.has(i, j), s = on ? -1 : 1, di = this.nb[i].size, dj = this.nb[j].size;
    if (!on && (di >= VMAX || dj >= VMAX)) return Infinity;
    let d = P.gv * (((VMAX - di - s) ** 2 - (VMAX - di) ** 2) + ((VMAX - dj - s) ** 2 - (VMAX - dj) ** 2)) + s * (-P.r * this.c4through(i, j) + P.t3 * this.c3through(i, j));
    if (P.m) {
      const key = (a, b) => a < b ? a * this.N + b : b * this.N + a, edges = new Map([[key(i, j), [i, j]]]);
      const sq = this.squaresThrough(i, j); for (const q of sq) for (const [a, b] of q) edges.set(key(a, b), [a, b]);
      let before = 0; for (const [a, b] of edges.values()) before += this.edgeTerm(a, b);
      this.set(i, j, !on); let after = 0; for (const [a, b] of edges.values()) after += this.edgeTerm(a, b); this.set(i, j, on);
      d += after - before;
    }
    return d;
  }
  energy() { const P = this.P; let e = 0; for (let i = 0; i < this.N; i++) e += P.gv * (VMAX - this.nb[i].size) ** 2;
    e += -P.r * this.count4() + P.t3 * this.count3();
    if (P.m) for (let i = 0; i < this.N; i++) for (const j of this.nb[i]) if (j > i) e += this.edgeTerm(i, j);
    return e; }
  count3() { let c = 0; for (let i = 0; i < this.N; i++) for (const j of this.nb[i]) if (j > i) for (const k of this.nb[j]) if (k > j && this.A[k][i]) c++; return c; }
  count4() { let c = 0; for (let i = 0; i < this.N; i++) for (let j = i + 1; j < this.N; j++) { let common = 0; for (const k of this.nb[i]) if (this.A[k][j]) common++; c += common * (common - 1) / 2; } return c / 2; }
  step(T) { // Metropolis-Hastings: half the time remove a random link, half add a random non-link
    const N = this.N, M = N * (N - 1) / 2, R = this.R;
    if (R() < 0.5) { if (!this.E) return; const k = (R() * this.E) | 0; let c = 0, i = -1, j = -1; outer: for (let a = 0; a < N; a++) for (const x of this.nb[a]) if (x > a) { if (c === k) { i = a; j = x; break outer; } c++; }
      const d = this.dE(i, j), q = this.E / (M - this.E + 1); if (R() < Math.min(1, q * Math.exp(-d / T))) this.set(i, j, false); }
    else { if (this.E === M) return; let i, j; do { i = (R() * N) | 0; j = (R() * N) | 0; } while (i === j || this.A[i][j]); const d = this.dE(i, j), q = (M - this.E) / (this.E + 1);
      if (d !== Infinity && R() < Math.min(1, q * Math.exp(-d / T))) this.set(i, j, true); }
  }
  distances() { const N = this.N; let s = 0, n = 0, conn = true; for (let a = 0; a < N; a++) { const d = new Int32Array(N).fill(-1); d[a] = 0; let fr = [a]; while (fr.length) { const nx = []; for (const v of fr) for (const w of this.nb[v]) if (d[w] < 0) { d[w] = d[v] + 1; nx.push(w); } fr = nx; }
      for (let b = 0; b < N; b++) if (b !== a) { if (d[b] < 0) conn = false; else { s += d[b]; n++; } } } return { mean: s / n, conn }; }
  components() { const seen = new Uint8Array(this.N), sizes = []; for (let a = 0; a < this.N; a++) if (!seen[a]) { let st = [a], c = 0; seen[a] = 1; while (st.length) { const v = st.pop(); c++; for (const w of this.nb[v]) if (!seen[w]) { seen[w] = 1; st.push(w); } } sizes.push(c); } return sizes.sort((x, y) => y - x); }
  // node is "lattice-like" if valence 4, its 4 links bound exactly 4 squares, and each of those links borders exactly 2 squares
  latticeLike() { let c = 0; for (let i = 0; i < this.N; i++) { if (this.nb[i].size !== 4) continue; let sq = 0, good = true; for (const j of this.nb[i]) { const s = this.c4through(i, j); sq += s; if (s !== 2) good = false; } if (good && sq === 8) c++; } return c; }
}
const PA = { gv: 2, r: 1, t3: 2, m: 0 }, PB = { gv: 2, r: 1, t3: 2, m: 1 };
const torus = (L, P) => { const g = new Graph(L * L, rng(1), P), id = (x, y) => ((y + L) % L) * L + ((x + L) % L); for (let y = 0; y < L; y++) for (let x = 0; x < L; x++) { g.set(id(x, y), id(x + 1, y), true); g.set(id(x, y), id(x, y + 1), true); } return g; };
const k44s = (N, P) => { const g = new Graph(N, rng(1), P); for (let b = 0; b + 8 <= N; b += 8) for (let a = 0; a < 4; a++) for (let c = 4; c < 8; c++) g.set(b + a, b + c, true); return g; };

// ---------- checks ----------
for (const [name, P] of [["A", PA], ["B", PB]]) {
  const R = rng(4); let worst = 0;
  for (let rep = 0; rep < 300; rep++) { const g = new Graph(16, R, P); for (let k = 0; k < 60; k++) { const i = (R() * 16) | 0, j = (R() * 16) | 0; if (i !== j && !g.has(i, j) && g.nb[i].size < 4 && g.nb[j].size < 4) g.set(i, j, true); }
    let i = (R() * 16) | 0, j = (R() * 16) | 0; if (i === j) j = (i + 1) % 16; const d = g.dE(i, j); if (d === Infinity) continue; const e0 = g.energy(); g.set(i, j, !g.has(i, j)); worst = Math.max(worst, Math.abs(g.energy() - e0 - d)); }
  ok(`model ${name}: incremental dE = full recomputation`, worst < 1e-9, "300 random toggles on random 16-node graphs");
  const N = 5, T = 4, g = new Graph(N, rng(9), P), pairs = []; for (let i = 0; i < N; i++) for (let j = i + 1; j < N; j++) pairs.push([i, j]);
  const code = () => pairs.reduce((s, [i, j], k) => s + (g.has(i, j) ? 1 << k : 0), 0), hist = new Float64Array(1 << pairs.length), steps = 8e6;
  for (let s = 0; s < steps; s++) { g.step(T); hist[code()]++; }
  let Z = 0; const w = []; for (let c = 0; c < 1 << pairs.length; c++) { const h = new Graph(N, rng(1), P); pairs.forEach(([i, j], k) => { if (c >> k & 1) h.set(i, j, true); }); const ok4 = h.nb.every(s => s.size <= VMAX); w.push(ok4 ? Math.exp(-h.energy() / T) : 0); Z += w[c]; }
  let tv = 0; for (let c = 0; c < w.length; c++) tv += Math.abs(hist[c] / steps - w[c] / Z); tv /= 2;
  ok(`model ${name}: sampler matches the Boltzmann distribution (5 nodes, all 1024 graphs, T 4)`, tv < 0.01, `total-variation distance ${tv.toFixed(4)} (pure noise shrinks as 1/sqrt(steps): checked separately at 2e6, 8e6, 32e6 steps: 0.0094, 0.0050, 0.0024)`);
}
{ const t = torus(8, PA), k = k44s(64, PA), tb = torus(8, PB), kb = k44s(64, PB);
  console.log(`\nENERGIES OF TWO CANDIDATE GROUND STATES, 64 nodes:`);
  console.log(`  model A: square torus ${t.energy()}, eight disjoint K4,4 blocks ${k.energy()}   (lower wins)`);
  console.log(`  model B: square torus ${tb.energy()}, eight disjoint K4,4 blocks ${kb.energy()}`);
  ok("model A prefers disconnected K4,4 blocks to a lattice", k.energy() < t.energy(), "a loop reward with valence 4 does not select space");
  ok("model B prefers the lattice", tb.energy() < kb.energy(), "with the manifold term the square torus is lower");
}
// ---------- results: cool slowly ----------
console.log("\nRESULT: cool from T = 4 to T = 0.02 (geometric), 3 seeds per size. (4 x 4 is left out: on so small a torus,");
console.log("  rows that wrap round in 4 steps are extra 4-cycles, so it is not a clean square lattice.)");
const rows = [];
for (const [name, P, slow] of [["A", PA, 1], ["B", PB, 1], ["B slow x5", PB, 5]]) for (const L of [6, 8]) {
  const N = L * L, tE = torus(L, P).energy();
  for (const seed of [1, 2, 3]) {
    const g = new Graph(N, rng(100 * L + seed + (name === "A" ? 0 : 7)), P), stages = 150, perStage = 200 * N * slow;
    for (let s = 0; s < stages; s++) { const T = 4 * Math.pow(0.02 / 4, s / (stages - 1)); for (let k = 0; k < perStage; k++) g.step(T); }
    const d = g.distances(), comps = g.components(), ll = g.latticeLike();
    rows.push({ model: name, N, seed, E: g.energy(), torusE: tE, lattice: ll, comps: comps.length, largest: comps[0], mean: d.mean, conn: d.conn, c3: g.count3() });
    console.log(`  model ${name.padEnd(9)} N ${N} seed ${seed}: E ${g.energy()} (torus ${tE}), lattice-like nodes ${ll}/${N}, components ${comps.length} (largest ${comps[0]}), triangles ${g.count3()}`);
  }
}
const sum = m => { const r = rows.filter(x => x.model === m); return `${(100 * r.reduce((s, x) => s + x.lattice / x.N, 0) / r.length).toFixed(0)}% lattice-like nodes on average, ${r.filter(x => x.comps === 1).length}/${r.length} runs connected, ${r.filter(x => x.E <= x.torusE).length}/${r.length} at or below the torus energy`; };
console.log(`\n  model A: ${sum("A")}\n  model B: ${sum("B")}\n  model B, 5x slower cooling: ${sum("B slow x5")}`);
console.log(JSON.stringify(rows));
console.log(fail ? `\n${fail} check(s) failed` : "\nall checks passed"); process.exitCode = fail ? 1 : 0;

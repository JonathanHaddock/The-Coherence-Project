// ORIGIN lab: 2D quantum gravity from glued triangles, with and without causality.
// Standard physics, separate from origin's pixel rules.
//
// DT  (Euclidean dynamical triangulations): every way of gluing N equilateral triangles into a sphere counts
//     equally. Monte Carlo by edge flips. Known answer: the geometry is fractal, Hausdorff dimension 4.
// CDT (causal dynamical triangulations, Ambjorn & Loll): triangles are glued between time slices, so every
//     configuration has a time order. Monte Carlo by (2,2) swaps and (2,4)/(4,2) vertex moves. Known answer:
//     an ordinary 2D geometry, Hausdorff dimension 2.
// The test: put the same "any gluing counts" rule on both, and see what the causal constraint alone does.
(function (root) {
  function rng(seed) { let a = seed >>> 0 || 1; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }

  // ---------------- DT: triangulated sphere ----------------
  class DT {
    constructor(N, seed = 1) {
      this.R = rng(seed); this.tri = []; this.nb = []; this.adj = []; // tri[t] = [a,b,c]; nb[t][k] = triangle across edge opposite vertex k
      // tetrahedron
      this.adj = [new Set([1, 2, 3]), new Set([0, 2, 3]), new Set([0, 1, 3]), new Set([0, 1, 2])];
      this.tri = [[0, 1, 2], [0, 3, 1], [1, 3, 2], [2, 3, 0]];
      this.rebuildNb();
      while (this.tri.length < N) this.split((this.R() * this.tri.length) | 0);
      this.rebuildNb(); this.flips = 0; this.tries = 0;
    }
    rebuildNb() { const map = new Map(), key = (a, b) => a < b ? a + "," + b : b + "," + a; this.nb = this.tri.map(() => [-1, -1, -1]);
      this.tri.forEach((t, i) => { for (let k = 0; k < 3; k++) { const e = key(t[(k + 1) % 3], t[(k + 2) % 3]); if (map.has(e)) { const [j, kk] = map.get(e); this.nb[i][k] = j; this.nb[j][kk] = i; } else map.set(e, [i, k]); } }); }
    split(i) { // 1 -> 3: new vertex inside triangle i
      const [a, b, c] = this.tri[i], v = this.adj.length; this.adj.push(new Set([a, b, c])); for (const x of [a, b, c]) this.adj[x].add(v);
      this.tri[i] = [a, b, v]; this.tri.push([b, c, v], [c, a, v]);
    }
    // flip the edge opposite vertex k of triangle i
    flip(i, k) {
      this.tries++;
      const j = this.nb[i][k]; const t = this.tri[i], a = t[(k + 1) % 3], b = t[(k + 2) % 3], c = t[k];
      const u = this.tri[j], kk = u.findIndex(x => x !== a && x !== b), d = u[kk];
      if (c === d || this.adj[c].has(d) || this.adj[a].size <= 3 || this.adj[b].size <= 3) return false;
      // triangles (c,a,b) and (d,b,a) -> (c,a,d) and (c,d,b)   (orientation: i = c,a,b ; j contains b,a,d)
      const nbI = this.nb[i], nbJ = this.nb[j];
      const ext = (tri, nbs, p, q) => { for (let m = 0; m < 3; m++) { const x = tri[(m + 1) % 3], y = tri[(m + 2) % 3]; if ((x === p && y === q) || (x === q && y === p)) return nbs[m]; } return -2; };
      const nCa = ext(t, nbI, c, a), nBc = ext(t, nbI, b, c), nAd = ext(u, nbJ, a, d), nDb = ext(u, nbJ, d, b);
      this.tri[i] = [c, a, d]; this.tri[j] = [c, d, b];
      this.nb[i] = [nAd, j, nCa];  // opposite c: edge a-d ; opposite a: edge d-c (= j) ; opposite d: edge c-a
      this.nb[j] = [nDb, nBc, i];  // opposite c: edge d-b ; opposite d: edge b-c ; opposite b: edge c-d (= i)
      const fix = (n, oldT, newT) => { if (n < 0) return; for (let m = 0; m < 3; m++) if (this.nb[n][m] === oldT) { this.nb[n][m] = newT; return; } };
      fix(nAd, j, i); fix(nBc, i, j); // a-d moved from j to i; b-c moved from i to j
      this.adj[a].delete(b); this.adj[b].delete(a); this.adj[c].add(d); this.adj[d].add(c);
      this.flips++; return true;
    }
    sweep() { const n = this.tri.length; for (let s = 0; s < n; s++) this.flip((this.R() * n) | 0, (this.R() * 3) | 0); }
    graph() { return this.adj.map(s => [...s]); }
    // consistency: every edge in exactly two triangles, Euler V - E + F = 2, adjacency matches triangles, nb symmetric
    check() {
      const V = this.adj.length, F = this.tri.length, edges = new Map(), key = (a, b) => a < b ? a + "," + b : b + "," + a;
      for (const t of this.tri) for (let k = 0; k < 3; k++) { const e = key(t[k], t[(k + 1) % 3]); edges.set(e, (edges.get(e) || 0) + 1); }
      let twice = true; for (const v of edges.values()) if (v !== 2) twice = false;
      let adjOK = true; for (const [e] of edges) { const [a, b] = e.split(",").map(Number); if (!this.adj[a].has(b)) adjOK = false; }
      let deg = 0; for (const s of this.adj) deg += s.size; if (deg !== 2 * edges.size) adjOK = false;
      let nbOK = true; this.nb.forEach((ns, i) => ns.forEach(j => { if (j < 0 || !this.nb[j].includes(i)) nbOK = false; }));
      return { euler: V - edges.size + F, twice, adjOK, nbOK, minDeg: Math.min(...this.adj.map(s => s.size)) };
    }
  }

  // ---------------- CDT: T periodic time slices ----------------
  // Strip t (between slice t and t+1) is a cyclic sequence of triangles: 1 = up (base on slice t), 0 = down
  // (base on slice t+1). offU[t] = slice-t edge index of the first up triangle in the array; offD[t] =
  // slice-(t+1) edge index of the first down triangle. l[t] = number of vertices (= edges) on slice t.
  class CDT {
    constructor(T, l0, seed = 1, N0 = null, eps = 0.0) {
      this.R = rng(seed); this.T = T; this.l = new Array(T).fill(l0); this.s = []; this.offU = new Array(T).fill(0); this.offD = new Array(T).fill(0);
      for (let t = 0; t < T; t++) { const a = []; for (let k = 0; k < l0; k++) a.push(1, 0); this.s.push(a); }
      this.N0 = N0 ?? 2 * T * l0; this.eps = eps; this.acc = { swap: 0, ins: 0, rem: 0 }; this.tried = { swap: 0, ins: 0, rem: 0 };
    }
    get N() { return 2 * this.l.reduce((a, b) => a + b, 0); }
    // position in strip array of the j-th up (kind 1) or down (kind 0) triangle, counted from the array start
    nth(t, kind, j) { const a = this.s[t]; let c = 0; for (let p = 0; p < a.length; p++) if (a[p] === kind) { if (c === j) return p; c++; } return -1; }
    swap() { // (2,2) move
      this.tried.swap++; const t = (this.R() * this.T) | 0, a = this.s[t], n = a.length, p = (this.R() * n) | 0, q = (p + 1) % n;
      if (a[p] === a[q]) return false;
      if (q === 0) { // wrap: element 0 changes type
        if (a[0] === 1) { this.offU[t] = (this.offU[t] + 1) % this.l[t]; this.offD[t] = (this.offD[t] - 1 + this.l[(t + 1) % this.T]) % this.l[(t + 1) % this.T]; }
        else { this.offD[t] = (this.offD[t] + 1) % this.l[(t + 1) % this.T]; this.offU[t] = (this.offU[t] - 1 + this.l[t]) % this.l[t]; }
      }
      [a[p], a[q]] = [a[q], a[p]]; this.acc.swap++; return true;
    }
    w(N) { return -this.eps * (N - this.N0) ** 2; } // log weight (volume fixing only; every triangulation of size N counts equally)
    insert() { // (2,4): split edge e of slice s, s = t+1
      this.tried.ins++; const N = this.N, E = N / 2; let pick = (this.R() * E) | 0, s = 0; while (pick >= this.l[s]) { pick -= this.l[s]; s++; } const e = pick;
      const A = Math.min(1, (E / (E + 1)) * Math.exp(this.w(N + 2) - this.w(N))); if (this.R() >= A) return false;
      const t = (s - 1 + this.T) % this.T, L = this.l[s];
      const pd = this.nth(t, 0, (e - this.offD[t] + L) % L), pu = this.nth(s, 1, (e - this.offU[s] + L) % L);
      this.s[t].splice(pd + 1, 0, 0); this.s[s].splice(pu + 1, 0, 1); this.l[s] = L + 1;
      if (this.offD[t] > e) this.offD[t]++; if (this.offU[s] > e) this.offU[s]++;
      this.acc.ins++; return true;
    }
    remove() { // (4,2): remove vertex v of slice s if it has exactly one past and one future link
      this.tried.rem++; const N = this.N, V = N / 2; let pick = (this.R() * V) | 0, s = 0; while (pick >= this.l[s]) { pick -= this.l[s]; s++; } const v = pick, L = this.l[s];
      if (L <= 3) return false;
      const t = (s - 1 + this.T) % this.T, eL = (v - 1 + L) % L, eR = v; // vertex v sits between edges v-1 and v
      const a = this.s[t], b = this.s[s];
      const pdL = this.nth(t, 0, (eL - this.offD[t] + L) % L), pdR = this.nth(t, 0, (eR - this.offD[t] + L) % L);
      const puL = this.nth(s, 1, (eL - this.offU[s] + L) % L), puR = this.nth(s, 1, (eR - this.offU[s] + L) % L);
      if ((pdL + 1) % a.length !== pdR || (puL + 1) % b.length !== puR) return false; // more than one past or future link
      const A = Math.min(1, (V / (V - 1)) * Math.exp(this.w(N - 2) - this.w(N))); if (this.R() >= A) return false;
      const firstD = a.indexOf(0), firstU = b.indexOf(1);
      a.splice(pdR, 1); b.splice(puR, 1); this.l[s] = L - 1;
      // renumber: edges v-1 and v merge into edge v-1, edges above v shift down by one. If the deleted triangle was
      // the first of its kind in the array, the new first is the next one (old edge v+1, now edge v, mod L-1).
      const fix = (o, wasFirst) => wasFirst ? v % (L - 1) : (o > v ? o - 1 : o);
      this.offD[t] = fix(this.offD[t], pdR === firstD); this.offU[s] = fix(this.offU[s], puR === firstU);
      this.acc.rem++; return true;
    }
    sweep() { const n = this.N; for (let k = 0; k < n; k++) { const r = this.R(); if (r < 0.5) this.swap(); else if (r < 0.75) this.insert(); else this.remove(); } }
    // vertex graph: id(t, i); spatial links within slices, time-like links from the strip sequences
    graph() {
      const base = []; let c = 0; for (let t = 0; t < this.T; t++) { base.push(c); c += this.l[t]; }
      const g = Array.from({ length: c }, () => new Set()), id = (t, i) => base[t] + ((i % this.l[t]) + this.l[t]) % this.l[t];
      for (let t = 0; t < this.T; t++) for (let i = 0; i < this.l[t]; i++) { g[id(t, i)].add(id(t, i + 1)); g[id(t, i + 1)].add(id(t, i)); }
      for (let t = 0; t < this.T; t++) {
        const u = (t + 1) % this.T; let lo = this.offU[t], up = this.offD[t];
        const link = () => { g[id(t, lo)].add(id(u, up)); g[id(u, up)].add(id(t, lo)); };
        link(); for (const x of this.s[t]) { if (x === 1) lo++; else up++; link(); }
      }
      return g.map(s => [...s]);
    }
    // consistency: strip t has l[t] ups and l[t+1] downs; the time-like walk closes; Euler V - E + F = 0 (torus)
    check() {
      let counts = true; for (let t = 0; t < this.T; t++) { const a = this.s[t], up = a.filter(x => x === 1).length; if (up !== this.l[t] || a.length - up !== this.l[(t + 1) % this.T]) counts = false; }
      const g = this.graph(), V = g.length, E = g.reduce((s, n) => s + n.length, 0) / 2, F = this.N;
      let sym = true; g.forEach((ns, i) => ns.forEach(j => { if (!g[j].includes(i)) sym = false; }));
      return { counts, euler: V - E + F, sym, minL: Math.min(...this.l) };
    }
  }
  // breadth-first shells from a start vertex
  function shells(g, start, rmax) { const d = new Int32Array(g.length).fill(-1), out = new Array(rmax + 1).fill(0); d[start] = 0; let fr = [start]; out[0] = 1;
    for (let r = 1; r <= rmax && fr.length; r++) { const nx = []; for (const v of fr) for (const w of g[v]) if (d[w] < 0) { d[w] = r; nx.push(w); } out[r] = nx.length; fr = nx; } return out; }
  function meanDistance(g, R, samples = 20) { let s = 0, n = 0; for (let k = 0; k < samples; k++) { const st = (R() * g.length) | 0, d = new Int32Array(g.length).fill(-1); d[st] = 0; let fr = [st], r = 0;
    while (fr.length) { r++; const nx = []; for (const v of fr) for (const w of g[v]) if (d[w] < 0) { d[w] = r; nx.push(w); } fr = nx; } for (const x of d) { s += x; n++; } } return s / n; }
  const api = { DT, CDT, shells, meanDistance, rng };
  if (typeof module !== "undefined") module.exports = api; else root.Tri = api;
})(this);

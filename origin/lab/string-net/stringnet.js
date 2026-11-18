// ORIGIN lab: string-net (Z2 toric code) on an L x L torus. Standard physics, separate from origin's pixel rules.
//
// One qubit on every link (2 L^2 links). Two local rules:
//   A_v = product of X on the 4 links at vertex v   (a "Gauss law": string ends cost energy)
//   B_p = product of Z on the 4 links of plaquette p (a flux / loop term)
//   H = - sum_v A_v - sum_p B_p
// The ground state is a superposition of closed-string configurations: a string-net condensate.
// Excitations: e = a vertex with A_v = -1 (end of a Z string), m = a plaquette with B_p = -1 (end of an X
// string on the dual lattice). Their bound state e x m is a fermion although every qubit is a boson.
// Statistics are computed with Levin & Wen's T-junction test (cond-mat/0302460) on exact Pauli algebra.
(function (root) {
  // Pauli string on n qubits: P = i^ph X^x Z^z (x, z bit arrays)
  class Pauli {
    constructor(n) { this.n = n; this.x = new Uint8Array(n); this.z = new Uint8Array(n); this.ph = 0; }
    static X(n, qs) { const p = new Pauli(n); for (const q of qs) p.x[q] ^= 1; return p; }
    static Z(n, qs) { const p = new Pauli(n); for (const q of qs) p.z[q] ^= 1; return p; }
    copy() { const p = new Pauli(this.n); p.x.set(this.x); p.z.set(this.z); p.ph = this.ph; return p; }
    // this * o
    mul(o) { const p = new Pauli(this.n); let s = 0; for (let k = 0; k < this.n; k++) { s += this.z[k] & o.x[k]; p.x[k] = this.x[k] ^ o.x[k]; p.z[k] = this.z[k] ^ o.z[k]; }
      p.ph = (this.ph + o.ph + 2 * s) % 4; return p; }
    dag() { const p = this.copy(); let s = 0; for (let k = 0; k < this.n; k++) s += this.x[k] & this.z[k]; p.ph = ((4 - this.ph) % 4 + 2 * s) % 4; return p; } // (i^ph X Z)^dag = i^-ph Z X = i^-ph (-1)^{xz} X Z
    commutes(o) { let s = 0; for (let k = 0; k < this.n; k++) s += (this.x[k] & o.z[k]) + (this.z[k] & o.x[k]); return s % 2 === 0; }
    sameUpToPhase(o) { for (let k = 0; k < this.n; k++) if (this.x[k] !== o.x[k] || this.z[k] !== o.z[k]) return false; return true; }
  }
  class Torus {
    constructor(L) {
      this.L = L; this.n = 2 * L * L;
      this.v = (x, y) => ((y + L) % L) * L + ((x + L) % L);
      this.ex = (x, y) => 2 * this.v(x, y);       // link from (x,y) to (x+1,y)
      this.ey = (x, y) => 2 * this.v(x, y) + 1;   // link from (x,y) to (x,y+1)
      this.A = []; this.B = [];
      for (let y = 0; y < L; y++) for (let x = 0; x < L; x++) {
        this.A.push(Pauli.X(this.n, [this.ex(x, y), this.ex(x - 1, y), this.ey(x, y), this.ey(x, y - 1)]));
        this.B.push(Pauli.Z(this.n, [this.ex(x, y), this.ex(x, y + 1), this.ey(x, y), this.ey(x + 1, y)])); // plaquette with lower-left corner (x,y)
      }
    }
    // which stabilizers an operator flips (anticommutes with): the excitations it creates or moves
    violations(P) { return { e: this.A.map((a, k) => a.commutes(P) ? -1 : k).filter(k => k >= 0), m: this.B.map((b, k) => b.commutes(P) ? -1 : k).filter(k => k >= 0) }; }
    // hopping operators. e hops along a link (Z on it); m hops across a link (X on the link it crosses);
    // eps = e at vertex (x,y) bound to m at the plaquette whose lower-left corner is (x,y).
    hop(kind, x, y, dir) { // dir: "E" or "N" from (x, y)
      const n = this.n, el = dir === "E" ? this.ex(x, y) : this.ey(x, y);
      const ml = dir === "E" ? this.ey(x + 1, y) : this.ex(x, y + 1);       // link shared by plaquette (x,y) and its neighbour
      if (kind === "e") return Pauli.Z(n, [el]);
      if (kind === "m") return Pauli.X(n, [ml]);
      return Pauli.Z(n, [el]).mul(Pauli.X(n, [ml]));                       // eps
    }
    // GF(2) rank of the stabilizer generators: ground-state degeneracy = 2^(n - rank)
    stabilizerRank() {
      const rows = [...this.A, ...this.B].map(p => { const r = new Uint8Array(2 * this.n); r.set(p.x, 0); r.set(p.z, this.n); return r; });
      let rank = 0; for (let c = 0; c < 2 * this.n && rank < rows.length; c++) {
        let piv = -1; for (let r = rank; r < rows.length; r++) if (rows[r][c]) { piv = r; break; } if (piv < 0) continue;
        [rows[rank], rows[piv]] = [rows[piv], rows[rank]];
        for (let r = 0; r < rows.length; r++) if (r !== rank && rows[r][c]) for (let k = 0; k < 2 * this.n; k++) rows[r][k] ^= rows[rank][k];
        rank++;
      }
      return rank;
    }
  }
  // Levin-Wen T-junction: three legs meeting at a centre. t_k moves a particle from the end of leg k to the centre.
  // t1 t2^dag t3 = e^{i theta} t3 t2^dag t1 defines the exchange statistics theta (0 boson, pi fermion).
  function exchangePhase(t1, t2, t3) {
    const a = t1.mul(t2.dag()).mul(t3), b = t3.mul(t2.dag()).mul(t1);
    if (!a.sameUpToPhase(b)) throw new Error("legs do not form a T-junction");
    return ((a.ph - b.ph) % 4 + 4) % 4; // in units of pi/2: 0 -> +1, 2 -> -1
  }
  const api = { Pauli, Torus, exchangePhase };
  if (typeof module !== "undefined") module.exports = api; else root.StringNet = api;
})(this);

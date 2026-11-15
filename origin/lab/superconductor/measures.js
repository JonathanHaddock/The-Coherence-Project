// Pairing signatures for layer 1, from the literature (see README):
// 1. Wake-following (retarded attraction): how often an electron passes within `near` of where another
//    electron was `tau` earlier, divided by chance (pi near^2 / area). Measured for a range of delays.
//    The lattice's attraction is delayed, so a real effect should peak at a delay, not at tau = 0.
// 2. Opposite momenta: among electron pairs within `R` of each other, the mean cosine of the angle
//    between their velocities. 0 = no preference; negative = they tend to move in opposite directions
//    (the k, -k character of Cooper pairs).
// Both are read against the g = 0 control (same everything, no lattice coupling).
(function (root) {
  class PairMeasures {
    constructor(lab, { every = 25, delays = [0, 2, 4, 8, 16, 32, 64], near = 1, R = 3 } = {}) {
      this.lab = lab; this.every = every; this.delays = delays; this.near = near; this.R = R;
      this.maxD = Math.max(...delays); this.hist = []; this.count = 0;
      this.hit = new Float64Array(delays.length); this.tries = new Float64Array(delays.length);
      this.cosSum = 0; this.cosN = 0;
    }
    // call after every lab.step()
    tick() {
      if (++this.count % this.every) return;
      const L = this.lab, ne = L.ne;
      this.hist.push({ x: Float64Array.from(L.ex), y: Float64Array.from(L.ey) });
      if (this.hist.length > this.maxD + 1) this.hist.shift();
      const now = this.hist[this.hist.length - 1];
      this.delays.forEach((d, k) => {
        const past = this.hist[this.hist.length - 1 - d]; if (!past) return;
        for (let a = 0; a < ne; a++) for (let b = 0; b < ne; b++) {
          if (a === b) continue;
          const dx = L.wrapD(now.x[b] - past.x[a], L.Lx), dy = L.wrapD(now.y[b] - past.y[a], L.Ly);
          this.tries[k]++; if (dx * dx + dy * dy < this.near * this.near) this.hit[k]++;
        }
      });
      for (let a = 0; a < ne; a++) for (let b = a + 1; b < ne; b++) {
        const dx = L.wrapD(L.ex[b] - L.ex[a], L.Lx), dy = L.wrapD(L.ey[b] - L.ey[a], L.Ly);
        if (dx * dx + dy * dy > this.R * this.R) continue;
        const va = Math.hypot(L.evx[a], L.evy[a]) || 1, vb = Math.hypot(L.evx[b], L.evy[b]) || 1;
        this.cosSum += (L.evx[a] * L.evx[b] + L.evy[a] * L.evy[b]) / (va * vb); this.cosN++;
      }
    }
    result() {
      const L = this.lab, chance = Math.PI * this.near * this.near / (L.Lx * L.Ly);
      return {
        delayTime: this.delays.map(d => d * this.every * L.p.dt),
        wake: this.delays.map((d, k) => this.tries[k] ? (this.hit[k] / this.tries[k]) / chance : 0),
        oppCos: this.cosN ? this.cosSum / this.cosN : 0, oppN: this.cosN,
      };
    }
  }
  const api = { PairMeasures };
  if (typeof module !== "undefined") module.exports = api; else root.SCMeasures = api;
})(this);

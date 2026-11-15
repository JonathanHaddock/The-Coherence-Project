// Particle observer for the origin lattice. It only reads engine state and adds no rule.
// Pixel kinds by filled-cell count (as in rule 23 / the triangle note):
//   0 = neutrino (charge 0), 1 = down quark (-1/3), 2 = up quark (+2/3), 3 = electron (-1).
// Composites: a connected group (6-neighbour) of quark pixels, bordered only by non-quark pixels.
//   A group of exactly 3 is a "triplet": uud = proton-like (+1), udd = neutron-like (0),
//   uuu = +2, ddd = -1. Groups of 2 = pairs, larger groups are counted by size.
// Lifetime: a triplet on the same 3 sites with the same kinds as last tick has survived one more tick.
(function (root) {
  const KIND = ["neutrino", "down", "up", "electron"];
  const Q3 = [0, -1, 2, -3]; // charge in thirds
  const POP = new Uint8Array(8).map((_, p) => (p & 1) + ((p >> 1) & 1) + ((p >> 2) & 1));

  function tripletName(u) { return ["ddd", "udd", "uud", "uuu"][u]; }
  const TRIP_LABEL = { uud: "proton-like (+1)", udd: "neutron-like (0)", uuu: "uuu (+2)", ddd: "ddd (−1)" };

  class Observer {
    constructor(N, NB) {
      this.N = N; this.NB = NB;
      this.comp = new Int32Array(N); this.stack = new Int32Array(N);
      this.prev = new Map(); // key -> age
      this.ageHist = new Map(); // "uud" -> array of lifetimes ended
      this.t = 0;
    }
    observe(eng) {
      const { N, NB, comp, stack } = this, pat = eng.pat;
      const s = {
        t: eng.t, kinds: [0, 0, 0, 0], flashByKind: [0, 0, 0, 0], charge3: 0,
        trip: { uud: 0, udd: 0, uuu: 0, ddd: 0 }, pairs: 0, bigGroups: 0, bigSites: 0, maxGroup: 0,
        isolatedElectrons: 0, triplets: [], oldest: 0, carrier: [0, 0, 0], carrierTotal: 0,
      };
      for (let i = 0; i < N; i++) {
        const k = POP[pat[i]]; s.kinds[k]++; s.charge3 += Q3[k];
        if (eng.fired[i]) s.flashByKind[k]++;
      }
      if (eng.cfg.channels) for (let i = 0; i < N; i++) { s.carrier[0] += eng.car3[i*3]; s.carrier[1] += eng.car3[i*3+1]; s.carrier[2] += eng.car3[i*3+2]; }
      for (let i = 0; i < N; i++) s.carrierTotal += eng.carrier[i];
      // quark groups
      comp.fill(-1);
      const next = new Map();
      for (let i = 0; i < N; i++) {
        const k = POP[pat[i]];
        if (k === 3) { let alone = true; for (let q = 0; q < 6; q++) if (POP[pat[NB[i*6+q]]] === 3) { alone = false; break; } if (alone) s.isolatedElectrons++; }
        if (comp[i] !== -1 || k === 0 || k === 3) continue;
        let top = 0, size = 0, ups = 0; const sites = [];
        stack[top++] = i; comp[i] = i;
        while (top) {
          const a = stack[--top]; size++; if (POP[pat[a]] === 2) ups++; if (sites.length < 4) sites.push(a);
          for (let q = 0; q < 6; q++) { const b = NB[a*6+q]; const kb = POP[pat[b]]; if (comp[b] === -1 && (kb === 1 || kb === 2)) { comp[b] = i; stack[top++] = b; } }
        }
        if (size > s.maxGroup) s.maxGroup = size;
        if (size === 2) s.pairs++;
        else if (size > 3) { s.bigGroups++; s.bigSites += size; }
        else if (size === 3) {
          const name = tripletName(ups); s.trip[name]++;
          sites.sort((x, y) => x - y);
          const key = name + ":" + sites.join(",");
          const age = (this.prev.get(key) || 0) + 1; next.set(key, age);
          if (age > s.oldest) s.oldest = age;
          s.triplets.push({ name, sites, age });
        }
      }
      for (const [key, age] of this.prev) if (!next.has(key)) {
        const n = key.slice(0, 3); if (!this.ageHist.has(n)) this.ageHist.set(n, []); this.ageHist.get(n).push(age);
      }
      this.prev = next; this.t = eng.t;
      return s;
    }
    lifetimes() {
      const out = {};
      for (const n of ["uud", "udd", "uuu", "ddd"]) {
        const a = this.ageHist.get(n) || [];
        const mean = a.length ? a.reduce((x, y) => x + y, 0) / a.length : 0;
        out[n] = { ended: a.length, mean, max: a.length ? Math.max(...a) : 0 };
      }
      return out;
    }
  }
  const api = { Observer, KIND, Q3, POP, TRIP_LABEL };
  if (typeof module !== "undefined") module.exports = api; else root.OriginObserve = api;
})(this);

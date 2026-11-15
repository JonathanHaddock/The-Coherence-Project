// Run the engine and write a particle census as TSV (one row every `every` ticks).
// node scripts/observe-run.js display=one_cell update=sync core=8 ticks=600 seed=1 every=10 [gravity=on] [feedback=cancel] [exclusion=on] [channels=on] [motion=on] > out.tsv
const { Engine } = require("../viewer/engine.js");
const { Observer } = require("../viewer/observe-core.js");
const a = Object.fromEntries(process.argv.slice(2).map(s => s.split("=")));
const cfg = { mode: "lattice", display: a.display || "one_cell", update: a.update || "sync", core: +(a.core ?? 8),
  gravity: a.gravity === "on" || a.feedback === "reinforce", cancel: a.feedback === "cancel",
  exclusion: a.exclusion === "on", channels: a.channels === "on", motion: a.motion === "on", seed: BigInt(a.seed || 1) };
const ticks = +(a.ticks || 600), every = +(a.every || 10);
const eng = new Engine(cfg);
const NBmod = require("../viewer/engine.js"); // NB is not exported; rebuild it
const S = NBmod.S, N = NBmod.N, NB = new Int32Array(N * 6);
for (let i = 0; i < N; i++) { const x = i % S, y = ((i / S) | 0) % S, z = (i / (S * S)) | 0, f = (p, q, r) => (r * S + q) * S + p;
  NB.set([f((x+1)%S,y,z), f((x+S-1)%S,y,z), f(x,(y+1)%S,z), f(x,(y+S-1)%S,z), f(x,y,(z+1)%S), f(x,y,(z+S-1)%S)], i * 6); }
const ob = new Observer(N, NB);
console.log(["tick","flashes","neutrino","down","up","electron","charge3","flash_nu","flash_d","flash_u","flash_e",
  "uud","udd","uuu","ddd","pairs","big_groups","big_sites","max_group","lone_electrons","oldest_triplet","carrier","weak","em","strong"].join("\t"));
for (let t = 0; t < ticks; t++) {
  const f = eng.tickLattice();
  if ((t + 1) % every) { ob.observe(eng); continue; }
  const s = ob.observe(eng);
  console.log([eng.t, f, ...s.kinds, s.charge3, ...s.flashByKind, s.trip.uud, s.trip.udd, s.trip.uuu, s.trip.ddd,
    s.pairs, s.bigGroups, s.bigSites, s.maxGroup, s.isolatedElectrons, s.oldest, s.carrierTotal.toFixed(1), ...s.carrier.map(x => x.toFixed(1))].join("\t"));
}
const L = ob.lifetimes();
console.error("triplet lifetimes (ended):", JSON.stringify(L));

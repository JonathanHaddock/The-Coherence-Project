// Invariant checks for rules 30-31 in the JS engine. node check5.js [ticks]
// Every tick: total charge unchanged, total colour unchanged, number of quark and lepton pixels unchanged,
// the multiset of (colour cells, weak cells) per pixel unchanged, and the Gauss law exact at every site.
const path = require("path"), { Engine, N } = require(path.join(__dirname, "../../viewer/engine.js"));
const T = +(process.argv[2] ?? 60); let fail = 0;
const ok = (n, c, d) => { console.log(`${c ? "PASS" : "FAIL"}  ${n}  ${d}`); if (!c) fail++; };
const census = e => { const h = new Map(); for (let i = 0; i < N; i++) { const p = e.p5[i], key = Engine.ncol(p) + "," + (((p >> 3) & 1) + ((p >> 4) & 1)); h.set(key, (h.get(key) || 0) + 1); } return [...h.entries()].sort().join(";"); };
const settings = [
  { label: "colour, conserve+excite, no motion", cfg: { five: true, colour: true, conserve: true, excite: true } },
  { label: "colour, conserve+excite, motion", cfg: { five: true, colour: true, conserve: true, excite: true, motion: true } },
  { label: "colour, motion + EM, core 8", cfg: { five: true, colour: true, conserve: true, excite: true, motion: true, em: true, core: 8 } },
  { label: "colour off (rule 30 only), motion", cfg: { five: true, colour: false, conserve: true, excite: true, motion: true } },
  { label: "rule 32, motion", cfg: { five: true, colour: true, conserve: true, excite: true, motion: true, allowed: true } },
  { label: "rules 32+33, core 10, motion + EM + exclusion", cfg: { five: true, colour: true, conserve: true, excite: true, motion: true, em: true, exclusion: true, allowed: true, neutral: true, core: 10 } },
];
for (const { label, cfg } of settings) {
  const e = new Engine(Object.assign({ mode: "lattice", display: "one_cell", update: "sync", core: 0, seed: 20261110n }, cfg));
  const s0 = e.stats5(), c0 = census(e); let worstG = s0.gauss, qOK = true, colOK = true, cenOK = true, flashes = 0, ex = 0, blk = 0, relax = 0, swaps = 0;
  for (let t = 0; t < T; t++) { flashes += e.tick(); const s = e.stats5(); worstG = Math.max(worstG, s.gauss); if (s.charge3 !== s0.charge3) qOK = false;
    if (s.colour[0] !== s0.colour[0] || s.colour[1] !== s0.colour[1]) colOK = false; ex += s.exchanges; blk += s.blocked; relax += s.relaxed; swaps += s.swaps; }
  if (census(e) !== c0) cenOK = false; const s = e.stats5();
  ok(`${label}: conservation`, qOK && colOK && cenOK, `charge ${s0.charge3}/3 kept, colour (${s0.colour}) kept, (colour cells, weak cells) census kept over ${T} ticks`);
  if (cfg.colour) ok(`${label}: Gauss law`, worstG === 0, `largest violation at any site, any tick: ${worstG}`);
  console.log(`      flashes ${flashes}, exchanges ${ex}, blocked ${blk}, plaquette moves ${relax}, moves ${swaps}; flux energy ${s0.fluxE.toFixed(0)} -> ${s.fluxE.toFixed(0)}, links carrying flux ${s0.strings} -> ${s.strings}`);
}
console.log(fail ? `${fail} check(s) failed` : "all checks passed"); process.exitCode = fail ? 1 : 0;

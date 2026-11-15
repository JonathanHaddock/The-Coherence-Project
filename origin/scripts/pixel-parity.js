// Check: a field of copies of the one-pixel model (pixel-model.js) = the engine (engine.js).
// node scripts/pixel-parity.js
const { Engine } = require("../viewer/engine.js");
const { Field } = require("../viewer/pixel-model.js");
const cases = [
  ["one_cell sync", { display: "one_cell", update: "sync" }],
  ["flip_all sweep", { display: "flip_all", update: "sweep" }],
  ["hold sync gravity (6)", { display: "hold", update: "sync", gravity: true }],
  ["one_cell sync cancel (21)", { display: "one_cell", update: "sync", cancel: true }],
  ["one_cell sync exclusion (22)", { display: "one_cell", update: "sync", exclusion: true }],
  ["flip_all sweep channels (23)", { display: "flip_all", update: "sweep", channels: true }],
  ["one_cell sync motion (24)", { display: "one_cell", update: "sync", motion: true }],
  ["one_cell sweep motion+em (24,25)", { display: "one_cell", update: "sweep", motion: true, em: true }],
  ["one_cell sync excite (26)", { display: "one_cell", update: "sync", excite: true }],
  ["one_cell sync conserve (27)", { display: "one_cell", update: "sync", conserve: true }],
  ["one_cell sync excite+conserve (26,27)", { display: "one_cell", update: "sync", excite: true, conserve: true }],
  ["flip_all sweep all 23-27", { display: "flip_all", update: "sweep", channels: true, motion: true, em: true, conserve: true }],
  ["flip_all sweep excite+motion+em (24-26)", { display: "flip_all", update: "sweep", excite: true, motion: true, em: true }],
];
const T = +(process.argv[2] || 40);
let bad = 0;
for (const [name, c] of cases) {
  const cfg = Object.assign({ core: 8, seed: 3n }, c);
  const e = new Engine(cfg), f = new Field(cfg);
  let a = 0, b = 0;
  for (let t = 0; t < T; t++) { a += e.tickLattice(); b += f.tick(); }
  let same = a === b;
  for (let i = 0; i < f.N && same; i++) if (f.px[i].pattern !== e.pat[i]) same = false;
  if (!same) bad++;
  console.log(`${same ? "SAME" : "DIFF"}  ${name.padEnd(34)} engine ${a}  pixels ${b}`);
}
process.exit(bad ? 1 : 0);

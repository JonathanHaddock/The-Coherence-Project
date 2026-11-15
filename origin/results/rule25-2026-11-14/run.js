// Rule 25 runs: do opposite charges end up as neighbours more often than chance?
// node run.js display update condition(still|move|move_em) seed ticks
// opp_ratio: share of charged-charged neighbour pairs with opposite sign, over the share expected
//   if the same charges were placed at random (1 = chance, >1 = opposites gather).
// ee_ratio: electron-electron neighbour pairs over chance (<1 = electrons keep apart).
const { Engine, N } = require("../../viewer/engine.js");
const POPC = [0, 1, 1, 2, 1, 2, 2, 3], Q = [0, -1, 2, -3];
const [display, update, cond, seed, ticks] = process.argv.slice(2);
const e = new Engine({ display, update, core: 8, motion: cond !== "still", em: cond === "move_em", seed: BigInt(seed) });
const S = 48, out = [];
function measure() {
  let pos = 0, neg = 0, el = 0;
  for (let i = 0; i < N; i++) { const q = Q[POPC[e.pat[i]]]; if (q > 0) pos++; else if (q < 0) neg++; if (q === -3) el++; }
  let pairs = 0, opp = 0, all = 0, ee = 0;
  for (let i = 0; i < N; i++) {
    const x = i % S, y = ((i / S) | 0) % S, z = (i / (S * S)) | 0, a = Q[POPC[e.pat[i]]];
    for (const j of [((z * S + y) * S + (x + 1) % S), ((z * S + (y + 1) % S) * S + x), ((((z + 1) % S) * S + y) * S + x)]) {
      const b = Q[POPC[e.pat[j]]]; all++;
      if (a === -3 && b === -3) ee++;
      if (a && b) { pairs++; if ((a > 0) !== (b > 0)) opp++; }
    }
  }
  const c = pos + neg, expOpp = 2 * pos * neg / (c * c), expEE = (el / N) ** 2;
  return [(opp / pairs / expOpp).toFixed(4), (ee / all / expEE).toFixed(4)];
}
for (let t = 0; t < +ticks; t++) {
  const f = e.tickLattice();
  if ((t + 1) % 50) continue;
  out.push([display, update, cond, seed, t + 1, (f / N).toFixed(4), e.swaps, ...measure()].join("\t"));
}
console.log(out.join("\n"));

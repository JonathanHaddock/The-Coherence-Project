// ORIGIN lab: superconductor, layer 3 ("what would Tc be?").
// Allen-Dynes modified McMillan formula (Allen & Dynes, PRB 12, 905, 1975):
//   Tc = f1 f2 (omega_log / 1.2) exp( -1.04 (1 + lambda) / (lambda - mu* (1 + 0.62 lambda)) )
// lambda = electron-phonon coupling, omega_log = log-average phonon frequency (kelvin),
// mu* = Coulomb pseudopotential (typically 0.10-0.15). Reliable near lambda ~ 1.6; weaker far from it.
//
// Linking to the layer-1 lab (McMillan 1968): lambda = eta / (M <omega^2>), eta = electronic stiffness
// ~ g^2 x electron density. So from a reference metal:
//   lambda   = lambda_ref * (g/g_ref)^2 * (M_ref <w2>_ref) / (M <w2>)   (M cancels: M<w2> = spring stiffness)
//   omega_log = omega_ref * (lab omega_log / lab omega_log_ref)
(function (root) {
  function allenDynes(lambda, wlog, mu = 0.1, w2overWlog = 1) {
    const den = lambda - mu * (1 + 0.62 * lambda);
    if (den <= 0) return 0;
    const L1 = 2.46 * (1 + 3.8 * mu), L2 = 1.82 * (1 + 6.3 * mu) * w2overWlog;
    const f1 = Math.cbrt(1 + Math.pow(lambda / L1, 1.5));
    const f2 = 1 + ((w2overWlog - 1) * lambda * lambda) / (lambda * lambda + L2 * L2);
    return f1 * f2 * (wlog / 1.2) * Math.exp(-1.04 * (1 + lambda) / den);
  }
  function mcmillan(lambda, wlog, mu = 0.1) {
    const den = lambda - mu * (1 + 0.62 * lambda);
    return den <= 0 ? 0 : (wlog / 1.2) * Math.exp(-1.04 * (1 + lambda) / den);
  }
  // Validation set. Values as listed in arXiv 2604.04719 (2026) from Allen & Dynes's Table I;
  // still to be checked against PRB 12, 905 itself.
  const MATERIALS = [
    { name: "Al", lambda: 0.43, wlog: 300, Tc: 1.18 },
    { name: "Sn", lambda: 0.72, wlog: 110, Tc: 3.72 },
    { name: "Pb", lambda: 1.55, wlog: 52, Tc: 7.20 },
    { name: "Nb", lambda: 1.26, wlog: 115, Tc: 9.25 },
  ];
  // phonon frequencies (list) -> omega_log, <omega^2>, assuming constant coupling (alpha^2 F ~ F)
  function phononMoments(ws) {
    let a = 0, b = 0, c = 0;
    for (const w of ws) if (w > 1e-9) { a += 1 / w; b += Math.log(w) / w; c += w; } // weights F(w)/w
    return { wlog: Math.exp(b / a), w2: c / a };
  }
  // scale a reference metal by the lab's changes (see header)
  function fromLab(ref, lab, labRef, mu = 0.1) {
    const lambda = ref.lambda * (lab.g / labRef.g) ** 2 * (labRef.M * labRef.w2) / (lab.M * lab.w2);
    const wlog = ref.wlog * lab.wlog / labRef.wlog;
    return { lambda, wlog, Tc: allenDynes(lambda, wlog, mu) };
  }
  const api = { allenDynes, mcmillan, MATERIALS, phononMoments, fromLab };
  if (typeof module !== "undefined") module.exports = api; else root.SCTc = api;
  if (typeof require !== "undefined" && typeof module !== "undefined" && require.main === module) {
    console.log("material\tlambda\tomega_log_K\tTc_measured\tTc_AllenDynes_mu0.10\tTc_AllenDynes_mu0.13");
    for (const m of MATERIALS) console.log([m.name, m.lambda, m.wlog, m.Tc, allenDynes(m.lambda, m.wlog, 0.10).toFixed(2), allenDynes(m.lambda, m.wlog, 0.13).toFixed(2)].join("\t"));
  }
})(this);

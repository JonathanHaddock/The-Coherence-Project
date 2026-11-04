//! Lepton universality: are electrons, muons and taus identical by force?
//!
//! The CMS open-data files are outreach subsets capped at fixed event
//! counts, with no published efficiencies for their selections, so their
//! event counts cannot be compared. Efficiency-corrected comparisons come
//! from published measurements:
//!
//! - CMS, JHEP 10 (2011) 132, arXiv:1107.4789 (2010 data, 36 pb^-1):
//!   sigma(pp -> Z) x B(Z -> ll), 60 < m < 120 GeV, each channel corrected
//!   for its own acceptance and efficiency. Luminosity cancels in the ratio.
//! - LEP Z partial widths (PDG): the direct, most precise test.

const std = @import("std");

pub const Measurement = struct {
    value: f64,
    stat: f64,
    syst: f64,
    theory: f64,
    lumi: f64,
};

/// CMS sigma x B in nb (arXiv:1107.4789, Section 10).
pub const cms_ee: Measurement = .{ .value = 0.992, .stat = 0.011, .syst = 0.018, .theory = 0.016, .lumi = 0.040 };
pub const cms_mumu: Measurement = .{ .value = 0.968, .stat = 0.008, .syst = 0.007, .theory = 0.018, .lumi = 0.039 };

/// CMS acceptance and electron efficiency for context (same paper, Tables 1 and 4).
pub const cms_acceptance_ee = 0.3876;
pub const cms_acceptance_mumu = 0.3978;
pub const cms_efficiency_ee = 0.609; // +- 0.011, relative to both electrons in ECAL acceptance

/// LEP Z partial widths in MeV, without assuming universality.
pub const lep_ee = [2]f64{ 83.90, 0.12 };
pub const lep_mumu = [2]f64{ 83.96, 0.18 };
pub const lep_tautau = [2]f64{ 84.05, 0.22 };
pub const lep_mumu_over_ee = [2]f64{ 1.0009, 0.0028 };

pub const Ratio = struct { value: f64, err_no_theory: f64, err_all: f64 };

/// sigma(ee) / sigma(mumu). Luminosity cancels; theory errors are treated
/// as uncorrelated (conservative, since part of them is common).
pub fn cmsRatio() Ratio {
    const r = cms_ee.value / cms_mumu.value;
    const rel = struct {
        fn sq(m: Measurement, comptime field: []const u8) f64 {
            const x = @field(m, field) / m.value;
            return x * x;
        }
    }.sq;
    const no_th = rel(cms_ee, "stat") + rel(cms_ee, "syst") + rel(cms_mumu, "stat") + rel(cms_mumu, "syst");
    const all = no_th + rel(cms_ee, "theory") + rel(cms_mumu, "theory");
    return .{ .value = r, .err_no_theory = r * @sqrt(no_th), .err_all = r * @sqrt(all) };
}

test "CMS ratio is consistent with one" {
    const r = cmsRatio();
    try std.testing.expectApproxEqAbs(1.0248, r.value, 0.0005);
    try std.testing.expect(@abs(r.value - 1) < 2 * r.err_all);
}

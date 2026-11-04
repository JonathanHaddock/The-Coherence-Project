//! `origin export`: write ORIGIN's derived datasets as CSV with a manifest.
//!
//!   dilepton-events.csv        one row per collision, every verified dataset
//!   z-ee-vs-mumu.csv           Z -> ee and Z -> mumu mass spectra, 0.5 GeV bins
//!   z-ee-vs-mumu-summary.csv   peak mass, width and counts per lepton
//!   selection.csv              selection and weighting per entity and variant
//!   MANIFEST.txt               rows, bytes and adler32 for each file, plus sources

const std = @import("std");
const Io = std.Io;
const store = @import("store.zig");
const events = @import("events.zig");
const spectrum = @import("../analysis/spectrum.zig");
const selection = @import("../analysis/selection.zig");

pub const out_dir = "datasets";

const Written = struct { name: []const u8, rows: usize, bytes: usize, adler32: u32 };

fn save(io: Io, gpa: std.mem.Allocator, list: *std.ArrayList(Written), name: []const u8, data: []const u8, rows: usize) !void {
    const path = try std.fmt.allocPrint(gpa, "{s}/{s}", .{ out_dir, name });
    defer gpa.free(path);
    try Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = data });
    try list.append(gpa, .{ .name = name, .rows = rows, .bytes = data.len, .adler32 = std.hash.Adler32.hash(data) });
    std.debug.print("  wrote {s:<28} {d:>8} rows {d:>10} bytes\n", .{ name, rows, data.len });
}

pub const ZSummary = struct {
    lepton: []const u8,
    events: usize,
    opposite: usize,
    in_window: usize,
    peak: f64,
    fwhm: f64,
    mean: f64,
};

/// Peak and full width at half maximum from 0.25 GeV bins in 80-100 GeV.
fn zSummary(lepton: []const u8, total: usize, masses: []const f64) ZSummary {
    var opposite_in: usize = 0;
    var sum: f64 = 0;
    var bins: [80]u32 = @splat(0);
    for (masses) |m| {
        if (m >= 60 and m < 120) opposite_in += 1;
        if (m >= 81 and m < 101) sum += m;
        if (m >= 80 and m < 100) bins[@intFromFloat((m - 80) / 0.25)] += 1;
    }
    var in_mean: usize = 0;
    for (masses) |m| {
        if (m >= 81 and m < 101) in_mean += 1;
    }
    const sorted_peak = spectrum.findPeak(masses, 91.19, 0.04);
    // Smooth over 3 bins, then find the half-maximum crossings.
    var smooth: [80]f64 = undefined;
    var top: f64 = 0;
    var top_i: usize = 0;
    for (0..80) |i| {
        const a = if (i > 0) bins[i - 1] else bins[i];
        const c = if (i < 79) bins[i + 1] else bins[i];
        smooth[i] = (@as(f64, @floatFromInt(a)) + @as(f64, @floatFromInt(bins[i])) + @as(f64, @floatFromInt(c))) / 3;
        if (smooth[i] > top) {
            top = smooth[i];
            top_i = i;
        }
    }
    var lo = top_i;
    while (lo > 0 and smooth[lo] > top / 2) lo -= 1;
    var hi = top_i;
    while (hi < 79 and smooth[hi] > top / 2) hi += 1;
    return .{
        .lepton = lepton,
        .events = total,
        .opposite = masses.len,
        .in_window = opposite_in,
        .peak = if (sorted_peak) |p| p.mass else 0,
        .fwhm = @as(f64, @floatFromInt(hi - lo)) * 0.25,
        .mean = if (in_mean > 0) sum / @as(f64, @floatFromInt(in_mean)) else 0,
    };
}

pub fn run(io: Io, gpa: std.mem.Allocator) !void {
    try Io.Dir.cwd().createDirPath(io, out_dir);
    var written: std.ArrayList(Written) = .empty;
    defer written.deinit(gpa);

    var cat = try store.Catalogue.load(io, gpa);
    defer cat.deinit();

    // 1. Per-event table across every verified dataset.
    var ev_csv: std.Io.Writer.Allocating = .init(gpa);
    defer ev_csv.deinit();
    const w = &ev_csv.writer;
    try w.print("dataset,lepton,run,event,q1,pt1,eta1,phi1,q2,pt2,eta2,phi2,mass,pair_pt,pair_rapidity\n", .{});
    var rows: usize = 0;
    var sources: std.ArrayList(u8) = .empty;
    defer sources.deinit(gpa);

    var z_ee: std.ArrayList(f64) = .empty;
    defer z_ee.deinit(gpa);
    var z_mm: std.ArrayList(f64) = .empty;
    defer z_mm.deinit(gpa);
    var ee_total: usize = 0;
    var mm_total: usize = 0;

    for (cat.entries) |entry| {
        const evs = store.loadEvents(io, gpa, entry) catch |err| switch (err) {
            error.DatasetMissing, error.DatasetCorrupt => {
                std.debug.print("  skipped {s} ({s}); run scripts/fetch.sh\n", .{ entry.name, @errorName(err) });
                continue;
            },
            else => return err,
        };
        defer gpa.free(evs);
        const stem = entry.name[0 .. std.mem.lastIndexOfScalar(u8, entry.name, '.') orelse entry.name.len];
        const lepton = store.leptonName(entry.name);
        try sources.print(gpa, "  {s} ({d} bytes, adler32 {x:0>8}) {s}\n", .{ entry.name, entry.size, entry.adler32, entry.url });
        for (evs) |ev| {
            const pair = ev.mu1.p.add(ev.mu2.p);
            try w.print("{s},{s},{d},{d},{d},{d:.4},{d:.4},{d:.4},{d},{d:.4},{d:.4},{d:.4},{d:.4},{d:.4},{d:.4}\n", .{
                stem,                lepton,              ev.run,                ev.event,
                ev.mu1.charge,       ev.mu1.p.pt(),       ev.mu1.p.eta(),        ev.mu1.p.phi(),
                ev.mu2.charge,       ev.mu2.p.pt(),       ev.mu2.p.eta(),        ev.mu2.p.phi(),
                pair.mass(),         pair.pt(),           pair.rapidity(),
            });
            rows += 1;
        }
        // Collect the two Z samples for the comparison.
        const is_ee = std.mem.eql(u8, stem, "Zee");
        const is_mm = std.mem.eql(u8, stem, "Zmumu");
        if (is_ee or is_mm) {
            const list = if (is_ee) &z_ee else &z_mm;
            if (is_ee) ee_total = evs.len else mm_total = evs.len;
            for (evs) |ev| {
                if (ev.oppositeCharge()) try list.append(gpa, ev.mass());
            }
        }
    }
    try save(io, gpa, &written, "dilepton-events.csv", ev_csv.written(), rows);

    // 3. Z -> ee vs Z -> mumu.
    std.mem.sort(f64, z_ee.items, {}, std.sort.asc(f64));
    std.mem.sort(f64, z_mm.items, {}, std.sort.asc(f64));
    var z_csv: std.Io.Writer.Allocating = .init(gpa);
    defer z_csv.deinit();
    try z_csv.writer.print("mass_lo_gev,mass_hi_gev,ee_events,mumu_events\n", .{});
    var b: usize = 0;
    while (b < 120) : (b += 1) {
        const lo = 60.0 + 0.5 * @as(f64, @floatFromInt(b));
        var ne: usize = 0;
        var nm: usize = 0;
        for (z_ee.items) |m| {
            if (m >= lo and m < lo + 0.5) ne += 1;
        }
        for (z_mm.items) |m| {
            if (m >= lo and m < lo + 0.5) nm += 1;
        }
        try z_csv.writer.print("{d:.1},{d:.1},{d},{d}\n", .{ lo, lo + 0.5, ne, nm });
    }
    try save(io, gpa, &written, "z-ee-vs-mumu.csv", z_csv.written(), 120);

    const se = zSummary("electron", ee_total, z_ee.items);
    const sm = zSummary("muon", mm_total, z_mm.items);
    var zs: std.Io.Writer.Allocating = .init(gpa);
    defer zs.deinit();
    try zs.writer.print("lepton,events,opposite_charge,in_60_120_gev,peak_gev,fwhm_gev,mean_81_101_gev\n", .{});
    for ([_]ZSummary{ se, sm }) |s| {
        try zs.writer.print("{s},{d},{d},{d},{d:.3},{d:.2},{d:.3}\n", .{ s.lepton, s.events, s.opposite, s.in_window, s.peak, s.fwhm, s.mean });
    }
    try save(io, gpa, &written, "z-ee-vs-mumu-summary.csv", zs.written(), 2);

    // 4. Selection and weighting.
    var sel: std.Io.Writer.Allocating = .init(gpa);
    defer sel.deinit();
    try sel.writer.print("scale,weak_definition,entity,em,weak,strong,selectivity,off_dominant_share,effective_forces\n", .{});
    var sel_rows: usize = 0;
    for (selection.scales) |sc| {
        for ([_]bool{ false, true }) |with_w| {
            for (std.enums.values(selection.Entity), selection.entity_names) |e, name| {
                const v = selection.vector(e, sc, with_w);
                try sel.writer.print("{s},{s},{s},{e:.5},{e:.5},{e:.5},{d:.4},{d:.4},{d:.3}\n", .{
                    sc.name, if (with_w) "Z+W" else "Z", name, v[0], v[1], v[2],
                    selection.selectivity(v), selection.offDominant(v), selection.effectiveForces(v),
                });
                sel_rows += 1;
            }
        }
    }
    try save(io, gpa, &written, "selection.csv", sel.written(), sel_rows);

    // Manifest.
    var man: std.Io.Writer.Allocating = .init(gpa);
    defer man.deinit();
    try man.writer.print(
        \\# ORIGIN derived datasets. Regenerate with: origin export
        \\# file                       rows      bytes   adler32
        \\
    , .{});
    for (written.items) |f| try man.writer.print("{s:<28} {d:>8} {d:>10}  {x:0>8}\n", .{ f.name, f.rows, f.bytes, f.adler32 });
    try man.writer.print(
        \\
        \\# Sources (CMS Run2011A, CERN Open Data record 545, CC0; verified by adler32):
        \\{s}
        \\# selection.csv: PDG 2024 couplings, sin^2(theta_W) = 0.23129 (MS-bar, m_Z).
        \\# Z comparison: electrons are measured by the calorimeter, muons by the
        \\# tracker and muon chambers, with different selections; compare peak
        \\# positions, not event counts or widths, without efficiency corrections.
        \\
    , .{sources.items});
    const mpath = out_dir ++ "/MANIFEST.txt";
    try Io.Dir.cwd().writeFile(io, .{ .sub_path = mpath, .data = man.written() });
    std.debug.print("  wrote MANIFEST.txt\n\n", .{});

    std.debug.print(
        \\Z -> ee vs Z -> mumu (opposite charge)
        \\  {s:<9} {s:>8} {s:>12} {s:>10} {s:>9} {s:>12}
        \\
    , .{ "LEPTON", "EVENTS", "IN 60-120", "PEAK GeV", "FWHM", "MEAN 81-101" });
    for ([_]ZSummary{ se, sm }) |s| {
        std.debug.print("  {s:<9} {d:>8} {d:>12} {d:>10.3} {d:>9.2} {d:>12.3}\n", .{ s.lepton, s.opposite, s.in_window, s.peak, s.fwhm, s.mean });
    }
    std.debug.print("  peak difference (e - mu): {d:.3} GeV\n", .{se.peak - sm.peak});
}

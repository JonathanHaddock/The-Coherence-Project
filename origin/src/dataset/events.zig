const std = @import("std");
const kinematics = @import("../analysis/kinematics.zig");
const FourVector = kinematics.FourVector;

pub const Muon = struct {
    p: FourVector,
    charge: i8,
};

pub const DimuonEvent = struct {
    run: u64,
    event: u64,
    mu1: Muon,
    mu2: Muon,

    pub fn mass(self: DimuonEvent) f64 {
        return self.mu1.p.add(self.mu2.p).mass();
    }

    pub fn oppositeCharge(self: DimuonEvent) bool {
        return self.mu1.charge != self.mu2.charge;
    }
};

const max_columns = 32;

/// Column positions for one muon. Energy and momentum components are used
/// when the file provides them; otherwise momentum is reconstructed from
/// (pt, eta, phi) with the muon mass.
const MuonColumns = struct {
    e: ?usize,
    px: ?usize,
    py: ?usize,
    pz: ?usize,
    pt: usize,
    eta: usize,
    phi: usize,
    q: usize,

    fn find(header: []const []const u8, comptime n: []const u8) !MuonColumns {
        return .{
            .e = index(header, "E" ++ n),
            .px = index(header, "px" ++ n),
            .py = index(header, "py" ++ n),
            .pz = index(header, "pz" ++ n),
            .pt = index(header, "pt" ++ n) orelse return error.MissingColumn,
            .eta = index(header, "eta" ++ n) orelse return error.MissingColumn,
            .phi = index(header, "phi" ++ n) orelse return error.MissingColumn,
            .q = index(header, "Q" ++ n) orelse return error.MissingColumn,
        };
    }

    fn read(c: MuonColumns, row: []const []const u8) !Muon {
        const p = if (c.e != null and c.px != null and c.py != null and c.pz != null) FourVector{
            .e = try float(row[c.e.?]),
            .px = try float(row[c.px.?]),
            .py = try float(row[c.py.?]),
            .pz = try float(row[c.pz.?]),
        } else FourVector.fromPtEtaPhi(
            try float(row[c.pt]),
            try float(row[c.eta]),
            try float(row[c.phi]),
            kinematics.muon_mass_gev,
        );
        return .{ .p = p, .charge = try std.fmt.parseInt(i8, row[c.q], 10) };
    }
};

fn index(header: []const []const u8, name: []const u8) ?usize {
    for (header, 0..) |column, i| {
        if (std.mem.eql(u8, column, name)) return i;
    }
    return null;
}

fn float(text: []const u8) !f64 {
    return std.fmt.parseFloat(f64, text);
}

fn splitRow(line: []const u8, out: *[max_columns][]const u8) ![]const []const u8 {
    var n: usize = 0;
    var fields = std.mem.splitScalar(u8, line, ',');
    while (fields.next()) |field| : (n += 1) {
        if (n == max_columns) return error.TooManyColumns;
        out[n] = std.mem.trim(u8, field, " \r");
    }
    return out[0..n];
}

/// Parse a CMS open-data dimuon CSV into events.
pub fn parse(gpa: std.mem.Allocator, text: []const u8) ![]DimuonEvent {
    var lines = std.mem.splitScalar(u8, text, '\n');

    var header_buf: [max_columns][]const u8 = undefined;
    const header = try splitRow(lines.next() orelse return error.EmptyFile, &header_buf);
    const run_col = index(header, "Run") orelse return error.MissingColumn;
    const event_col = index(header, "Event") orelse return error.MissingColumn;
    const c1 = try MuonColumns.find(header, "1");
    const c2 = try MuonColumns.find(header, "2");

    var events: std.ArrayList(DimuonEvent) = .empty;
    errdefer events.deinit(gpa);

    var row_buf: [max_columns][]const u8 = undefined;
    while (lines.next()) |line| {
        if (std.mem.trim(u8, line, " \r").len == 0) continue;
        const row = try splitRow(line, &row_buf);
        if (row.len != header.len) return error.RaggedRow;
        try events.append(gpa, .{
            .run = try std.fmt.parseInt(u64, row[run_col], 10),
            .event = try std.fmt.parseInt(u64, row[event_col], 10),
            .mu1 = try c1.read(row),
            .mu2 = try c2.read(row),
        });
    }
    return events.toOwnedSlice(gpa);
}

test "parses both CSV layouts to the same mass" {
    // The same Z candidate written with and without explicit four-momenta.
    const with_p4 =
        \\Run,Event,type1,E1,px1,py1,pz1,pt1,eta1,phi1,Q1,type2,E2,px2,py2,pz2,pt2,eta2,phi2,Q2
        \\1,2,G,45.0,30.0,0.0,33.541,30.0,0.9624,0.0,1,G,45.0,-30.0,0.0,-33.541,30.0,-0.9624,3.14159265,-1
    ;
    const pt_only =
        \\Run,Event,pt1,eta1,phi1,Q1,pt2,eta2,phi2,Q2
        \\1,2,30.0,0.9624,0.0,1,30.0,-0.9624,3.14159265,-1
    ;
    const a = try parse(std.testing.allocator, with_p4);
    defer std.testing.allocator.free(a);
    const b = try parse(std.testing.allocator, pt_only);
    defer std.testing.allocator.free(b);

    try std.testing.expect(a[0].oppositeCharge());
    try std.testing.expectApproxEqAbs(90.0, a[0].mass(), 0.01);
    try std.testing.expectApproxEqAbs(a[0].mass(), b[0].mass(), 0.01);
}

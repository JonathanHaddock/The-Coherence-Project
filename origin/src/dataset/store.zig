const std = @import("std");
const Io = std.Io;
const manifest = @import("manifest.zig");
const events = @import("events.zig");
const kinematics = @import("../analysis/kinematics.zig");

pub const manifests_dir = "data/manifests";
pub const raw_dir = "data/raw";
pub const results_dir = "results";

/// Largest dataset file ORIGIN will load into memory.
const max_file_bytes = 256 * 1024 * 1024;

pub const Status = enum { ok, missing, wrong_size, bad_checksum };

pub const Check = struct {
    entry: manifest.Entry,
    status: Status,
    actual_size: u64 = 0,
    actual_adler32: u32 = 0,
};

/// All manifest entries from every file in data/manifests/. The returned
/// arena owns the entries; call deinit on it when done.
pub const Catalogue = struct {
    arena: std.heap.ArenaAllocator,
    entries: []manifest.Entry,

    pub fn load(io: Io, gpa: std.mem.Allocator) !Catalogue {
        var arena: std.heap.ArenaAllocator = .init(gpa);
        errdefer arena.deinit();
        const a = arena.allocator();

        var dir = try Io.Dir.cwd().openDir(io, manifests_dir, .{ .iterate = true });
        defer dir.close(io);

        var all: std.ArrayList(manifest.Entry) = .empty;
        var it = dir.iterate();
        while (try it.next(io)) |file| {
            if (file.kind != .file or !std.mem.endsWith(u8, file.name, ".txt")) continue;
            const text = try dir.readFileAlloc(io, file.name, a, .limited(1024 * 1024));
            try all.appendSlice(a, try manifest.parse(a, text));
        }
        return .{ .arena = arena, .entries = all.items };
    }

    pub fn find(self: Catalogue, name: []const u8) ?manifest.Entry {
        for (self.entries) |e| {
            if (std.ascii.eqlIgnoreCase(e.name, name)) return e;
            // Allow the name without its extension: "Zmumu" for "Zmumu.csv".
            const stem = e.name[0 .. std.mem.lastIndexOfScalar(u8, e.name, '.') orelse e.name.len];
            if (std.ascii.eqlIgnoreCase(stem, name)) return e;
        }
        return null;
    }

    pub fn deinit(self: *Catalogue) void {
        self.arena.deinit();
    }
};

/// Read a raw dataset file. Caller frees.
pub fn readRaw(io: Io, gpa: std.mem.Allocator, name: []const u8) ![]u8 {
    var dir = try Io.Dir.cwd().openDir(io, raw_dir, .{});
    defer dir.close(io);
    return dir.readFileAlloc(io, name, gpa, .limited(max_file_bytes));
}

/// Integrity verification: compare a downloaded file against the size and
/// adler32 checksum published by its source.
pub fn verify(io: Io, gpa: std.mem.Allocator, entry: manifest.Entry) !Check {
    const bytes = readRaw(io, gpa, entry.name) catch |err| switch (err) {
        error.FileNotFound => return .{ .entry = entry, .status = .missing },
        else => return err,
    };
    defer gpa.free(bytes);

    var check: Check = .{
        .entry = entry,
        .status = .ok,
        .actual_size = bytes.len,
        .actual_adler32 = std.hash.Adler32.hash(bytes),
    };
    if (check.actual_size != entry.size) {
        check.status = .wrong_size;
    } else if (check.actual_adler32 != entry.adler32) {
        check.status = .bad_checksum;
    }
    return check;
}

/// Load and verify a dataset, then parse its events. Caller frees the slice.
pub fn loadEvents(io: Io, gpa: std.mem.Allocator, entry: manifest.Entry) ![]events.DimuonEvent {
    const check = try verify(io, gpa, entry);
    switch (check.status) {
        .ok => {},
        .missing => return error.DatasetMissing,
        .wrong_size, .bad_checksum => return error.DatasetCorrupt,
    }
    const bytes = try readRaw(io, gpa, entry.name);
    defer gpa.free(bytes);
    return events.parseLeptons(gpa, bytes, leptonMass(entry.name));
}

/// Electron datasets (Zee) need the electron mass; the rest are dimuon.
pub fn leptonMass(name: []const u8) f64 {
    return if (std.mem.startsWith(u8, name, "Zee")) kinematics.electron_mass_gev else kinematics.muon_mass_gev;
}

pub fn leptonName(name: []const u8) []const u8 {
    return if (std.mem.startsWith(u8, name, "Zee")) "electron" else "muon";
}

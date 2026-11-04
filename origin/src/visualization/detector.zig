const std = @import("std");

pub fn generate(allocator: std.mem.Allocator) ![]u8 {
    return std.fmt.allocPrint(allocator,
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<svg xmlns="http://www.w3.org/2000/svg"
        \\ width="1000" height="760" viewBox="0 0 1000 760">
        \\<rect width="1000" height="760" fill="#080d18"/>
        \\<text x="500" y="42" fill="#ffffff"
        \\ font-size="26" text-anchor="middle"
        \\ font-family="monospace">ORIGIN — PARTICLE EVENT DISPLAY</text>
        \\<text x="500" y="70" fill="#8ca5c5"
        \\ font-size="13" text-anchor="middle"
        \\ font-family="monospace">SIMULATED COLLISION EVENT 000001</text>
        \\
        \\<g transform="translate(500 390)">
        \\<circle r="270" fill="none" stroke="#35465d" stroke-width="2"/>
        \\<circle r="215" fill="none" stroke="#35465d" stroke-width="2"/>
        \\<circle r="145" fill="none" stroke="#35465d" stroke-width="2"/>
        \\<circle r="75" fill="none" stroke="#35465d" stroke-width="2"/>
        \\
        \\<circle r="270" fill="none" stroke="#26364a" stroke-dasharray="4 8"/>
        \\<circle r="215" fill="none" stroke="#26364a" stroke-dasharray="4 8"/>
        \\
        \\<path d="M-290 0 H290 M0 -290 V290"
        \\ stroke="#26364a" stroke-width="1"/>
        \\
        \\<circle r="7" fill="#ffffff"/>
        \\<circle r="15" fill="none" stroke="#ffffff"
        \\ stroke-width="1.5"/>
        \\
        \\<path d="M0 0 Q65 -65 115 -220"
        \\ fill="none" stroke="#ff5252" stroke-width="3"/>
        \\<path d="M0 0 Q-75 -80 -245 -105"
        \\ fill="none" stroke="#42a5f5" stroke-width="3"/>
        \\<path d="M0 0 Q95 35 255 100"
        \\ fill="none" stroke="#66bb6a" stroke-width="3"/>
        \\<path d="M0 0 Q-45 95 -120 245"
        \\ fill="none" stroke="#ffca28" stroke-width="3"/>
        \\<path d="M0 0 Q-100 15 -265 25"
        \\ fill="none" stroke="#ab47bc" stroke-width="3"/>
        \\<path d="M0 0 L185 -185"
        \\ fill="none" stroke="#26c6da" stroke-width="3"
        \\ stroke-dasharray="9 5"/>
        \\
        \\<circle cx="115" cy="-220" r="5" fill="#ff5252"/>
        \\<circle cx="-245" cy="-105" r="5" fill="#42a5f5"/>
        \\<circle cx="255" cy="100" r="5" fill="#66bb6a"/>
        \\<circle cx="-120" cy="245" r="5" fill="#ffca28"/>
        \\<circle cx="-265" cy="25" r="5" fill="#ab47bc"/>
        \\<circle cx="185" cy="-185" r="5" fill="#26c6da"/>
        \\</g>
        \\
        \\<g font-family="monospace" font-size="15">
        \\<text x="55" y="715" fill="#ff5252">RED — ELECTRON</text>
        \\<text x="290" y="715" fill="#42a5f5">BLUE — MUON</text>
        \\<text x="500" y="715" fill="#66bb6a">GREEN — PROTON</text>
        \\<text x="55" y="740" fill="#ffca28">YELLOW — TAU</text>
        \\<text x="290" y="740" fill="#ab47bc">PURPLE — NEUTRON</text>
        \\<text x="590" y="740" fill="#26c6da">CYAN — PHOTON</text>
        \\</g>
        \\</svg>
    , .{});
}

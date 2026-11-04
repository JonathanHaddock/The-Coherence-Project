# ORIGIN

A terminal particle observation engine written in Zig (0.17). It is the
computational side of The Coherence Project; see `../Lepton coherence` for the
Koide-relation hypothesis it is built to test.

## Build

```sh
zig build          # binary at zig-out/bin/origin
zig build test     # unit tests
```

## Commands

| Command | Status |
|---|---|
| `origin info` | System and module status |
| `origin catalogue` | The 6 registered particles |
| `origin constants` | CODATA physical constants |
| `origin observe <particle>` | Mass, charge, class (name or symbol, any case) |
| `origin koide` | Koide ratio Q for e, mu, tau and its angle to (1,1,1) |
| `origin science` | Unit system demo |
| `origin dataset` | Not implemented |
| `origin analyze` | Placeholder |

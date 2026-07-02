# Changelog

## 2.0.0

Major rewrite: pure Swift, `UInt64`-packed. See [MIGRATION.md](MIGRATION.md)
for the full old→new mapping.

### Changed

- **Breaking:** `Geohash` is now a packed value type (`Hashable`, `Sendable`,
  `Codable`) replacing the `String`-based static API. The `LengthedGeohash`
  family keeps its 1.x shape (plus a new `Geohash12`) but wraps the packed
  type and follows the new neighbor semantics: optional pole-facing
  neighbors and an 8-direction `Direction`. Its coordinate and string
  initializers remain non-failable and trap on invalid input, as in 1.x;
  the new failable `init?(_ geohash:)` is the non-trapping path.
- **Breaking:** canonical `>=` boundary rule — a coordinate exactly on a cell
  boundary now belongs to the higher cell, matching every mainstream
  implementation. 1.x used `>`. Only exactly grid-aligned coordinates are
  affected.
- **Breaking:** latitude no longer wraps at the poles: `neighbor(.north)` on
  a top-row cell is `nil` (1.x returned a geometrically meaningless
  bottom-row cell). Longitude still wraps at the antimeridian.
- **Breaking:** invalid coordinates, lengths, or strings return `nil`
  instead of trapping.
- **Breaking:** geohash length is capped at 12 (~3.7 cm cells); 1.x allowed
  up to 22.
- `hashesForRegion` is now `Geohash.cells(intersecting:latitudeDelta:longitudeDelta:length:)`
  and returns packed values. Unlike 1.x it caps the result size (`maxCells:`
  parameter, default 10,000) and returns an empty array beyond it, instead
  of attempting a multi-million-cell allocation for oversized boxes.

### Removed

- The `FlitsGeohashC` target. The package is now a single pure-Swift target.

### Performance

Measured on Apple Silicon, release build (v1 numbers include the mandatory
C-boundary bridging cost):

| Operation (length 7) | 1.x | 2.0 |
|---|---|---|
| Encode → `Geohash` | 231 ns (String) | ~12 ns |
| Neighbor | 223 ns | ~5 ns |
| Encode → `String` | 231 ns | ~37 ns |

All non-`String` operations perform zero heap allocations. Gates are
enforced in CI via `swift run -c release Benchmarks enforce`.

### Compatibility

- 2.0 output is bit-for-bit identical to 1.x on 108,000 committed golden
  fixtures (random global coordinates, lengths 1–12, neighbors, regions),
  which exclude the documented boundary and pole cases by construction.
- `Codable` encodes as the base32 string, so wire formats are unchanged.

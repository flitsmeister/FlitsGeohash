# Migrating from FlitsGeohash 1.x to 2.0

FlitsGeohash 2.0 replaces the C-backed, `String`-based implementation with a
pure Swift `Geohash` value type packed into a single `UInt64`. Encoding a
coordinate dropped from ~231 ns to ~12 ns, a neighbor lookup from ~223 ns to
~5 ns, and all non-`String` operations are allocation-free.

The intended usage change: **stop passing geohash strings around.** Keep
`Geohash` values everywhere — dictionary keys, sets, comparisons — and only
call `.string` at the edges of your system (persistence, wire formats,
logging).

## API mapping

| 1.x | 2.0 |
|---|---|
| `Geohash.hash(coordinate, length: 7)` | `Geohash(coordinate, length: 7)?.string` — or keep the `Geohash` value |
| `coordinate.geohash(length: 7)` | `coordinate.geohash(length: 7)?.string` |
| `Geohash.adjacent(hash: s, direction: .north)` | `Geohash(string: s)?.neighbor(.north)` |
| `Geohash.neighbors(hash: s)` | `Geohash(string: s)?.neighbors()` |
| `neighbors.allNeighbors(and: hash)` | `geohash.allNeighborsAndSelf()` |
| `Geohash.hashesForRegion(centerCoordinate:latitudeDelta:longitudeDelta:length:)` | `Geohash.cells(intersecting:latitudeDelta:longitudeDelta:length:)` — result size now capped (`maxCells:`, default 10,000; `[]` beyond it) |
| `Geohash7(coordinate)`, `LengthedGeohash<...>` | `Geohash(coordinate, length: 7)` — the packed type replaces the typed-length family |
| `lengthed.toLowerLength()` | `geohash.prefix(shorterLength)` |
| `Geohash.Direction` (4 cardinal cases) | `Geohash.Direction` (8 cases, including diagonals) |

`Geohash` is `Hashable`, `Sendable`, and `Codable` (encoded as its base32
string, so JSON payloads are wire-compatible with 1.x strings).

## Behavioral changes

### Boundary rule: `>` becomes `>=` (canonical)

1.x assigned a coordinate lying exactly on a cell boundary to the *lower*
cell (`>` semantics, an idiosyncrasy of the bundled C library). 2.0 adopts
the canonical rule used by every mainstream implementation: a coordinate on
a boundary belongs to the **higher** cell (floor semantics).

Example: `(0, 0)` now encodes to `"s000…"` (previously `"7zzz…"`).

Real-world coordinates from GPS or map interactions are effectively never
exactly on a cell boundary (a 200k-coordinate fuzz found zero such cases);
only grid-aligned synthetic data is affected.

### Latitude no longer wraps at the poles

1.x "wrapped" latitude: the north neighbor of a top-row cell like `"zzzz"`
came back as a bottom-row cell — geometrically meaningless. In 2.0,
`neighbor(.north)` on a top-row cell returns `nil`, as do the diagonals
involving that edge. `Neighbors` has optional `north`/`south`/diagonal
fields, and `allNeighborsAndSelf()` simply omits absent cells (6 elements in
a pole row instead of 9).

Longitude still wraps at the antimeridian: `east` and `west` always exist.

### Invalid input returns `nil` instead of trapping

1.x called `precondition` on an invalid coordinate or length — a crash on
data-driven input. 2.0's initializers are failable: `Geohash(coordinate,
length:)` and `Geohash(string:)` return `nil` for out-of-range coordinates,
lengths outside `1...12`, or malformed strings. `Geohash.cells(intersecting:)`
returns `[]` for invalid input.

### Length is capped at 12

1.x accepted lengths up to 22. Length 12 already resolves to ~3.7 cm cells;
longer hashes served no purpose and do not fit the packed representation.

## Removed

- The `FlitsGeohashC` target (no more C interop; trivially portable to Linux).
- `LengthedGeohash`, `GeohashLengthed`, `GeohashLength1...11`, and the
  `Geohash1...11` type aliases.
- The `String`-based static API on `Geohash`.

## Adoption notes for consumers

Consumers pin exact versions, so nothing changes until you opt in to 2.0.
When you do, prefer storing `Geohash` values directly: they are 8-byte
`Hashable` keys whose equality and hashing are single integer operations,
and geohashes of different lengths never collide. Caches built to avoid the
cost of 1.x neighbor lookups can usually be deleted — computing a neighbor
is now cheaper than a dictionary hit.

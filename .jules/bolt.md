## 2025-05-15 - [MazeBuilder Optimization]
**Learning:** The `MazeBuilder` expansion loop was performing redundant table rotations and bitmask calculations in each iteration, resulting in significant allocation overhead and O(N) search complexity.
**Action:** Pre-calculate all 6 rotated variants (including door masks and sorted direction lists) of each room prefab type at module initialization. This allows the generator to use O(1) bitwise operations and O(1) table lookups in the main expansion loop, reducing generation time by ~60%.

## 2025-05-16 - [Spatial Hash Room Lookup]
**Learning:** O(N) linear search for spatial queries (like `findRoomByPosition`) is a major bottleneck as the maze size grows. Using a grid-based spatial hash with bit-packed numeric keys (`bit32.bor`) provides O(1) average lookup and avoids string/Vector3 allocations. A 3x3 neighborhood search is required to maintain correctness when the detection radius approaches the cell size.
**Action:** Implement a spatial hash for all position-based entity lookups in rendering or runtime logic. Use numeric bit-packed keys for grid coordinates to minimize GC pressure in Luau.

## 2025-05-17 - [Hex Tiling Optimization]
**Learning:** High-frequency procedural geometry loops (like hex tiling) suffer significantly from `Vector3` and table allocations in Luau. Unrolling loops and using pure numeric coordinates with pre-calculated normals can yield a >15x speedup. Selene's `if_same_then_else` rule requires combining identical conditional branches using logical `or` to maintain clean linting.
**Action:** Always prefer numeric coordinate math over `Vector3` methods in tight loops. Pre-calculate constant math expressions (e.g., `math.tan(math.pi / 6)`) and hex normals at the module level.

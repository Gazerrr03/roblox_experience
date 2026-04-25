## 2025-05-15 - [MazeBuilder Optimization]
**Learning:** The `MazeBuilder` expansion loop was performing redundant table rotations and bitmask calculations in each iteration, resulting in significant allocation overhead and O(N) search complexity.
**Action:** Pre-calculate all 6 rotated variants (including door masks and sorted direction lists) of each room prefab type at module initialization. This allows the generator to use O(1) bitwise operations and O(1) table lookups in the main expansion loop, reducing generation time by ~60%.

## 2025-05-16 - [Spatial Hash Room Lookup]
**Learning:** O(N) linear search for spatial queries (like `findRoomByPosition`) is a major bottleneck as the maze size grows. Using a grid-based spatial hash with bit-packed numeric keys (`bit32.bor`) provides O(1) average lookup and avoids string/Vector3 allocations. A 3x3 neighborhood search is required to maintain correctness when the detection radius approaches the cell size.
**Action:** Implement a spatial hash for all position-based entity lookups in rendering or runtime logic. Use numeric bit-packed keys for grid coordinates to minimize GC pressure in Luau.

## 2025-05-17 - [Hex Tiling Optimization]
**Learning:** High-frequency procedural geometry loops (like hex tiling) suffer significantly from `Vector3` and table allocations in Luau. Unrolling loops and using pure numeric coordinates with pre-calculated normals can yield a >15x speedup. Selene's `if_same_then_else` rule requires combining identical conditional branches using logical `or` to maintain clean linting.
**Action:** Always prefer numeric coordinate math over `Vector3` methods in tight loops. Pre-calculate constant math expressions (e.g., `math.tan(math.pi / 6)`) and hex normals at the module level.

## 2026-04-11 - [Hex Tiling Math & Allocation Optimization]
**Learning:** Checking the 4 corners of a tile for hex containment is redundant. By utilizing hexagonal symmetry, a tile bounding-box can be verified against the hexagon using 3 directional bands and pre-calculated buffers. Inlining `Instance.new` calls in hot loops further reduces GC pressure by eliminating temporary configuration tables.
**Action:** Use the 3-band bounding-box check for tiling procedural geometry. Inline part creation in high-frequency loops to avoid table allocations.

## 2025-05-20 - [Hot Path Hoisting & Lookup Optimization]
**Learning:** In `HexMazeWorldRenderer.luau`, hoisting the X-axis containment check out of the inner loop in `createHexTiledSlab` provides a ~30% speedup by skipping entire rows of grid tiles. Additionally, replacing string-based doorway lookups with nested tables in `canTraverseBetweenPositions` avoids allocation overhead and string comparison costs, yielding a ~14% performance gain.
**Action:** Always hoist invariant condition checks out of nested loops. Prefer nested tables over string-concatenated keys for O(1) relationship lookups in high-frequency pathfinding/collision paths.

## 2025-05-20 - [Nested Table vs String Key Lookup]
**Learning:** In Luau, string concatenation (`..`) to create lookup keys in high-frequency functions (like `canTraverseBetweenPositions`) is a significant source of GC pressure and execution time. Replacing `map[idA .. '|' .. idB]` with a nested table `map[idA][idB]` eliminates all string allocations in the hot path.
**Action:** Prefer nested table lookups over concatenated string keys for frequently accessed 2D spatial or graph relationships.

## 2025-05-21 - [Hex Tiling Loop Bound Optimization]
**Learning:** In procedural geometry generation, iterating over a square bounding box and using conditional checks to fill a shape (like a hexagon) is inefficient. By solving the geometric inequalities to calculate precise loop bounds, we can eliminate all conditional branching in the inner loop and reduce total iterations to only the required set, yielding a ~7x performance gain in tiling logic.
**Action:** Always prefer calculating precise loop bounds for geometric fill operations over bounding-box-and-test approaches in performance-critical paths.

## 2026-04-25 - [Monster Logic & Perception Optimization]
**Learning:** High-frequency monster AI routines (10Hz) suffer from significant GC pressure and CPU overhead due to per-tick table allocations and redundant Vector3/Magnitude math. Reusing tables (with ) and switching to squared distance comparisons with numeric coordinate math (bypassing Vector3 metatables) yields substantial gains.
**Action:** Always implement table reuse for per-frame entity maps in AI components. Use squared distance and scalar coordinate math in hot-path spatial queries to avoid unnecessary object churn and square root calculations.

## 2026-04-25 - [Monster Logic & Perception Optimization]
**Learning:** High-frequency monster AI routines (10Hz) suffer from significant GC pressure and CPU overhead due to per-tick table allocations and redundant Vector3/Magnitude math. Reusing tables (with `table.clear`) and switching to squared distance comparisons with numeric coordinate math (bypassing Vector3 metatables) yields substantial gains.
**Action:** Always implement table reuse for per-frame entity maps in AI components. Use squared distance and scalar coordinate math in hot-path spatial queries to avoid unnecessary object churn and square root calculations.

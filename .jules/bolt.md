## 2025-05-15 - [MazeBuilder Optimization]
**Learning:** The `MazeBuilder` expansion loop was performing redundant table rotations and bitmask calculations in each iteration, resulting in significant allocation overhead and O(N) search complexity.
**Action:** Pre-calculate all 6 rotated variants (including door masks and sorted direction lists) of each room prefab type at module initialization. This allows the generator to use O(1) bitwise operations and O(1) table lookups in the main expansion loop, reducing generation time by ~60%.

## 2025-05-20 - [Spatial Hash Lookup Optimization]
**Learning:** The `HexMazeWorldRenderer` was performing O(N) linear searches across all rooms for every position-to-room lookup, causing significant overhead in worlds with many rooms or frequent proximity checks.
**Action:** Implement a grid-based spatial hash using bit-packed numeric keys (`bit32`) for O(1) cell lookups. This avoids string allocations and reduces search complexity. Use component-wise squared distance comparisons within the candidate cells to eliminate `Vector3` allocations and `math.sqrt` calls during the search loop.

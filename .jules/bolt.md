## 2025-05-15 - [MazeBuilder Optimization]
**Learning:** The `MazeBuilder` expansion loop was performing redundant table rotations and bitmask calculations in each iteration, resulting in significant allocation overhead and O(N) search complexity.
**Action:** Pre-calculate all 6 rotated variants (including door masks and sorted direction lists) of each room prefab type at module initialization. This allows the generator to use O(1) bitwise operations and O(1) table lookups in the main expansion loop, reducing generation time by ~60%.

## 2026-04-01 - [HexMazeWorldRenderer Spatial Hash]
**Learning:** The O(N) linear search in `findRoomByPosition` becomes a bottleneck as maze size increases. Implementing a grid-based spatial hash with bit-packed numeric keys provides a ~45x speedup for 500 rooms.
**Action:** Use spatial hashes for coordinate-based lookups. Ensure a 3x3 neighborhood search if the detection radius is close to the cell size to maintain correctness. Use squared distance comparisons to avoid `math.sqrt` and `Vector3` allocations in tight loops.

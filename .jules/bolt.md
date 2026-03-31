## 2025-05-15 - [MazeBuilder Optimization]
**Learning:** The `MazeBuilder` expansion loop was performing redundant table rotations and bitmask calculations in each iteration, resulting in significant allocation overhead and O(N) search complexity.
**Action:** Pre-calculate all 6 rotated variants (including door masks and sorted direction lists) of each room prefab type at module initialization. This allows the generator to use O(1) bitwise operations and O(1) table lookups in the main expansion loop, reducing generation time by ~60%.

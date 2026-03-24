## 2024-05-24 - Procedural Generation Optimization
**Learning:** High-frequency string allocations for table keys (e.g., `string.format("%d:%d", q, r)`) and redundant table rotations in tight loops are major bottlenecks in Luau procedural generation. Bitwise operations on integers are significantly more efficient than table-based sets for direction and connectivity checks.
**Action:** Use numeric hashing for spatial coordinates and pre-calculate all possible prefab variants (rotations/masks) at module load time to keep the generation loop allocation-free.

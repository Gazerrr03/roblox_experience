# Bolt's Journal - Critical Learnings

## 2025-01-24 - Procedural Generation Bottlenecks
**Learning:** Procedural generation algorithms in Luau often suffer from high GC pressure due to frequent string formatting for keys and table allocations for coordinates/directions.
**Action:** Use numeric bit-packed keys for spatial and state lookups. Pre-calculate immutable data structures like prefab variants during module initialization.

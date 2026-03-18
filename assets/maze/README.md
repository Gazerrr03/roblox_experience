# Maze Studio Asset Contract

The long-term source of truth for formal maze art lives in a Studio asset container.
Runtime generation owns placement, rotation, and interaction wiring. Art assets only
need to satisfy the stable module names below.

Required modules:

- `WallSegment`
- `DoorFrame`
- `DoorLeaf`
- `FloorPanel`
- `ExtractionMarker`

Rules:

- Build rooms from small boundary modules instead of one black-box room mesh.
- Keep pivots and anchor points stable so code can place modules deterministically.
- Missing modules or broken naming must fail loudly during build.
- Internal decoration is optional and can evolve later without changing the layout contract.

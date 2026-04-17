#!/usr/bin/env python3
import numpy as np
import trimesh
from PIL import Image
import os

# Load GLB mesh
glb_path = "/Users/qizhi_dong/Projects/roblox_experience/tmp/run-terrain/RunTerrain_OriginalHigh_Textured_Single.glb"
print(f"Loading {glb_path}...")
scene = trimesh.load(glb_path)

# Handle Scene vs Mesh
if isinstance(scene, trimesh.Scene):
    # Get all mesh data from scene
    all_vertices = []
    for name, mesh in scene.geometry.items():
        if isinstance(mesh, trimesh.Trimesh):
            print(f"  Found mesh: {name} with {len(mesh.vertices)} vertices")
            all_vertices.append(mesh.vertices)
    verts = np.vstack(all_vertices)
elif isinstance(scene, trimesh.Trimesh):
    verts = scene.vertices
else:
    print(f"Unknown type: {type(scene)}")
    exit(1)

print(f"Total vertices: {len(verts)}")

# Get bounds
x_min, x_max = verts[:, 0].min(), verts[:, 0].max()
y_min, y_max = verts[:, 1].min(), verts[:, 1].max()
z_min, z_max = verts[:, 2].min(), verts[:, 2].max()

print(f"Bounds: X[{x_min:.1f}, {x_max:.1f}], Y[{y_min:.1f}, {y_max:.1f}], Z[{z_min:.1f}, {z_max:.1f}]")
print(f"XZ span: {x_max-x_min:.0f}x{z_max-z_min:.0f}, Y range: {y_max-y_min:.0f}")

RES = 2048
x_span = x_max - x_min
z_span = z_max - z_min
y_range = y_max - y_min

# Build spatial hash grid (32x32 cells)
gs = max(x_span, z_span) / 32
gx_idx = ((verts[:, 0] - x_min) / gs).astype(int)
gz_idx = ((verts[:, 2] - z_min) / gs).astype(int)

hash_grid = {}
for i in range(len(verts)):
    key = (gx_idx[i], gz_idx[i])
    if key not in hash_grid:
        hash_grid[key] = []
    hash_grid[key].append(verts[i, 1])

def sample_height(px, pz):
    gx = int((px - x_min) / gs)
    gz = int((pz - z_min) / gs)
    best = y_min
    best_d = float('inf')
    for dx in [-1, 0, 1]:
        for dz in [-1, 0, 1]:
            key = (gx + dx, gz + dz)
            if key in hash_grid:
                for hy in hash_grid[key]:
                    d = (px - x_min - gx * gs) ** 2 + (pz - z_min - gz * gs) ** 2
                    if d < best_d:
                        best_d = d
                        best = hy
    return best

# Generate heightmap
print(f"Generating {RES}x{RES} heightmap...")
pixels = np.zeros((RES, RES), dtype=np.uint8)

for zi in range(RES):
    if zi % 128 == 0:
        print(f"Progress: {zi}/{RES}")
    z = z_min + (zi / (RES - 1)) * z_span
    for xi in range(RES):
        x = x_min + (xi / (RES - 1)) * x_span
        h = sample_height(x, z)
        n = int((h - y_min) / y_range * 255) if y_range > 0 else 0
        n = max(0, min(255, n))
        pixels[zi, xi] = n

# Save as PNG
out_path = "/Users/qizhi_dong/Projects/roblox_experience/places/run/terrain_heightmap.png"
img = Image.fromarray(pixels, mode='L')
img.save(out_path)
print(f"Done: {out_path}")
print(f"XZ {x_span:.0f}x{z_span:.0f} studs, Y {y_range:.0f}, 1px={x_span/RES:.2f} studs")
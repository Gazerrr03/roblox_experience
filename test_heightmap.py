"""
极小测试高度图生成
"""
import bpy, os, sys
import mathutils
from mathutils import Vector

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

GLB_PATH = "/Users/qizhi_dong/Projects/roblox_experience/tmp/run-terrain/RunTerrain_OriginalHigh_Textured_Single.glb"
OUTPUT_DIR = "/Users/qizhi_dong/Projects/roblox_experience/places/run"

print(f"Importing: {GLB_PATH}")
bpy.ops.import_scene.gltf(filepath=GLB_PATH)

obj = None
for o in bpy.data.objects:
    if o.type == 'MESH':
        obj = o
        break

if obj is None:
    print("ERROR: No mesh found")
    sys.exit(1)

print(f"Found: {obj.name}")

depsgraph = bpy.context.view_layer.depsgraph
mesh = obj.to_mesh()
mesh.transform(obj.matrix_world)

verts = [obj.matrix_world @ v.co for v in mesh.vertices]

x_vals = [v.x for v in verts]
y_vals = [v.y for v in verts]
z_vals = [v.z for v in verts]

x_min, x_max = min(x_vals), max(x_vals)
y_min, y_max = min(y_vals), max(y_vals)
z_min, z_max = min(z_vals), max(z_vals)

print(f"X: {x_min:.1f} to {x_max:.1f}")
print(f"Y: {y_min:.1f} to {y_max:.1f}")
print(f"Z: {z_min:.1f} to {z_max:.1f}")

x_span = x_max - x_min
y_span = y_max - y_min
z_range = z_max - z_min

# 测试用极小分辨率
RES = 64

print(f"\nGenerating {RES}x{RES} test heightmap...")

kd = mathutils.kdtree.KDTree(len(verts))
for i, v in enumerate(verts):
    kd.insert(v, i)
kd.balance()

pixels = [0.0] * (RES * RES * 4)

for zi in range(RES):
    y_pos = y_min + (zi / (RES - 1)) * y_span
    for xi in range(RES):
        x_pos = x_min + (xi / (RES - 1)) * x_span
        co = Vector((x_pos, y_pos, (z_min + z_max) / 2))
        hit, index, dist = kd.find(co)
        h = verts[index].z
        n = int((h - z_min) / z_range * 255) if z_range > 0 else 0
        n = max(0, min(255, n))
        idx = (zi * RES + xi) * 4
        pixels[idx] = n/255
        pixels[idx+1] = n/255
        pixels[idx+2] = n/255
        pixels[idx+3] = 1.0

img = bpy.data.images.new("TerrainHeightmap", RES, RES)
img.pixels = pixels
img.update()

os.makedirs(OUTPUT_DIR, exist_ok=True)
output_path = os.path.join(OUTPUT_DIR, "terrain_heightmap_64.png")
img.save_render(output_path)

print(f"\nDone! Saved to: {output_path}")
print(f"Size: {x_span:.0f} x {y_span:.0f} studs")
print(f"Height: {z_range:.0f} studs")
print(f"1 pixel = {x_span/RES:.2f} studs")

bpy.ops.wm.quit_blender()

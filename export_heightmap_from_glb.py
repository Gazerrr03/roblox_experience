"""
RunTerrain 高度图导出脚本
在终端运行: /Applications/Blender.app/Contents/MacOS/blender --background --python export_heightmap_from_glb.py
"""

import bpy, os, sys
import mathutils
from mathutils import Vector

# 清除现有场景
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# GLB 文件路径
GLB_PATH = "/Users/qizhi_dong/Projects/roblox_experience/tmp/run-terrain/RunTerrain_OriginalHigh_Textured_Single.glb"
OUTPUT_DIR = "/Users/qizhi_dong/Projects/roblox_experience/places/run"

# 导入 GLB
print(f"Importing: {GLB_PATH}")
bpy.ops.import_scene.gltf(filepath=GLB_PATH)

# 找到 terrain 对象
obj = None
for o in bpy.data.objects:
    if o.type == 'MESH':
        obj = o
        break

if obj is None:
    print("ERROR: No mesh found")
    sys.exit(1)

print(f"Found: {obj.name}")

# 获取变换后的网格数据
depsgraph = bpy.context.view_layer.depsgraph
mesh = obj.to_mesh()
mesh.transform(obj.matrix_world)

verts = [obj.matrix_world @ v.co for v in mesh.vertices]

# 分析各个轴的范围
x_vals = [v.x for v in verts]
y_vals = [v.y for v in verts]
z_vals = [v.z for v in verts]

x_min, x_max = min(x_vals), max(x_vals)
y_min, y_max = min(y_vals), max(y_vals)
z_min, z_max = min(z_vals), max(z_vals)

print(f"\nAxis ranges:")
print(f"  X: {x_min:.1f} to {x_max:.1f} (span: {x_max-x_min:.0f})")
print(f"  Y: {y_min:.1f} to {y_max:.1f} (span: {y_max-y_min:.0f})")
print(f"  Z: {z_min:.1f} to {z_max:.1f} (span: {z_max-z_min:.0f})")

# Z 是高度轴 (span=80 vs X/Y span=1338)
# Roblox: X-Z 水平面, Y 高度
# Blender GLB导入后可能坐标系有旋转
# 直接用 Z 作为高度

x_span = x_max - x_min
y_span = y_max - y_min
z_range = z_max - z_min

print(f"\nHeight range (Z): {z_min:.1f} to {z_max:.1f} (span: {z_range:.0f})")

# 参数
RES = 256  # 减小分辨率以避免 Studio 崩溃

# 建立 KDTree
print("\nBuilding KDTree...")
kd = mathutils.kdtree.KDTree(len(verts))
for i, v in enumerate(verts):
    kd.insert(v, i)
kd.balance()

print(f"Generating {RES}x{RES} heightmap...")

# 创建像素缓冲
pixels = [0.0] * (RES * RES * 4)

# 采样 - 在 X-Y 平面采样，取 Z 作为高度
for zi in range(RES):
    if zi % 64 == 0:
        print(f"  Progress: {zi}/{RES}")
    # Y 轴作为图像的行
    y_pos = y_min + (zi / (RES - 1)) * y_span
    for xi in range(RES):
        x_pos = x_min + (xi / (RES - 1)) * x_span
        # 在 (x, y, z_mid) 位置找最近顶点
        co = Vector((x_pos, y_pos, (z_min + z_max) / 2))
        hit, index, dist = kd.find(co)
        # 获取该顶点的 Z 高度
        h = verts[index].z
        n = int((h - z_min) / z_range * 255) if z_range > 0 else 0
        n = max(0, min(255, n))
        idx = (zi * RES + xi) * 4
        pixels[idx] = n/255
        pixels[idx+1] = n/255
        pixels[idx+2] = n/255
        pixels[idx+3] = 1.0

# 保存图像
img = bpy.data.images.new("TerrainHeightmap", RES, RES)
img.pixels = pixels
img.update()

os.makedirs(OUTPUT_DIR, exist_ok=True)
output_path = os.path.join(OUTPUT_DIR, "terrain_heightmap.png")
img.save_render(output_path)

print(f"\nDone! Saved to: {output_path}")
print(f"\nRoblox import settings:")
print(f"  Size: {x_span:.0f} x {y_span:.0f} studs")
print(f"  Height (Y max in Roblox): {z_range:.0f} studs")
print(f"  1 pixel = {x_span/RES:.2f} studs")

# 自动退出
bpy.ops.wm.quit_blender()

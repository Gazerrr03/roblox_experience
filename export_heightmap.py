"""
RunTerrain 高度图导出脚本
在 Blender 中打开 .blend 文件，然后:
1. 打开 Text Editor
2. 打开此脚本
3. 点击 Run Script
4. 高度图会保存到 places/run/terrain_heightmap.png
"""

import bpy, os

# 查找当前场景中的 RunTerrain 对象
obj = bpy.data.objects.get("RunTerrain_OriginalHigh")
if obj is None:
    print("ERROR: RunTerrain_OriginalHigh not found in scene")
else:
    print(f"Found terrain: {obj.name}")

    # 获取变换后的网格数据
    depsgraph = bpy.context.view_layer.depsgraph
    mesh = obj.to_mesh()
    mesh.transform(obj.matrix_world)

    verts = [(v.co.x, v.co.y, v.co.z) for v in mesh.vertices]
    x_min=min(v[0] for v in verts); x_max=max(v[0] for v in verts)
    y_min=min(v[1] for v in verts); y_max=max(v[1] for v in verts)
    z_min=min(v[2] for v in verts); z_max=max(v[2] for v in verts)

    print(f"Mesh bounds:")
    print(f"  X: {x_min:.1f} to {x_max:.1f} (span: {x_max-x_min:.0f})")
    print(f"  Y: {y_min:.1f} to {y_max:.1f} (span: {y_max-y_min:.0f})")
    print(f"  Z: {z_min:.1f} to {z_max:.1f} (span: {z_max-z_min:.0f})")
    print(f"Vertices: {len(verts)}")

    # Roblox Terrain 参数
    # Roblox 原生 terrain: Y轴高度, 1灰度=1 stud, 最高256级
    # 高度图分辨率
    RES = 1024  # 建议 512 或 1024

    # XZ 平面范围 (studs)
    x_span = x_max - x_min
    z_span = z_max - z_min
    y_range = y_max - y_min  # 高度范围

    # 网格采样加速
    gs = max(x_span, z_span) / 32

    hash_grid = {}
    for v in verts:
        gx = int((v[0] - x_min) / gs)
        gz = int((v[2] - z_min) / gs)
        key = (gx, gz)
        if key not in hash_grid:
            hash_grid[key] = []
        hash_grid[key].append(v[1])  # Y = 高度

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
                        d = (px - x_min - gx * gs)**2 + (pz - z_min - gz * gs)**2
                        if d < best_d:
                            best_d = d
                            best = hy
        return best

    # 生成高度图
    print(f"\nGenerating {RES}x{RES} heightmap...")
    pixels = []
    for zi in range(RES):
        z = z_min + (zi / (RES - 1)) * z_span
        if zi % 128 == 0:
            print(f"  Progress: {zi}/{RES} ({zi*100//RES}%)")
        for xi in range(RES):
            x = x_min + (xi / (RES - 1)) * x_span
            h = sample_height(x, z)
            # 归一化到 0-255 (Roblox heightmap 用 256 级)
            n = int((h - y_min) / y_range * 255) if y_range > 0 else 0
            n = max(0, min(255, n))
            pixels.extend([n/255, n/255, n/255, 1])  # RGBA

    # 保存图像
    img_name = "TerrainHeightmap"
    if img_name in bpy.data.images:
        bpy.data.images[img_name].user_clear()

    img = bpy.data.images.new(img_name, RES, RES)
    img.pixels = pixels
    img.update()

    # 输出路径
    blend_dir = os.path.dirname(bpy.data.filepath) if bpy.data.filepath else os.getcwd()
    output_path = os.path.join(blend_dir, "places", "run", "terrain_heightmap.png")

    # 确保目录存在
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # 保存
    img.save_render(output_path)
    print(f"\nDone! Heightmap saved to:")
    print(f"  {output_path}")
    print(f"\nTerrain info:")
    print(f"  XZ span: {x_span:.0f} x {z_span:.0f} studs")
    print(f"  Y height: {y_range:.0f} studs")
    print(f"  Resolution: {RES}x{RES} pixels")
    print(f"  1 pixel = {x_span/RES:.2f} studs")
    print(f"\nRoblox import settings:")
    print(f"  Size: {x_span:.0f} x {z_span:.0f} studs")
    print(f"  Height: {y_range:.0f} studs (Y max = {y_range:.0f})")

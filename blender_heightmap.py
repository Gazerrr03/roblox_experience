import bpy, bmesh, os

# Clear existing mesh objects
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Import GLB file
glb_path = "/Users/qizhi_dong/Projects/roblox_experience/tmp/run-terrain/RunTerrain_OriginalHigh_Textured_Single.glb"
bpy.ops.import_scene.gltf(filepath=glb_path)

# Find the terrain object
obj = None
for o in bpy.data.objects:
    if o.type == 'MESH':
        obj = o
        break

if obj is None:
    print("ERROR: No mesh found in GLB file")
else:
    print(f"Found mesh: {obj.name}")

    # Get depsgraph properly for background mode
    depsgraph = bpy.context.view_layer.depsgraph
    mesh = obj.to_mesh()
    mesh.transform(obj.matrix_world)

    verts = [(v.co.x, v.co.y, v.co.z) for v in mesh.vertices]
    x_min=min(v[0] for v in verts); x_max=max(v[0] for v in verts)
    y_min=min(v[1] for v in verts); y_max=max(v[1] for v in verts)
    z_min=min(v[2] for v in verts); z_max=max(v[2] for v in verts)

    print(f"Mesh bounds: X[{x_min:.1f}, {x_max:.1f}], Y[{y_min:.1f}, {y_max:.1f}], Z[{z_min:.1f}, {z_max:.1f}]")
    print(f"Mesh vertices: {len(verts)}, XZ span: {x_max-x_min:.0f}x{z_max-z_min:.0f}")

    RES=2048
    x_span=x_max-x_min; z_span=z_max-z_min; y_range=y_max-y_min
    gs=max(x_span,z_span)/32

    hash_grid={}
    for v in verts:
        gx=int((v[0]-x_min)/gs); gz=int((v[2]-z_min)/gs)
        key=(gx,gz)
        if key not in hash_grid: hash_grid[key]=[]
        hash_grid[key].append(v[1])

    def sample_height(px,pz):
        gx=int((px-x_min)/gs); gz=int((pz-z_min)/gs)
        best=y_min; best_d=float('inf')
        for dx in[-1,0,1]:
            for dz in[-1,0,1]:
                key=(gx+dx,gz+dz)
                if key in hash_grid:
                    for hy in hash_grid[key]:
                        d=(px-x_min-gx*gs)**2+(pz-z_min-gz*gs)**2
                        if d<best_d: best_d=d; best=hy
        return best

    pixels=[]
    for zi in range(RES):
        z=z_min+(zi/(RES-1))*z_span
        if zi%256==0: print(f"Progress: {zi}/{RES}")
        for xi in range(RES):
            x=x_min+(xi/(RES-1))*x_span
            h=sample_height(x,z)
            n=int((h-y_min)/y_range*255) if y_range>0 else 0
            n=max(0,min(255,n))
            pixels.extend([n/255,n/255,n/255,1])

    img_name="TerrainHeightmap"
    if img_name in bpy.data.images: bpy.data.images[img_name].user_clear()
    img=bpy.data.images.new(img_name,RES,RES)
    img.pixels=pixels; img.update()
    out="/Users/qizhi_dong/Projects/roblox_experience/places/run/terrain_heightmap.png"
    img.save_render(out)
    print(f"Done: {out}")
    print(f"XZ {x_span:.0f}x{z_span:.0f} studs, Y {y_range:.0f}, 1px={x_span/RES:.2f} studs")
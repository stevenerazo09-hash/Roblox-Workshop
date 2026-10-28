# Renders the Build a Mage Farm UI icons as transparent 512x512 PNGs.
# Run headless:  blender -b -P make_icons.py
# Output: art/icons/<name>.png and art/icons.blend (last icon's scene, for tweaking)

import math
import os

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "icons")
os.makedirs(OUT, exist_ok=True)
SIZE = 512


def rgb(r, g, b):
    # Shader colours are linear; convert from the sRGB values we think in.
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    return (lin(r), lin(g), lin(b), 1)


# ---------------------------------------------------------------- scene setup
def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT", "CYCLES"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    if scene.render.engine == "CYCLES":
        scene.cycles.samples = 48
    else:
        try:
            scene.eevee.taa_render_samples = 32
        except AttributeError:
            pass
    scene.render.resolution_x = SIZE
    scene.render.resolution_y = SIZE
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    try:
        scene.view_settings.view_transform = "Standard"
    except TypeError:
        pass
    world = bpy.data.worlds.new("World")
    try:
        world.use_nodes = True
    except AttributeError:
        pass
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (0.8, 0.82, 0.95, 1)
    bg.inputs[1].default_value = 0.35
    scene.world = world

    sun = bpy.data.lights.new("Key", "SUN")
    sun.energy = 2.6
    key = bpy.data.objects.new("Key", sun)
    key.rotation_euler = (math.radians(50), math.radians(-10), math.radians(-35))
    scene.collection.objects.link(key)
    rim = bpy.data.lights.new("Rim", "SUN")
    rim.energy = 1.5
    rim_obj = bpy.data.objects.new("Rim", rim)
    rim_obj.rotation_euler = (math.radians(-60), math.radians(20), math.radians(160))
    scene.collection.objects.link(rim_obj)
    return scene


_materials = {}


def material(color, emission=0.1, metallic=0.0, roughness=0.5):
    key = (tuple(round(c, 3) for c in color), emission, metallic, roughness)
    if key in _materials:
        return _materials[key]
    mat = bpy.data.materials.new("Mat")
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    for name in ("Emission Color", "Emission"):
        if name in bsdf.inputs:
            bsdf.inputs[name].default_value = color
            break
    if "Emission Strength" in bsdf.inputs:
        bsdf.inputs["Emission Strength"].default_value = emission
    _materials[key] = mat
    return mat


def outline_material():
    if "Outline" in bpy.data.materials:
        return bpy.data.materials["Outline"]
    mat = bpy.data.materials.new("Outline")
    mat.use_nodes = True
    bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (0.03, 0.02, 0.05, 1)
    bsdf.inputs["Roughness"].default_value = 1
    mat.use_backface_culling = True
    return mat


def finish(obj, color, smooth=True, bevel=0.04, outline=0.045, **matkw):
    obj.data.materials.clear()
    obj.data.materials.append(material(color, **matkw))
    obj.data.materials.append(outline_material())
    if bevel > 0 and obj.type == "MESH":
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 3
    if smooth and obj.type == "MESH":
        for poly in obj.data.polygons:
            poly.use_smooth = True
    sol = obj.modifiers.new("Outline", "SOLIDIFY")
    sol.thickness = outline
    sol.offset = 1
    sol.use_flip_normals = True
    sol.material_offset = 1
    return obj


def prim(kind, loc=(0, 0, 0), scale=(1, 1, 1), rot=(0, 0, 0), color=rgb(255, 255, 255), minor=0.12, **kw):
    ops = {
        "cube": lambda: bpy.ops.mesh.primitive_cube_add(size=1),
        "sphere": lambda: bpy.ops.mesh.primitive_uv_sphere_add(radius=0.5, segments=40, ring_count=20),
        "cylinder": lambda: bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=1, vertices=48),
        "prism": lambda: bpy.ops.mesh.primitive_cylinder_add(radius=0.5, depth=1, vertices=3),
        "cone": lambda: bpy.ops.mesh.primitive_cone_add(radius1=0.5, radius2=0, depth=1, vertices=48),
        "torus": lambda: bpy.ops.mesh.primitive_torus_add(major_radius=0.5, minor_radius=minor, major_segments=64, minor_segments=16),
    }
    ops[kind]()
    obj = bpy.context.active_object
    obj.location = loc
    obj.scale = scale
    obj.rotation_euler = tuple(math.radians(a) for a in rot)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    smooth = kind not in ("cube", "prism")
    finish(obj, color, smooth=smooth, bevel=kw.pop("bevel", 0.04 if kind in ("cube", "prism") else 0), **kw)
    return obj


def text(body, loc, size, color, rot=(90, 0, 0), extrude=0.08):
    bpy.ops.object.text_add(location=loc, rotation=tuple(math.radians(a) for a in rot))
    obj = bpy.context.active_object
    obj.data.body = body
    obj.data.size = size
    obj.data.extrude = extrude
    obj.data.align_x = "CENTER"
    obj.data.align_y = "CENTER"
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.active_object
    finish(obj, color, smooth=False, bevel=0, outline=0.03)
    return obj


def clover(center, radius, color, leaves=4, stem=True, **kw):
    """Flat clover in the XZ plane, facing the camera (-Y)."""
    leaves_parts = []
    cx, cy, cz = center
    dark = tuple(c * 0.55 for c in color[:3]) + (1,)
    parts = leaves_parts
    for i in range(leaves):
        a = math.radians(90 + i * 360 / leaves)
        # Heart-shaped leaf: two round lobes on the outside, a diamond tip pointing at the centre.
        for side in (-1, 1):
            la = a + side * math.radians(27)
            lx = cx + math.cos(la) * radius * 0.7
            lz = cz + math.sin(la) * radius * 0.7
            parts.append(prim("sphere", loc=(lx, cy, lz), scale=(radius * 0.5, radius * 0.16, radius * 0.5), color=color, **kw))
        tx = cx + math.cos(a) * radius * 0.42
        tz = cz + math.sin(a) * radius * 0.42
        tip_angle = 45 - math.degrees(a)
        parts.append(prim("cube", loc=(tx, cy, tz), scale=(radius * 0.5, radius * 0.15, radius * 0.5), rot=(0, tip_angle, 0), color=color, bevel=radius * 0.06, **kw))

    # Fuse the leaves into one smooth surface so the outline only traces the silhouette.
    bpy.ops.object.select_all(action="DESELECT")
    for p in leaves_parts:
        p.modifiers.clear()
        p.select_set(True)
    bpy.context.view_layer.objects.active = leaves_parts[0]
    bpy.ops.object.join()
    fused = bpy.context.active_object
    remesh = fused.modifiers.new("Remesh", "REMESH")
    remesh.mode = "VOXEL"
    remesh.voxel_size = radius * 0.03
    remesh.use_smooth_shade = True
    finish(fused, color, smooth=True, bevel=0, **kw)
    parts = [fused]
    if stem:
        parts.append(prim("cylinder", loc=(cx + radius * 0.3, cy + radius * 0.05, cz - radius * 1.0), scale=(radius * 0.13, radius * 0.13, radius * 0.95), rot=(0, -25, 0), color=dark, **kw))
    parts.append(prim("sphere", loc=(cx, cy - radius * 0.06, cz), scale=(radius * 0.26, radius * 0.2, radius * 0.26), color=dark, **kw))
    return parts


def star(center, radius, color, points=5, depth=0.12, **kw):
    """Flat star badge in the XZ plane, facing the camera (-Y). Used on grimoire
    covers instead of a clover (clover-on-grimoire is another IP's look)."""
    import bmesh

    cx, cy, cz = center
    mesh = bpy.data.meshes.new("Star")
    bm = bmesh.new()
    verts = []
    for i in range(points * 2):
        r = radius if i % 2 == 0 else radius * 0.45
        a = math.radians(90 + i * 180 / points)
        verts.append(bm.verts.new((cx + math.cos(a) * r, cy, cz + math.sin(a) * r)))
    bm.faces.new(verts)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Star", mesh)
    bpy.context.scene.collection.objects.link(obj)
    thick = obj.modifiers.new("Thick", "SOLIDIFY")
    thick.thickness = depth
    finish(obj, color, smooth=False, bevel=0, **kw)
    return obj


# ---------------------------------------------------------------- framing + render
def frame_and_render(name, view=(0.55, -1.0, 0.45)):
    scene = bpy.context.scene
    objs = [o for o in scene.objects if o.type == "MESH"]
    mins = Vector((1e9, 1e9, 1e9))
    maxs = Vector((-1e9, -1e9, -1e9))
    for o in objs:
        for corner in o.bound_box:
            w = o.matrix_world @ Vector(corner)
            mins = Vector((min(mins[i], w[i]) for i in range(3)))
            maxs = Vector((max(maxs[i], w[i]) for i in range(3)))
    center = (mins + maxs) / 2
    extent = (maxs - mins).length
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = extent * 0.92
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    direction = Vector(view).normalized()
    cam.location = center + direction * (extent * 3)
    look = (center - cam.location).to_track_quat("-Z", "Y")
    cam.rotation_euler = look.to_euler()
    scene.camera = cam
    scene.render.filepath = os.path.join(OUT, name + ".png")
    bpy.ops.render.render(write_still=True)
    print("rendered", name)


# ---------------------------------------------------------------- icons
GOLD = rgb(255, 205, 60)
WHITE = rgb(250, 250, 255)
DARK = rgb(35, 30, 45)


def icon_roll():
    prim("cube", scale=(1.5, 0.45, 1.9), color=rgb(95, 45, 160), bevel=0.08)
    prim("cube", loc=(0.08, 0.02, 0), scale=(1.42, 0.38, 1.78), color=rgb(245, 235, 210))
    prim("cube", loc=(-0.72, 0, 0), scale=(0.14, 0.5, 1.95), color=rgb(70, 30, 120), bevel=0.05)
    for z in (0.75, -0.75):
        prim("cube", loc=(0, -0.23, z), scale=(1.5, 0.05, 0.12), color=rgb(255, 190, 30), metallic=0.6)
    star((0.05, -0.3, 0.02), 0.5, GOLD, metallic=0.5, emission=0.5)


def icon_book():
    prim("cube", scale=(1.4, 0.4, 1.8), color=rgb(60, 130, 255), bevel=0.08)
    prim("cube", loc=(0.08, 0.02, 0), scale=(1.32, 0.33, 1.68), color=WHITE)
    prim("cube", loc=(-0.66, 0, 0), scale=(0.14, 0.45, 1.85), color=rgb(40, 90, 200), bevel=0.05)
    star((0.05, -0.27, 0.05), 0.4, GOLD, metallic=0.5)


def icon_hat():
    prim("cylinder", loc=(0, 0, 0), scale=(2.6, 2.6, 0.18), color=rgb(140, 70, 230))
    prim("cone", loc=(0, 0, 0.95), scale=(1.5, 1.5, 1.9), rot=(-8, 6, 0), color=rgb(160, 90, 255))
    prim("cylinder", loc=(0, 0, 0.22), scale=(1.42, 1.42, 0.26), color=GOLD, metallic=0.4)
    prim("sphere", loc=(0.25, -0.62, 0.95), scale=(0.3, 0.12, 0.3), color=GOLD, emission=0.8)


def icon_bag():
    prim("cube", loc=(0, 0, -0.1), scale=(2.0, 1.0, 1.7), color=rgb(255, 60, 150), bevel=0.1)
    prim("cube", loc=(0, 0, 0.62), scale=(2.06, 1.06, 0.22), color=rgb(255, 120, 190), bevel=0.06)
    for x in (-0.45, 0.45):
        prim("torus", loc=(x, 0, 0.78), scale=(0.62, 0.62, 0.9), rot=(90, 0, 0), minor=0.05, color=rgb(120, 30, 80))
    clover((0, -0.52, -0.15), 0.42, WHITE, stem=False)


def icon_arrow():
    green = rgb(40, 210, 70)
    prim("cube", loc=(0, 0, -0.55), scale=(0.8, 0.6, 1.4), color=green, bevel=0.08)
    prim("prism", loc=(0, 0, 0.45), scale=(2.1, 2.1, 0.6), rot=(90, 0, 0), color=green)


def icon_rebirth():
    gold = rgb(255, 195, 40)
    prim("cylinder", loc=(0, 0, -0.35), scale=(2.2, 2.2, 0.8), color=gold, metallic=0.5)
    for i in range(5):
        a = math.radians(-90 + 36 + i * 72)
        x, y = math.cos(a) * 0.82, math.sin(a) * 0.82
        prim("cone", loc=(x, y, 0.5), scale=(0.7, 0.7, 1.1), color=gold, metallic=0.5)
        prim("sphere", loc=(x, y, 1.1), scale=(0.3, 0.3, 0.3), color=gold, metallic=0.5)
    prim("sphere", loc=(0, -1.08, -0.35), scale=(0.5, 0.25, 0.5), color=rgb(240, 40, 60), emission=0.3)
    for i, x in enumerate((-0.75, 0.75)):
        y = -0.8
        prim("sphere", loc=(x, y, -0.35), scale=(0.34, 0.22, 0.34), color=rgb(60, 140, 255), emission=0.3)


def icon_calendar():
    prim("cube", scale=(1.9, 0.35, 1.8), color=WHITE, bevel=0.08)
    prim("cube", loc=(0, -0.02, 0.62), scale=(1.95, 0.4, 0.6), color=rgb(240, 60, 70), bevel=0.06)
    for x in (-0.5, 0.5):
        prim("torus", loc=(x, 0, 0.95), scale=(0.5, 0.5, 0.5), rot=(0, 90, 0), color=DARK)
    text("7", (0, -0.2, -0.28), 1.1, rgb(240, 60, 70))


def icon_gift():
    prim("cube", loc=(0, 0, -0.2), scale=(1.6, 1.3, 1.25), color=rgb(255, 80, 120), bevel=0.08)
    prim("cube", loc=(0, 0, 0.5), scale=(1.8, 1.45, 0.35), color=rgb(255, 110, 150), bevel=0.06)
    prim("cube", loc=(0, 0, 0.0), scale=(0.32, 1.5, 1.75), color=GOLD)
    for side in (-1, 1):
        prim("torus", loc=(side * 0.35, 0, 0.9), scale=(0.9, 0.9, 0.9), rot=(90, side * 35, 0), color=GOLD)


def icon_ticket():
    prim("cube", scale=(2.2, 0.25, 1.2), color=GOLD, bevel=0.06)
    for x in (-1.1, 1.1):
        prim("cylinder", loc=(x, 0, 0), scale=(0.45, 0.45, 0.4), rot=(90, 0, 0), color=rgb(255, 230, 140))
    text("123", (0, -0.15, 0), 0.75, rgb(140, 70, 20))


def icon_clover():
    clover((0, 0, 0), 1.0, rgb(80, 225, 100))


def icon_coin():
    prim("cylinder", scale=(2.0, 2.0, 0.35), rot=(90, 0, 0), color=GOLD, metallic=0.5, emission=0.25)
    prim("cylinder", loc=(0, -0.12, 0), scale=(1.55, 1.55, 0.2), rot=(90, 0, 0), color=rgb(255, 220, 100), metallic=0.4)
    text("G", (0, -0.25, 0), 1.2, rgb(200, 140, 20))  # G for Gold (was Y for Yul)


def icon_token():
    prim("cylinder", scale=(2.0, 2.0, 0.35), rot=(90, 0, 0), color=rgb(60, 190, 110), emission=0.25)
    prim("cylinder", loc=(0, -0.12, 0), scale=(1.55, 1.55, 0.2), rot=(90, 0, 0), color=rgb(110, 230, 150))
    clover((0, -0.3, 0.05), 0.5, WHITE, stem=False)


def potion(color):
    prim("sphere", loc=(0, 0, -0.25), scale=(1.6, 1.6, 1.6), color=color, emission=0.5)
    prim("cylinder", loc=(0, 0, 0.75), scale=(0.55, 0.55, 0.7), color=rgb(220, 240, 255))
    prim("cylinder", loc=(0, 0, 1.15), scale=(0.6, 0.6, 0.3), color=rgb(150, 100, 60))
    prim("sphere", loc=(-0.35, -0.6, 0.0), scale=(0.3, 0.15, 0.4), color=WHITE, emission=1.5)


def icon_luck_potion():
    potion(rgb(170, 90, 255))


def icon_yul_potion():
    potion(rgb(255, 160, 40))


def icon_tower():
    prim("cylinder", loc=(0, 0, -0.4), scale=(1.3, 1.3, 1.8), color=rgb(170, 165, 160))
    prim("cylinder", loc=(0, 0, 0.55), scale=(1.5, 1.5, 0.2), color=GOLD)
    prim("cone", loc=(0, 0, 1.25), scale=(1.7, 1.7, 1.3), color=rgb(90, 80, 160))
    prim("cube", loc=(0, -0.62, -0.85), scale=(0.45, 0.2, 0.7), color=rgb(110, 70, 40))
    clover((0, 0, 2.15), 0.3, rgb(110, 255, 140), stem=False, emission=1.0)


def icon_house():
    prim("cube", loc=(0, 0, -0.3), scale=(1.8, 1.4, 1.2), color=rgb(250, 235, 200), bevel=0.06)
    prim("prism", loc=(0, 0, 0.62), scale=(1.45, 1.45, 1.6), rot=(90, 0, 90), color=rgb(235, 70, 60))
    prim("cube", loc=(0, -0.68, -0.5), scale=(0.45, 0.1, 0.75), color=rgb(120, 75, 40))


def icon_server_luck(label="x2"):
    clover((0, 0.2, 0.2), 0.95, rgb(80, 225, 100), stem=False, emission=0.6)
    text(label, (0.45, -0.45, -0.75), 1.0, GOLD)


def icon_double():
    prim("cube", loc=(0.35, 0.35, 0.15), scale=(1.4, 0.4, 1.8), color=rgb(150, 30, 40), bevel=0.08)
    prim("cube", loc=(-0.3, -0.1, -0.1), scale=(1.4, 0.4, 1.8), color=rgb(95, 45, 160), bevel=0.08)
    star((-0.25, -0.35, -0.05), 0.42, GOLD, metallic=0.5)


ICONS = {
    "roll": icon_roll,
    "index": icon_book,
    "mages": icon_hat,
    "shop": icon_bag,
    "training": icon_arrow,
    "rank": icon_rebirth,
    "daily": icon_calendar,
    "gifts": icon_gift,
    "codes": icon_ticket,
    "luck": icon_clover,
    "yul": icon_coin,
    "token": icon_token,
    "luckpotion": icon_luck_potion,
    "yulpotion": icon_yul_potion,
    "tower": icon_tower,
    "base": icon_house,
    "serverluck": icon_server_luck,
    "serverluck4": lambda: icon_server_luck("x4"),
    "serverluck8": lambda: icon_server_luck("x8"),
    "doubleroll": icon_double,
}

only = os.environ.get("ICONS_ONLY")
for name, build in ICONS.items():
    if only and name not in only.split(","):
        continue
    reset_scene()
    _materials.clear()
    build()
    frame_and_render(name)

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "icons.blend"))
print("ALL DONE")

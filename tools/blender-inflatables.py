# Runs inside Blender (headless) with the Sollumz extension installed:
#
#   blender -b -P tools/blender-inflatables.py -- build/inflatables out/dir [model ...]
#
# For every <model>.obj written by tools/build-inflatables.py: imports it,
# makes a Sollumz drawable with the default shader and the palette texture
# embedded, a composite collision of spheres from <model>.json, exports a
# CodeWalker XML .ydr; then one .ytyp with an archetype per model. The
# XML is converted to binary by tools/cwconv.
import sys, json, importlib, pathlib
import bpy

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
src = pathlib.Path(argv[0]).resolve()
out = pathlib.Path(argv[1]).resolve()
only = set(argv[2:])
out.mkdir(parents=True, exist_ok=True)

# The extension module.
sz = None
for cand in ("bl_ext.https.sollumz", "bl_ext.user_default.sollumz", "sollumz"):
    try:
        sz = importlib.import_module(cand)
        break
    except Exception:
        pass
if sz is None:
    for name in list(sys.modules):
        if name.endswith(".sollumz"):
            sz = sys.modules[name]
            break
if sz is None:
    raise SystemExit("Sollumz extension not found")
ROOT = sz.__name__
m = lambda sub: importlib.import_module(ROOT + "." + sub)

props = m("sollumz_properties")
SollumType, LODLevel = props.SollumType, props.LODLevel
blenderhelper = m("tools.blenderhelper")
meshhelper = m("tools.meshhelper")
shader_materials = m("ydr.shader_materials")
ydrexport = m("ydr.ydrexport")
ytypexport = m("ytyp.ytypexport")
iecontext = m("iecontext")
collision_materials = m("ybn.collision_materials")
from szio.gta5 import AssetFormat, AssetTarget, AssetVersion

targets = (AssetTarget(AssetFormat.CWXML, AssetVersion.GEN8),)
settings = iecontext.ExportSettings(targets=targets)


def clear_scene():
    # Not read_factory_settings: that disables the extension and its properties.
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
        for d in list(coll):
            if d.users == 0:
                coll.remove(d)
    scene = bpy.context.scene
    while len(scene.ytyps) > 0:
        scene.ytyps.remove(0)


def build_model(info):
    model = info["model"]
    clear_scene()
    bpy.ops.wm.obj_import(filepath=str(src / (model + ".obj")), forward_axis="Y", up_axis="Z")
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    assert len(meshes) == 1, meshes
    mesh_obj = meshes[0]
    mesh_obj.name = model
    mesh_obj.data.name = model
    for poly in mesh_obj.data.polygons:
        poly.use_smooth = True
    # Sollumz shaders look for these names.
    me = mesh_obj.data
    if me.uv_layers:
        me.uv_layers[0].name = "UVMap 0"
    col = me.color_attributes.new("Color 1", "BYTE_COLOR", "CORNER")
    for d in col.data:
        d.color_srgb = (1.0, 1.0, 1.0, 1.0)

    # The drawable: an empty with the mesh as its high LOD model.
    drawable = blenderhelper.create_empty_object(SollumType.DRAWABLE, model)
    mesh_obj.parent = drawable
    mesh_obj.sollum_type = SollumType.DRAWABLE_MODEL
    lods = mesh_obj.sz_lods
    lods.get_lod(LODLevel.HIGH).mesh = mesh_obj.data
    lods.active_lod_level = LODLevel.HIGH
    drawable.drawable_properties.lod_dist_high = 400.0
    drawable.drawable_properties.lod_dist_med = 600.0
    drawable.drawable_properties.lod_dist_low = 800.0
    drawable.drawable_properties.lod_dist_vlow = 1000.0

    # The material: Sollumz 'default' shader with the palette embedded.
    palette = bpy.data.images.load(str(src / "sk_infl_palette.dds"))
    palette.name = "sk_infl_palette"
    mesh_obj.data.materials.clear()
    # Emissive: a lawn inflatable glows from inside, so the model must not
    # go dark at night like an ordinary prop.
    mat = shader_materials.create_shader("emissive.sps")
    mat.name = "sk_infl_palette"
    em = mat.node_tree.nodes.get("emissiveMultiplier")
    if em is not None:
        em.set_float(1.4)
    tex_nodes = [n for n in mat.node_tree.nodes if isinstance(n, bpy.types.ShaderNodeTexImage)]
    diffuse = next((n for n in tex_nodes if "Diffuse" in n.name), tex_nodes[0])
    diffuse.image = palette
    diffuse.texture_properties.embedded = True
    # sollumz_texture_name is derived from the image name
    mesh_obj.data.materials.append(mat)

    # Collision: a composite of spheres, one per big part.
    composite = blenderhelper.create_empty_object(SollumType.BOUND_COMPOSITE, model + "_col")
    composite.parent = drawable
    colmat = collision_materials.create_collision_material_from_index(0)   # DEFAULT
    for i, s in enumerate(info["spheres"]):
        sphere = blenderhelper.create_blender_object(SollumType.BOUND_SPHERE, "%s_s%d" % (model, i))
        meshhelper.create_sphere(sphere.data, radius=s["r"])
        sphere.location = (s["x"], s["y"], s["z"])
        sphere.parent = composite
        sphere.data.materials.append(colmat)

    # The light inside, cast on the ground around it.
    li = info.get("light")
    if li:
        ldata = bpy.data.lights.new(model + "_light", "POINT")
        ldata.sollum_type = props.LightType.POINT
        ldata.color = tuple(c / 255.0 for c in li["color"])
        lp = ldata.light_properties
        lp.intensity = 6.0
        lp.falloff = max(1.5, li["range"] * 1.6)
        lp.falloff_exponent = 8.0
        lobj = bpy.data.objects.new(model + "_light", ldata)
        lobj.sollum_type = SollumType.LIGHT
        bpy.context.collection.objects.link(lobj)
        lobj.parent = drawable
        lobj.location = (0.0, 0.0, li["z"])

    with iecontext.export_context_scope(iecontext.ExportContext(asset_name=model, settings=settings)):
        bundle = ydrexport.export_ydr(drawable)
        if not bundle:
            raise SystemExit("export failed for " + model)
        bundle.save(out, targets)
    print("[blender] exported", model)
    return drawable


def build_ytyp(infos):
    clear_scene()
    scene = bpy.context.scene
    ytyp = scene.ytyps.add()
    ytyp.name = "sk_inflatables"
    for info in infos:
        a = ytyp.new_archetype()
        a.name = info["model"]
        a.asset_name = info["model"]
        a.asset_type = props.AssetType.DRAWABLE if hasattr(props, "AssetType") else a.asset_type
        a.texture_dictionary = ""
        a.physics_dictionary = info["model"]
        a.lod_dist = 400.0
        mn, mx = info["bb_min"], info["bb_max"]
        a.bb_min = mn
        a.bb_max = mx
        c = [(mn[i] + mx[i]) / 2 for i in range(3)]
        a.bs_center = c
        a.bs_radius = max(((mx[i] - c[i]) ** 2 for i in range(3)), default=1.0) ** 0.5 * 1.75
    with iecontext.export_context_scope(iecontext.ExportContext(asset_name="sk_inflatables", settings=settings)):
        bundle = ytypexport.export_ytyp(scene, 0)
        if not bundle:
            raise SystemExit("ytyp export failed")
        bundle.save(out, targets)
    print("[blender] exported sk_inflatables.ytyp")


manifest = json.loads((src / "manifest.json").read_text(encoding="utf-8"))
infos = [i for i in manifest if not only or i["model"] in only]
for info in infos:
    build_model(info)
build_ytyp(infos)
print("[blender] done:", len(infos), "models")

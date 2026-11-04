#!/usr/bin/env python3
"""
Generates smooth meshes for the inflatables from shared/shapes.lua.

Every shape in the catalog is a list of ellipsoids. A figure built from
plain spheres looks like a balloon animal (every seam shows), so the body
parts are fused into ONE skin: a signed distance field of the union of
the ellipsoids with soft blending, meshed with marching cubes. Surface
features (eyes, belts, bands, anything the catalog marks `over`, and any
part set inside a bigger one) stay separate crisp spheres on top. Each
vertex is colored by the nearest part through a palette atlas.

Writes, per shape and size: <model>.obj (positions, normals, UVs) and
<model>.json (collision spheres, bounds, light); a shared palette DDS.
tools/blender-inflatables.py turns those into game models with Sollumz;
tools/cwconv converts to binary.

Usage:  python tools/build-inflatables.py                  # every inflatable
        python tools/build-inflatables.py santa penguin    # some
        python tools/build-inflatables.py --sizes 1.8,2.6  # sizes in meters (default: the catalog size)
        --cell 0.025   voxel size in meters (default 0.025)
        --blend 0.07   how softly parts fuse, in meters (default 0.07)
Needs:  lupa, numpy, scikit-image, Pillow.
"""
import json, math, pathlib, struct, sys
import numpy as np
from lupa import LuaRuntime
from PIL import Image
from skimage import measure

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent
OUT = ROOT / "build" / "inflatables"

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute("Config = { Holidays = {}, CustomProps = {}, Season = {} }")
lua.execute((ROOT / "shared" / "shapes.lua").read_text(encoding="utf-8"))
Shapes = lua.globals().Shapes


def lt(t):
    return [t[i] for i in range(1, len(t) + 1)]


def rot_matrix(ax, ay, az):
    """Rz * Ry * Rx, degrees, as the renderer and the preview sheet apply it."""
    ax, ay, az = map(math.radians, (ax, ay, az))
    cx, sx, cy, sy, cz, sz = math.cos(ax), math.sin(ax), math.cos(ay), math.sin(ay), math.cos(az), math.sin(az)
    return np.array([
        [cz * cy, cz * sy * sx - sz * cx, cz * sy * cx + sz * sx],
        [sz * cy, sz * sy * sx + cz * cx, sz * sy * cx - cz * sx],
        [-sy, cy * sx, cy * cx],
    ])


# ---------------------------------------------------------------- palette
class Palette:
    """Every color gets a cell in a 16x16 grid; UVs point at cell centers."""
    def __init__(self):
        self.colors = []
        self.index = {}

    def uv(self, c):
        key = (int(c[0]), int(c[1]), int(c[2]))
        i = self.index.get(key)
        if i is None:
            i = len(self.colors)
            self.colors.append(key)
            self.index[key] = i
        return ((i % 16) + 0.5) / 16.0, 1.0 - ((i // 16) + 0.5) / 16.0

    def save(self, png, dds, cell=16):
        img = Image.new("RGBA", (16 * cell, 16 * cell), (0, 0, 0, 255))
        px = img.load()
        for i, c in enumerate(self.colors):
            x0, y0 = (i % 16) * cell, (i // 16) * cell
            for y in range(cell):
                for x in range(cell):
                    px[x0 + x, y0 + y] = c + (255,)
        img.save(png)
        write_dds(img, dds)


def write_dds(img, path):
    """Uncompressed 32-bit A8R8G8B8, no mips: the only DDS Sollumz needs."""
    w, h = img.size
    header = struct.pack("<4sIIIIIII44xIIIIIIIIIIIII", b"DDS ", 124, 0x1 | 0x2 | 0x4 | 0x1000, h, w, w * 4, 0, 1,
                         32, 0x1 | 0x40, 0, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000, 0x1000, 0, 0, 0, 0)
    assert len(header) == 128
    path.write_bytes(header + img.tobytes("raw", "BGRA"))


# ---------------------------------------------------------------- parts
class Part:
    def __init__(self, p, size):
        self.c = np.array([p[1], p[2], p[3]]) * size
        self.r = np.array([p[4], p[5], p[6]]) * size
        rot = lt(p.rot) if p.rot else (0.0, 0.0, 0.0)
        self.R = rot_matrix(*rot)
        self.color = tuple(int(v) for v in lt(p.c))
        self.over = bool(p.over)
        self.lit = bool(p.lit)

    def sdf(self, pts):
        """Approximate signed distance (m) from points (N,3) to this ellipsoid."""
        local = (pts - self.c) @ self.R          # world -> local (R orthonormal)
        k0 = np.linalg.norm(local / self.r, axis=1)
        k1 = np.linalg.norm(local / (self.r * self.r), axis=1)
        return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)


def classify(parts):
    """Base parts fuse into the skin; features sit on top. A part set
    inside a bigger one counts as a feature (same rule as the renderer)."""
    for i, p in enumerate(parts):
        if p.over:
            continue
        vi = np.prod(p.r)
        for j, q in enumerate(parts):
            if i != j and not q.over and np.prod(q.r) > vi * 1.5:
                d = (p.c - q.c) / q.r
                if d @ d < 0.85:
                    p.over = True
                    break
    return [p for p in parts if not p.over], [p for p in parts if p.over]


# ---------------------------------------------------------------- mesh
def sphere_mesh(lon, lat):
    v = [(0.0, 0.0, 1.0)]
    for j in range(1, lat):
        phi = math.pi * j / lat
        for i in range(lon):
            th = 2 * math.pi * i / lon
            v.append((math.cos(th) * math.sin(phi), math.sin(th) * math.sin(phi), math.cos(phi)))
    v.append((0.0, 0.0, -1.0))
    last = len(v) - 1
    f = []
    for i in range(lon):
        f.append((0, 1 + i, 1 + (i + 1) % lon))
    for j in range(lat - 2):
        row, nxt = 1 + j * lon, 1 + (j + 1) * lon
        for i in range(lon):
            a, b = row + i, row + (i + 1) % lon
            c, d = nxt + i, nxt + (i + 1) % lon
            f.append((a, d, b))
            f.append((a, c, d))
    base = 1 + (lat - 2) * lon
    for i in range(lon):
        f.append((last, base + i, base + (i + 1) % lon))
    return np.array(v), np.array(f)


SPHERE = {"mid": sphere_mesh(20, 10), "lo": sphere_mesh(12, 6)}


def smooth_union(dists, k):
    """Soft minimum across parts (P parts x N points) with blend radius k."""
    out = dists[0]
    for i in range(1, dists.shape[0]):
        b = dists[i]
        h = np.clip(0.5 + 0.5 * (b - out) / k, 0.0, 1.0)
        out = b * (1 - h) + out * h - k * h * (1 - h)
    return out


def skin_mesh(base, cell, blend):
    """Marching cubes over the blended union of the base parts."""
    lo = np.min([p.c - p.r.max() for p in base], axis=0) - blend - 2 * cell
    hi = np.max([p.c + p.r.max() for p in base], axis=0) + blend + 2 * cell
    nx, ny, nz = [int(math.ceil((hi[i] - lo[i]) / cell)) + 1 for i in range(3)]
    xs = lo[0] + np.arange(nx) * cell
    ys = lo[1] + np.arange(ny) * cell
    zs = lo[2] + np.arange(nz) * cell
    grid = np.stack(np.meshgrid(xs, ys, zs, indexing="ij"), axis=-1).reshape(-1, 3)
    dists = np.stack([p.sdf(grid) for p in base], axis=0)
    field = smooth_union(dists, blend).reshape(nx, ny, nz)
    verts, faces, normals, _ = measure.marching_cubes(field, level=0.0, spacing=(cell, cell, cell))
    verts = verts + lo
    normals = normals / np.maximum(np.linalg.norm(normals, axis=1, keepdims=True), 1e-9)
    d = np.stack([p.sdf(verts) for p in base], axis=0)
    owner = d.argmin(axis=0)
    return verts, faces, normals, owner


def build(shape, size, palette, cell, blend):
    parts = [Part(p, size) for p in lt(shape.parts)]
    base, feats = classify(parts)
    lines = ["# sals_kewlholidays inflatable %s at %.2f m" % (shape.name, size), "mtllib palette.mtl", "usemtl palette", "s 1"]
    V = []
    F = []
    verts, faces, normals, owner = skin_mesh(base, cell, blend)
    uvs = [palette.uv(base[o].color) for o in owner]
    off = len(V)
    for i in range(len(verts)):
        V.append((*verts[i], *normals[i], *uvs[i]))
    for a, b, c in faces:
        # Wind every face so its geometric normal agrees with the field gradient (outward).
        n = np.cross(verts[b] - verts[a], verts[c] - verts[a])
        if n @ (normals[a] + normals[b] + normals[c]) < 0:
            b, c = c, b
        F.append((off + a, off + b, off + c))
    for p in feats:
        sv, sf = SPHERE["mid"] if p.r.max() > 0.08 else SPHERE["lo"]
        u, vv = palette.uv(p.color)
        off = len(V)
        for x, y, z in sv:
            pos = p.c + p.R @ (np.array([x, y, z]) * p.r)
            nrm = p.R @ (np.array([x, y, z]) / p.r)
            nrm = nrm / max(np.linalg.norm(nrm), 1e-9)
            V.append((*pos, *nrm, u, vv))
        for a, b, c in sf:
            F.append((off + a, off + b, off + c))
    for x, y, z, nx_, ny_, nz_, u, vv in V:
        lines.append("v %.5f %.5f %.5f" % (x, y, z))
        lines.append("vn %.5f %.5f %.5f" % (nx_, ny_, nz_))
        lines.append("vt %.5f %.5f" % (u, vv))
    for a, b, c in F:
        a, b, c = a + 1, b + 1, c + 1
        lines.append("f %d/%d/%d %d/%d/%d %d/%d/%d" % (a, a, a, b, b, b, c, c, c))
    allv = np.array([v[:3] for v in V])
    bb_min, bb_max = allv.min(axis=0).tolist(), allv.max(axis=0).tolist()
    spheres = [{"x": float(p.c[0]), "y": float(p.c[1]), "z": float(p.c[2]), "r": float(p.r.mean())} for p in base if p.r.max() >= 0.12]
    light = None
    if shape.light:
        l = shape.light
        col = lt(l.color) if l.color else [255, 220, 160]
        light = {"z": float(l.z or 0.5) * size, "color": [int(c) for c in col], "range": float(l.range or 1.3) * size}
    return "\n".join(lines) + "\n", spheres, bb_min, bb_max, len(V), len(F), light


def main():
    argv = sys.argv[1:]
    sizes, cell, blend = None, 0.025, 0.07
    names = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--sizes": sizes = [float(s) for s in argv[i + 1].split(",")]; i += 2
        elif a == "--cell": cell = float(argv[i + 1]); i += 2
        elif a == "--blend": blend = float(argv[i + 1]); i += 2
        else: names.append(a); i += 1
    OUT.mkdir(parents=True, exist_ok=True)
    palette = Palette()
    manifest = []
    for s in lt(Shapes.List):
        if s.kind != "inflatable" or (names and s.name not in names):
            continue
        for size in (sizes or [s.size]):
            model = "sk_infl_%s_%d" % (s.name, round(size * 10))
            obj, spheres, bb_min, bb_max, nv, nf, light = build(s, size, palette, cell, blend)
            (OUT / (model + ".obj")).write_text(obj, encoding="utf-8")
            info = {"model": model, "shape": s.name, "label": s.label, "size": size, "spheres": spheres,
                    "bb_min": bb_min, "bb_max": bb_max, "verts": nv, "tris": nf, "light": light}
            (OUT / (model + ".json")).write_text(json.dumps(info, indent=1), encoding="utf-8")
            manifest.append(info)
            print("%-28s %7d verts %7d tris  %2d collision spheres" % (model, nv, nf, len(spheres)))
    palette.save(OUT / "palette.png", OUT / "sk_infl_palette.dds")
    (OUT / "palette.mtl").write_text("newmtl palette\nKd 1 1 1\nmap_Kd palette.png\n", encoding="utf-8")
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=1), encoding="utf-8")
    print("palette: %d colors" % len(palette.colors))


if __name__ == "__main__":
    main()

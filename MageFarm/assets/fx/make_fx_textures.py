# Generates the VFX particle textures (white on transparent, tinted in code).
# Run headless:  blender -b --factory-startup -P art/make_fx_textures.py
# Output: art/fx/<name>.png (256x256 unless noted)

import math
import os

import bpy
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "fx")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


def grid(n):
    """Pixel-centre coordinates in [-1, 1] (y up)."""
    c = (np.arange(n) + 0.5) / n * 2 - 1
    x, y = np.meshgrid(c, c[::-1])
    return x, y


def save(name, alpha, size=None):
    alpha = np.clip(alpha, 0, 1).astype(np.float32)
    h, w = alpha.shape
    img = bpy.data.images.new(name, width=w, height=h, alpha=True)
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[..., 3] = alpha
    # Blender images are stored bottom row first
    img.pixels.foreach_set(rgba[::-1].ravel())
    img.filepath_raw = os.path.join(OUT, name + ".png")
    img.file_format = "PNG"
    img.save()
    print("wrote", name)


def gauss(d, sigma):
    return np.exp(-(d * d) / (2 * sigma * sigma))


N = 256
x, y = grid(N)
r = np.sqrt(x * x + y * y)
a = np.arctan2(y, x)

# Soft glow orb (fades to zero before the edge)
save("glow", gauss(r, 0.3) * np.clip(1 - r * r, 0, 1))

# 4-point star flare (PS99 twinkle / lens flare)
star = gauss(np.abs(y), 0.035) * gauss(np.abs(x), 0.55) + gauss(np.abs(x), 0.035) * gauss(np.abs(y), 0.55)
star = np.maximum(star, gauss(r, 0.12))
save("star4", star)

# Thin soft ring (shockwave)
save("ring", gauss(r - 0.8, 0.05))

# Sunburst rays (radial god-rays)
rays = (0.5 + 0.5 * np.cos(a * 12)) ** 6
rays *= gauss(r, 0.6) * (1 - gauss(r, 0.08) * 0.0)
rays = np.maximum(rays, gauss(r, 0.18) * 0.9)
save("rays", rays)

# Spark streak (tall thin, for rising sparks)
save("spark", gauss(np.abs(x), 0.06) * gauss(np.abs(y), 0.6))

# Smoke puff: several overlapping soft blobs + noise
smoke = np.zeros_like(r)
for _ in range(9):
    cx, cy = rng.uniform(-0.35, 0.35, 2)
    s = rng.uniform(0.25, 0.42)
    smoke = np.maximum(smoke, gauss(np.sqrt((x - cx) ** 2 + (y - cy) ** 2), s))
noise = rng.random((N // 16, N // 16))
noise = np.kron(noise, np.ones((16, 16)))
k = np.ones(15) / 15
noise = np.apply_along_axis(lambda m: np.convolve(m, k, mode="same"), 0, noise)
noise = np.apply_along_axis(lambda m: np.convolve(m, k, mode="same"), 1, noise)
smoke = smoke * (0.75 + 0.25 * noise) * np.clip(1 - r * r, 0, 1) ** 1.5
save("smoke", smoke)

# Flame wisp (teardrop pointing up)
fy = (y + 1) / 2  # 0 bottom .. 1 top
width = 0.45 * (1 - fy) ** 0.8 + 0.02
flame = gauss(np.abs(x) / np.maximum(width, 1e-3), 0.6) * gauss(fy - 0.25, 0.45) * (fy > 0.02)
save("flame", flame)

# Magic rune circle (Black Clover style grimoire circle)
rune = gauss(r - 0.9, 0.018) + gauss(r - 0.78, 0.012) + gauss(r - 0.45, 0.012)
for i in range(16):  # glyph ticks between the outer rings
    ang = i / 16 * 2 * math.pi
    gx, gy = math.cos(ang) * 0.84, math.sin(ang) * 0.84
    d = np.sqrt((x - gx) ** 2 + (y - gy) ** 2)
    rune += gauss(d, 0.025) * (0.6 if i % 2 else 1.0)
for i in range(4):  # clover leaves in the middle
    ang = math.pi / 4 + i * math.pi / 2
    for side in (-1, 1):
        la = ang + side * 0.45
        lx, ly = math.cos(la) * 0.2, math.sin(la) * 0.2
        rune += gauss(np.sqrt((x - lx) ** 2 + (y - ly) ** 2), 0.08) * 0.9
# five-point star lines (pentagram) inside the inner ring
pts = [(math.cos(math.pi / 2 + k * 4 * math.pi / 5) * 0.45, math.sin(math.pi / 2 + k * 4 * math.pi / 5) * 0.45) for k in range(6)]
for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
    dx, dy = x2 - x1, y2 - y1
    t = np.clip(((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy), 0, 1)
    d = np.sqrt((x - (x1 + t * dx)) ** 2 + (y - (y1 + t * dy)) ** 2)
    rune += gauss(d, 0.01) * 0.8
save("rune", rune)

# Crystal shard (elongated diamond)
shard = np.clip(1 - (np.abs(x) / 0.28 + np.abs(y) / 0.95), 0, 1) ** 0.5
shard *= 0.6 + 0.4 * (x > 0)  # one lit face
save("shard", shard)

# Leaf
lx = x / 0.42
ly = y / 0.9
leaf = np.clip(1 - (lx * lx + ly * ly), 0, 1) ** 0.4 * (np.abs(x) < 0.45 * np.cos(y * math.pi / 2) + 0.02)
leaf *= 1 - gauss(np.abs(x), 0.012) * 0.5  # centre vein
save("leaf", leaf)

# Four-leaf clover silhouette: 4 heart-shaped leaves with gaps between them
clover = np.zeros_like(r)
for i in range(4):
    ang = math.pi / 4 + i * math.pi / 2
    ux, uy = math.cos(ang), math.sin(ang)  # leaf axis
    # leaf-local coords: u along the axis, v across it
    u = x * ux + y * uy
    v = -x * uy + y * ux
    heart = np.zeros_like(r)
    for side in (-1, 1):
        heart = np.maximum(heart, (np.sqrt((u - 0.58) ** 2 + (v - side * 0.17) ** 2) < 0.24).astype(float))
    # tapered body from the centre to the lobes
    body = (u > 0.08) & (u < 0.62) & (np.abs(v) < (u - 0.08) * 0.62)
    clover = np.maximum(clover, np.maximum(heart, body.astype(float)))
clover = np.maximum(clover, (r < 0.09).astype(float))
save("clover", clover * 0.95)

# Trail / beam strip (soft edges, bright core) 256x64
tx, ty = np.meshgrid(np.linspace(-1, 1, 256), np.linspace(-1, 1, 64))
save("trail", gauss(ty, 0.32) * 0.85 + gauss(ty, 0.08) * 0.15)

print("ALL DONE")

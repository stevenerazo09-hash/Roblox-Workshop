# Generates the Sandbox textures into assets/images with numpy (Blender's Python):
#   sky_Bk/Dn/Ft/Lf/Rt/Up.png  stylized purple/blue night skybox with nebula and stars
#   grid.png                   baseplate grid tile (white lines on transparent)
#   aurora.png                 vertical streaks for the aurora beams
#   scanlines.png              System panel scanline + grid tile
#   glow.png                   soft radial glow (moon halo, panel burst)
#
#   "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P tools\make_images.py
#   env ONLY=sky,grid renders a subset; SKY_SIZE=512 for quick previews.
#
# The skybox is a function of the 3D view direction, so the six faces meet
# without seams. Face orientation was measured in Studio with labelled test
# faces (tools/make_sky_debug.ps1): Lf is +X, Rt is -X, Ft is -Z, Bk is +Z, and
# Up/Dn are turned 180 degrees with their top/bottom edge toward +X.

import os
import numpy as np
import bpy

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "images")
ONLY = set(filter(None, os.environ.get("ONLY", "").split(",")))
SKY_SIZE = int(os.environ.get("SKY_SIZE", "1024"))
os.makedirs(OUT, exist_ok=True)


def want(name):
	return not ONLY or name in ONLY


def save_png(name, rgba):
	"""rgba: float array (h, w, 4) in 0..1, row 0 = top of the image."""
	h, w = rgba.shape[:2]
	img = bpy.data.images.new(name, width=w, height=h, alpha=True)
	img.colorspace_settings.name = "sRGB"
	flipped = np.ascontiguousarray(np.clip(rgba[::-1], 0, 1), dtype=np.float32)  # Blender rows start at the bottom
	img.pixels.foreach_set(flipped.ravel())
	img.filepath_raw = os.path.join(OUT, name + ".png")
	img.file_format = "PNG"
	img.save()
	bpy.data.images.remove(img)
	print("wrote", name + ".png", w, "x", h)


def smoothstep(a, b, x):
	t = np.clip((x - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)


def mix(a, b, t):
	t = np.asarray(t)[..., None]
	return np.asarray(a) * (1 - t) + np.asarray(b) * t


def rgb(hex_):
	hex_ = hex_.lstrip("#")
	return np.array([int(hex_[i:i + 2], 16) / 255 for i in (0, 2, 4)])


# ------------------------------------------------------------------ noise
def _hash(ix, iy, iz):
	n = np.sin(ix * 127.1 + iy * 311.7 + iz * 74.7) * 43758.5453
	return n - np.floor(n)


def value_noise(p):
	"""3D value noise in 0..1 for points p (..., 3)."""
	f = np.floor(p)
	t = p - f
	t = t * t * (3 - 2 * t)
	x0, y0, z0 = f[..., 0], f[..., 1], f[..., 2]
	tx, ty, tz = t[..., 0], t[..., 1], t[..., 2]
	c = {}
	for dx in (0, 1):
		for dy in (0, 1):
			for dz in (0, 1):
				c[dx, dy, dz] = _hash(x0 + dx, y0 + dy, z0 + dz)
	x00 = c[0, 0, 0] * (1 - tx) + c[1, 0, 0] * tx
	x10 = c[0, 1, 0] * (1 - tx) + c[1, 1, 0] * tx
	x01 = c[0, 0, 1] * (1 - tx) + c[1, 0, 1] * tx
	x11 = c[0, 1, 1] * (1 - tx) + c[1, 1, 1] * tx
	y0_ = x00 * (1 - ty) + x10 * ty
	y1_ = x01 * (1 - ty) + x11 * ty
	return y0_ * (1 - tz) + y1_ * tz


def fbm(p, octaves=5, lacunarity=2.03, gain=0.5):
	total = np.zeros(p.shape[:-1])
	amp, norm = 1.0, 0.0
	q = p
	for _ in range(octaves):
		total += amp * value_noise(q)
		norm += amp
		amp *= gain
		q = q * lacunarity + 17.31
	return total / norm


# ------------------------------------------------------------------ skybox
def face_dirs(face, n):
	"""Unit view directions for each pixel of a face (row 0 = top)."""
	u = (np.arange(n) + 0.5) / n
	a, b = np.meshgrid(2 * u - 1, 2 * u - 1)  # a: left->right, b: top->bottom
	one = np.ones_like(a)
	vec = {
		"Ft": (a, -b, -one),
		"Bk": (-a, -b, one),
		"Lf": (one, -b, a),
		"Rt": (-one, -b, -a),
		"Up": (-b, one, -a),
		"Dn": (b, -one, -a),
	}[face]
	d = np.stack(vec, axis=-1)
	return d / np.linalg.norm(d, axis=-1, keepdims=True)


ZENITH = rgb("#05061a")
HIGH = rgb("#0b0f36")
MID = rgb("#1d1652")
HORIZON = rgb("#5a2d8c")
HORIZON_HOT = rgb("#c05cd8")
GROUND = rgb("#140a26")
NEB_A = rgb("#b13cff")  # magenta
NEB_B = rgb("#3a62ff")  # blue
NEB_C = rgb("#3fd6ff")  # cyan
BAND_NORMAL = np.array([0.35, 0.72, 0.6]) / np.linalg.norm([0.35, 0.72, 0.6])


def sky_face(face, n, seed):
	d = face_dirs(face, n)
	e = d[..., 1]  # elevation (sin)

	# Base gradient: hot purple horizon, navy overhead, dark violet below
	up = np.clip(e, 0, 1)
	col = mix(HORIZON, MID, smoothstep(0.0, 0.18, up))
	col = mix(col, HIGH, smoothstep(0.15, 0.5, up))
	col = mix(col, ZENITH, smoothstep(0.5, 1.0, up))
	# Horizon glow, brighter in some directions so it isn't a flat line
	glow_var = 0.55 + 0.9 * fbm(d * 1.4 + 23.0, 3)
	glow = np.exp(-np.abs(e) * 8) * glow_var
	col = col + HORIZON_HOT * (glow * 0.28)[..., None]
	col = np.where((e < 0)[..., None], mix(col, GROUND, smoothstep(0.0, 0.25, -e)), col)

	# Nebula: domain-warped fbm in a band across the sky
	p = d * 2.2 + seed
	warp = np.stack([fbm(p + 3.1, 4), fbm(p + 7.7, 4), fbm(p + 11.3, 4)], axis=-1)
	neb = fbm(p * 1.6 + warp * 1.8, 6)
	detail = fbm(p * 5.0 + warp, 4)
	band = np.exp(-((d @ BAND_NORMAL) ** 2) / (2 * 0.33 ** 2))
	density = np.clip((neb - 0.42) * 2.6, 0, 1) ** 1.6 * band * (0.65 + 0.7 * detail)
	density *= smoothstep(-0.08, 0.22, e)
	hue = fbm(p * 0.9 + 40.0, 3)
	ncol = mix(NEB_B, NEB_A, smoothstep(0.38, 0.62, hue))
	ncol = mix(ncol, NEB_C, smoothstep(0.62, 0.8, detail) * 0.6)
	col = col + ncol * (density * 1.15)[..., None]
	# Dark dust lanes cut through the brightest parts
	dust = np.clip((fbm(p * 3.2 + 60.0, 5) - 0.55) * 3.0, 0, 1) * band
	col = col * (1 - 0.45 * dust)[..., None]

	# Stars: many faint ones, a few bright ones with a soft halo
	rng = np.random.default_rng(abs(hash(face)) % 2 ** 32)
	r = rng.random((n, n))
	vis = smoothstep(-0.02, 0.12, e)
	faint = (r > 0.9975) * rng.uniform(0.25, 0.8, (n, n))
	bright = (r > 0.99965) * rng.uniform(0.8, 1.6, (n, n))
	halo = np.zeros_like(bright)
	for dy in (-1, 0, 1):
		for dx in (-1, 0, 1):
			if dx or dy:
				halo += np.roll(np.roll(bright, dy, 0), dx, 1) * (0.35 if dx and dy else 0.55)
	tint = mix(np.array([1.0, 1.0, 1.0]), np.array([0.75, 0.82, 1.0]), rng.random((n, n)))
	stars = (faint + bright + halo)[..., None] * tint * (1 - 0.6 * density)[..., None]
	col = col + stars * vis[..., None]

	# Soft tone map so bright nebula cores don't clip hard
	col = 1 - np.exp(-col * 1.35)
	alpha = np.ones(col.shape[:2])
	return np.concatenate([col, alpha[..., None]], axis=-1)


if want("sky"):
	for face in ("Ft", "Bk", "Lf", "Rt", "Up", "Dn"):
		save_png("sky_" + face, sky_face(face, SKY_SIZE, seed=np.array([4.2, 1.7, 9.3])))

# ------------------------------------------------------------------ grid
if want("grid"):
	n, cells = 256, 4
	px = np.arange(n)
	cell = n // cells
	dist = np.minimum(px % cell, cell - (px % cell))  # distance to nearest line
	line = np.exp(-(dist.astype(float) ** 2) / 1.2)
	glow = np.exp(-(dist.astype(float) ** 2) / 18.0) * 0.25
	a1 = np.clip(line + glow, 0, 1)
	alpha = np.maximum(a1[None, :], a1[:, None])
	rgba = np.ones((n, n, 4))
	rgba[..., 3] = alpha
	save_png("grid", rgba)

# ------------------------------------------------------------------ aurora
if want("aurora"):
	# On a Roblox Beam the image's x axis spans the beam's width (the curtain's
	# height) and its y axis runs along the beam (checked in Studio). So: the
	# height profile goes across the columns (column 0 = the bright base) and
	# the vertical rays vary down the rows.
	w, h = 256, 512
	across = np.linspace(0, 1, w)
	profile = smoothstep(0.0, 0.1, across) * np.exp(-across * 2.4)  # soft base, long fade upward
	edge = np.exp(-((across - 0.12) ** 2) / 0.004) * 0.35  # bright band just above the base
	along = np.linspace(0, 8, h)
	pts = np.stack([along, np.zeros_like(along), np.zeros_like(along)], axis=-1)
	streak = 0.35 + 0.65 * fbm(pts * 3.0 + 5.0, 5) ** 1.5
	streak += 0.15 * np.clip(np.sin(along * 9.0) * 0.5 + 0.5, 0, 1) ** 4
	alpha = np.clip(streak[:, None] * (profile + edge)[None, :], 0, 1)
	rgba = np.ones((h, w, 4))
	rgba[..., 3] = alpha
	save_png("aurora", rgba)

# ------------------------------------------------------------------ scanlines
if want("scanlines"):
	n = 128
	yy, xx = np.mgrid[0:n, 0:n]
	scan = ((yy % 4) == 0) * 0.55
	grid = (((xx % 32) == 0) | ((yy % 32) == 0)) * 0.35
	alpha = np.clip(scan + grid, 0, 1)
	rgba = np.ones((n, n, 4))
	rgba[..., 3] = alpha
	save_png("scanlines", rgba)

# ------------------------------------------------------------------ glow
if want("glow"):
	n = 256
	yy, xx = np.mgrid[0:n, 0:n]
	r = np.hypot(xx - n / 2 + 0.5, yy - n / 2 + 0.5) / (n / 2)
	alpha = np.clip(np.exp(-(r ** 2) * 4.5) - np.exp(-4.5) * r, 0, 1)
	rgba = np.ones((n, n, 4))
	rgba[..., 3] = alpha
	save_png("glow", rgba)

print("done")

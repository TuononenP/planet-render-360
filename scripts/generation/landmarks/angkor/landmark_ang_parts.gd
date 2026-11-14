class_name LandmarkAngParts
extends RefCounted

## Masonry parts shared by the Angkor Thom temples (Baphuon, Phimeanakas,
## the terraces, Preah Palilay, Thommanon, Chau Say Tevoda), in true metres
## on LandmarkMesh: the shared material kit, moulded blocks, steep stairs,
## roofed gallery rings, gopuras and the stone lions, elephants and garudas
## that guard them. Parts take material KEYS registered by `kit`.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")

## Shared Khmer palette for the Angkor park's temples: the weathered grey
## sandstone (lichen-darkened, a little warm at golden hour), its lighter
## mouldings, the porous brown laterite of platforms and enclosure walls
## (brown, not brick-red), the dark stone roof slabs and worn paving. A
## temple keeps its own sandstone hex where the stone really differs
## (Banteay Srei's pink, Banteay Samre's buff); laterite and roofs are one
## stone across the park.
const STONE_GREY := "#827B6D"
const TRIM := "#8C8574"
const LATERITE := "#74583F"
const ROOF := "#5E594F"
const FLAGSTONE := "#7C7668"

## Registers the keys the Angkor temples draw with: sandstone "Stone" (tint
## `stone_hex`) and its lighter mouldings "Trim", "Laterite", the dark
## "Roof" slabs, "Dark" doorways and "Moss".
static func kit(lm: LandmarkMesh, stone_hex: String = "#7D7565") -> void:
	lm.use("Stone", LandmarkMaterials.pbr("stone", stone_hex, 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", TRIM, 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LATERITE, 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("stone", ROOF, 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#242120", 2.0))
	lm.use("Moss", LandmarkMaterials.pbr("forest", "#4E5C34", 4.0))

## Basis turning local +Z toward compass side 0 = south (+Z), 1 = east (+X),
## 2 = north (-Z), 3 = west (-X).
static func facing(side: int) -> Basis:
	return Basis(Vector3.UP, PI * 0.5 * float(side))

## Stair rising `rise` from ground at `base` to local z = 0 and running out
## along the basis +Z; boxes `width` wide. Returns its horizontal run.
static func stair(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, width: float,
		rise: float, riser: float = 0.4, tread: float = 0.36) -> float:
	var n: int = maxi(int(ceil(rise / riser)), 1)
	var r: float = rise / float(n)
	for k in n:
		var hgt: float = r * float(n - k)
		lm.box(key, base + basis * Vector3(0, hgt * 0.5, tread * (float(k) + 0.5)),
			Vector3(width, hgt, tread), basis, 0.0)
	return tread * float(n)

## Moulded masonry block h tall, footprint centred on `c` (ground point) with
## half-sizes hx, hz: the die, a base moulding, a string course and a cornice.
static func block(lm: LandmarkMesh, key: String, trim: String, c: Vector3, hx: float, hz: float,
		h: float) -> void:
	lm.box(key, c + Vector3(0, h * 0.5, 0), Vector3(hx * 2.0, h, hz * 2.0))
	lm.box(trim, c + Vector3(0, 0.3, 0), Vector3(hx * 2.0 + 0.6, 0.6, hz * 2.0 + 0.6), Basis(), 0.0)
	lm.box(trim, c + Vector3(0, h * 0.5, 0), Vector3(hx * 2.0 + 0.2, 0.2, hz * 2.0 + 0.2), Basis(), 0.0)
	lm.box(trim, c + Vector3(0, h - 0.25, 0), Vector3(hx * 2.0 + 0.5, 0.5, hz * 2.0 + 0.5), Basis(), 0.0)

## One roofed gallery range from ground point a to b, `t` thick and `h` to
## the eaves, a gabled slab roof on top and dark window slots along the
## face that looks toward `out`.
static func run(lm: LandmarkMesh, wall: String, roof: String, dark: String, a: Vector3, b: Vector3,
		t: float, h: float, out: Vector3) -> void:
	var d := b - a
	var ln := d.length()
	if ln < 0.5:
		return
	var basis := Basis(Vector3.UP, atan2(d.x, d.z))
	var m := (a + b) * 0.5
	lm.box(wall, m + Vector3(0, h * 0.5, 0), Vector3(t, h, ln), basis)
	lm.box(roof, m + Vector3(0, h + 0.15, 0), Vector3(t + 0.9, 0.3, ln + 0.4), basis, 0.0)
	lm.gable(roof, m + Vector3(0, h + 0.3, 0), t + 0.2, ln, 1.1, basis, 0.3, wall)
	var side: float = 1.0 if out.dot(basis.x) > 0.0 else -1.0
	var n: int = int(ln / 4.0)
	for i in n:
		var z: float = -ln * 0.5 + ln * (float(i) + 0.5) / float(n)
		lm.box(dark, m + basis * Vector3(side * (t * 0.5 + 0.03), h * 0.55, z),
			Vector3(0.1, h * 0.38, 1.0), basis, 0.0)

## Rectangular gallery ring on the platform at height y: outer half-sizes
## hx, hz, ranges `t` thick, `h` to the eaves, broken by a `gap`-wide opening
## in the middle of every side (gap 0 = closed).
static func ring(lm: LandmarkMesh, wall: String, roof: String, dark: String, y: float, hx: float,
		hz: float, t: float, h: float, gap: float) -> void:
	var cx := hx - t * 0.5
	var cz := hz - t * 0.5
	var g := gap * 0.5
	for s in [-1.0, 1.0]:
		var oz := Vector3(0, 0, s)
		var ox := Vector3(s, 0, 0)
		if g > 0.1:
			run(lm, wall, roof, dark, Vector3(-cx, y, s * cz), Vector3(-g, y, s * cz), t, h, oz)
			run(lm, wall, roof, dark, Vector3(g, y, s * cz), Vector3(cx, y, s * cz), t, h, oz)
			run(lm, wall, roof, dark, Vector3(s * cx, y, -cz + t * 0.5), Vector3(s * cx, y, -g), t, h, ox)
			run(lm, wall, roof, dark, Vector3(s * cx, y, g), Vector3(s * cx, y, cz - t * 0.5), t, h, ox)
		else:
			run(lm, wall, roof, dark, Vector3(-cx, y, s * cz), Vector3(cx, y, s * cz), t, h, oz)
			run(lm, wall, roof, dark, Vector3(s * cx, y, -cz + t * 0.5), Vector3(s * cx, y, cz - t * 0.5),
				t, h, ox)

## Gateway pavilion standing at ground point `base`, its passage along the
## basis +Z: a moulded plinth, a gabled hall `hall_l` long under a stepped
## tower of half-width `hw`, `tower_h` tall in all (plinth included); `full`
## builds the redented sanctuary tower, otherwise three plain receding steps.
static func gopura(lm: LandmarkMesh, wall: String, roof: String, dark: String, base: Vector3,
		basis: Basis, hw: float, tower_h: float, hall_l: float, full: bool = true) -> void:
	lm.box(wall, base + basis * Vector3(0, 0.4, 0), Vector3(hw * 2.6, 0.8, hall_l + 1.0), basis)
	var wall_h := tower_h * 0.4
	lm.box(wall, base + basis * Vector3(0, 0.8 + wall_h * 0.5, 0), Vector3(hw * 1.8, wall_h, hall_l), basis)
	lm.gable(roof, base + basis * Vector3(0, 0.8 + wall_h, 0), hw * 1.8 + 0.3, hall_l, wall_h * 0.35,
		basis, 0.4, wall)
	for s in [-1.0, 1.0]:
		lm.box(dark, base + basis * Vector3(0, 0.8 + wall_h * 0.4, s * (hall_l * 0.5 + 0.03)),
			Vector3(hw * 0.9, wall_h * 0.8, 0.1), basis, 0.0)
	if full:
		U.prasat(lm, wall, roof, dark, base + Vector3(0, 0.8, 0), hw, tower_h - 0.8, 3, 0.3)
		return
	var step_h := (tower_h - 0.8 - wall_h) / 3.0
	for q in 3:
		var w := hw * (1.6 - 0.4 * float(q)) * 2.0
		lm.box(roof, base + Vector3(0, 0.8 + wall_h + step_h * (float(q) + 0.5), 0), Vector3(w, step_h, w),
			Basis(), 0.0)

## Seated stone lion of height s at `base`, facing the basis +Z.
static func lion(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, s: float) -> void:
	lm.box(key, base + basis * Vector3(0, s * 0.225, -s * 0.2), Vector3(s * 0.5, s * 0.45, s * 0.6), basis, 0.0)
	lm.box(key, base + basis * Vector3(0, s * 0.4, s * 0.15), Vector3(s * 0.42, s * 0.8, s * 0.35), basis, 0.0)
	lm.box(key, base + basis * Vector3(0, s * 0.8, s * 0.22), Vector3(s * 0.56, s * 0.4, s * 0.3), basis, 0.0)
	lm.box(key, base + basis * Vector3(0, s * 0.78, s * 0.42), Vector3(s * 0.34, s * 0.3, s * 0.2), basis, 0.0)
	for sx in [-1.0, 1.0]:
		lm.box(key, base + basis * Vector3(sx * s * 0.14, s * 0.25, s * 0.38), Vector3(s * 0.1, s * 0.5, s * 0.12),
			basis, 0.0)

## Standing stone elephant of height s (head and back) at `base`, facing the
## basis +Z, trunk curling down in front.
static func elephant(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, s: float) -> void:
	lm.box(key, base + basis * Vector3(0, s * 0.62, -s * 0.05), Vector3(s * 0.55, s * 0.5, s * 0.95), basis, 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box(key, base + basis * Vector3(sx * s * 0.18, s * 0.19, sz * s * 0.3 - s * 0.05),
				Vector3(s * 0.15, s * 0.38, s * 0.15), basis, 0.0)
	lm.box(key, base + basis * Vector3(0, s * 0.75, s * 0.55), Vector3(s * 0.34, s * 0.4, s * 0.34), basis, 0.0)
	lm.beam(key, base + basis * Vector3(0, s * 0.62, s * 0.74), base + basis * Vector3(0, s * 0.1, s * 0.84),
		s * 0.12, s * 0.1, basis * Vector3.RIGHT)
	for sx in [-1.0, 1.0]:
		lm.box(key, base + basis * Vector3(sx * s * 0.24, s * 0.74, s * 0.46), Vector3(s * 0.05, s * 0.34, s * 0.3),
			basis, 0.0)

## Garuda guardian of height s, wings raised, standing at `base` and facing
## the basis +Z.
static func garuda(lm: LandmarkMesh, key: String, base: Vector3, basis: Basis, s: float) -> void:
	for sx in [-1.0, 1.0]:
		lm.box(key, base + basis * Vector3(sx * s * 0.09, s * 0.2, 0), Vector3(s * 0.12, s * 0.4, s * 0.12),
			basis, 0.0)
		var sh := base + basis * Vector3(sx * s * 0.17, s * 0.72, -s * 0.02)
		lm.beam(key, sh, sh + basis * Vector3(sx * s * 0.28, s * 0.3, -s * 0.06), s * 0.16, s * 0.05,
			basis * Vector3.BACK)
	lm.box(key, base + basis * Vector3(0, s * 0.55, 0), Vector3(s * 0.34, s * 0.4, s * 0.2), basis, 0.0)
	lm.box(key, base + basis * Vector3(0, s * 0.8, 0.0), Vector3(s * 0.2, s * 0.18, s * 0.18), basis, 0.0)
	lm.box(key, base + basis * Vector3(0, s * 0.78, s * 0.13), Vector3(s * 0.06, s * 0.08, s * 0.1), basis, 0.0)
	lm.spire(key, base + basis * Vector3(0, s * 0.89, 0), s * 0.08, s * 0.14, 0.0)

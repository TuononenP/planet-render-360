class_name LandmarkSfAlcatrazBuildings
extends RefCounted

## The buildings and structures of Alcatraz Island in true metres on a
## LandmarkMesh, in the island frame of LandmarkSfAlcatraz (+X along
## bearing 125 degrees, +Z along 215 degrees, y = 0 at the water). Each
## stands on a pad whose height comes from the island's ground function
## `gy` (Vector2 -> metres, -1 off the island). Keys: Concrete, Stucco,
## Roof, Glass, Rust, White, Light, Ruin, Steel, Asphalt.

const SKIN := 0.35
const ISLAND_BEARING := 125.0

## Yaw of a building whose long axis runs along compass `bearing`.
static func basis_for(bearing: float) -> Basis:
	return Basis(Vector3.UP, -deg_to_rad(bearing - ISLAND_BEARING))

## Foundation under a footprint (centre `c`, `size` x by z): a block from
## below the lowest corner up to the mean ground, so a building on a
## terrace edge never floats. Returns the floor height.
static func pad(lm: LandmarkMesh, gy: Callable, c: Vector2, size: Vector2, basis: Basis) -> float:
	var lo := INF
	var sum := 0.0
	var n := 0
	for o in [Vector2(0, 0), Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
		var ov: Vector2 = o
		var q: Vector3 = basis * Vector3(ov.x * size.x * 0.5, 0.0, ov.y * size.y * 0.5)
		var y: float = gy.call(c + Vector2(q.x, q.z))
		lo = minf(lo, maxf(y, 0.0))
		if y > 0.0:
			sum += y
			n += 1
	var base: float = sum / float(n) if n > 0 else 3.0
	var bottom := maxf(lo - 6.0, 0.0)
	var h := base - bottom
	if h > 0.1:
		lm.box("Concrete", Vector3(c.x, bottom + h * 0.5, c.y), Vector3(size.x + 0.6, h, size.y + 0.6), basis, 0.0)
	return base

## Walled block `size` (x long, y tall, z deep) standing at `base`, every
## face pierced with real window openings (`win` size, first sill, storeys
## `storey` apart, one bay per `bay` m).
static func block(lm: LandmarkMesh, wall: String, c: Vector2, base: float, size: Vector3, basis: Basis,
		win: Vector2, sill: float, storey: float, bay: float) -> void:
	var mw := size.x - 2.0 * SKIN
	var md := size.z - 2.0 * SKIN
	var ctr := Vector3(c.x, base, c.y)
	lm.box(wall, ctr + Vector3(0, size.y * 0.5, 0), Vector3(mw, size.y, md), basis, 0.0)
	var normals: Array[Vector3] = [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]
	for f in 4:
		var along_x := f < 2
		var fw := mw if along_x else md
		var half := md * 0.5 if along_x else mw * 0.5
		var n: Vector3 = basis * normals[f]
		var right: Vector3 = n.cross(Vector3.UP)
		var origin := ctr + n * half - right * fw * 0.5
		var cols := maxi(1, roundi(fw / bay))
		var rows := maxi(1, floori((size.y - sill - 0.3) / storey) + 1)
		LandmarkDetail.pierced_face(lm, wall, "Glass", origin, right, n, fw, size.y, cols, rows, win, sill,
			storey, SKIN)

## Flat roof slab with a parapet round it, top of the walls at y.
static func flat_roof(lm: LandmarkMesh, key: String, c: Vector2, y: float, size: Vector2, basis: Basis,
		parapet: float = 0.9) -> void:
	lm.box(key, Vector3(c.x, y + 0.15, c.y), Vector3(size.x + 0.5, 0.3, size.y + 0.5), basis, 0.0)
	for s in [-1.0, 1.0]:
		var oz: Vector3 = basis * Vector3(0, 0, float(s) * (size.y * 0.5 + 0.1))
		lm.box(key, Vector3(c.x, y + 0.3 + parapet * 0.5, c.y) + oz, Vector3(size.x + 0.5, parapet, 0.35), basis, 0.0)
		var ox: Vector3 = basis * Vector3(float(s) * (size.x * 0.5 + 0.1), 0, 0)
		lm.box(key, Vector3(c.x, y + 0.3 + parapet * 0.5, c.y) + ox, Vector3(0.35, parapet, size.y + 0.5), basis, 0.0)

## Pitched roof over a block whose long axis is the building's local X.
static func gable_roof(lm: LandmarkMesh, key: String, wall: String, c: Vector2, y: float, size: Vector2,
		basis: Basis, rise: float) -> void:
	var gb := basis * Basis(Vector3.UP, -PI * 0.5)
	lm.gable(key, Vector3(c.x, y, c.y), size.y, size.x, rise, gb, 0.5, wall)

## The 1912 Main Cellhouse: 137 x 30 m, three tiers of cells behind tall
## steel-sash windows, flat roof with a long glazed monitor over the
## corridors and ventilator stacks, and the recreation yard walled on
## the cliff side.
static func cellhouse(lm: LandmarkMesh, gy: Callable, c: Vector2) -> void:
	var basis := basis_for(137.0)
	var size := Vector2(137.0, 30.0)
	var base := pad(lm, gy, c, size, basis)
	var h := 14.0
	block(lm, "Concrete", c, base, Vector3(size.x, h, size.y), basis, Vector2(1.7, 2.9), 1.2, 4.3, 3.4)
	flat_roof(lm, "Roof", c, base + h, size, basis, 0.8)
	var top := base + h + 0.3
	# Glazed monitor over the cell blocks, and the two corridor skylights.
	lm.box("Concrete", Vector3(c.x, top + 0.9, c.y), Vector3(104.0, 1.8, 7.0), basis)
	for s in [-1.0, 1.0]:
		var o: Vector3 = basis * Vector3(0, 0, float(s) * 3.55)
		lm.box("Glass", Vector3(c.x, top + 1.0, c.y) + o, Vector3(103.0, 1.1, 0.12), basis, 0.0)
	lm.box("Roof", Vector3(c.x, top + 1.9, c.y), Vector3(105.0, 0.25, 8.0), basis, 0.0)
	# Ventilator stacks along the roof.
	for i in 9:
		var lx := -52.0 + 13.0 * float(i)
		var p: Vector3 = basis * Vector3(lx, 0, 9.0)
		lm.frustum("Steel", Vector3(c.x + p.x, top, c.y + p.z), 0.7, 0.55, 2.6, 8)
		lm.frustum("Steel", Vector3(c.x + p.x, top + 2.6, c.y + p.z), 1.0, 0.0, 0.6, 8)
		var q: Vector3 = basis * Vector3(lx + 6.0, 0, -9.0)
		lm.frustum("Steel", Vector3(c.x + q.x, top, c.y + q.z), 0.7, 0.55, 2.2, 8)
	# Recreation yard on the cliff (+Z) side, walled, with steps down.
	var yc := c + Vector2((basis * Vector3(-24.0, 0, 30.0)).x, (basis * Vector3(-24.0, 0, 30.0)).z)
	lm.box("Concrete", Vector3(yc.x, base + 0.12, yc.y), Vector3(44.0, 0.24, 24.0), basis, 0.0)
	for s in [-1.0, 1.0]:
		var wz: Vector3 = basis * Vector3(0, 0, float(s) * 12.0)
		lm.box("Concrete", Vector3(yc.x, base + 1.8, yc.y) + wz, Vector3(44.0, 3.6, 0.5), basis, 0.0)
		var wx: Vector3 = basis * Vector3(float(s) * 22.0, 0, 0)
		lm.box("Concrete", Vector3(yc.x, base + 1.8, yc.y) + wx, Vector3(0.5, 3.6, 24.0), basis, 0.0)
	var door: Vector3 = basis * Vector3(-32.0, 0, 16.6)
	lm.box("Concrete", Vector3(c.x + door.x, base + 0.15, c.y + door.z), Vector3(8.0, 0.3, 3.4), basis, 0.0)

## Administration Block at the cellhouse's sally end: 36 x 19 m, three
## storeys, cornice and a pedimented entrance bay.
static func admin(lm: LandmarkMesh, gy: Callable, c: Vector2) -> void:
	var basis := basis_for(53.0)
	var size := Vector2(36.0, 19.0)
	var base := pad(lm, gy, c, size, basis)
	block(lm, "Stucco", c, base, Vector3(size.x, 12.5, size.y), basis, Vector2(1.3, 2.1), 1.1, 4.0, 3.4)
	flat_roof(lm, "Roof", c, base + 12.5, size, basis, 1.0)
	var o: Vector3 = basis * Vector3(0, 0, size.y * 0.5 + 0.6)
	lm.box("Concrete", Vector3(c.x, base + 2.4, c.y) + o, Vector3(7.0, 4.8, 1.4), basis)
	lm.box("Concrete", Vector3(c.x, base + 5.2, c.y) + o, Vector3(8.0, 0.6, 2.0), basis)
	lm.box("Glass", Vector3(c.x, base + 1.8, c.y) + basis * Vector3(0, 0, size.y * 0.5 + 1.35), Vector3(2.2, 3.4, 0.1), basis, 0.0)

## Warden's house / officers' club / chapel style ruin: burned shell with
## empty openings, broken top edge and the standing chimneys.
static func ruin(lm: LandmarkMesh, gy: Callable, c: Vector2, size: Vector2, bearing: float, h: float) -> void:
	var basis := basis_for(bearing)
	var base := pad(lm, gy, c, size, basis)
	block(lm, "Ruin", c, base, Vector3(size.x, h, size.y), basis, Vector2(1.1, 1.8), 1.0, 3.5, 3.2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(c.x * 31.0 + c.y * 17.0))
	for i in 5:
		var lx := (rng.randf() - 0.5) * (size.x - 3.0)
		var lz := (rng.randf() - 0.5) * (size.y - 2.0)
		var p: Vector3 = basis * Vector3(lx, 0, lz)
		var ch := 2.0 + rng.randf() * 3.0
		lm.box("Ruin", Vector3(c.x + p.x, base + h + ch * 0.5 - 0.3, c.y + p.z), Vector3(0.9, ch, 0.9), basis)
	for s in [-1.0, 1.0]:
		var p: Vector3 = basis * Vector3(float(s) * (size.x * 0.5 - 1.2), 0, 0)
		lm.box("Ruin", Vector3(c.x + p.x, base + h + 2.0, c.y + p.z), Vector3(1.3, 4.0, 1.6), basis)

## Chapel: small gabled hall with a bell cote.
static func chapel(lm: LandmarkMesh, gy: Callable, c: Vector2) -> void:
	var basis := basis_for(107.0)
	var size := Vector2(18.0, 13.0)
	var base := pad(lm, gy, c, size, basis)
	block(lm, "Stucco", c, base, Vector3(size.x, 6.0, size.y), basis, Vector2(1.0, 2.3), 1.2, 9.0, 3.6)
	gable_roof(lm, "Roof", "Stucco", c, base + 6.0, size, basis, 3.2)
	var p: Vector3 = basis * Vector3(size.x * 0.5 - 1.0, 0, 0)
	lm.box("Stucco", Vector3(c.x + p.x, base + 9.5, c.y + p.z), Vector3(1.4, 2.6, 1.4), basis)
	lm.spire("Roof", Vector3(c.x + p.x, base + 10.8, c.y + p.z), 1.0, 1.8, 0.0)

## Guard tower: square concrete shaft with a glazed cab, overhanging roof.
static func guard_tower(lm: LandmarkMesh, gy: Callable, c: Vector2, bearing: float, h: float = 8.5) -> void:
	var basis := basis_for(bearing)
	var size := Vector2(5.0, 5.0)
	var base := pad(lm, gy, c, size, basis)
	lm.box("Concrete", Vector3(c.x, base + (h - 2.8) * 0.5, c.y), Vector3(4.2, h - 2.8, 4.2), basis)
	block(lm, "Concrete", c, base + h - 2.8, Vector3(5.0, 2.4, 5.0), basis, Vector2(1.5, 1.2), 0.7, 9.0, 1.7)
	lm.box("Roof", Vector3(c.x, base + h - 0.2, c.y), Vector3(6.2, 0.4, 6.2), basis, 0.0)
	lm.box("Steel", Vector3(c.x, base + h + 0.25, c.y), Vector3(0.1, 0.9, 0.1), basis, 0.0)
	lm.box("Concrete", basis * Vector3(0, 0, 2.2) + Vector3(c.x, base + 1.2, c.y), Vector3(1.1, 2.4, 0.3), basis)

## Sally port: crenellated stone gatehouse with the arched passage.
static func sally_port(lm: LandmarkMesh, gy: Callable, c: Vector2) -> void:
	var basis := basis_for(136.0)
	var size := Vector2(26.0, 17.0)
	var base := pad(lm, gy, c, size, basis)
	var h := 8.0
	lm.box("Concrete", Vector3(c.x, base + h * 0.5, c.y), Vector3(size.x - 0.4, h, size.y - 0.4), basis, 0.0)
	# Arched openings through both long faces, crenellations on top.
	for s in [-1.0, 1.0]:
		var n: Vector3 = basis * Vector3(0, 0, float(s))
		var face := Vector3(c.x, base, c.y) + n * (size.y * 0.5 - 0.2)
		lm.box("Glass", face + Vector3(0, 2.0, 0), Vector3(3.4, 4.0, 0.12), basis, 0.0)
		LandmarkDetail.arch(lm, "Concrete", face + Vector3(0, 4.0, 0) + n * 0.05, n, 3.4, 0.5, 0.4)
		for k in 2:
			var wx: Vector3 = basis * Vector3(float(s) * 0.0 + (-7.0 if k == 0 else 7.0), 0, 0)
			lm.box("Glass", face + wx + Vector3(0, 4.6, 0), Vector3(1.0, 2.0, 0.12), basis, 0.0)
	for i in 18:
		var lx := -size.x * 0.5 + 0.8 + 1.5 * float(i)
		for s in [-1.0, 1.0]:
			var p: Vector3 = basis * Vector3(lx, 0, float(s) * (size.y * 0.5 - 0.3))
			lm.box("Concrete", Vector3(c.x + p.x, base + h + 0.5, c.y + p.z), Vector3(0.9, 1.0, 0.6), basis, 0.0)
	lm.box("Concrete", Vector3(c.x, base + h + 0.1, c.y), Vector3(size.x, 0.2, size.y), basis, 0.0)

## Building 64: the three-storey apartment block above the dock.
static func apartments(lm: LandmarkMesh, gy: Callable, c: Vector2) -> void:
	var basis := basis_for(135.0)
	var size := Vector2(70.0, 16.0)
	var base := pad(lm, gy, c, size, basis)
	block(lm, "Stucco", c, base, Vector3(size.x, 11.5, size.y), basis, Vector2(1.2, 1.9), 1.2, 3.7, 3.2)
	gable_roof(lm, "Roof", "Stucco", c, base + 11.5, size, basis, 3.6)
	for i in 4:
		var p: Vector3 = basis * Vector3(-24.0 + 16.0 * float(i), 0, 0)
		lm.box("Concrete", Vector3(c.x + p.x, base + 15.8, c.y + p.z), Vector3(1.0, 3.6, 1.0), basis)

## Dining hall / New Industries / Model Industries style flat-roofed
## industrial or institutional block with a strip of windows.
static func hall(lm: LandmarkMesh, gy: Callable, c: Vector2, size: Vector2, bearing: float, h: float,
		win: Vector2, storey: float, bay: float, wall: String = "Concrete", monitor: bool = false) -> void:
	var basis := basis_for(bearing)
	var base := pad(lm, gy, c, size, basis)
	block(lm, wall, c, base, Vector3(size.x, h, size.y), basis, win, 1.2, storey, bay)
	flat_roof(lm, "Roof", c, base + h, size, basis, 0.8)
	if monitor:
		lm.box(wall, Vector3(c.x, base + h + 1.5, c.y), Vector3(size.x * 0.7, 1.6, size.y * 0.3), basis)
		lm.box("Glass", Vector3(c.x, base + h + 1.6, c.y) + basis * Vector3(0, 0, size.y * 0.15 + 0.02),
			Vector3(size.x * 0.68, 0.9, 0.1), basis, 0.0)
		lm.box("Roof", Vector3(c.x, base + h + 2.45, c.y), Vector3(size.x * 0.72, 0.2, size.y * 0.34), basis, 0.0)

## Quartermaster's: two-storey stucco warehouse under a gable.
static func quartermaster(lm: LandmarkMesh, gy: Callable, c: Vector2) -> void:
	var basis := basis_for(130.0)
	var size := Vector2(34.0, 13.0)
	var base := pad(lm, gy, c, size, basis)
	block(lm, "Stucco", c, base, Vector3(size.x, 7.6, size.y), basis, Vector2(1.2, 1.8), 1.2, 3.6, 3.4)
	gable_roof(lm, "Roof", "Stucco", c, base + 7.6, size, basis, 3.0)

## Powerhouse (1939 generating plant) with its tall concrete smokestack.
static func powerhouse(lm: LandmarkMesh, gy: Callable, c: Vector2) -> void:
	var basis := basis_for(78.0)
	var size := Vector2(40.0, 24.0)
	var base := pad(lm, gy, c, size, basis)
	block(lm, "Concrete", c, base, Vector3(size.x, 11.0, size.y), basis, Vector2(2.0, 4.2), 1.4, 5.0, 4.2)
	flat_roof(lm, "Roof", c, base + 11.0, size, basis, 0.9)
	var p: Vector3 = basis * Vector3(size.x * 0.5 + 3.0, 0, 4.0)
	var sb := Vector3(c.x + p.x, base, c.y + p.z)
	lm.lathe("Concrete", sb, PackedVector2Array([Vector2(2.9, 0.0), Vector2(2.6, 3.0), Vector2(2.0, 14.0),
		Vector2(1.65, 28.0), Vector2(1.9, 28.6), Vector2(1.9, 29.2)]), 14)
	for k in 5:
		LandmarkNaParts.ring(lm, "Steel", sb + Vector3(0, 5.0 + 5.0 * float(k), 0), 2.6 - 0.18 * float(k), 0.25, 0.3, 14)
	lm.box("Concrete", Vector3(c.x + p.x, base + 2.5, c.y + p.z) - basis * Vector3(4.0, 0, 0), Vector3(8.0, 5.0, 4.0), basis)

## Water tower: riveted rust-red tank on a braced steel trestle.
static func water_tower(lm: LandmarkMesh, gy: Callable, c: Vector2) -> void:
	var basis := basis_for(107.0)
	var base := pad(lm, gy, c, Vector2(11.0, 11.0), basis)
	var leg_h := 13.0
	var legs := 8
	var b0 := Vector3(c.x, base, c.y)
	for i in legs:
		var a := TAU * float(i) / float(legs)
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Rust", b0 + d * 5.0, b0 + d * 3.5 + Vector3(0, leg_h, 0), 0.4, 0.4)
		lm.box("Concrete", b0 + d * 5.0 + Vector3(0, 0.3, 0), Vector3(1.0, 0.6, 1.0), Basis(), 0.0)
	for lv in 3:
		var y := 3.0 + 3.6 * float(lv)
		var r := 5.0 - 1.5 * (y / leg_h)
		for i in legs:
			var a0 := TAU * float(i) / float(legs)
			var a1 := TAU * float(i + 1) / float(legs)
			var p0 := b0 + Vector3(cos(a0) * r, y, sin(a0) * r)
			var p1 := b0 + Vector3(cos(a1) * r, y, sin(a1) * r)
			lm.beam("Rust", p0, p1, 0.22, 0.22)
			var q1 := b0 + Vector3(cos(a1) * (r - 0.45), y + 3.6, sin(a1) * (r - 0.45))
			lm.beam("Rust", p0, q1, 0.14, 0.14)
	var tb := b0 + Vector3(0, leg_h, 0)
	lm.lathe("Rust", tb, PackedVector2Array([Vector2(0.1, 0.0), Vector2(3.9, 0.0), Vector2(4.2, 0.4),
		Vector2(4.25, 6.8), Vector2(4.1, 7.0)]), 20)
	for k in 5:
		LandmarkNaParts.ring(lm, "Steel", tb + Vector3(0, 1.0 + 1.4 * float(k), 0), 4.2, 0.2, 0.25, 20)
	lm.lathe("Rust", tb + Vector3(0, 7.0, 0), PackedVector2Array([Vector2(4.5, 0.0), Vector2(0.15, 2.6)]), 20)
	lm.beam("Steel", tb + Vector3(4.3, 0.0, 0.0), tb + Vector3(4.3, 7.0, 0.0), 0.12, 0.3)
	lm.box("Steel", tb + Vector3(0, 9.9, 0), Vector3(0.1, 0.8, 0.1), Basis(), 0.0)

## Lighthouse (1909): keeper's base, tapering octagonal concrete tower,
## gallery with railing, glazed lantern, dome and finial. `b` is the
## summit height; the finial tip stands exactly `total` above it.
static func lighthouse(lm: LandmarkMesh, c: Vector2, b: float, total: float) -> void:
	var base := Vector3(c.x, b, c.y)
	var basis := basis_for(118.0)
	lm.box("Stucco", base + Vector3(0, 3.2, 0), Vector3(11.0, 6.4, 8.0), basis)
	lm.box("White", base + Vector3(0, 6.6, 0), Vector3(11.8, 0.4, 8.8), basis, 0.0)
	LandmarkDetail.cornice(lm, "White", base + basis * Vector3(-5.5, 6.4, 4.3), base + basis * Vector3(5.5, 6.4, 4.3),
		basis * Vector3(0, 0, 1), 0.6, false)
	for i in 5:
		var lx := -4.0 + 2.0 * float(i)
		for s in [-1.0, 1.0]:
			var p: Vector3 = basis * Vector3(lx, 0, float(s) * 4.02)
			lm.box("Glass", base + p + Vector3(0, 3.0, 0), Vector3(0.9, 1.8, 0.1), basis, 0.0)
	var ty := 6.8
	var gallery := total - 4.4
	lm.lathe("White", base + Vector3(0, ty, 0), PackedVector2Array([Vector2(2.9, 0.0), Vector2(2.6, (gallery - ty) * 0.5),
		Vector2(2.3, gallery - ty)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 4:
		var y := ty + 2.2 + 3.6 * float(k)
		var r := LandmarkNaParts.radius_at(PackedVector2Array([Vector2(2.9, 0.0), Vector2(2.3, gallery - ty)]), y - ty) + 0.05
		for a in 4:
			var d := Vector3(cos(TAU * float(a) / 4.0 + PI / 4.0), 0, sin(TAU * float(a) / 4.0 + PI / 4.0))
			lm.box("Glass", base + d * r + Vector3(0, y, 0), Vector3(0.5, 1.2, 0.1), Basis.looking_at(d), 0.0)
	# Gallery: corbelled floor, rail, lantern with lens and dome.
	var gb := base + Vector3(0, gallery, 0)
	lm.lathe("White", gb + Vector3(0, -0.8, 0), PackedVector2Array([Vector2(2.3, 0.0), Vector2(3.5, 0.5), Vector2(3.6, 0.8)]), 16)
	LandmarkNaParts.ring_rail(lm, "Steel", gb + Vector3(0, 0.0, 0), 3.4, 1.1, 1.2)
	lm.lathe("White", gb, PackedVector2Array([Vector2(3.5, 0.0), Vector2(3.5, 0.3), Vector2(1.9, 0.35)]), 16)
	lm.lathe("Glass", gb + Vector3(0, 0.3, 0), PackedVector2Array([Vector2(1.7, 0.0), Vector2(1.7, 2.2)]), 12, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Light", gb + Vector3(0, 0.6, 0), PackedVector2Array([Vector2(0.5, 0.0), Vector2(0.7, 0.7), Vector2(0.4, 1.5)]), 10)
	LandmarkNaParts.ring_posts(lm, "Steel", gb + Vector3(0, 0.3, 0), 1.75, 2.2, 8, 0.14, 0.14, 0.5)
	lm.lathe("Steel", gb + Vector3(0, 2.5, 0), PackedVector2Array([Vector2(2.1, 0.0), Vector2(2.0, 0.2), Vector2(1.2, 0.8),
		Vector2(0.4, 1.3), Vector2(0.05, total - gallery - 2.5)]), 16)

## Dock: concrete pier deck with fender line, bollards, and the small
## dock office.
static func dock(lm: LandmarkMesh, poly: PackedVector2Array, y: float) -> void:
	lm.poly_prism("Concrete", poly, y - 0.05, y + 0.6)
	var n := poly.size()
	for i in n:
		var p := poly[i]
		var q := poly[(i + 1) % n]
		var d := q - p
		var ln := d.length()
		if ln < 3.0:
			continue
		var a := atan2(-d.y, d.x)
		lm.box("Steel", Vector3((p.x + q.x) * 0.5, y + 0.9, (p.y + q.y) * 0.5), Vector3(ln, 0.12, 0.2), Basis(Vector3.UP, a), 0.0)
		var cnt := int(ln / 6.0)
		for k in cnt + 1:
			var t := float(k) / float(maxi(cnt, 1))
			var bp := p.lerp(q, t)
			lm.frustum("Steel", Vector3(bp.x, y + 0.6, bp.y), 0.22, 0.28, 0.5, 8)
	lm.box("Stucco", Vector3(130.0, y + 2.4, -102.0), Vector3(12.0, 3.6, 6.0))
	lm.box("Roof", Vector3(130.0, y + 4.4, -102.0), Vector3(13.0, 0.4, 7.0), Basis(), 0.0)
	for k in 4:
		lm.box("Glass", Vector3(124.8 + 3.4 * float(k), y + 2.7, -98.97), Vector3(1.4, 1.4, 0.1), Basis(), 0.0)

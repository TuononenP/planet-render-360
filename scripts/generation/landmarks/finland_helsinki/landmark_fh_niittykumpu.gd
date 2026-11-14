class_name LandmarkFhNiittykumpu
extends RefCounted

## Niittykumpu's metro-centre skyline, true metres, extruded from
## OpenStreetMap outlines (LandmarkFhWestFootprints): Niittyhuippu (SRV
## 2017, 24 storeys, 90 m, white, butterfly roof) and the 12-storey white
## Niittytori tower rising out of the Niitty mall podium
## (LandmarkFhMalls.niitty), the dark 16-storey tower at Niittytaival 5
## (2020, OSM building:colour #2e211b) and the Paavilainens' red-brick
## Olari Church (1981): brick pilasters and full-height, very narrow
## windows on the Merituulentie front. Sources and estimates:
## docs/espoo-landmark-sources.md.

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

## Height of the mall podium the metro-centre towers rise from.
const PODIUM_M := 14.0
## Depth of Niittytaival's balconies from the brick (the outline's proud
## runs give 1.2–1.35 m; the balconies reach a little past them).
const BALCONY_DEPTH_M := 2.0

static func _materials() -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("concrete", "#EEEDE8", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2F4048"))
	lm.use("Balcony", LandmarkMaterials.glass("#A9BCC4"))
	lm.use("Metal", LandmarkMaterials.paint("#3E4446", 0.6))
	lm.use("Roof", LandmarkMaterials.paint("#55595A", 0.8))
	return lm

## White residential shaft over the podium glazing: a glazed balcony
## band and window ribbon on every storey, a parapet or butterfly roof.
static func _tower(lm: LandmarkMesh, poly: PackedVector2Array, top: float, floors: int, butterfly: bool) -> void:
	var eave := top - (4.0 if butterfly else 1.0)
	var pitch := (eave - PODIUM_M) / float(floors)
	lm.poly_prism("Glass", F.offset(poly, -0.5), 0.0, PODIUM_M)
	lm.poly_prism("White", poly, PODIUM_M, eave)
	W.ribbons(lm, "Glass", poly, PODIUM_M + 1.1, 1.3, floors, pitch)
	W.ribbons(lm, "Balcony", poly, PODIUM_M + 0.25, 0.8, floors, pitch, 0.35)
	W.ribbons(lm, "White", poly, PODIUM_M, 0.22, floors, pitch, 0.45)
	W.ribs(lm, "Metal", poly, PODIUM_M + 0.9, eave - 0.5, 2.4, 0.1, 0.12)
	if butterfly:
		W.butterfly(lm, "White", F.offset(poly, 0.3), eave, top - eave)
	else:
		lm.poly_prism("White", F.offset(poly, 0.15), eave, top)
		lm.poly_prism("Roof", F.offset(poly, -0.5), eave + 0.2, top - 0.4)

## 21 residential storeys above the mall; the butterfly roof lifts both
## ends to 90 m.
static func niittyhuippu(model: Node3D) -> void:
	var lm := _materials()
	_tower(lm, W.outline("niittyhuippu"), 90.0, 21, true)
	lm.commit(model, "Niittyhuippu_")

static func niittytori(model: Node3D) -> void:
	var lm := _materials()
	_tower(lm, W.outline("niittytori_tower"), 38.0, 7, false)
	lm.commit(model, "Niittytori_")

## Dark brick-clad shaft whose two long faces carry a full-width stack
## of glazed balconies, light-framed punched windows on the other faces,
## a glazed lobby and the recessed 16th-floor sauna and lounge storey
## behind a glass terrace rail. The OSM outline traces the balcony
## stacks: on each long face the middle run stands ~1.3 m proud of the
## corner steps, so the brick core is the outline without those runs.
static func niittytaival(model: Node3D) -> void:
	var lm := _materials()
	lm.use("Dark", LandmarkMaterials.pbr("brick", "#3A2A22", 3.0))
	lm.use("Slab", LandmarkMaterials.pbr("concrete", "#B4B2AC", 3.0))
	lm.use("Frame", LandmarkMaterials.paint("#D9D7D1", 0.5, 0.1))
	lm.use("Alu", LandmarkMaterials.paint("#8E9396", 0.35, 0.6))
	lm.use("Back", LandmarkMaterials.pbr("concrete", "#CFCAC0", 3.0))
	# Frameless balcony glazing is clear: the light balcony walls, doors
	# and slab soffits show through it, with a sky sheen on top.
	var clear := LandmarkMaterials.glass("#2F4048").duplicate() as StandardMaterial3D
	clear.albedo_color = Color(0.80, 0.87, 0.90, 0.2)
	clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	clear.roughness = 0.03
	clear.metallic = 0.0
	clear.metallic_specular = 0.8
	lm.use("Glazing", clear)
	var smoked := LandmarkMaterials.glass("#2F4048").duplicate() as StandardMaterial3D
	smoked.albedo_color = Color(0.30, 0.34, 0.37, 0.72)
	smoked.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoked.roughness = 0.12
	smoked.metallic = 0.0
	smoked.metallic_specular = 0.7
	lm.use("Smoked", smoked)
	var poly := W.outline("niittytaival_tower")
	var top := 50.5
	var base := 3.6
	var eave := 46.6
	var floors := 14
	var pitch := (eave - base) / float(floors)
	var stacks: Array[Dictionary] = []
	var drop := {}
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if a.distance_to(b) < 22.0:
			continue
		var out := W.outward(poly, a, b)
		var pa := poly[(i - 1 + poly.size()) % poly.size()]
		var pb := poly[(i + 2) % poly.size()]
		stacks.append({"a": pa, "b": pb, "out": out, "depth": BALCONY_DEPTH_M})
		drop[i] = true
		drop[(i + 1) % poly.size()] = true
	var core := PackedVector2Array()
	for i in poly.size():
		if not drop.has(i):
			core.append(poly[i])
	lm.poly_prism("Glass", F.offset(core, -0.4), 0.0, base)
	lm.poly_prism("Dark", core, base, eave)
	_punched_windows(lm, core, stacks, base + 0.85, floors, pitch)
	for s: Dictionary in stacks:
		_balcony_stack(lm, s, base, floors, pitch)
	# 16th floor: sauna and lounge glazing set back behind the terrace rail.
	lm.poly_prism("Glass", F.offset(poly, -1.4), eave, 49.6)
	var rail := F.offset(poly, -0.1)
	lm.poly_prism("Smoked", rail, eave, eave + 1.1, false)
	lm.poly_prism("Alu", F.offset(rail, 0.03), eave + 1.1, eave + 1.16, false)
	lm.poly_prism("Dark", F.offset(poly, 0.1), 49.6, top)
	lm.poly_prism("Roof", F.offset(poly, -0.6), 49.7, top - 0.3)
	lm.commit(model, "Niittytaival_")

## One long face's glazed balconies: slab edges every storey, brick end
## fins, light fins between the bays, a smoked lower panel under a
## handrail and frameless glazing above it with thin vertical joints.
static func _balcony_stack(lm: LandmarkMesh, s: Dictionary, base: float, floors: int, pitch: float) -> void:
	var a: Vector2 = s["a"]
	var out: Vector2 = s["out"]
	var depth: float = s["depth"]
	var along: Vector2 = (s["b"] as Vector2) - a
	along -= out * along.dot(out)
	var length := along.length()
	along /= length
	var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
	var top := base + pitch * float(floors)
	var at := func(u: float, v: float, y: float) -> Vector3:
		var p := a + along * u + out * v
		return Vector3(p.x, y, p.y)
	for k in floors + 1:
		var y := base + pitch * float(k)
		lm.box("Slab", at.call(length * 0.5, depth * 0.5, y - 0.11), Vector3(length, 0.22, depth + 0.05), basis, 0.0)
	for u: float in [0.15, length - 0.15]:
		lm.box("Dark", at.call(u, depth * 0.5, (base + top) * 0.5), Vector3(0.3, top - base, depth + 0.05), basis, 0.0)
	var bays := maxi(2, roundi(length / 6.0))
	var bay := (length - 0.3) / float(bays)
	for j in range(1, bays):
		lm.box("Slab", at.call(0.15 + bay * float(j), depth * 0.5, (base + top) * 0.5),
			Vector3(0.2, top - base, depth - 0.1), basis, 0.0)
	var v := depth - 0.12
	for k in floors:
		var y := base + pitch * float(k)
		var head := y + pitch - 0.26
		for j in bays:
			var u0 := 0.15 + bay * float(j) + 0.12
			var u1 := u0 + bay - 0.24
			var w := u1 - u0
			var mid := (u0 + u1) * 0.5
			# Behind the glass: the rendered balcony wall, a door and a window.
			lm.box("Back", at.call(mid, 0.03, (y + head) * 0.5 + 0.02), Vector3(w + 0.2, head - y + 0.22, 0.06), basis, 0.0)
			var door := u0 + 0.35 + 0.45
			_framed(lm, at.call(door, 0.07, y), basis, 0.9, 2.15)
			if w > 3.2:
				_framed(lm, at.call((door + 0.45 + u1) * 0.5, 0.07, y + 0.75), basis, minf(w - 2.0, 2.4), 1.4)
			lm.box("Smoked", at.call(mid, v, y + 0.52), Vector3(w, 1.04, 0.03), basis, 0.0)
			lm.box("Alu", at.call(mid, v + 0.02, y + 1.07), Vector3(w, 0.06, 0.09), basis, 0.0)
			lm.box("Glazing", at.call(mid, v, (y + 1.1 + head) * 0.5), Vector3(w, head - y - 1.1, 0.02), basis, 0.0)
			lm.box("Alu", at.call(mid, v, head + 0.03), Vector3(w, 0.06, 0.07), basis, 0.0)
			var panes := maxi(1, roundi(w / 0.75))
			for p in range(1, panes):
				lm.box("Alu", at.call(u0 + w * float(p) / float(panes), v + 0.015, (y + 1.1 + head) * 0.5),
					Vector3(0.025, head - y - 1.1, 0.02), basis, 0.0)

## A dark pane `w` x `h` with its sill at `c`, in a light frame.
static func _framed(lm: LandmarkMesh, c: Vector3, basis: Basis, w: float, h: float) -> void:
	var side := basis.x * (w * 0.5)
	lm.box("Glass", c + Vector3(0, h * 0.5, 0), Vector3(w, h, 0.02), basis, 0.0)
	lm.box("Frame", c + Vector3(0, h, 0), Vector3(w + 0.1, 0.07, 0.06), basis, 0.0)
	lm.box("Frame", c, Vector3(w + 0.1, 0.07, 0.06), basis, 0.0)
	lm.box("Frame", c + side + Vector3(0, h * 0.5, 0), Vector3(0.07, h, 0.06), basis, 0.0)
	lm.box("Frame", c - side + Vector3(0, h * 0.5, 0), Vector3(0.07, h, 0.06), basis, 0.0)

## Light-framed windows with sills on every core wall not hidden behind a
## balcony stack, `rows` storeys `pitch` apart from y0.
static func _punched_windows(lm: LandmarkMesh, core: PackedVector2Array, stacks: Array[Dictionary],
		y0: float, rows: int, pitch: float) -> void:
	const W_M := 1.3
	const H_M := 1.75
	for i in core.size():
		var a := core[i]
		var b := core[(i + 1) % core.size()]
		var behind := false
		for s: Dictionary in stacks:
			if a.distance_to(s["a"]) < 0.01 and b.distance_to(s["b"]) < 0.01:
				behind = true
		var n := int(a.distance_to(b) / 3.2)
		if behind or n < 1:
			continue
		var along := (b - a).normalized()
		var out := W.outward(core, a, b)
		var o3 := Vector3(out.x, 0, out.y)
		var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
		var p0 := a + along * 0.5
		var p1 := b - along * 0.5
		U.window_grid(lm, "Glass", Vector3(p0.x, 0, p0.y), Vector3(p1.x, 0, p1.y), o3, y0, rows, pitch, n,
			W_M, H_M, 0.02)
		for r in rows:
			var y := y0 + pitch * float(r)
			for k in n:
				var c2 := p0.lerp(p1, (float(k) + 0.5) / float(n))
				var c := Vector3(c2.x, y, c2.y) + o3 * 0.06
				var side := Vector3(along.x, 0, along.y) * (W_M * 0.5 + 0.04)
				lm.box("Frame", c + Vector3(0, H_M + 0.04, 0), Vector3(W_M + 0.16, 0.08, 0.12), basis, 0.0)
				lm.box("Frame", c + Vector3(0, 0.04, 0), Vector3(W_M + 0.16, 0.08, 0.12), basis, 0.0)
				lm.box("Frame", c + side + Vector3(0, H_M * 0.5, 0), Vector3(0.08, H_M, 0.12), basis, 0.0)
				lm.box("Frame", c - side + Vector3(0, H_M * 0.5, 0), Vector3(0.08, H_M, 0.12), basis, 0.0)
				lm.box("Frame", c + Vector3(0, H_M * 0.5, 0), Vector3(0.05, H_M, 0.08), basis, 0.0)
				lm.box("Alu", c + o3 * 0.06 + Vector3(0, -0.03, 0), Vector3(W_M + 0.24, 0.06, 0.24), basis, 0.0)

## Red-brick church wrapping its mound: pilasters, full-height slit
## windows, a brick coping and the taller church-hall block inside.
static func olari_church(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8E4634", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2C383C"))
	lm.use("Roof", LandmarkMaterials.paint("#4C4F4F", 0.8))
	var poly := W.outline("olari_church")
	var eave := 9.5
	lm.poly_prism("Brick", poly, 0.0, eave)
	W.ribs(lm, "Brick", poly, 0.0, eave + 0.4, 2.4, 0.7, 0.45)
	W.edge_windows(lm, "Glass", poly, 0.9, 1, 1.0, 2.4, 0.4, 7.6)
	lm.poly_prism("Brick", F.offset(poly, 0.5), eave, eave + 0.6)
	lm.poly_prism("Roof", F.offset(poly, -0.3), eave + 0.6, eave + 0.8)
	var hall := F.offset(poly, -7.0)
	if not hall.is_empty():
		lm.poly_prism("Brick", hall, eave, 12.4)
		lm.poly_prism("Brick", F.offset(hall, 0.3), 12.4, 13.0)
		lm.poly_prism("Roof", F.offset(hall, -0.3), 12.6, 12.8)
	lm.commit(model, "Olari_church_")

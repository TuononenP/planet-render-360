class_name StoTekniska
extends RefCounted

## Tekniska museet (Ragnar Hjorth, 1936), Museivägen on Norra Djurgården.
## Origin at the centre of OSM way 10502173 (88.3 x 53 m, bearing 8, registry
## yaw -82), +X along the long axis, the front and the main entrance at -Z
## (the plaza on Museivägen, facing west), the vaulted hall behind at +Z.
## From the entrance, quarter and aerial photos in visual-plan/refs/
## landmarks/tekniska_museet/ (the sources doc's limestone and brick are
## wrong: beige-ochre rendered functionalist concrete):
## - A plain 88 m block, three storeys to a 12.2 m flat eave on a low
##   plinth, a pale copper-green band at the parapet. Long ribbon windows in
##   bays of 5.4 m, three panes each, at ground (low), first and second floor.
## - A fourth, recessed storey (4 m back from the front) of glazed ribbons
##   under a dark flat roof, with two rooftop glass lanterns and a round
##   ventilation stack with a cap (the 16.8 m registry height).
## - The main entrance in the middle: a two-storey glazed hall in a steel
##   frame (6.2 m wide) with a balcony rail at first-floor level, the
##   TEKNISKA MUSEET lettering above the ground-floor doors, a paved ramp
##   forecourt with railings and two flagpoles beside it.
## - Behind the block the green copper barrel-vaulted hall (26 m wide, 68 m
##   long, crown 10.5 m) with a glazed ribbon along the crown and arched
##   end walls.
## Bay counts are read from the photos; the east link and the wings of the
## neighbouring Etnografiska are not modelled.

const X0 := -44.0
const X1 := 44.0
const ZF := -26.5
const ZB := -6.5
const EAVE := 12.2
const ROOF_TOP := 15.2
const TOP := 16.8
const HALL_X0 := -42.0
const HALL_X1 := 26.0
const HALL_Z0 := -6.5
const HALL_Z1 := 19.5
const HALL_SPRING := 3.0
const HALL_RISE := 7.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#CDAE82", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#B9B3A6", 2.5))
	lm.use("Frame", LandmarkMaterials.pbr("concrete", "#E9E6DC", 2.0, 0.5, 0.2))
	lm.use("Glass", LandmarkMaterials.glass("#2A3944"))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3C4044", 3.0, 0.55, 0.2))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#8DB5A0", 2.0, 0.55, 0.3))
	lm.use("Vault", LandmarkMaterials.pbr("copper", "#7FAE98", 3.0))
	lm.use("Sky", LandmarkMaterials.pbr("concrete", "#D8DCD6", 2.0, 0.35, 0.1))
	lm.use("Iron", LandmarkMaterials.pbr("concrete", "#9AA0A4", 2.0, 0.5, 0.5))
	lm.use("Sign", LandmarkMaterials.lit("#E8E6DA", 0.35))
	lm.use("Lit", LandmarkMaterials.lit("#FFD9A0", 0.5))
	_block(lm)
	_top_storey(lm)
	_entrance(lm)
	_hall(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.9, 0.74)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-30.0, 1.2, ZF - 16.0), Vector3(-14.0, 7.0, ZF), 45.0, 0.9, 50.0, warm],
		[Vector3(30.0, 1.2, ZF - 16.0), Vector3(14.0, 7.0, ZF), 45.0, 0.9, 50.0, warm],
		[Vector3(0.0, 1.2, ZF - 18.0), Vector3(0.0, 6.0, ZF), 38.0, 0.9, 40.0, warm],
	])

## A ribbon window w x h at `pos` facing `out`: frame, glass and two mullions.
static func _ribbon(lm: LandmarkMesh, pos: Vector3, out: Vector3, w: float, h: float) -> void:
	var right := Vector3.UP.cross(out).normalized()
	var basis := Basis(right, Vector3.UP, out)
	var c := pos + Vector3(0, h * 0.5, 0)
	lm.box("Frame", c + out * 0.04, Vector3(w + 0.24, h + 0.24, 0.08), basis, 0.0)
	lm.box("Glass", c + out * 0.09, Vector3(w - 0.1, h - 0.1, 0.04), basis, 0.0)
	for k in [-1.0, 1.0]:
		lm.box("Frame", c + right * (w / 3.0) * float(k) * 0.5 + out * 0.13,
			Vector3(0.1, h, 0.06), basis, 0.0)
	lm.box("Frame", c + out * 0.13, Vector3(w, 0.1, 0.06), basis, 0.0)

static func _block(lm: LandmarkMesh) -> void:
	var cx := (X0 + X1) * 0.5
	var w := X1 - X0
	var cz := (ZF + ZB) * 0.5
	var d := ZB - ZF
	lm.box("Trim", Vector3(cx, 0.3, cz), Vector3(w + 0.4, 0.6, d + 0.4), Basis(), 0.0)
	LandmarkFhUtil.blk(lm, "Wall", cx, 0.0, cz, w, EAVE, d)
	lm.box("Copper", Vector3(cx, EAVE - 0.15, cz), Vector3(w + 0.5, 0.3, d + 0.5), Basis(), 0.0)
	lm.box("Roof", Vector3(cx, EAVE + 0.1, cz), Vector3(w + 0.2, 0.2, d + 0.2), Basis(), 0.0)
	var n := 16
	for i in n:
		var x := lerpf(X0 + 3.5, X1 - 3.5, (float(i) + 0.5) / float(n))
		if absf(x) < 5.0:
			continue
		for s in [ZF, ZB]:
			var zs: float = s
			var out := Vector3(0, 0, -1.0 if zs == ZF else 1.0)
			_ribbon(lm, Vector3(x, 0.9, zs), out, 4.2, 1.5)
			_ribbon(lm, Vector3(x, 4.7, zs), out, 4.2, 2.0)
			_ribbon(lm, Vector3(x, 8.7, zs), out, 4.2, 2.0)
	# End walls: a pair of windows per floor and a spiral stair on the east end.
	for z in [-21.0, -12.0]:
		for e in [X0, X1]:
			var out := Vector3(-1.0 if e == X0 else 1.0, 0, 0)
			_ribbon(lm, Vector3(e, 4.7, float(z)), out, 3.0, 2.0)
			_ribbon(lm, Vector3(e, 8.7, float(z)), out, 3.0, 2.0)

## The recessed fourth storey, its roof, two lanterns and the stack.
static func _top_storey(lm: LandmarkMesh) -> void:
	var x0 := X0 + 2.0
	var x1 := X1 - 8.0
	var z0 := ZF + 4.5
	var z1 := ZB - 1.5
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var h := ROOF_TOP - EAVE
	LandmarkFhUtil.blk(lm, "Wall", cx, EAVE, cz, x1 - x0, h, z1 - z0)
	lm.box("Roof", Vector3(cx, ROOF_TOP + 0.12, cz), Vector3(x1 - x0 + 1.2, 0.25, z1 - z0 + 1.2), Basis(), 0.0)
	var n := 14
	for i in n:
		var x := lerpf(x0 + 2.0, x1 - 2.0, (float(i) + 0.5) / float(n))
		for s in [z0, z1]:
			var zs: float = s
			var out := Vector3(0, 0, -1.0 if zs == z0 else 1.0)
			_ribbon(lm, Vector3(x, EAVE + 0.55, zs), out, 4.4, 1.9)
	for lx in [-18.0, 14.0]:
		LandmarkFhUtil.blk(lm, "Glass", float(lx), ROOF_TOP + 0.2, cz + 1.0, 8.0, 1.2, 4.6)
		lm.box("Frame", Vector3(float(lx), ROOF_TOP + 1.5, cz + 1.0), Vector3(8.6, 0.25, 5.2), Basis(), 0.0)
	# The round ventilation stack with a ringed cap, to the registry height.
	var stack := Vector3(30.0, ROOF_TOP + 0.2, cz - 1.5)
	lm.frustum("Roof", stack, 1.1, 1.0, TOP - ROOF_TOP - 0.2, 12)
	lm.frustum("Iron", stack + Vector3.UP * (TOP - ROOF_TOP - 0.5), 1.35, 1.35, 0.3, 12)

static func _entrance(lm: LandmarkMesh) -> void:
	var z := ZF
	# Glazed hall projecting 0.5 m from the wall, two storeys tall.
	lm.box("Frame", Vector3(0, 4.6, z - 0.3), Vector3(6.8, 9.2, 0.6), Basis(), 0.0)
	lm.box("Glass", Vector3(0, 4.6, z - 0.62), Vector3(6.2, 9.0, 0.06), Basis(), 0.0)
	for k in 5:
		lm.box("Frame", Vector3(-2.5 + 1.25 * float(k), 4.6, z - 0.68), Vector3(0.1, 9.0, 0.08), Basis(), 0.0)
	for y in [2.8, 5.0, 7.2]:
		lm.box("Frame", Vector3(0, float(y), z - 0.68), Vector3(6.2, 0.1, 0.08), Basis(), 0.0)
	# Balcony rail at first-floor level and the lettering band above the doors.
	LandmarkDetail.balustrade(lm, "Iron", Vector3(-3.1, 4.6, z - 0.85), Vector3(3.1, 4.6, z - 0.85), 0.9, 3.1)
	lm.box("Sign", Vector3(0, 4.0, z - 0.74), Vector3(5.6, 0.45, 0.08), Basis(), 0.0)
	lm.box("Lit", Vector3(0, 1.4, z - 0.74), Vector3(4.4, 2.4, 0.04), Basis(), 0.0)
	# Forecourt: a paved ramp with railings and two flagpoles.
	lm.box("Trim", Vector3(0, 0.12, z - 5.5), Vector3(12.0, 0.24, 9.0), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		var xs: float = float(sx)
		lm.beam("Iron", Vector3(xs * 6.4, 0.9, z - 1.0), Vector3(xs * 6.4, 0.9, z - 10.0), 0.07, 0.07)
		for k in 4:
			lm.beam("Iron", Vector3(xs * 6.4, 0.0, z - 1.5 - 2.8 * float(k)),
				Vector3(xs * 6.4, 0.9, z - 1.5 - 2.8 * float(k)), 0.07, 0.07)
		lm.beam("Iron", Vector3(xs * 10.0, 0.0, z - 6.0), Vector3(xs * 10.0, 9.0, z - 6.0), 0.14, 0.14)

## The green barrel-vaulted hall behind the block.
static func _hall(lm: LandmarkMesh) -> void:
	var zc := (HALL_Z0 + HALL_Z1) * 0.5
	var hw := (HALL_Z1 - HALL_Z0) * 0.5
	var steps := 14
	var xs := PackedFloat32Array()
	var bays := 8
	for i in bays + 1:
		xs.append(lerpf(HALL_X0, HALL_X1, float(i) / float(bays)))
	for j in steps:
		var t0 := PI * float(j) / float(steps)
		var t1 := PI * float(j + 1) / float(steps)
		var p0 := Vector2(zc + hw * cos(t0), HALL_SPRING + HALL_RISE * sin(t0))
		var p1 := Vector2(zc + hw * cos(t1), HALL_SPRING + HALL_RISE * sin(t1))
		var mid := (t0 + t1) * 0.5
		var n := Vector3(0, sin(mid) / HALL_RISE, cos(mid) / hw).normalized()
		var crown := j >= 5 and j <= 8
		for i in bays:
			var key := "Sky" if crown and i % 2 == 1 else "Vault"
			lm.quad(key, Vector3(xs[i], p0.y, p0.x), Vector3(xs[i + 1], p0.y, p0.x),
				Vector3(xs[i + 1], p1.y, p1.x), Vector3(xs[i], p1.y, p1.x), n)
	# Ribs over each bay line and the low side walls under the vault.
	for i in bays + 1:
		var prev := Vector3(xs[i], HALL_SPRING, zc + hw)
		for j in range(1, steps + 1):
			var t := PI * float(j) / float(steps)
			var p := Vector3(xs[i], HALL_SPRING + (HALL_RISE + 0.12) * sin(t), zc + (hw + 0.1) * cos(t))
			lm.beam("Frame", prev, p, 0.22, 0.22)
			prev = p
	for z in [HALL_Z0, HALL_Z1]:
		LandmarkFhUtil.blk(lm, "Wall", (HALL_X0 + HALL_X1) * 0.5, 0.0, float(z) + (0.2 if float(z) == HALL_Z0 else -0.2),
			HALL_X1 - HALL_X0, HALL_SPRING, 0.4)
	# Arched end walls: a fan from the middle to the base and the arc.
	for e in [HALL_X0, HALL_X1]:
		var out := Vector3(-1.0 if e == HALL_X0 else 1.0, 0, 0)
		var c := Vector3(float(e), 2.5, zc)
		var ring: Array[Vector3] = [Vector3(float(e), 0.0, zc + hw)]
		for j in range(0, steps + 1):
			var t := PI * float(j) / float(steps)
			ring.append(Vector3(float(e), HALL_SPRING + HALL_RISE * sin(t), zc + hw * cos(t)))
		ring.append(Vector3(float(e), 0.0, zc - hw))
		for k in ring.size() - 1:
			lm.tri("Roof", c, ring[k], ring[k + 1], out, out, out, Vector2(0, 0),
				Vector2(ring[k].z - zc, -ring[k].y), Vector2(ring[k + 1].z - zc, -ring[k + 1].y))

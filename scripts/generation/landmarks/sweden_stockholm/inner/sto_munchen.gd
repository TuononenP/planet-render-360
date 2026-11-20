class_name StoMunchen
extends RefCounted

## Münchenbryggeriet (the Münchenbryggeriet brewery, 1853-1938, Söder
## Mälarstrand), origin at the centre of the complex, +X along the range
## (OSM bearing 91.6, registry yaw 1.6), +Z south, the quay front at -Z.
## A 313 x 66 m brick complex of 29 stepped masses 8-39 m high, rebuilt
## from the OSM building:part ways (sto_munchen_data.gd), so the roofline,
## the notched south side and the curved wing follow the map.
##
## Facade (from the Commons photos in visual-plan/refs/landmarks/munchenbryggeriet/):
## - a grey granite base storey 6.5 m high with big round-arched windows
##   about every 5 m, under a light limestone string course;
## - red-brown clinker brick above, in storeys 3.7 m apart, windows
##   1.3 x 2.2 m about every 2.9 m, a limestone belt every second storey and
##   a corbelled cornice under the eaves;
## - steep dark blue-grey zinc roofs (gabled halls, hipped blocks, a
##   mansard on the long ranges) with rows of small gabled dormers;
## - slender round brick corner turrets with pointed zinc caps at the
##   ends of the range and the east wing;
## - the 45 m brick boiler-house chimney (OSM node, 45 m) behind the west
##   hall on the hillside, a SEAT_META child so it stands on the ground
##   there: its base is 50 m south of the quay front.
## Sources: OSM ways 17392811 and the building:part set 1558373424..42,
## 1560106769..78 (heights less roof:height give the wall tops), chimney
## node 11752125847; en/sv Wikipedia for the brewery's history.

const H := 45.0
const CHIMNEY_AT := Vector3(-87.0, 0.0, 49.7)
const BASE_H := 6.5
const STOREY := 3.7

static func materials() -> Dictionary:
	return {
		"Brick": LandmarkMaterials.pbr("brick", "#A4553C", 3.0),
		"Granite": LandmarkMaterials.pbr("stone", "#797A79", 3.0),
		"Trim": LandmarkMaterials.pbr("limestone", "#CDBFA6", 2.5),
		"Slate": LandmarkMaterials.pbr("slate", "#59636E", 3.0, 0.55, 0.2),
		"Glass": LandmarkMaterials.glass("#20282D"),
	}

static func build(model: Node3D) -> void:
	var mats := materials()
	var lm := LandmarkMesh.new()
	StoChurchKit.use_all(lm, mats)
	for part in StoMunchenData.PARTS:
		_mass(lm, part)
	_facades(lm)
	_dormers(lm)
	_turrets(lm)
	lm.commit(model)
	_chimney(model, mats)

static func _poly(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size(), 2):
		out.append(Vector2(float(flat[i]), float(flat[i + 1])))
	return out

## One mass of the complex: its brick walls and its roof.
static func _mass(lm: LandmarkMesh, part: Array) -> void:
	var y0: float = part[0]
	var wall: float = part[1]
	var roof: String = part[2]
	var rise: float = part[3]
	var poly := _poly(part[9])
	lm.poly_prism("Brick", poly, y0, wall, false)
	var c := Vector3(part[4], wall, part[5])
	match roof:
		"g":
			_roof(lm, c, part[7], part[8], rise, part[6], false)
		"h":
			_roof(lm, c, part[7], part[8], rise, part[6], true)
		"p":
			LandmarkFhParts.slope_roof(lm, "Slate", poly, LandmarkFhParts.centre(poly), 0.45, wall, wall + rise)
		_:
			lm.poly_prism("Slate", poly, wall - 0.02, wall + 0.4)

## Gabled or hipped zinc roof over the rectangle hl x hw (half sizes) turned
## so its ridge runs along the angle `ang` from +X toward +Z; eaves at c.y.
static func _roof(lm: LandmarkMesh, c: Vector3, hl: float, hw: float, rise: float, ang: float,
		hip: bool) -> void:
	var r := Basis(Vector3.UP, PI * 0.5 - ang)
	var rl := maxf(hl - hw, 0.05) if hip else hl
	var y := c.y
	var p := func(x: float, h: float, z: float) -> Vector3:
		return c + r * Vector3(x, h, z)
	for s in [-1.0, 1.0]:
		var sg: float = s
		var n := r * Vector3(sg * rise, hw, 0.0).normalized()
		lm.quad("Slate", p.call(sg * hw, 0.0, -hl), p.call(sg * hw, 0.0, hl), p.call(0.0, rise, rl),
			p.call(0.0, rise, -rl), n)
		if hip:
			var ne := r * Vector3(0.0, hl - rl, rise * sg).normalized()
			lm.tri("Slate", p.call(-hw, 0.0, sg * hl), p.call(hw, 0.0, sg * hl), p.call(0.0, rise, sg * rl),
				ne, ne, ne, Vector2(0, 0), Vector2(hw * 2.0, 0), Vector2(hw, -rise))
		else:
			var ng := r * Vector3(0.0, 0.0, sg)
			lm.tri("Brick", p.call(-hw, 0.0, sg * hl), p.call(hw, 0.0, sg * hl), p.call(0.0, rise, sg * hl),
				ng, ng, ng, Vector2(0, 0), Vector2(hw * 2.0, 0), Vector2(hw, -rise))

## Stone base, string courses, window rows and the cornice on each exposed
## wall run.
static func _facades(lm: LandmarkMesh) -> void:
	for run in StoMunchenData.RUNS:
		var a := Vector3(run[0], 0.0, run[1])
		var b := Vector3(run[2], 0.0, run[3])
		var lo: float = run[4]
		var hi: float = run[5]
		var run_len := a.distance_to(b)
		var d := (b - a) / run_len
		var out := Vector3(d.z, 0.0, -d.x)
		var basis := Basis(Vector3.UP, atan2(out.x, out.z))
		var mid := (a + b) * 0.5
		var y := lo + 1.2
		if lo < 1.0 and hi > BASE_H + 4.0:
			lm.box("Granite", mid + out * 0.12 + Vector3(0, BASE_H * 0.5, 0), Vector3(run_len, BASE_H, 0.24), basis, 0.0)
			LandmarkFhUtil.openings(lm, "Glass", a, b, out, 1.4, maxi(int(run_len / 5.0), 1), 2.3, 3.7, true, 0.26)
			LandmarkFhParts.band(lm, "Trim", a, b, out, BASE_H, 0.4, 0.16)
			y = BASE_H + 1.1
		var rows := 0
		while y + 2.2 < hi - 0.6:
			LandmarkFhUtil.openings(lm, "Glass", a, b, out, y, maxi(int(run_len / 2.9), 1), 1.3, 2.2, false, 0.08)
			if rows % 2 == 1 and y + 3.7 < hi - 0.6:
				LandmarkFhParts.band(lm, "Trim", a, b, out, y + 2.7, 0.3, 0.1)
			y += STOREY
			rows += 1
		LandmarkFhParts.band(lm, "Trim", a, b, out, hi - 0.55, 0.55, 0.3)

## Small gabled zinc dormers along the long eaves of the pitched roofs.
static func _dormers(lm: LandmarkMesh) -> void:
	var unit := LandmarkMesh.new()
	StoChurchKit.use_all(unit, materials())
	unit.box("Slate", Vector3(0, 0.6, 0), Vector3(1.5, 1.2, 1.2), Basis(), 0.0)
	unit.quad("Glass", Vector3(-0.55, 0.15, 0.62), Vector3(0.55, 0.15, 0.62), Vector3(0.55, 1.05, 0.62),
		Vector3(-0.55, 1.05, 0.62), Vector3.BACK)
	unit.gable("Slate", Vector3(0, 1.2, 0), 1.5, 1.2, 0.75, Basis(), 0.1, "Slate")
	for part in StoMunchenData.PARTS:
		var roof: String = part[2]
		var hl: float = part[7]
		var hw: float = part[8]
		if roof == "f" or roof == "p" or hl < 9.0 or hw < 5.0:
			continue
		var r := Basis(Vector3.UP, PI * 0.5 - float(part[6]))
		var rise: float = part[3]
		var n := maxi(int((hl * 2.0 - 6.0) / 5.5), 1)
		for s in [-1.0, 1.0]:
			var sg: float = s
			for k in n:
				var u := lerpf(-hl + 3.5, hl - 3.5, (float(k) + 0.5) / float(n))
				var at := Vector3(part[4], part[1], part[5]) + r * Vector3(sg * hw * 0.6, rise * 0.4 - 0.1, u)
				lm.merge(unit, Transform3D(r * Basis(Vector3.UP, sg * PI * 0.5), at))

## Round brick corner turrets with pointed zinc caps at the ends of the range.
static func _turrets(lm: LandmarkMesh) -> void:
	for dir in [Vector2(1.0, -0.35), Vector2(-1.0, -0.35), Vector2(1.0, 0.35)]:
		var best := -INF
		var at := Vector2.ZERO
		var top := 0.0
		var cen := Vector2.ZERO
		for part in StoMunchenData.PARTS:
			if float(part[0]) > 0.1:
				continue
			var f: Array = part[9]
			for i in range(0, f.size(), 2):
				var sc: float = float(f[i]) * dir.x + float(f[i + 1]) * dir.y
				if sc > best:
					best = sc
					at = Vector2(f[i], f[i + 1])
					top = part[1]
					cen = Vector2(part[4], part[5])
		var p := at + (cen - at).normalized() * 1.7
		var base := Vector3(p.x, 0, p.y)
		lm.frustum("Brick", base, 1.8, 1.7, top + 2.0, 12)
		lm.frustum("Trim", base + Vector3(0, top + 1.5, 0), 2.0, 2.0, 0.5, 12)
		lm.lathe("Slate", base + Vector3(0, top + 2.0, 0), PackedVector2Array([
			Vector2(2.2, 0), Vector2(1.9, 0.9), Vector2(0.5, 5.2), Vector2(0.0, 6.6)]), 12)

## The brick boiler-house chimney (45 m, stone cap) on its own ground.
static func _chimney(model: Node3D, mats: Dictionary) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", mats["Brick"] as Material)
	lm.use("Trim", mats["Trim"] as Material)
	lm.frustum("Brick", Vector3.ZERO, 2.6, 1.8, 44.0, 4, PI * 0.25)
	lm.frustum("Trim", Vector3(0, 40.0, 0), 1.95, 1.95, 0.4, 4, PI * 0.25)
	lm.box("Trim", Vector3(0, 44.6, 0), Vector3(3.0, 0.8, 3.0))
	lm.box("Trim", Vector3(0, 0.6, 0), Vector3(4.2, 1.2, 4.2))
	var child := Node3D.new()
	child.name = "Chimney"
	child.position = CHIMNEY_AT
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

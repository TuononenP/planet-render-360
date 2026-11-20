class_name StoHogalid
extends RefCounted

## Högalidskyrkan (Ivar Tengbom, 1923), Högalid hill, Södermalm. Origin at
## the centre of the nave part (OSM way 1560103070), +X along the nave
## (bearing 82, registry yaw -8), the west front at x = -25.9 facing -X,
## +Z south. Brick church with two 68.5 m towers (OSM tower parts 321393288
## Olaus Petri and 321393289 Ansgar).
##
## Facade spec (photos in visual-plan/refs/landmarks/hogalid_church/):
## - Red-brown hand-made brick (Tengbom's "Stockholm" brick), nave 17.8 m
##   wide, wall to 23 m, steep green copper roof to a ridge at 33.5 m with
##   a stepped brick gable at the west end; two lean-to aisles 3 m wide
##   under green copper roofs (16.5 up to 20.5 m, OSM skillion parts).
## - West front: a granite stair of eight steps to three round-arched
##   stone portals (a wide carved central one, two smaller), above them one
##   very tall dark glass strip in a deep arched recess, two small arched
##   lights, a stone cross in the gable and a dark ball finial on the apex.
## - Towers 9 m square on the east end of the nave, one each side of it:
##   tapered brick shafts to 42.7 m with narrow slits, a gold clock on the
##   west and south faces, four arched belfry louvres on each face over a
##   small balcony; then a flared dark patinated "bell" (copper, 43-49 m),
##   an octagonal dark lantern with louvres (49-57 m), a green onion dome
##   (57-61.5 m) and a gilt spike and cross to 68.5 m.
## - A lower chancel (13 m wide) closes the nave at its east end between
##   and behind the towers, under the same ridge.
## Floodlit towers at night (StoChurchKit.flood).

const X0 := -25.9
const X1 := 14.0
const XE := 29.4
const ZN := -9.0
const ZS := 8.8
const EAVE := 23.0
const RIDGE := 33.5
const FLOOR := 1.6
const TOWERS := [Vector2(18.85, 9.05), Vector2(18.2, -10.3)]
const SHAFT := 42.7
const TOP := 68.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var mats := StoChurchKit.materials("brick", "#7E4335", "#B8A688", "#5B8A75")
	mats["Dark"] = LandmarkMaterials.pbr("concrete", "#434C47", 2.0, 0.5, 0.3)
	mats["Granite"] = LandmarkMaterials.pbr("stone", "#857F72", 2.5)
	StoChurchKit.use_all(lm, mats)
	_nave(lm)
	_aisles(lm, mats)
	_front(lm, mats)
	_chancel(lm)
	for t: Vector2 in TOWERS:
		_tower(lm, mats, t)
	lm.commit(model)
	StoChurchKit.flood(model, Vector3(18.5, 0, 0), TOP, 17.0)

static func _nave(lm: LandmarkMesh) -> void:
	var cz := (ZN + ZS) * 0.5
	lm.box("Granite", Vector3((X0 + X1) * 0.5, 0.6, cz), Vector3(X1 - X0 + 0.4, 1.2, ZS - ZN + 0.4), Basis(), 0.0)
	LandmarkFhUtil.blk(lm, "Wall", (X0 + X1) * 0.5, 0.0, cz, X1 - X0, EAVE, ZS - ZN)
	LandmarkFhUtil.ridge_x(lm, "Copper", "Wall", Vector3((X0 + X1) * 0.5, EAVE, cz), X1 - X0, ZS - ZN, RIDGE - EAVE, 0.5)
	# Dark copper edge band at the eaves.
	for z in [ZN, ZS]:
		lm.box("Dark", Vector3((X0 + X1) * 0.5, EAVE - 0.2, float(z)), Vector3(X1 - X0 + 0.6, 0.4, 0.5), Basis(), 0.0)

## The 3 m lean-to aisles, their windows and buttress pilasters.
static func _aisles(lm: LandmarkMesh, mats: Dictionary) -> void:
	LandmarkFhUtil.wedge(lm, "Wall", "Copper", X0, X1, ZN - 3.1, ZN, 0.0, 16.5, 20.5)
	LandmarkFhUtil.wedge(lm, "Wall", "Copper", X0, X1, ZS, ZS + 2.7, 0.0, 20.5, 16.5)
	var win := StoChurchKit.round_unit(mats, 1.5, 4.6)
	var n := 8
	for k in n:
		var x := lerpf(X0 + 4.0, X1 - 3.0, float(k) / float(n - 1))
		StoChurchKit.place(lm, win, Vector3(x, 8.0, ZN - 3.1), Vector3.FORWARD)
		StoChurchKit.place(lm, win, Vector3(x, 8.0, ZS + 2.7), Vector3.BACK)
		for z in [ZN - 3.1, ZS + 2.7]:
			lm.box("Wall", Vector3(x + 2.1, 8.5, float(z) + (0.25 if z > 0.0 else -0.25)), Vector3(0.5, 17.0, 0.5), Basis(), 0.0)
	# Clerestory lights in the strip of nave wall above the aisle roofs.
	var high := StoChurchKit.round_unit(mats, 1.1, 2.0, 0.25)
	for k in 9:
		var x := lerpf(X0 + 3.0, X1 - 2.5, float(k) / 8.0)
		StoChurchKit.place(lm, high, Vector3(x, 20.5, ZN), Vector3.FORWARD)
		StoChurchKit.place(lm, high, Vector3(x, 20.5, ZS), Vector3.BACK)

## The west front: stair, three portals, the tall glass strip, cross, finial.
static func _front(lm: LandmarkMesh, mats: Dictionary) -> void:
	var cz := (ZN + ZS) * 0.5
	var out := Vector3.LEFT
	LandmarkFhUtil.steps(lm, "Granite", Vector3(X0, 0, cz), out, 15.0, 0.42, FLOOR / 8.0, 8)
	# Stepped brick gable edge: copper coping on both rakes.
	for s in [-1.0, 1.0]:
		var sg: float = s
		lm.beam("Dark", Vector3(X0 - 0.1, EAVE, cz + sg * 9.1), Vector3(X0 - 0.1, RIDGE + 0.3, cz), 0.55, 0.55, Vector3.BACK)
	# Portals: stone surrounds with an arched head and a dark door.
	var portal := func(z: float, w: float, h: float) -> void:
		var o := Vector3(X0, FLOOR, z)
		LandmarkFhParts.lancet(lm, "Trim", "Glass", o, out, w, h, 0.55, false)
		lm.box("Trim", o + Vector3(-0.35, 0.0, 0.0) + Vector3(0, h + 0.8, 0), Vector3(0.6, 1.4, w + 1.8), Basis(), 0.0)
	portal.call(cz, 3.6, 6.6)
	portal.call(cz - 6.4, 2.4, 4.4)
	portal.call(cz + 6.4, 2.4, 4.4)
	# The tall dark glass strip in its arched recess, with a copper sill.
	lm.box("Trim", Vector3(X0 - 0.2, 14.5, cz), Vector3(0.5, 15.5, 3.4), Basis(), 0.0)
	LandmarkDetail.window(lm, "Trim", "Glass", Vector3(X0 - 0.4, 14.3, cz), out, 1.9, 13.0, true, 0.3)
	lm.box("Copper", Vector3(X0 - 0.6, 7.4, cz), Vector3(1.0, 0.35, 2.6), Basis(), 0.0)
	# Two small arched lights flanking the strip, a cross and the finial.
	var lite := StoChurchKit.round_unit(mats, 0.9, 2.2, 0.25)
	for z in [cz - 3.6, cz + 3.6]:
		StoChurchKit.place(lm, lite, Vector3(X0, 9.5, float(z)), out)
	lm.box("Trim", Vector3(X0 - 0.2, 28.0, cz), Vector3(0.4, 3.2, 0.7), Basis(), 0.0)
	lm.box("Trim", Vector3(X0 - 0.2, 28.7, cz), Vector3(0.4, 0.7, 2.3), Basis(), 0.0)
	lm.lathe("Dark", Vector3(X0 + 0.3, RIDGE + 0.2, cz), LandmarkFhUtil.ball(0.55), 10)
	lm.beam("Dark", Vector3(X0 + 0.3, RIDGE + 1.3, cz), Vector3(X0 + 0.3, RIDGE + 3.6, cz), 0.16, 0.16)

## The lower chancel between and behind the towers, under the same ridge.
static func _chancel(lm: LandmarkMesh) -> void:
	var x0 := X1
	var hz := 6.6
	var eave := RIDGE - hz * (RIDGE - EAVE) / ((ZS - ZN) * 0.5)
	LandmarkFhUtil.blk(lm, "Wall", (x0 + XE) * 0.5, 0.0, -0.2, XE - x0, eave, hz * 2.0)
	StoChurchKit.half_hip(lm, "Copper", "", x0, XE, hz, eave, RIDGE - eave, 0.4, false)

static func _tower(lm: LandmarkMesh, mats: Dictionary, at: Vector2) -> void:
	var hw0 := 4.45
	var hw1 := 3.95
	StoChurchKit.tapered_shaft(lm, "Wall", at.x, at.y, 0.0, SHAFT, hw0, hw1)
	lm.box("Granite", Vector3(at.x, 0.7, at.y), Vector3(hw0 * 2.0 + 0.5, 1.4, hw0 * 2.0 + 0.5), Basis(), 0.0)
	var tilt := atan((hw0 - hw1) / SHAFT)
	var slit := StoChurchKit.round_unit(mats, 0.5, 2.0, 0.2)
	var louvre := StoChurchKit.round_unit(mats, 1.2, 5.0, 0.25)
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var out: Vector3 = d
		var side := Vector3.UP.cross(out)
		for y in [6.0, 11.5, 17.0, 22.5, 27.0]:
			StoChurchKit.place(lm, slit, Vector3(at.x, y, at.y) + out * lerpf(hw0, hw1, float(y) / SHAFT), out, tilt)
		for s in [-1.0, 1.0]:
			StoChurchKit.place(lm, louvre, Vector3(at.x, 32.0, at.y) + out * lerpf(hw0, hw1, 32.0 / SHAFT) + side * float(s) * 1.5, out, tilt)
		lm.box("Copper", Vector3(at.x, 31.3, at.y) + out * (lerpf(hw0, hw1, 0.74) + 0.2), Vector3(hw1 * 1.6, 0.3, 0.7) if absf(out.z) > 0.5 else Vector3(0.7, 0.3, hw1 * 1.6), Basis(), 0.0)
		if out == Vector3.LEFT or out == Vector3.BACK:
			StoChurchKit.clock(lm, Vector3(at.x, 39.5, at.y) + out * (hw1 + 0.15), out, 1.25)
	StoChurchKit.tower_band(lm, "Trim", at.x, at.y, hw1, SHAFT - 0.6, 0.6, 0.3)
	var c := Vector3(at.x, SHAFT, at.y)
	# Flared dark bell, octagonal lantern with louvres, balcony, dome, spire.
	lm.lathe("Dark", c, PackedVector2Array([Vector2(5.9, 0), Vector2(6.1, 1.2), Vector2(5.0, 3.6),
		Vector2(4.1, 5.6), Vector2(3.9, 6.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	var lc := c + Vector3(0, 6.0, 0)
	lm.frustum("Dark", lc, 4.4, 4.4, 0.3, 8, PI / 8.0)
	lm.frustum("Dark", lc + Vector3(0, 0.3, 0), 3.7, 3.4, 8.0, 8, PI / 8.0)
	var glaze := StoChurchKit.round_unit(mats, 1.3, 5.2, 0.2)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var o := Vector3(cos(a), 0, sin(a))
		StoChurchKit.place(lm, glaze, lc + Vector3(0, 1.6, 0) + o * 3.2, o)
	lm.frustum("Dark", lc + Vector3(0, 8.3, 0), 3.8, 3.6, 0.5, 8, PI / 8.0)
	LandmarkFhUtil.onion(lm, "Copper", lc + Vector3(0, 8.8, 0), 3.5, 4.6, 12)
	var dome_top := lc + Vector3(0, 13.4, 0)
	lm.frustum("Dark", dome_top, 0.55, 0.4, 2.2, 8)
	StoChurchKit.finial(lm, dome_top + Vector3(0, 2.2, 0), 0.35, TOP - dome_top.y - 2.2)

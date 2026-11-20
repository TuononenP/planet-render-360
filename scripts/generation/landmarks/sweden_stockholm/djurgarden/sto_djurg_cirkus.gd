class_name StoDjurgCirkus
extends RefCounted

## Cirkus on Djurgården (Wilhelm Klemming's wooden circus building, 1892).
## Origin at the centroid of OSM way 5192172 (83.4 x 47.3 m, bearing 22),
## +X along the long axis (registry yaw -68), the front with the steps and
## the entrance pavilion toward -Z (the OSM outline bulges there for the
## semicircular veranda bay). The outline below is the OSM polygon in this
## frame.
##
## Spec (visual-plan/refs/landmarks/cirkus/; the brief's "red/white striped
## round roof and twin domed towers" is wrong: this is a yellow-ochre
## painted building with slate domes and red roofs):
## - A raised ground-floor veranda right round the front: ochre timber
##   frame with big glazed grid windows every 3.6 m, green awnings above,
##   a plinth, and a broad flight of steps to the central doors.
## - An upper storey of yellow plaster set back behind the veranda, with
##   twin round-headed windows every 4.3 m between plain pilasters and a
##   cream cornice, under a low red hipped roof.
## - A central entrance pavilion (11 m wide) with the CIRKUS name board,
##   three arched windows, a heavy cornice, a stepped slate cupola and on
##   top the bronze Nike quadriga.
## - Corner towers with terracotta-red brick panels and slate domes (left
##   end, right of the pavilion and at the east end).
## - Behind, the twelve-sided hall rises through the roof: arched windows
##   under a red conical roof and a red cupola.
## Height: no height tag; scaled from the photos at about 16.8 m to the
## quadriga top, unverified.

const POLY := [Vector2(-42.4, -10.9), Vector2(-36.0, -11.2), Vector2(-36.1, -16.4), Vector2(-18.4, -17.3),
	Vector2(-14.4, -22.4), Vector2(-9.8, -25.7), Vector2(-4.3, -27.3), Vector2(0.6, -26.3),
	Vector2(6.4, -23.2), Vector2(9.4, -18.6), Vector2(14.6, -18.8), Vector2(15.3, -17.1),
	Vector2(39.8, -17.8), Vector2(41.1, 19.9), Vector2(-35.5, 19.9), Vector2(-36.0, 16.0),
	Vector2(-41.1, 16.4)]
const BASE := 5.0
const UPPER := 10.0
const TOP := 16.8
const PAV_X := -4.5

static func build(model: Node3D) -> void:
	var mats := {
		"Wall": LandmarkMaterials.pbr("render", "#E2B045", 3.0),
		"Timber": LandmarkMaterials.pbr("wood", "#C69A52", 2.0, 0.7),
		"Trim": LandmarkMaterials.pbr("render", "#EBDDB5", 3.0),
		"Frame": LandmarkMaterials.paint("#6E4B2A"),
		"Glass": LandmarkMaterials.glass("#26323A"),
		"Red": LandmarkMaterials.pbr("sheet_metal", "#8A3224", 3.0, 0.55, 0.2),
		"Brick": LandmarkMaterials.pbr("brick", "#B5583F", 2.4),
		"Slate": LandmarkMaterials.pbr("slate", "#3E4046", 3.0, 0.5, 0.2),
		"Green": LandmarkMaterials.paint("#2D5B45", 0.8, 0.0),
		"Bronze": LandmarkMaterials.pbr("copper", "#4A5444", 2.0, 0.5, 0.6),
		"Stone": LandmarkMaterials.pbr("stone", "#8C877D", 2.5),
	}
	var lm := LandmarkMesh.new()
	StoChurchKit.use_all(lm, mats)
	var poly := PackedVector2Array(POLY)
	lm.poly_prism("Timber", poly, 0.0, BASE)
	lm.poly_prism("Red", poly, BASE, BASE + 0.18)
	_veranda(lm, mats)
	_upper(lm, mats)
	_pavilion(lm, mats)
	for p in [Vector2(-39.0, -10.0), Vector2(14.0, -14.5), Vector2(37.5, -14.5)]:
		_tower(lm, p)
	_hall(lm, mats)
	_steps(lm)
	lm.commit(model)

## Glazed grid windows and green awnings round the front edges.
static func _veranda(lm: LandmarkMesh, mats: Dictionary) -> void:
	var shop := StoDjurgKit.unit(mats, 2.6, 3.3, false, 0.2)
	var area := 0.0
	for i in POLY.size():
		var p: Vector2 = POLY[i]
		var q: Vector2 = POLY[(i + 1) % POLY.size()]
		area += p.x * q.y - q.x * p.y
	for i in POLY.size():
		var p: Vector2 = POLY[i]
		var q: Vector2 = POLY[(i + 1) % POLY.size()]
		var len := p.distance_to(q)
		if len < 3.0:
			continue
		var d := (q - p) / len
		var o := Vector2(d.y, -d.x) * (1.0 if area > 0.0 else -1.0)
		var out := Vector3(o.x, 0, o.y)
		var a := Vector3(p.x, 0, p.y)
		var b := Vector3(q.x, 0, q.y)
		var n := maxi(int((len - 1.0) / 3.6), 1)
		StoDjurgKit.row(lm, shop, a + (b - a).normalized() * 0.4, b - (b - a).normalized() * 0.4, out, 1.0, n)
		var basis := Basis((b - a).normalized(), Vector3.UP, out)
		lm.box("Timber", a.lerp(b, 0.5) + out * 0.15 + Vector3(0, BASE - 0.3, 0), Vector3(len, 0.6, 0.35), basis, 0.0)
		if o.y < -0.3:
			# Green awning sloping out over the glazing on the street side.
			lm.quad("Green", a + out * 1.6 + Vector3(0, 3.7, 0), b + out * 1.6 + Vector3(0, 3.7, 0),
				b + out * 0.1 + Vector3(0, 4.7, 0), a + out * 0.1 + Vector3(0, 4.7, 0), (Vector3.UP + out).normalized())

## Yellow upper storey with twin arched windows, red hipped roof.
static func _upper(lm: LandmarkMesh, mats: Dictionary) -> void:
	var x0 := -34.0
	var x1 := 40.0
	var z0 := -12.0
	var z1 := 17.0
	LandmarkFhUtil.blk(lm, "Wall", (x0 + x1) * 0.5, BASE, (z0 + z1) * 0.5, x1 - x0, UPPER - BASE, z1 - z0)
	lm.box("Trim", Vector3((x0 + x1) * 0.5, UPPER - 0.3, (z0 + z1) * 0.5), Vector3(x1 - x0 + 0.8, 0.7, z1 - z0 + 0.8), Basis(), 0.0)
	LandmarkFhUtil.hip(lm, "Red", Vector3((x0 + x1) * 0.5, UPPER, (z0 + z1) * 0.5), x1 - x0 + 1.4, z1 - z0 + 1.4, 1.4, 0.4)
	var arch := StoDjurgKit.unit(mats, 1.1, 2.4, true, 0.2)
	var n := 17
	for i in n:
		var x := lerpf(x0 + 2.2, x1 - 2.2, float(i) / float(n - 1))
		if absf(x - PAV_X) < 6.5:
			continue
		for s in [-0.75, 0.75]:
			StoChurchKit.place(lm, arch, Vector3(x + float(s), BASE + 1.4, z0), Vector3(0, 0, -1))
			StoChurchKit.place(lm, arch, Vector3(x + float(s), BASE + 1.4, z1), Vector3(0, 0, 1))
		lm.box("Trim", Vector3(x + 2.15, BASE + 2.8, z0 - 0.1), Vector3(0.7, 4.8, 0.3), Basis(), 0.0)

## The entrance pavilion: name board, three arched windows, stepped slate cupola, quadriga.
static func _pavilion(lm: LandmarkMesh, mats: Dictionary) -> void:
	var w := 11.0
	var zc := -14.5
	var d := 5.0
	LandmarkFhUtil.blk(lm, "Wall", PAV_X, BASE, zc, w, 6.2, d)
	lm.box("Trim", Vector3(PAV_X, 11.0, zc), Vector3(w + 0.9, 0.9, d + 0.9), Basis(), 0.0)
	var arch := StoDjurgKit.unit(mats, 1.2, 2.6, true, 0.22)
	for dx in [-3.0, 0.0, 3.0]:
		StoChurchKit.place(lm, arch, Vector3(PAV_X + float(dx), BASE + 1.0, zc - d * 0.5), Vector3(0, 0, -1))
	lm.box("Frame", Vector3(PAV_X, BASE + 5.1, zc - d * 0.5 - 0.07), Vector3(8.0, 0.8, 0.14), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Trim", Vector3(PAV_X + float(s) * 4.7, BASE + 3.1, zc - d * 0.5 - 0.15), Vector3(1.5, 6.2, 0.3), Basis(), 0.0)
	# Two-stage slate cupola.
	LandmarkFhUtil.hip(lm, "Slate", Vector3(PAV_X, 11.45, zc), w + 0.8, d + 0.8, 1.9, 0.6)
	LandmarkFhUtil.hip(lm, "Slate", Vector3(PAV_X, 13.35, zc), (w + 0.8) * 0.6, (d + 0.8) * 0.6, 0.95, 0.55)
	_quadriga(lm, Vector3(PAV_X, 14.3, zc))

## Bronze Nike on a chariot drawn by four horses, simplified.
static func _quadriga(lm: LandmarkMesh, at: Vector3) -> void:
	lm.box("Bronze", at + Vector3(-1.4, 0.55, 0), Vector3(1.4, 0.6, 1.2), Basis(), 0.0)
	lm.lathe("Bronze", at + Vector3(-1.4, 0.85, 0), PackedVector2Array([Vector2(0.42, 0.0), Vector2(0.28, 0.8), Vector2(0.2, 1.1)]), 8)
	lm.lathe("Bronze", at + Vector3(-1.4, 1.95, 0), LandmarkFhUtil.ball(0.2), 8)
	lm.beam("Bronze", at + Vector3(-1.4, 1.5, 0), at + Vector3(-1.5, 2.5, 0.3), 0.06, 0.06)
	for i in 4:
		var z := (float(i) - 1.5) * 0.5
		lm.box("Bronze", at + Vector3(0.6, 0.75, z), Vector3(1.3, 0.6, 0.38), Basis(), 0.0)
		lm.beam("Bronze", at + Vector3(1.1, 0.9, z), at + Vector3(1.7, 1.55, z), 0.3, 0.26)
		lm.box("Bronze", at + Vector3(1.85, 1.7, z), Vector3(0.55, 0.32, 0.28), Basis(), 0.0)
		for lx in [0.1, 1.1]:
			lm.beam("Bronze", at + Vector3(float(lx), 0.5, z), at + Vector3(float(lx) + 0.15, 0.0, z), 0.13, 0.13)
	lm.beam("Bronze", at + Vector3(-0.8, 0.65, 0), at + Vector3(0.0, 0.65, 0), 0.1, 0.1)

## A corner tower: terracotta-red brick panel faces and a slate dome.
static func _tower(lm: LandmarkMesh, c: Vector2) -> void:
	var h := 11.6
	var s := 7.0
	LandmarkFhUtil.blk(lm, "Wall", c.x, BASE, c.y, s, h - BASE, s)
	lm.box("Brick", Vector3(c.x, BASE + 3.2, c.y - s * 0.5 - 0.06), Vector3(4.0, 5.0, 0.14), Basis(), 0.0)
	lm.box("Trim", Vector3(c.x, h - 0.3, c.y), Vector3(s + 0.8, 0.8, s + 0.8), Basis(), 0.0)
	lm.lathe("Slate", Vector3(c.x, h, c.y), PackedVector2Array([
		Vector2(s * 0.62, 0.0), Vector2(s * 0.64, 0.5), Vector2(s * 0.5, 1.5), Vector2(s * 0.3, 2.4),
		Vector2(s * 0.1, 2.9), Vector2(0.0, 3.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.beam("Frame", Vector3(c.x, h + 3.0, c.y), Vector3(c.x, h + 4.4, c.y), 0.1, 0.1)

## The twelve-sided hall behind: arched window band, red cone and cupola.
static func _hall(lm: LandmarkMesh, mats: Dictionary) -> void:
	var cx := PAV_X
	var cz := 3.0
	var a := 13.0
	var r := a / cos(PI / 12.0)
	lm.lathe("Wall", Vector3(cx, UPPER, cz), PackedVector2Array([Vector2(r, 0.0), Vector2(r, 2.4)]), 12, 1.0, 1.0,
		PI / 12.0, false)
	var arch := StoDjurgKit.unit(mats, 1.1, 1.7, true, 0.2)
	for k in 12:
		var ang := float(k) * PI / 6.0
		var n := Vector3(cos(ang), 0, sin(ang))
		var side := Vector3.UP.cross(n)
		for s in [-3.0, -1.5, 0.0, 1.5, 3.0]:
			StoChurchKit.place(lm, arch, Vector3(cx, UPPER + 0.4, cz) + n * a + side * float(s), n)
	lm.lathe("Red", Vector3(cx, UPPER + 2.4, cz), PackedVector2Array([
		Vector2(r + 0.5, 0.0), Vector2(r * 0.6, 1.2), Vector2(r * 0.22, 2.2)]), 12, 1.0, 1.0, PI / 12.0, false)
	var y := UPPER + 4.4
	lm.frustum("Red", Vector3(cx, y, cz), 3.0, 2.8, 1.0, 12, 0.0)
	lm.lathe("Red", Vector3(cx, y + 1.0, cz), PackedVector2Array([
		Vector2(3.1, 0.0), Vector2(2.6, 0.5), Vector2(1.5, 0.95), Vector2(0.0, 1.2)]), 12)

static func _steps(lm: LandmarkMesh) -> void:
	LandmarkFhUtil.steps(lm, "Stone", Vector3(PAV_X, 0.0, -27.0), Vector3(0, 0, -1), 14.0, 0.45, 0.12, 4)

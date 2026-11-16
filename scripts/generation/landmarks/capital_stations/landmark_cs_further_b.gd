class_name LandmarkCsFurtherB
extends RefCounted

## More capital stations hand-built after the photo review, in the station
## frame (+X along the main facade, +Z the forecourt): Ashgabat, Belgrade
## Centre, Bratislava, Brazzaville, Colombo Fort, Damascus Hejaz,
## Dushanbe, Chișinău and Phnom Penh.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Ashgabat station (2009): the white arcaded range with its patterned
## pilasters under low blue roofs, and the central entrance block carrying
## a ribbed blue dome, the slim white tower over it and its gilt needle.
static func ashgabat(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#F2F0EA", "#E8E2D0", "sheet_metal", "#3E5E9C")
	lm.use("Blue", LandmarkMaterials.pbr("sheet_metal", "#2F5DA8", 2.0))
	lm.use("Band", LandmarkMaterials.pbr("render", "#5E8A5A", 3.0))
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 33.0, 0.0, 44.0, 18.0, 0.0, 9.0, "hip", 2.0, 4.0, 4.5)
		K.arch_row(lm, "Trim", "Glass", Vector3(s * 12.0, 0, 9.05), Vector3(s * 54.0, 0, 9.05), Vector3.BACK, 0.4, 9, 2.8,
			6.0, 1)
		LandmarkFhParts.strips(lm, "Band", Vector3(s * 11.5, 0, 9.0), Vector3(s * 54.5, 0, 9.0), Vector3.BACK, 0.0, 8.6,
			10, 0.7, 0.3)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.5, 22.0, 20.0, 0.0, 13.0, "flat", 0.0, 4.0, 4.5)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 0.2, 10.55), Vector3.BACK, 8.0, 9.0, 5)
	LandmarkFhParts.strips(lm, "Band", Vector3(-10.5, 0, 10.5), Vector3(10.5, 0, 10.5), Vector3.BACK, 0.0, 12.6, 2,
		1.2, 0.3)
	var c := Vector3(0, 13.0, 0.5)
	lm.lathe("Walls", c, PackedVector2Array([Vector2(8.0, 0.0), Vector2(8.0, 1.6)]), 24)
	lm.lathe("Blue", c + Vector3.UP * 1.6, LandmarkFhUtil.dome_prof(8.4, 3.4), 24)
	lm.box("Walls", c + Vector3.UP * 11.0, Vector3(5.0, 16.0, 5.0))
	lm.box("Trim", c + Vector3.UP * 18.8, Vector3(5.6, 0.6, 5.6))
	for i in 4:
		var n := Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
		K.clock(lm, "Dial", "Trim", c + n * 2.55 + Vector3.UP * 16.5, n, 1.4)
	lm.lathe("Gilt", c + Vector3.UP * 19.1, LandmarkFhUtil.dome_prof(2.4, 2.0), 12)
	lm.frustum("Gilt", c + Vector3.UP * 21.0, 0.6, 0.05, 12.0, 8)
	lm.commit(model)

## Belgrade Centre (Prokop, 2016): the long glazed hall, its glass wall
## following the curve under a deep band of orange vertical fins on a
## white steel frame, over the platforms cut below the street.
static func belgrade(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E6E8E8", "#F0F0EE", "sheet_metal", "#8E8A84")
	lm.use("Curtain", LandmarkMaterials.pbr("render", "#7F96A6", 6.0, 0.2, 0.3))
	lm.use("Fins", LandmarkMaterials.pbr("render", "#B5652F", 3.0))
	var n := 12
	var r := 520.0
	var span := 240.0
	for i in n:
		# The front follows a gentle arc bowing toward the forecourt.
		var t0 := (float(i) / float(n) - 0.5) * span / r
		var t1 := (float(i + 1) / float(n) - 0.5) * span / r
		var a := Vector3(sin(t0) * r, 0, cos(t0) * r - r + 20.0)
		var b := Vector3(sin(t1) * r, 0, cos(t1) * r - r + 20.0)
		var m := (a + b) * 0.5
		var dir := (b - a).normalized()
		var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
		var out := basis.z
		var w := a.distance_to(b)
		lm.box("Curtain", m + Vector3.UP * 7.0 - out * 18.0, Vector3(w + 0.4, 14.0, 36.0), basis)
		lm.box("Walls", m + Vector3.UP * 14.4 - out * 18.0, Vector3(w + 0.4, 0.8, 37.0), basis)
		LandmarkFhParts.strips(lm, "Fins", a + Vector3.UP * 0.0, b, out, 15.0, 11.0, maxi(int(w / 1.2), 2), 0.35, 1.2)
		lm.box("Walls", m + Vector3.UP * 26.4 - out * 18.0, Vector3(w + 0.4, 0.8, 38.0), basis)
		LandmarkFhParts.strips(lm, "Walls", a, b, out, 0.0, 14.0, 4, 0.4, 0.3)
	# The fin band's lid and back.
	lm.box("Roof", Vector3(0, 20.0, -20.0), Vector3(span - 6.0, 12.0, 30.0))
	lm.commit(model)

## Bratislava hlavná stanica (1960s): the glazed hall under its signature
## white bands, a deep cantilevered fascia over the ground floor and a
## second, wider one sloping out over the set-back upper glazing.
static func bratislava(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#F2F2EE", "#E8E8E4", "concrete", "#BDBAB2")
	lm.use("Curtain", LandmarkMaterials.pbr("render", "#8FA6B4", 6.0, 0.2, 0.3))
	lm.box("Curtain", Vector3(0, 3.0, -2.0), Vector3(160.0, 6.0, 22.0))
	LandmarkFhParts.strips(lm, "Steel", Vector3(-79.0, 0, 9.05), Vector3(79.0, 0, 9.05), Vector3.BACK, 0.0, 6.0, 41, 0.2,
		0.15)
	_fascia(lm, Vector3(0, 6.0, 9.0), 164.0, 6.0, 2.4)
	lm.box("Curtain", Vector3(0, 11.5, -4.0), Vector3(100.0, 5.0, 18.0))
	_fascia(lm, Vector3(0, 14.0, 5.0), 108.0, 8.0, 3.0)
	lm.box("Roof", Vector3(0, 13.9, -4.0), Vector3(100.0, 0.4, 18.0))
	lm.commit(model)

## A sloped white fascia band `w` long at its inner top edge `c`, standing
## `depth` out over the forecourt and `h` tall, its soffit closed.
static func _fascia(lm: LandmarkMesh, c: Vector3, w: float, depth: float, h: float) -> void:
	var a := Vector3(-w * 0.5, 0, 0)
	var b := Vector3(w * 0.5, 0, 0)
	var lo := Vector3(0, -h * 0.4, depth)
	var hi := Vector3(0, h * 0.6, depth * 0.85)
	lm.quad("Walls", c + a + lo, c + b + lo, c + b + hi, c + a + hi, Vector3(0, 0.3, 1).normalized())
	lm.quad("Walls", c + a + hi, c + b + hi, c + b + Vector3.UP * h * 0.6, c + a + Vector3.UP * h * 0.6, Vector3.UP)
	lm.quad("Walls", c + b + lo, c + a + lo, c + a, c + b, Vector3.DOWN)
	for e in [a, b]:
		var nx := Vector3(signf(e.x), 0, 0)
		lm.quad("Walls", c + e, c + e + lo, c + e + hi, c + e + Vector3.UP * h * 0.6, nx)
		lm.quad("Walls", c + e + Vector3.UP * h * 0.6, c + e + hi, c + e + lo, c + e, -nx)

## Brazzaville station (Congo–Océan, 1930s): the white two-storey range
## under low hipped metal roofs, the upper hip stepped back over the
## middle, and the front colonnade carrying the first-floor balcony.
static func brazzaville(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#EFEBE0", "#F6F3EA", "sheet_metal", "#7D7F80")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -2.0, 54.0, 16.0, 0.0, 9.0, "hip", 2.4, 4.0, 4.4)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -2.0, 26.0, 12.0, 9.0, 3.5, "hip", 2.2, 3.4, 3.2)
	LandmarkFhUtil.columns(lm, "Trim", Vector3(-24.0, 0, 9.0), Vector3(24.0, 0, 9.0), 13, 4.4, 0.3)
	lm.box("Trim", Vector3(0, 4.6, 7.6), Vector3(50.0, 0.4, 3.4))
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-25.0, 4.8, 9.1), Vector3(25.0, 4.8, 9.1), 0.6, 0.15, 1.0, 0.15)
	lm.box("Trim", Vector3(0, 5.85, 9.1), Vector3(50.0, 0.1, 0.25))
	lm.commit(model)

## Colombo Fort (1917): the long low platform sheds under grey corrugated
## gables, and the white entrance pavilion at the end, a tall arched
## portal in a gable flanked by pinnacled piers.
static func colombo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#F1EFE8", "#F6F4EE", "sheet_metal", "#6E7377")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", -6.0, 0.0, 72.0, 11.0, 0.0, 5.5, "gable_x", 3.0, 4.0, 4.5)
	K.canopy(lm, "Roof", "Steel", Vector3(-42.0, 0, 5.5), Vector3(30.0, 0, 5.5), Vector3.BACK, 4.0, 4.0)
	var p := Vector3(36.0, 0, 0.5)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", p.x, p.z, 11.0, 12.0, 0.0, 12.0, "gable_z", 3.0, 3.0, 4.0)
	K.arch_window(lm, "Trim", "Glass", p + Vector3(0, 0.2, 6.05), Vector3.BACK, 5.4, 8.6, 1)
	for s in [-1.0, 1.0]:
		lm.box("Trim", p + Vector3(s * 5.2, 7.5, 6.2), Vector3(1.4, 15.0, 1.0))
		lm.frustum("Trim", p + Vector3(s * 5.2, 15.0, 6.2), 0.6, 0.1, 1.6, 6)
	lm.commit(model)

## The Hejaz station in Damascus (Fernando de Aranda, 1917): the beige
## stone range of two storeys with its arched upper windows, the end
## pavilions a little taller with great arched windows, and the centre
## with its columned porch, balcony and crest on the parapet.
static func damascus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#CDBB98", "#DCCDB0", "concrete", "#A89C86")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 40.0, 13.0, 0.0, 12.0, "flat", 0.0, 3.4, 5.5, true)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 23.0, 0.0, 8.0, 14.0, 0.0, 14.5, "flat", 0.0, 3.4, 5.5)
		K.arch_window(lm, "Trim", "Glass", Vector3(s * 23.0, 7.2, 7.05), Vector3.BACK, 3.4, 5.6, 2)
	LandmarkFhUtil.columns(lm, "Trim", Vector3(-5.0, 0, 8.6), Vector3(5.0, 0, 8.6), 4, 5.2, 0.35)
	lm.box("Trim", Vector3(0, 5.5, 7.6), Vector3(12.0, 0.6, 2.4))
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-6.0, 5.8, 8.7), Vector3(6.0, 5.8, 8.7), 0.6, 0.15, 1.0, 0.15)
	lm.box("Walls", Vector3(0, 13.4, 6.3), Vector3(8.0, 2.8, 0.6))
	lm.lathe("Trim", Vector3(0, 14.8, 6.3), PackedVector2Array([Vector2(3.0, 0.0), Vector2(1.6, 1.2), Vector2(0.0, 1.6)]),
		10, 1.0, 0.25)
	lm.box("Steel", Vector3(0, 18.5, 6.0), Vector3(0.12, 4.0, 0.12), Basis(), 0.0)
	lm.commit(model)

## Dushanbe station: the beige-grey three-storey block of square windows
## under a flat roof, and the projecting single-storey glazed entrance hall
## with the city's name in red letters along its roof.
static func dushanbe(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#C9BB98", "#DDD3BC", "concrete", "#A8A296")
	lm.use("Sign", LandmarkMaterials.lit("#C0392B", 0.4))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -2.0, 98.0, 10.0, 0.0, 14.0, "flat", 0.0, 4.4, 4.4)
	lm.box("Glass", Vector3(0, 3.0, 5.0), Vector3(34.0, 6.0, 8.0))
	LandmarkFhParts.strips(lm, "Trim", Vector3(-17.0, 0, 9.05), Vector3(17.0, 0, 9.05), Vector3.BACK, 0.0, 6.0, 12, 0.3,
		0.15)
	lm.box("Trim", Vector3(0, 6.3, 5.0), Vector3(35.0, 0.6, 9.0))
	for i in 7:
		lm.box("Sign", Vector3(-10.5 + 3.5 * float(i), 8.0, 7.5), Vector3(2.4, 2.6, 0.3))
	lm.commit(model)

## Chișinău station (1871, rebuilt 1948): the cream stone range with its
## round-arched windows, small corner pavilions under red pyramids, and
## the tall centre block under a steep red gabled roof, its great arched
## window framed in carved stone over the three-arched porch.
static func chisinau(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#D8C29A", "#ECE2C8", "terracotta", "#8B2E2A")
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 44.0, -1.0, 62.0, 20.0, 0.0, 10.0, "hip", 2.5, 3.6, 5.0, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 70.0, 0.0, 8.0, 24.0, 0.0, 12.0, "hip", 4.0, 3.0, 5.0)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 26.0, 24.0, 0.0, 16.0, "gable_z", 7.0, 4.0, 5.0)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 6.6, 12.05), Vector3.BACK, 12.0, 8.4, 7)
	var prev := Vector3.ZERO
	for k in 11:
		var t := PI * float(k) / 10.0
		var q := Vector3(cos(t) * 7.4, 9.0 + sin(t) * 7.4, 12.4)
		if k > 0:
			lm.beam("Trim", prev, q, 1.4, 0.6)
		prev = q
	K.arch_row(lm, "Trim", "Glass", Vector3(-7.0, 0, 12.6), Vector3(7.0, 0, 12.6), Vector3.BACK, 0.2, 3, 3.6, 5.2, 1)
	lm.box("Walls", Vector3(0, 2.8, 12.3), Vector3(16.0, 5.6, 1.0))
	lm.commit(model)

## Phnom Penh station (Jean Desbois, 1932): the white Art Deco front, its
## ribbed centre with the round clock, two end towers rising above it with
## vertical ribs, the green bands under the parapets and the long green
## canopy along the ground floor.
static func phnom_penh(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#EDE8D8", "#F3EFE4", "concrete", "#C9C4B8")
	lm.use("Green", LandmarkMaterials.pbr("render", "#2F7A64", 3.0))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 40.0, 24.0, 0.0, 14.0, "flat", 0.0, 3.6, 4.6)
	LandmarkFhParts.strips(lm, "Trim", Vector3(-9.0, 0, 12.05), Vector3(9.0, 0, 12.05), Vector3.BACK, 4.6, 8.8, 8, 0.6,
		0.4)
	K.clock(lm, "Dial", "Trim", Vector3(0, 12.0, 12.5), Vector3.BACK, 1.3)
	lm.box("Green", Vector3(0, 13.0, 12.2), Vector3(40.0, 0.6, 0.4))
	for s in [-1.0, 1.0]:
		var x: float = s * 24.5
		lm.box("Walls", Vector3(x, 9.5, 9.0), Vector3(9.0, 19.0, 9.0))
		LandmarkFhParts.strips(lm, "Trim", Vector3(x - 3.0, 0, 13.55), Vector3(x + 3.0, 0, 13.55), Vector3.BACK, 5.0, 12.0,
			4, 0.6, 0.3)
		lm.box("Green", Vector3(x, 17.6, 9.0), Vector3(9.4, 0.6, 9.4))
		lm.box("Trim", Vector3(x, 19.2, 9.0), Vector3(9.8, 0.8, 9.8))
	lm.box("Green", Vector3(0, 4.2, 14.0), Vector3(58.0, 0.4, 4.0))
	lm.commit(model)

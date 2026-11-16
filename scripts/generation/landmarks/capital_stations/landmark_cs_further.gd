class_name LandmarkCsFurther
extends RefCounted

## Capital stations hand-built after a photo review found their outline
## models too generic, in the station frame (+X along the main facade, +Z
## the forecourt): Accra, Ljubljana, Nairobi, Vatican City, Wellington,
## Naypyidaw, Pretoria and Yerevan.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Accra Central (1909): a long single-storey cream range on a red base
## under a pitched corrugated roof carried out over a veranda of red
## columns, the small clock turret with its red pyramid cap on the ridge,
## and the arched, gabled porch at the east end.
static func accra(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#ECE2BF", "#8B2A22", "sheet_metal", "#B9A585")
	lm.use("Red", LandmarkMaterials.pbr("render", "#8B2A22", 3.0))
	lm.use("Cap", LandmarkMaterials.pbr("sheet_metal", "#9C2A22", 2.0))
	lm.box("Walls", Vector3(0, 2.6, -2.0), Vector3(30.0, 5.2, 12.0))
	lm.box("Red", Vector3(0, 0.6, -2.0), Vector3(30.4, 1.2, 12.4))
	LandmarkFhUtil.window_grid(lm, "Glass", Vector3(-14.0, 0, 4.05), Vector3(14.0, 0, 4.05), Vector3.BACK, 1.6, 1, 3.0,
		8, 1.4, 2.2)
	LandmarkFhUtil.ridge_x(lm, "Roof", "Walls", Vector3(0, 5.2, 1.0), 31.0, 19.0, 3.0, 0.6)
	LandmarkFhUtil.columns(lm, "Red", Vector3(-14.5, 0, 9.8), Vector3(14.5, 0, 9.8), 9, 4.4, 0.3)
	lm.box("Red", Vector3(0, 4.8, 9.8), Vector3(30.0, 0.5, 0.5))
	# The clock turret on the ridge.
	var t := Vector3(-2.0, 7.8, 1.0)
	lm.box("Steel", t + Vector3.UP * 0.9, Vector3(2.6, 1.8, 2.6))
	lm.box("Walls", t + Vector3.UP * 2.8, Vector3(3.0, 2.0, 3.0))
	for i in 4:
		var n := Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
		K.clock(lm, "Dial", "Red", t + n * 1.55 + Vector3.UP * 2.8, n, 0.75)
	LandmarkFhUtil.hip(lm, "Cap", t + Vector3.UP * 3.8, 4.0, 4.0, 3.0)
	# The arched porch at the east end.
	K.block(lm, "Walls", "Red", "Glass", "Cap", 17.5, 1.0, 7.0, 10.0, 0.0, 6.0, "gable_z", 2.5, 4.0, 4.0)
	K.arch_window(lm, "Red", "Glass", Vector3(17.5, 0.2, 6.05), Vector3.BACK, 3.6, 4.6, 1)
	lm.commit(model)

## Ljubljana station (1849, rebuilt 1920s): the long pale yellow range of
## three storeys under a low grey hip, the central risalit with its arched
## ground-floor doors and attic, and the slim square clock tower with its
## cupola rising from the roof behind it.
static func ljubljana(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#EFE3B5", "#F4EEDC", "slate", "#5E6266")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 76.0, 22.0, 0.0, 14.0, "hip", 3.0, 3.6, 4.6)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 1.0, 20.0, 23.0, 0.0, 15.5, "hip", 2.5, 3.4, 4.6)
	K.arch_row(lm, "Trim", "Glass", Vector3(-7.5, 0, 12.55), Vector3(7.5, 0, 12.55), Vector3.BACK, 0.8, 4, 2.6, 4.2, 1)
	LandmarkFhParts.strips(lm, "Trim", Vector3(-9.6, 0, 12.5), Vector3(9.6, 0, 12.5), Vector3.BACK, 0.0, 15.0, 6, 0.8,
		0.3)
	var t := Vector3(0, 15.5, -2.0)
	lm.box("Walls", t + Vector3.UP * 6.0, Vector3(4.0, 12.0, 4.0))
	lm.box("Trim", t + Vector3.UP * 11.8, Vector3(4.6, 0.6, 4.6))
	for i in 4:
		var n := Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
		K.clock(lm, "Dial", "Trim", t + n * 2.05 + Vector3.UP * 10.0, n, 1.2)
	LandmarkFhUtil.openings(lm, "Glass", t + Vector3(-0.8, 0, 2.05), t + Vector3(0.8, 0, 2.05), Vector3.BACK, 4.0, 1,
		1.2, 3.6, true)
	lm.lathe("Roof", t + Vector3.UP * 12.1, LandmarkFhUtil.dome_prof(2.3, 2.2), 12)
	lm.frustum("Trim", t + Vector3.UP * 14.3, 0.2, 0.05, 1.4, 6)
	lm.commit(model)

## Nairobi station (1929): the long low range of grey-brown rubble stone
## under red-brown hips, and its entrance between two steep stone gables
## with louvred vents, three arches between them under the name board.
static func nairobi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "stone", "#5E554A", "#C9C0AE", "terracotta", "#8C4A3A")
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 44.0, -1.0, 62.0, 14.0, 0.0, 6.5, "hip", 3.0, 4.0, 4.5)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 9.0, 0.0, 9.0, 18.0, 0.0, 7.5, "gable_z", 6.0, 3.0, 4.5)
		lm.box("Steel", Vector3(s * 9.0, 10.5, 9.1), Vector3(2.0, 2.6, 0.2))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -1.0, 10.0, 14.0, 0.0, 6.5, "flat")
	K.arch_row(lm, "Trim", "Glass", Vector3(-4.0, 0, 6.05), Vector3(4.0, 0, 6.05), Vector3.BACK, 0.2, 3, 2.4, 4.2, 1)
	lm.box("Dial", Vector3(0, 6.2, 6.4), Vector3(26.0, 1.4, 0.2))
	lm.commit(model)

## Vatican City station (Giuseppe Momo, 1933): the white travertine block
## of two storeys, red tiled roofs on its wings, the projecting central
## portico of four columns and the copper-green dome over the hall behind.
static func vatican(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#EDE8DC", "#F4F1EA", "terracotta", "#B5543A")
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#6FA89A", 2.0))
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 18.0, -1.0, 20.0, 28.0, 0.0, 10.0, "hip", 2.0, 3.4, 4.6)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -1.0, 16.0, 28.0, 0.0, 12.0, "flat", 0.0, 3.4, 4.6)
	var c := Vector3(0, 12.0, -1.0)
	lm.lathe("Walls", c, PackedVector2Array([Vector2(6.0, 0.0), Vector2(6.0, 1.6)]), 20)
	lm.lathe("Copper", c + Vector3.UP * 1.6, LandmarkFhUtil.dome_prof(6.4, 4.8), 20)
	lm.lathe("Trim", c + Vector3.UP * 6.4, PackedVector2Array([Vector2(1.0, 0.0), Vector2(1.0, 1.2), Vector2(0.0, 1.8)]),
		8)
	# The portico.
	LandmarkFhUtil.columns(lm, "Trim", Vector3(-4.5, 0, 16.0), Vector3(4.5, 0, 16.0), 4, 8.5, 0.5)
	lm.box("Trim", Vector3(0, 9.2, 15.0), Vector3(11.0, 1.4, 3.4))
	lm.box("Walls", Vector3(0, 10.6, 14.6), Vector3(9.0, 1.4, 2.4))
	lm.box("Glass", Vector3(0, 3.6, 13.1), Vector3(5.0, 7.2, 0.2))
	lm.commit(model)

## Wellington station (William Gray Young, 1937): the red brick office
## block of five storeys behind a giant Doric portico of cream stone,
## eight columns with an attic carrying the clock, and the platform roofs
## stretching back behind it.
static func wellington(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#8E4A36", "#E6DCC6", "concrete", "#8A8680")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 42.0, 140.0, 38.0, 0.0, 22.0, "flat", 0.0, 3.6, 4.2)
	# The portico: a stone frame, eight giant columns and the clock attic.
	lm.box("Trim", Vector3(0, 10.0, 62.0), Vector3(44.0, 20.0, 2.0))
	lm.box("Glass", Vector3(0, 8.0, 63.1), Vector3(36.0, 15.0, 0.2))
	LandmarkFhUtil.columns(lm, "Trim", Vector3(-17.5, 0, 65.0), Vector3(17.5, 0, 65.0), 8, 16.0, 1.0)
	lm.box("Trim", Vector3(0, 17.2, 64.0), Vector3(42.0, 2.4, 4.0))
	lm.box("Trim", Vector3(0, 21.0, 62.6), Vector3(44.0, 5.0, 2.4))
	K.clock(lm, "Dial", "Trim", Vector3(0, 21.5, 63.85), Vector3.BACK, 1.6)
	K.canopy(lm, "Steel", "Steel", Vector3(-12.0, 0, 66.0), Vector3(12.0, 0, 66.0), Vector3.BACK, 3.0, 4.2, 2)
	# The platform roofs behind.
	for i in 6:
		var x := -60.0 + 24.0 * float(i)
		lm.box("Roof", Vector3(x, 4.6, -20.0), Vector3(9.0, 0.4, 78.0))
		for z in [-50.0, -30.0, -10.0, 10.0]:
			lm.box("Steel", Vector3(x, 2.2, z), Vector3(0.4, 4.4, 0.4))
	lm.commit(model)

## Naypyidaw Central (2009): the long low white terminal with dark glazed
## bands under a flat overhanging roof on slim columns, and the glazed
## cylindrical rotunda at its middle under stepped flat discs.
static func naypyidaw(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#F0F0EC", "#E2E4E2", "sheet_metal", "#9AA0A6")
	lm.use("Curtain", LandmarkMaterials.pbr("render", "#5F7F80", 6.0, 0.2, 0.3))
	lm.box("Walls", Vector3(0, 4.5, -2.0), Vector3(232.0, 9.0, 38.0))
	for y in [2.0, 6.0]:
		LandmarkFhParts.band(lm, "Curtain", Vector3(-115.0, 0, 17.0), Vector3(115.0, 0, 17.0), Vector3.BACK, y, 2.4, 0.15)
	lm.box("Roof", Vector3(0, 9.5, 0.0), Vector3(238.0, 1.0, 46.0))
	for i in 24:
		var x := -115.0 + 230.0 * float(i) / 23.0
		lm.box("Walls", Vector3(x, 4.5, 22.0), Vector3(0.6, 9.0, 0.6))
	# The rotunda.
	var c := Vector3(0, 0, 2.0)
	lm.lathe("Curtain", c, PackedVector2Array([Vector2(16.0, 0.0), Vector2(16.0, 17.0)]), 32)
	for y in [6.0, 11.0]:
		lm.lathe("Walls", c + Vector3.UP * y, PackedVector2Array([Vector2(16.3, 0.0), Vector2(16.3, 0.6)]), 32)
	lm.lathe("Walls", c + Vector3.UP * 17.0, PackedVector2Array([Vector2(18.5, 0.0), Vector2(18.5, 1.4)]), 32)
	lm.lathe("Roof", c + Vector3.UP * 18.4, PackedVector2Array([Vector2(13.0, 0.0), Vector2(13.0, 1.6),
		Vector2(0.0, 2.2)]), 32)
	lm.commit(model)

## Pretoria station (Herbert Baker, 1910): the cream stuccoed range of two
## tall storeys under a red tiled hip with chimneys, its ground-floor
## arcade, the columned loggia above the centre, and the small domed clock
## lantern on the ridge.
static func pretoria(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E8DEC4", "#F2ECDC", "terracotta", "#B5523B")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 2.0, 82.0, 22.0, 0.0, 13.0, "hip", 5.0, 4.2, 6.0)
	K.arch_row(lm, "Trim", "Glass", Vector3(-38.0, 0, 13.05), Vector3(38.0, 0, 13.05), Vector3.BACK, 0.2, 14, 3.0, 5.4, 1)
	LandmarkFhUtil.columns(lm, "Trim", Vector3(-9.0, 0, 14.0) + Vector3.UP * 6.4, Vector3(9.0, 0, 14.0) + Vector3.UP * 6.4,
		6, 5.8, 0.35)
	lm.box("Trim", Vector3(0, 6.3, 13.6), Vector3(20.0, 0.4, 1.4))
	lm.box("Glass", Vector3(0, 9.2, 13.1), Vector3(17.0, 5.6, 0.2))
	for x in [-30.0, -12.0, 12.0, 30.0]:
		lm.box("Walls", Vector3(x, 17.5, 2.0), Vector3(1.4, 4.0, 1.4))
	var t := Vector3(0, 17.0, 2.0)
	lm.box("Walls", t + Vector3.UP * 1.8, Vector3(3.4, 3.6, 3.4))
	for i in 4:
		var n := Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
		K.clock(lm, "Dial", "Trim", t + n * 1.75 + Vector3.UP * 2.0, n, 0.9)
	lm.lathe("Trim", t + Vector3.UP * 3.6, LandmarkFhUtil.dome_prof(1.9, 2.0), 12)
	lm.frustum("Trim", t + Vector3.UP * 5.6, 0.12, 0.04, 1.2, 6)
	lm.commit(model)

## Yerevan station (1956): the long pink tuff range of round-arched
## arcades, the raised centre with its great arched window, and the tower
## over it, a square shaft and an arcaded belvedere tier under a slim
## needle spire carrying the star.
static func yerevan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "stone", "#D29C88", "#E8D2C2", "concrete", "#B9A99E")
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 52.0, -2.0, 74.0, 40.0, 0.0, 11.0, "flat", 0.0, 4.4, 5.0)
		K.arch_row(lm, "Trim", "Glass", Vector3(s * 17.0, 0, 18.1), Vector3(s * 87.0, 0, 18.1), Vector3.BACK, 0.4, 14,
			3.4, 7.0, 1)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 84.0, 0.0, 10.0, 44.0, 0.0, 13.0, "flat", 0.0, 3.4, 5.0)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 30.0, 44.0, 0.0, 16.0, "flat", 0.0, 4.0, 5.0)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 0.2, 22.05), Vector3.BACK, 9.0, 13.0, 5)
	# The tower.
	var t := Vector3(0, 16.0, 6.0)
	lm.box("Walls", t + Vector3.UP * 5.0, Vector3(9.0, 10.0, 9.0))
	lm.box("Trim", t + Vector3.UP * 10.2, Vector3(10.0, 0.8, 10.0))
	var b := t + Vector3.UP * 10.6
	for i in 4:
		var n := Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
		var r := Vector3.UP.cross(n)
		LandmarkFhUtil.columns(lm, "Trim", b + n * 3.6 - r * 3.6, b + n * 3.6 + r * 3.6, 4, 6.0, 0.35)
	lm.box("Walls", b + Vector3.UP * 3.0, Vector3(5.4, 6.0, 5.4))
	lm.box("Trim", b + Vector3.UP * 6.4, Vector3(8.6, 0.8, 8.6))
	lm.box("Walls", b + Vector3.UP * 8.3, Vector3(4.6, 3.0, 4.6))
	lm.box("Trim", b + Vector3.UP * 10.0, Vector3(5.2, 0.5, 5.2))
	lm.frustum("Trim", b + Vector3.UP * 10.25, 1.6, 0.25, 18.0, 8)
	lm.box("Gilt", b + Vector3.UP * 29.0, Vector3(1.8, 1.8, 0.3))
	lm.commit(model)

class_name LandmarkFhJatkasaari
extends RefCounted

## Jätkäsaari and Ruoholahti, true metres, extruded from OpenStreetMap
## outlines (LandmarkFhInnerFootprints): Clarion Hotel Helsinki (2016),
## two chequered grey towers (78 m and lower) with a glass atrium between
## them on V-shaped pilotis and a glazed sky bar; West Terminal 2 (2017),
## a glass hall under a white roof; the Cable Factory (Kaapelitehdas,
## 1939–54), a very long grey-brick factory with a red-brick top band;
## and the Salmisaari power station, its brick boiler house, the 1953
## brick chimney (114 m), the 150 m chimney and the round heat-storage
## tanks. Sources and estimates: docs/helsinki-landmark-sources.md.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")

const CLARION_M := 78.0
## The second tower's roof, estimated from photographs (both have 16
## hotel floors; the taller one adds the sky bar and plant storeys).
const CLARION_LOW_M := 66.0
const TERMINAL_M := 18.0
const CABLE_FACTORY_M := 28.0
const SALMISAARI_M := 150.0

static func clarion(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Panel", LandmarkMaterials.pbr("concrete", "#CDD0CF", 2.0))
	lm.use("Dark", LandmarkMaterials.paint("#4B5357", 0.6, 0.2))
	lm.use("Glass", LandmarkMaterials.glass("#2D3C44"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BDB8AE", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#55595A", 0.8))
	var podium := I.outline("clarion_hotel")
	var deck := 9.2
	lm.poly_prism("Glass", F.offset(podium, -0.4), 0.0, deck - 0.6)
	lm.poly_prism("Concrete", podium, deck - 0.6, deck)
	var south := W._poly(I.CLARION_SOUTH)
	var north := W._poly(I.CLARION_NORTH)
	for t: Array in [[south, CLARION_M - 8.0], [north, CLARION_LOW_M - 2.0]]:
		var poly: PackedVector2Array = t[0]
		var top: float = t[1]
		W.ribs(lm, "Concrete", F.offset(poly, -0.6), 0.0, deck, 6.0, 1.1, 1.1)
		lm.poly_prism("Panel", poly, deck, top)
		_checker(lm, poly, deck, top, 1.6, 3.8)
	# The sky bar's glass storey and the plant storeys above it.
	lm.poly_prism("Glass", F.offset(south, 0.05), CLARION_M - 8.0, CLARION_M - 4.0)
	lm.poly_prism("Panel", south, CLARION_M - 4.0, CLARION_M)
	lm.poly_prism("Roof", F.offset(south, -0.4), CLARION_M - 0.3, CLARION_M - 0.1)
	# The rooftop pool's glass box on the lower tower.
	lm.poly_prism("Roof", F.offset(north, -0.4), CLARION_LOW_M - 2.0, CLARION_LOW_M - 1.8)
	lm.poly_prism("Glass", F.offset(north, -3.0), CLARION_LOW_M - 2.0, CLARION_LOW_M)
	var atrium := W._poly(I.CLARION_ATRIUM)
	lm.poly_prism("Glass", atrium, deck, CLARION_LOW_M - 3.0)
	W.ribs(lm, "Dark", atrium, deck, CLARION_LOW_M - 3.0, 1.6, 0.08, 0.1)
	lm.commit(model, "Clarion_")

## Chequerboard of dark panels over a light shaft: every other bay of
## every storey, shifted by one bay a storey.
static func _checker(lm: LandmarkMesh, poly: PackedVector2Array, y0: float, y1: float, bay: float,
		pitch: float) -> void:
	var rows := int((y1 - y0) / pitch)
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var n := int(a.distance_to(b) / bay)
		if n < 2:
			continue
		var along := (b - a).normalized()
		var out := W.outward(poly, a, b)
		var w := a.distance_to(b) / float(n)
		var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
		for r in rows:
			for k in n:
				if (k + r + i) % 2 != 0:
					continue
				var c := a + along * (w * (float(k) + 0.5)) + out * 0.06
				lm.box("Dark", Vector3(c.x, y0 + pitch * (float(r) + 0.5), c.y),
					Vector3(w * 0.96, pitch * 0.96, 0.12), basis, 0.0)

## Glazed hall with white fins under an overhanging white roof, the
## raised central hall in its widest part.
static func west_terminal(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#3B4D57"))
	lm.use("White", LandmarkMaterials.pbr("concrete", "#F1F1EE", 2.5))
	lm.use("Steel", LandmarkMaterials.paint("#9AA0A3", 0.45, 0.5))
	var poly := I.outline("west_terminal_2")
	var eave := 11.0
	lm.poly_prism("Glass", F.offset(poly, -0.3), 0.0, eave)
	W.ribs(lm, "White", poly, 0.0, eave, 3.0, 0.3, 0.35)
	lm.poly_prism("White", F.offset(poly, 1.8), eave, eave + 1.2)
	var hall := F.offset(poly, -10.0)
	lm.poly_prism("Glass", hall, eave + 1.2, TERMINAL_M - 1.2, false)
	W.ribs(lm, "Steel", hall, eave + 1.2, TERMINAL_M - 1.2, 2.0, 0.12, 0.15)
	lm.poly_prism("White", F.offset(hall, 1.2), TERMINAL_M - 1.2, TERMINAL_M)
	lm.commit(model, "West_terminal_2_")

## Five tall storeys of paired multi-pane windows in pale grey brick, the
## red-brick top band of small windows, grey plant boxes on the roof.
static func cable_factory(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B7B0A2", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("brick", "#8E4A36", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("concrete", "#CFC9BC", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6E6A64", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2D3436"))
	lm.use("Roof", LandmarkMaterials.paint("#5A5D5E", 0.8))
	lm.use("Metal", LandmarkMaterials.paint("#868C90", 0.5, 0.4))
	var poly := I.outline("cable_factory")
	var band := 19.0
	var eave := 22.4
	lm.poly_prism("Granite", F.offset(poly, 0.12), 0.0, 0.8)
	lm.poly_prism("Brick", poly, 0.8, band)
	lm.poly_prism("Red", poly, band, eave, false)
	lm.poly_prism("Trim", F.offset(poly, 0.25), eave - 0.4, eave, false)
	lm.poly_prism("Roof", F.offset(poly, 0.05), eave - 0.1, eave + 0.05)
	W.edge_windows(lm, "Glass", poly, 1.4, 4, 4.3, 3.4, 2.4, 2.9, "Trim")
	W.edge_windows(lm, "Glass", poly, band + 0.8, 1, 1.0, 1.7, 0.9, 0.9)
	var yaw := atan2(0.299, 0.954)
	U.blk(lm, "Metal", 0.0, eave, -22.7, 34.0, CABLE_FACTORY_M - eave, 11.0, yaw)
	U.blk(lm, "Metal", 40.0, eave, 7.0, 30.0, CABLE_FACTORY_M - eave, 11.0, yaw)
	lm.commit(model, "Cable_factory_")

## The brick boiler house with its 9- and 11-storey parts and tall strip
## windows, the two chimneys and the heat-storage tanks.
static func salmisaari(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#7E4636", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#CFC7B6", 3.0))
	lm.use("Steel", LandmarkMaterials.paint("#6D7C86", 0.5, 0.5))
	lm.use("Dark", LandmarkMaterials.paint("#3A3B3C", 0.7))
	lm.use("Glass", LandmarkMaterials.glass("#2E3538"))
	lm.use("Roof", LandmarkMaterials.paint("#55524F", 0.8))
	var base := I.outline("salmisaari_power_plant")
	var mid := W._poly(I.SALMISAARI_MID)
	var high := W._poly(I.SALMISAARI_HIGH)
	for t: Array in [[base, 18.0], [mid, 34.0], [high, 42.0]]:
		var poly: PackedVector2Array = t[0]
		var top: float = t[1]
		lm.poly_prism("Brick", poly, 0.0, top)
		W.ribs(lm, "Brick", poly, 0.0, top, 4.0, 0.7, 0.3)
		lm.poly_prism("Roof", F.offset(poly, -0.2), top, top + 0.2)
		W.edge_windows(lm, "Glass", poly, top - 15.0 if top > 20.0 else 2.0, 1, 1.0, 4.0, 1.3,
			11.0 if top > 20.0 else 6.0)
	var bc := I.BRICK_CHIMNEY
	lm.frustum("Brick", Vector3(bc.x, 0.0, bc.y), I.CHIMNEY_RADII["brick"], 3.2, 112.0, 20)
	lm.frustum("Dark", Vector3(bc.x, 112.0, bc.y), 3.4, 3.3, 2.0, 20)
	var tc := I.TALL_CHIMNEY
	lm.frustum("Concrete", Vector3(tc.x, 0.0, tc.y), I.CHIMNEY_RADII["tall"], 3.0, SALMISAARI_M - 3.0, 20)
	lm.frustum("Dark", Vector3(tc.x, SALMISAARI_M - 3.0, tc.y), 3.1, 3.0, 3.0, 20)
	for c: Vector2 in I.TANKS:
		lm.frustum("Steel", Vector3(c.x, 0.0, c.y), I.TANK_RADIUS_M, I.TANK_RADIUS_M, 32.0, 32)
		lm.frustum("Dark", Vector3(c.x, 32.0, c.y), I.TANK_RADIUS_M + 0.1, I.TANK_RADIUS_M - 0.6, 0.6, 32)
	lm.commit(model, "Salmisaari_")

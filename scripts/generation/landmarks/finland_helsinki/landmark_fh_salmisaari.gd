extends RefCounted

## Salmisaari power station (Salmisaari A, 1953, and the 1980s B plant), the
## coal-and-gas CHP plant on the Ruoholahti shore. Origin at the Salmisaari A
## boiler house (OSM way 14829857), yaw 0; every outline below is OSM, in
## LandmarkFhInnerFootprints.
##
## From the Commons photos (visual-plan/refs/landmarks/salmisaari_power_plant/):
## - Orange-brown brick boiler halls in stepped masses (the 9- and 11-level
##   parts, ways 445475464 and 445475459) with tall vertical window strips
##   between brick piers, flat roofs and small plant boxes.
## - Two slender chimneys: the pale concrete 150 m stack (way 349596091) and
##   the 1953 brick stack (way 349596089, 114 m, a wider flared top).
## - The Lampoakku heat-storage tanks (ways 349596073, 349596077), round
##   steel cylinders with a rolled cap.
##
## Measured: all outlines, 114 m and 150 m chimney heights (OSM), 34 m and
## 42 m part heights from the level counts; the City LoD2 reads 45.2 m for
## the boiler house and does not cover the stacks. Estimated: the 18 m low
## block, the tank height (32 m), the plant boxes, the stack taper and all
## colours.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")

const ENTRY := {"type": "salmisaari_power_plant", "skyline": true, "name": "Salmisaari Power Station", "lat": 60.163982, "lon": 24.903529,
	"radius_m": 6000.0, "wiki_title": "Salmisaari", "height_m": 150.0, "clear_m": 14.0,
	"clear_offsets_m": [[-23.8, -38.5], [56.2, -153.4], [-26.4, -73.4], [-14.1, -57.5], [9.0, -21.0],
		[-9.0, 21.0], [-21.0, -3.0], [23.0, -5.0], [9.0, 19.0], [-7.0, -17.0], [17.0, -27.0],
		[-23.0, 21.0], [-5.0, 29.0], [-27.0, 5.0]],
	"kind": "Power station", "aliases": ["salmisaari power station", "salmisaari power plant",
		"salmisaaren voimalaitos", "salmisaari a", "salmisaari chimney", "sundholmens kraftverk"]}

const SALMISAARI_M := 150.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B27A52", 3.0))
	lm.use("Pier", LandmarkMaterials.pbr("brick", "#8F5A3C", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D4CDBE", 3.0))
	lm.use("Steel", LandmarkMaterials.paint("#6D7C86", 0.5, 0.5))
	lm.use("Dark", LandmarkMaterials.paint("#3A3B3C", 0.7))
	lm.use("Glass", LandmarkMaterials.glass("#2E3538"))
	lm.use("Roof", LandmarkMaterials.paint("#55524F", 0.8))
	lm.use("Lamp", LandmarkMaterials.lit("#FF2A1A", 1.2))
	var base := I.outline("salmisaari_power_plant")
	var mid := W._poly(I.SALMISAARI_MID)
	var high := W._poly(I.SALMISAARI_HIGH)
	for t: Array in [[base, 18.0], [mid, 34.0], [high, 42.0]]:
		var poly: PackedVector2Array = t[0]
		var top: float = t[1]
		lm.poly_prism("Brick", poly, 0.0, top)
		W.ribs(lm, "Pier", poly, 0.0, top, 4.0, 0.7, 0.3)
		lm.poly_prism("Pier", F.offset(poly, 0.3), top - 0.9, top, false)
		lm.poly_prism("Roof", F.offset(poly, -0.2), top, top + 0.2)
		var y0 := top - 15.0 if top > 20.0 else 2.0
		W.edge_windows(lm, "Glass", poly, y0, 1, 1.0, 4.0, 1.3, 11.0 if top > 20.0 else 6.0, "Pier")
		if top > 20.0:
			# Lower strip of smaller windows under the tall ones.
			W.edge_windows(lm, "Glass", poly, 3.0, 2, 5.0, 4.0, 1.3, 2.2)
			var c := F.offset(poly, -4.0)
			if c.size() >= 3:
				var cen := Vector2.ZERO
				for p in c:
					cen += p
				cen /= float(c.size())
				U.blk(lm, "Steel", cen.x, top + 0.2, cen.y, 6.0, 2.6, 4.0)
	var bc := I.BRICK_CHIMNEY
	var br: float = I.CHIMNEY_RADII["brick"]
	lm.frustum("Brick", Vector3(bc.x, 0.0, bc.y), br, 3.2, 108.0, 24)
	lm.frustum("Pier", Vector3(bc.x, 100.0, bc.y), 3.5, 3.5, 0.5, 24)
	lm.frustum("Brick", Vector3(bc.x, 108.0, bc.y), 3.2, 3.7, 4.0, 24)
	lm.frustum("Dark", Vector3(bc.x, 112.0, bc.y), 3.7, 3.4, 2.0, 24)
	var tc := I.TALL_CHIMNEY
	var tr: float = I.CHIMNEY_RADII["tall"]
	lm.frustum("Concrete", Vector3(tc.x, 0.0, tc.y), tr, 3.0, SALMISAARI_M - 8.0, 24)
	# Shuttering joints every 12 m and the darker crown with its red lamps.
	for k in 11:
		var y := 12.0 * float(k + 1)
		var r := lerpf(tr, 3.0, y / (SALMISAARI_M - 8.0)) + 0.05
		lm.frustum("Dark", Vector3(tc.x, y, tc.y), r, r, 0.25, 24)
	lm.frustum("Dark", Vector3(tc.x, SALMISAARI_M - 8.0, tc.y), 3.1, 3.0, 8.0, 24)
	var halos: Array = []
	for y in [SALMISAARI_M - 4.0, SALMISAARI_M - 0.3]:
		for s in [-1.0, 1.0]:
			lm.box("Lamp", Vector3(tc.x + s * 3.2, y, tc.y), Vector3(0.4, 0.4, 0.4))
			halos.append([Vector3(tc.x + s * 3.2, y, tc.y), 3.0, Color(1.0, 0.1, 0.05)])
	for s in [-1.0, 1.0]:
		lm.box("Lamp", Vector3(bc.x + s * 3.6, 112.0, bc.y), Vector3(0.4, 0.4, 0.4))
		halos.append([Vector3(bc.x + s * 3.6, 112.0, bc.y), 2.6, Color(1.0, 0.1, 0.05)])
	for c: Vector2 in I.TANKS:
		lm.frustum("Steel", Vector3(c.x, 0.0, c.y), I.TANK_RADIUS_M, I.TANK_RADIUS_M, 32.0, 32)
		lm.frustum("Dark", Vector3(c.x, 32.0, c.y), I.TANK_RADIUS_M + 0.1, I.TANK_RADIUS_M - 0.6, 0.6, 32)
		for k in 7:
			lm.frustum("Dark", Vector3(c.x, 4.5 * float(k + 1), c.y), I.TANK_RADIUS_M + 0.06, I.TANK_RADIUS_M + 0.06, 0.2, 32)
	model.set_meta(LandmarkLights.HALO_META, halos)
	lm.commit(model, "Salmisaari_")

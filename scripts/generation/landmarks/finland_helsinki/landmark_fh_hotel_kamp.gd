extends RefCounted

## Hotel Kämp (Theodor Höijer, 1887), Pohjoisesplanadi 29. Origin at the OSM
## outline's bounding-box centre, front +Z toward the Esplanadi (registry yaw
## -3 keeps the street grid).
##
## Measured: the outline of the hotel (way 123550178, simplified to 1 m: the
## 29 m Esplanadi front with its 55 m long east wing, the north wing and the
## short wing round the Kämp Galleria court), eight levels per OSM. The
## registry point lay 55 m from the hotel. Estimated from visual-plan/refs/
## hotel_kamp/ (no LoD2 row in reach): the ochre-brown stucco, cream pilasters
## and window surrounds, string courses at every floor, balconies with white
## balustrades, terracotta-orange panels on the top two floors, the heavy
## bracketed cornice and balustraded parapet, the glazed café storey under a
## cream awning. Storey heights (shop 5.2 m, then five floors of 3.6 m, attic
## 3.4 m) and the 28 m top are read from the photo scale.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "hotel_kamp", "name": "Hotel Kämp", "lat": 60.168162, "lon": 24.946729,
	"radius_m": 1500.0, "wiki_title": "Hotel Kämp", "height_m": 28.5, "clear_m": 34.0,
	"yaw_deg": -3.0, "kind": "Hotel", "aliases": ["hotel kämp", "hotelli kämp", "hotel kamp"]}

const OUTLINE := [-2.4, -20.6, -36.2, -21.0, -36.2, -33.3, 7.6, -33.1, 7.7, -21.3, 36.2, -21.3, 36.2, 32.1, 35.0, 33.3, 7.5, 33.3, 7.5, 16.9, -2.4, 16.9]
const SHOP := 5.2
const FLOOR := 3.6
const EAVE := 25.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#9C7448", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E8DEC6", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7E746A", 3.0))
	lm.use("Panel", LandmarkMaterials.pbr("render", "#B5683C", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#4A4E50", 0.6, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#3A2E28"))
	lm.use("Shop", LandmarkMaterials.glass("#34403F"))
	lm.use("Awning", LandmarkMaterials.paint("#D8CDB0", 0.8, 0.0))
	lm.use("Lamp", LandmarkMaterials.lit("#F6E8BC", 0.35))
	var p := D.poly(OUTLINE)
	D.block(lm, p, {"eave": EAVE, "plinth": 1.0, "cornice": 1.3, "cornice_out": 0.9, "bay": 3.6, "pier_w": 0.6,
		"pier_proj": 0.28, "win": Vector2(1.6, 2.4), "sill": 0.7, "y0": SHOP, "storey": FLOOR, "rows": 5,
		"depth": 0.3, "min_len": 6.0, "stone": "Stone"})
	# String courses at the floors and the orange panel band under the cornice.
	for k in range(1, 6):
		D.slab(lm, "Trim", p, 0.3, SHOP + FLOOR * float(k) - 0.35, 0.4)
	D.slab(lm, "Panel", p, 0.1, SHOP + FLOOR * 3.0, FLOOR * 1.7)
	# Attic storey above the cornice and a balustraded parapet.
	var top := EAVE + 3.0
	lm.poly_prism("Wall", D.grow(p, -1.2), EAVE, top, false)
	D.slab(lm, "Roof", D.grow(p, -1.6), 0.0, top - 0.05, 0.3)
	D.slab(lm, "Trim", p, 0.5, top - 0.3, 0.5)
	for run in D.runs(p):
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		if a.distance_to(b) < 6.0:
			continue
		var o: Vector3 = run[2]
		LandmarkDetail.balustrade(lm, "Trim", a + Vector3(0, top + 0.2, 0) + o * 0.4, b + Vector3(0, top + 0.2, 0) + o * 0.4, 0.9, 2.4, 6)
		# Cream pilasters and a glazed café storey under the awning on the Esplanadi
		# front and the east side.
		if o.z > 0.5 or o.x > 0.5:
			P.pierce(lm, "Stone", "Shop", a, b, o, 0.0, SHOP - 0.2, maxi(int(round(a.distance_to(b) / 3.6)), 1), 1,
				Vector2(2.8, 3.8), 0.5, 4.0, 0.25)
			var m := (a + b) * 0.5
			var dir := (b - a).normalized()
			var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
			lm.box("Awning", m + Vector3(0, SHOP - 0.9, 0) + o * 1.9, Vector3(a.distance_to(b) - 1.0, 0.25, 4.0), basis, 0.0)
	# Rooftop name sign.
	lm.box("Lamp", Vector3(20.0, top + 0.9, 31.0), Vector3(9.0, 1.0, 0.25), Basis(), 0.0)
	lm.commit(model)
	D.flood(model, [
		[Vector3(22.0, 0.5, 45.0), Vector3(22.0, 14.0, 33.0), 55.0, 0.9, 45.0, Color(1.0, 0.9, 0.74)],
		[Vector3(46.0, 0.5, 20.0), Vector3(36.0, 14.0, 8.0), 55.0, 0.7, 45.0, Color(1.0, 0.9, 0.74)]])

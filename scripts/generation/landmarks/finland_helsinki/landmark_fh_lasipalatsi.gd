class_name LandmarkFhLasipalatsi
extends RefCounted

## Lasipalatsi (the Glass Palace, 1936, Revell, Riihimäki and Kokko) beside
## Amos Rex, true metres, extruded from its OpenStreetMap outline (way
## 8035238, 3 levels, flat roof; yaw 0): pale rendered functionalist block
## with glazed shopfront storey on slim steel mullions, two storeys of ribbon
## windows, the signature slender white clock/chimney tower (OSM way 28775756)
## rising to 24.0 m, and the Bio Rex neon rooftop sign and entrance marquee.

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

const OUTLINE := [
	-58.9, -24.3, -62.5, -34.0, -35.8, -53.9, -36.5, -54.8, -31.7, -58.4, -31.0, -57.5, -20.8, -65.4,
	49.7, 28.1, 6.7, 59.9, -0.4, 50.4, 31.5, 26.8, 19.0, 10.2, 13.9, 14.3, -17.8, -28.0]

const EAVE := 12.2
const SHOP := 4.6
const TOWER_TOP := 24.0

static func lasipalatsi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E2E0D4", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#ECEADC", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#5A7A82"))
	lm.use("Metal", LandmarkMaterials.paint("#EDEBE0", 0.5))
	lm.use("Roof", LandmarkMaterials.paint("#5A5E5E", 0.8))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4A8", 0.7))
	lm.use("Neon", LandmarkMaterials.lit("#E84A38", 0.75))
	var poly := PackedVector2Array()
	for i in range(0, OUTLINE.size() - 1, 2):
		poly.append(Vector2(float(OUTLINE[i]), float(OUTLINE[i + 1])))
	lm.poly_prism("Wall", poly, 0.0, EAVE)
	# Glazed shopfront storey on slim steel mullions, over a low plinth.
	lm.poly_prism("Glass", F.offset(poly, 0.06), 0.5, SHOP, false)
	W.ribs(lm, "Metal", poly, 0.5, SHOP, 2.2, 0.07, 0.12)
	lm.poly_prism("Trim", F.offset(poly, 0.25), SHOP, SHOP + 0.35)
	# Two storeys of continuous ribbon windows, mullioned.
	W.ribbons(lm, "Glass", poly, SHOP + 1.3, 1.7, 2, 3.4)
	W.ribs(lm, "Metal", poly, SHOP + 1.3, SHOP + 3.0, 3.0, 0.08, 0.12)
	W.ribs(lm, "Metal", poly, SHOP + 4.7, SHOP + 6.4, 3.0, 0.08, 0.12)
	# Flat roof behind a pale parapet.
	lm.poly_prism("Trim", F.offset(poly, 0.2), EAVE, EAVE + 0.6)
	lm.poly_prism("Roof", F.offset(poly, -0.5), EAVE + 0.3, EAVE + 0.5)
	_clock_tower(lm)
	_biorex_marquee(lm)
	lm.commit(model, "Lasipalatsi_")
	var warm := Color(1.0, 0.90, 0.72)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(38.0, 1.5, -18.0), Vector3(14.0, 10.0, -10.0), 55.0, 0.9, 65.0, warm],
		[Vector3(46.0, 1.5, 42.0), Vector3(24.0, 14.0, 26.0), 50.0, 1.0, 60.0, warm],
		[Vector3(-42.0, 1.5, -52.0), Vector3(-28.0, 10.0, -40.0), 52.0, 0.8, 55.0, warm],
		[Vector3(2.0, 1.5, 36.0), Vector3(14.0, 20.0, 20.0), 32.0, 1.1, 50.0, warm],
	])

## Slender white functionalist clock/chimney tower (OSM way 28775756) to 24.0 m.
static func _clock_tower(lm: LandmarkMesh) -> void:
	var tc := Vector3(16.0, 0.0, 20.0)
	lm.frustum("Wall", tc + Vector3(0, EAVE, 0), 1.65, 1.45, TOWER_TOP - EAVE - 0.35, 24)
	lm.frustum("Trim", tc + Vector3(0, TOWER_TOP - 0.35, 0), 1.60, 1.60, 0.35, 24)
	lm.frustum("Metal", tc + Vector3(0, 15.8, 0), 1.65, 1.65, 0.16, 24)
	lm.frustum("Metal", tc + Vector3(0, 21.8, 0), 1.55, 1.55, 0.16, 24)
	# Vertical illuminated clock dial and housing facing Mannerheimintie and square.
	for ang in [0.64, -2.50]:
		var dir := Vector3(cos(ang), 0.0, sin(ang))
		var basis := Basis.looking_at(dir)
		lm.box("Metal", tc + dir * 1.48 + Vector3(0, 19.0, 0), Vector3(0.95, 4.2, 0.25), basis, 0.0)
		lm.box("Lamp", tc + dir * 1.58 + Vector3(0, 19.0, 0), Vector3(0.70, 3.8, 0.10), basis, 0.0)
		lm.disc("Lamp", tc + dir * 1.60 + Vector3(0, 20.6, 0), dir, 0.45, 16)
		lm.box("Metal", tc + dir * 1.66 + Vector3(0, 20.72, 0), Vector3(0.06, 0.30, 0.04), basis, 0.0)
		lm.box("Metal", tc + dir * 1.66 + Vector3(0, 20.60, 0), Vector3(0.24, 0.06, 0.04), basis, 0.0)

## Bio Rex rooftop neon sign frame and lit entrance marquee canopy.
static func _biorex_marquee(lm: LandmarkMesh) -> void:
	var dir := Vector3(0.80, 0.0, -0.60).normalized()
	var basis := Basis.looking_at(dir)
	var sign_c := Vector3(28.0, EAVE + 0.5, 33.0)
	for dx in [-4.8, -1.6, 1.6, 4.8]:
		lm.box("Metal", sign_c + basis.x * dx + Vector3(0, 1.6, 0), Vector3(0.14, 3.2, 0.14), basis, 0.0)
	lm.box("Metal", sign_c + Vector3(0, 2.2, 0), Vector3(11.4, 2.2, 0.22), basis, 0.0)
	# Glowing BIO REX letter blocks in Lamp and Neon.
	for i in 6:
		var lx := -4.2 + float(i) * 1.68 + (0.45 if i >= 3 else 0.0)
		lm.box("Lamp", sign_c + basis.x * lx + Vector3(0, 2.2, 0) + dir * 0.15,
			Vector3(1.05, 1.55, 0.12), basis, 0.0)
	# Bio Rex entrance marquee canopy on the south-east Mannerheimintie face.
	var marq := Vector3(28.2, SHOP + 0.1, 43.8)
	lm.box("Metal", marq, Vector3(12.0, 0.55, 3.8), basis, 0.0)
	lm.box("Lamp", marq + dir * 1.85, Vector3(11.6, 0.36, 0.14), basis, 0.0)
	lm.box("Neon", marq - dir * 0.0 + Vector3(0, 0.42, 0), Vector3(9.0, 0.48, 0.18), basis, 0.0)

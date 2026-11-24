extends RefCounted

## Equestrian Statue of Marshal Mannerheim (Aimo Tukiainen, 1960),
## Mannerheiminaukio outside Kiasma and Postitalo.
##
## Vertical-walled rectangular pedestal clad in 6 horizontal ashlar courses of
## smooth-dressed warm brownish-pink Vehmaa granite above a recessed granite
## kick-base, bearing dark-bronze raised block letters `MANNERHEIM` at eye level
## on the long side face, surmounted by the flush bronze base slab and 4.65 m
## equestrian bronze of Marshal Mannerheim on his mare Käthy (11.1 m total).

const ASSET_DIR := "res://assets/landmarks/helsinki_3d/"

const ENTRY := {"type": "mannerheim_statue", "name": "Marshal Mannerheim Equestrian Statue",
	"lat": 60.1715897, "lon": 24.9363006, "radius_m": 2000.0,
	"wiki_title": "Equestrian statue of Marshal Mannerheim", "height_m": 11.1, "clear_m": 8.0,
	"yaw_deg": 28.0, "kind": "Monument", "secondary": true,
	"aliases": ["marshal mannerheim equestrian statue", "mannerheim statue", "marshal mannerheim statue",
		"mannerheimin ratsastajapatsas", "marsalkka mannerheimin ratsastajapatsas"]}

const _GLYPHS := {
	"M": [[-0.42, 0.0, 0.14, 1.0], [0.42, 0.0, 0.14, 1.0], [-0.20, 0.18, 0.13, 0.56], [0.20, 0.18, 0.13, 0.56], [0.0, -0.02, 0.14, 0.42]],
	"A": [[-0.28, 0.0, 0.14, 1.0], [0.28, 0.0, 0.14, 1.0], [0.0, 0.42, 0.52, 0.15], [0.0, -0.06, 0.52, 0.14]],
	"N": [[-0.32, 0.0, 0.14, 1.0], [0.32, 0.0, 0.14, 1.0], [0.0, 0.0, 0.18, 0.72]],
	"E": [[-0.28, 0.0, 0.14, 1.0], [0.04, 0.42, 0.56, 0.15], [0.0, 0.0, 0.48, 0.14], [0.04, -0.42, 0.56, 0.15]],
	"R": [[-0.28, 0.0, 0.14, 1.0], [0.04, 0.42, 0.54, 0.15], [0.04, 0.04, 0.54, 0.14], [0.28, 0.23, 0.14, 0.46], [0.22, -0.24, 0.16, 0.52]],
	"H": [[-0.32, 0.0, 0.14, 1.0], [0.32, 0.0, 0.14, 1.0], [0.0, 0.0, 0.56, 0.15]],
	"I": [[0.0, 0.0, 0.15, 1.0]],
}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var bronze := LandmarkMaterials.pbr("limestone", "#35473F", 1.2, 0.44, 0.48).duplicate() as StandardMaterial3D
	bronze.set_meta("landmark_marble", true)
	lm.use("PlazaGranite", LandmarkMaterials.pbr("stone", "#8A857E", 2.4))
	lm.use("VehmaaGranite", LandmarkMaterials.marble("#9E7267", 0.50))
	lm.use("GraniteJoint", LandmarkMaterials.marble("#684A43", 0.65))
	lm.use("Bronze", bronze)
	lm.use("DarkLetterBronze", LandmarkMaterials.paint("#232825", 0.42, 0.72))

	# Recessed bottom granite kick-base rising directly from the plaza pavement (y = 0.00 .. 0.45 m)
	var ped_w := 2.54
	var ped_l := 5.74
	lm.box("VehmaaGranite", Vector3(0.0, 0.225, 0.0), Vector3(ped_w - 0.06, 0.45, ped_l - 0.06), Basis(), 0.0)
	lm.box("GraniteJoint", Vector3(0.0, 3.45, 0.0), Vector3(ped_w - 0.025, 6.00, ped_l - 0.025), Basis(), 0.0)

	# 6 precision-cut horizontal courses of vertical-walled Vehmaa pink-brown granite ashlar
	# (y = 0.45 .. 6.45 m -> each course 1.00 m high with crisp 1.2 cm recessed stone joints!)
	var course_h := 1.00
	var joint := 0.012
	for c in 6:
		var yc := 0.45 + (float(c) + 0.5) * course_h
		var ch := course_h - joint

		# Front (+Z) & Rear (-Z) narrow end slabs (alternating 1-slab / 2-slab bond)
		for sz: float in [-1.0, 1.0]:
			var zf: float = sz * (ped_l * 0.5 - 0.012)
			if c % 2 == 0:
				lm.box("VehmaaGranite", Vector3(0.0, yc, zf), Vector3(ped_w, ch, 0.024), Basis(), 0.0)
			else:
				var hw := (ped_w - joint) * 0.5
				lm.box("VehmaaGranite", Vector3(-(hw + joint) * 0.5, yc, zf), Vector3(hw, ch, 0.024), Basis(), 0.0)
				lm.box("VehmaaGranite", Vector3((hw + joint) * 0.5, yc, zf), Vector3(hw, ch, 0.024), Basis(), 0.0)

		# Left (+X) & Right (-X) long side faces with staggered 3-bay ashlar slabs
		var splits: Array = [-2.87, -0.96, 0.96, 2.87] if (c % 2 == 0) else [-2.87, -1.35, 0.48, 1.92, 2.87]
		for sx: float in [-1.0, 1.0]:
			var xf: float = sx * (ped_w * 0.5 - 0.012)
			for bi in range(splits.size() - 1):
				var z0: float = float(splits[bi]) + (0.0 if bi == 0 else joint * 0.5)
				var z1: float = float(splits[bi + 1]) - (0.0 if bi == splits.size() - 2 else joint * 0.5)
				lm.box("VehmaaGranite", Vector3(xf, yc, 0.5 * (z0 + z1)), Vector3(0.024, ch, z1 - z0), Basis(), 0.0)

	# Cap top surface of the granite monolith at y = 6.45 m
	lm.box("VehmaaGranite", Vector3(0.0, 6.44, 0.0), Vector3(ped_w, 0.02, ped_l), Basis(), 0.0)

	# Eye-level dark-bronze `M A N N E R H E I M` raised inscription on left long side (+X), 2nd course
	var word := "MANNERHEIM"
	var l_h := 0.22
	var l_w := 0.16
	var step_z := 0.245
	var z_start := -0.15
	for idx in word.length():
		var ch_key := word.substr(idx, 1)
		var zc := z_start - float(idx) * step_z
		var strokes: Array = _GLYPHS.get(ch_key, [])
		for st in strokes:
			var s: Array = st
			lm.box("DarkLetterBronze",
				Vector3(ped_w * 0.5 + 0.012, 1.72 + float(s[1]) * l_h, zc - float(s[0]) * l_w),
				Vector3(0.022, float(s[3]) * l_h, float(s[2]) * l_w), Basis(), 0.0)

	# High-precision bronze equestrian Marshal Mannerheim & Käthy (6.45 + 4.65 = 11.10 m exact!)
	SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "mannerheim_equestrian_bronze.glb",
		Vector3(0.0, 6.45, 0.0), Vector3.ONE, 0.0)
	lm.commit(model)

	var warm := Color(1.0, 0.89, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-5.2, 0.5, 5.4), Vector3(0.0, 8.2, 0.0), 42.0, 0.95, 22.0, warm],
		[Vector3(5.2, 0.5, 5.4), Vector3(0.0, 8.2, 0.0), 42.0, 0.95, 22.0, warm],
		[Vector3(0.0, 0.5, -6.0), Vector3(0.0, 8.2, 0.0), 44.0, 0.85, 22.0, warm],
	])

extends RefCounted

## Pasila link tower (Pasilan linkkitorni), Länsi-Pasila beside the Yle
## buildings: a concrete shaft carrying seven antenna platforms and a steel
## mast. Origin at the shaft (OSM way 445084921, 60.20469 N 24.923106 E), yaw 0.
##
## Measured (OSM, 2026-11): the shaft is a 10 m round concrete tower,
## 112 m tall ("height" tag); seven ring platforms are mapped as building
## parts at 30-31.5 m (r 9.9), 56-57 (11.6), 60-61 (12.2), 67-68 (8.5), 79-80
## (13.2), 87-88 (13.4) and 95-96 m (13.7) with their radii from the part
## areas, in metal grey (#c2c2c2). Published: 146 m to the mast tip (the
## registry value; 112 + a 34 m mast). Estimated: the shaft taper (r 5.0 to
## 3.6), mast radii and the red-white banding of its top, dish placement.
## The registry's earlier point (60.2068 N, 24.9341 E) was 700 m east of the
## tower; the green lattice tower in the Commons photo
## (visual-plan/refs/landmarks/pasila_link_tower/view.jpg, Elisa's, further
## east) is a different mast and is not modelled here. Only one photograph
## of the tower itself was found among the CC files; not otherwise checked.

const ENTRY := {"type": "pasila_link_tower", "name": "Pasila TV Tower", "lat": 60.20469, "lon": 24.923106,
	"radius_m": 1500.0, "wiki_title": "Pasila TV tower", "height_m": 146.0, "clear_m": 12.0,
	"kind": "Tower", "aliases": ["pasila tv tower", "pasilan linkkitorni", "böle tv-torn", "yle tower pasila"]}

const SHAFT_H := 112.0
const PLATFORMS := [[30.0, 9.9], [56.0, 11.6], [60.0, 12.2], [67.0, 8.5], [79.0, 13.2], [87.0, 13.4], [95.0, 13.7]]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A89A8A", 3.0))
	lm.use("Metal", LandmarkMaterials.paint("#C2C2C2", 0.45, 0.6))
	lm.use("Red", LandmarkMaterials.paint("#C0281E", 0.5, 0.2))
	lm.use("White", LandmarkMaterials.paint("#ECEBE6", 0.5, 0.2))
	lm.use("Dark", LandmarkMaterials.paint("#3A3C3E", 0.6, 0.4))
	lm.use("Lamp", LandmarkMaterials.lit("#FF3322", 2.0))
	lm.frustum("Concrete", Vector3.ZERO, 5.0, 3.6, SHAFT_H, 24)
	lm.frustum("Concrete", Vector3.ZERO, 6.2, 5.0, 2.0, 24)
	for pf in PLATFORMS:
		var y: float = pf[0]
		var r: float = pf[1]
		lm.frustum("Metal", Vector3(0, y - 1.4, 0), r * 0.35, r, 1.4, 24)
		lm.frustum("Metal", Vector3(0, y, 0), r, r, 0.6, 24)
		lm.frustum("Dark", Vector3(0, y + 0.6, 0), r, r, 0.14, 24)
		# Railing posts and a dish pair on the larger platforms.
		for k in 12:
			var a := TAU * float(k) / 12.0
			lm.beam("Metal", Vector3(cos(a) * (r - 0.2), y + 0.6, sin(a) * (r - 0.2)),
				Vector3(cos(a) * (r - 0.2), y + 1.7, sin(a) * (r - 0.2)), 0.1)
		if r > 11.0:
			for k in 3:
				var a2 := TAU * (float(k) + 0.3) / 3.0
				lm.lathe("White", Vector3(cos(a2) * (r - 2.2), y + 0.8, sin(a2) * (r - 2.2)),
					PackedVector2Array([Vector2(0.0, 0.0), Vector2(1.3, 0.5), Vector2(1.4, 1.2)]), 12)
	# Top: a stub of the shaft, the mast with its red and white bands.
	lm.frustum("Concrete", Vector3(0, SHAFT_H, 0), 3.6, 1.4, 4.0, 16)
	for k in 8:
		var key := "Red" if k % 2 == 0 else "White"
		var r0 := 0.55 - 0.03 * float(k)
		lm.frustum(key, Vector3(0, SHAFT_H + 4.0 + 3.75 * float(k), 0), r0, r0 - 0.03, 3.75, 10)
	lm.box("Lamp", Vector3(0, SHAFT_H + 34.3, 0), Vector3(0.6, 0.6, 0.6))
	model.set_meta(LandmarkLights.HALO_META, [[Vector3(0, SHAFT_H + 34.3, 0), 3.0, Color(1.0, 0.12, 0.06)]])
	lm.commit(model)

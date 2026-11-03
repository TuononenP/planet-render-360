extends RefCounted

## Grouped attractions relative to the Eclipse site at 59.3230, 18.0963.
## Fritt Fall and Ikaros are at OSM ways 1122922291 and 1122930534;
## the operator gives heights 80 m and 95 m. Monster is the park's 34 m,
## 700 m inverted coaster (gronalund.com/attraktioner/monster). Its plan
## follows the above-ground OSM track ways 1312875271/2/3/4/6 and
## 1312887388. OSM layers are crossing order, not measured altitudes:
## the vertical profile and support positions below are approximations.
## The 2023-closed Jetline is intentionally absent.

const FRITT := Vector2(38.33, -29.69)
const IKAROS := Vector2(-54.85, -25.30)

const MONSTER_TRACKS := [
	[Vector3(-27.64, 18.50, -27.89),
		Vector3(-24.90, 16.62, -27.81),
		Vector3(-22.17, 15.05, -29.10),
		Vector3(-20.27, 14.00, -31.27),
		Vector3(-18.14, 13.55, -36.33),
		Vector3(-17.42, 13.62, -43.27),
		Vector3(-15.45, 14.00, -65.89)],
	[Vector3(-44.16, 24.00, -119.89),
		Vector3(-36.07, 29.46, -118.60),
		Vector3(-30.41, 33.17, -119.09),
		Vector3(-27.07, 34.07, -120.80),
		Vector3(-25.62, 32.16, -123.62),
		Vector3(-25.74, 28.50, -127.44)],
	[Vector3(-24.03, 23.00, -109.68),
		Vector3(-77.74, 23.19, -114.03),
		Vector3(-81.08, 23.35, -112.97),
		Vector3(-83.21, 23.45, -111.21),
		Vector3(-84.20, 23.47, -109.31),
		Vector3(-83.97, 23.37, -106.64),
		Vector3(-81.69, 23.16, -103.06),
		Vector3(-78.20, 22.81, -100.32),
		Vector3(-70.98, 22.33, -97.88),
		Vector3(-54.19, 21.74, -92.32),
		Vector3(-46.22, 21.03, -89.42),
		Vector3(-32.31, 20.24, -87.06),
		Vector3(-21.83, 19.38, -85.05),
		Vector3(-7.39, 18.50, -80.17)],
	[Vector3(-7.39, 18.50, -80.17),
		Vector3(0.58, 17.86, -77.09),
		Vector3(2.83, 17.24, -75.11),
		Vector3(4.58, 16.63, -72.75),
		Vector3(4.08, 16.06, -70.50),
		Vector3(2.49, 15.53, -68.97),
		Vector3(-0.97, 15.06, -68.60),
		Vector3(-8.45, 14.65, -70.34),
		Vector3(-13.35, 14.31, -73.39),
		Vector3(-19.20, 14.05, -81.46),
		Vector3(-24.37, 13.88, -91.64),
		Vector3(-29.20, 13.80, -98.15),
		Vector3(-32.05, 13.80, -100.59),
		Vector3(-34.70, 13.91, -101.80),
		Vector3(-37.44, 14.11, -102.26),
		Vector3(-42.53, 14.42, -101.77),
		Vector3(-53.39, 14.81, -99.82),
		Vector3(-56.02, 15.31, -99.55),
		Vector3(-58.49, 15.89, -99.71),
		Vector3(-61.07, 16.55, -100.81),
		Vector3(-63.50, 17.30, -102.98),
		Vector3(-65.40, 18.12, -105.95),
		Vector3(-66.08, 19.00, -109.57),
		Vector3(-65.32, 19.93, -114.41),
		Vector3(-63.19, 20.91, -118.18),
		Vector3(-59.96, 21.92, -120.08),
		Vector3(-53.43, 22.95, -121.26),
		Vector3(-44.16, 24.00, -119.89)],
	[Vector3(-25.74, 28.50, -127.44),
		Vector3(-27.26, 27.83, -129.83),
		Vector3(-30.14, 27.17, -130.98),
		Vector3(-33.07, 26.52, -130.93),
		Vector3(-35.69, 25.90, -129.49),
		Vector3(-37.13, 25.32, -126.29),
		Vector3(-36.87, 24.78, -122.11),
		Vector3(-33.15, 24.29, -117.00),
		Vector3(-27.07, 23.84, -112.58),
		Vector3(-20.50, 23.46, -109.12),
		Vector3(-16.66, 23.14, -104.13),
		Vector3(-9.33, 22.88, -90.34),
		Vector3(-5.49, 22.68, -85.81),
		Vector3(-3.21, 22.54, -84.63),
		Vector3(4.99, 22.45, -82.11),
		Vector3(9.82, 22.42, -79.29),
		Vector3(12.89, 22.44, -75.34),
		Vector3(13.73, 22.50, -71.91),
		Vector3(13.20, 22.59, -68.86),
		Vector3(11.75, 22.71, -66.85),
		Vector3(9.59, 22.85, -64.74),
		Vector3(7.98, 23.00, -63.36)],
	[Vector3(-13.65, 23.00, -56.03),
		Vector3(-19.51, 23.30, -53.67),
		Vector3(-27.41, 23.47, -49.17),
		Vector3(-31.85, 23.39, -44.80),
		Vector3(-33.45, 23.00, -39.69),
		Vector3(-33.60, 22.27, -35.12),
		Vector3(-32.35, 21.22, -31.85),
		Vector3(-30.14, 19.92, -28.95),
		Vector3(-27.64, 18.50, -27.89)]
]

static func add(lm: LandmarkMesh) -> void:
	lm.use("DropTower", LandmarkMaterials.pbr("concrete", "#D5D5D0", 2.0, 0.55, 0.35))
	lm.use("RideDetail", LandmarkMaterials.pbr("concrete", "#A85142", 2.0, 0.6, 0.25))
	lm.use("CoasterTrack", LandmarkMaterials.pbr("concrete", "#42413F", 2.0, 0.55, 0.25))
	lm.use("CoasterSupport", LandmarkMaterials.pbr("concrete", "#A4A19B", 2.0, 0.6, 0.2))
	_fritt(lm)
	_ikaros(lm)
	_monster(lm)

static func _fritt(lm: LandmarkMesh) -> void:
	var p := Vector3(FRITT.x, 0, FRITT.y)
	# Pale central mast, crown and three dark red gondola rails.
	lm.frustum("DropTower", p, 2.7, 2.7, 67.0, 16)
	lm.frustum("DropTower", p + Vector3.UP * 67.0, 6.0, 5.6, 5.0, 20)
	lm.frustum("DropTower", p + Vector3.UP * 72.0, 0.7, 0.35, 8.0, 10)
	for k in 3:
		var a := TAU * float(k) / 3.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("RideDetail", p + d * 2.8 + Vector3.UP * 2.0,
			p + d * 2.8 + Vector3.UP * 67.0, 0.35, 0.35)
		lm.box("RideDetail", p + d * 3.4 + Vector3.UP * 11.0, Vector3(2.3, 1.6, 1.2),
			Basis(Vector3.UP, -a + PI * 0.5))

static func _ikaros(lm: LandmarkMesh) -> void:
	var p := Vector3(IKAROS.x, 0, IKAROS.y)
	# A narrow tower on a five-metre-wide platform, with the sun on top.
	for x in [-1.4, 1.4]:
		for z in [-1.4, 1.4]:
			lm.beam("DropTower", p + Vector3(float(x), 0.3, float(z)),
				p + Vector3(float(x), 88.0, float(z)), 0.35, 0.35)
	for floor in 8:
		var lo := maxf(float(floor) * 11.0, 0.3)
		var hi := float(floor + 1) * 11.0
		for side in [-1.4, 1.4]:
			var v := float(side)
			lm.beam("DropTower", p + Vector3(-1.4, lo, v), p + Vector3(1.4, hi, v), 0.2, 0.2)
			lm.beam("DropTower", p + Vector3(1.4, lo, v), p + Vector3(-1.4, hi, v), 0.2, 0.2)
			lm.beam("DropTower", p + Vector3(v, lo, -1.4), p + Vector3(v, hi, 1.4), 0.2, 0.2)
			lm.beam("DropTower", p + Vector3(v, lo, 1.4), p + Vector3(v, hi, -1.4), 0.2, 0.2)
	lm.box("RideDetail", p + Vector3(0, 7.0, -2.2),
		Vector3(4.8, 2.0, 1.2))
	lm.frustum("RideDetail", p + Vector3.UP * 88.0, 2.2, 1.7, 2.0, 12)
	lm.frustum("Gilt", p + Vector3.UP * 90.0, 1.7, 0.1, 5.0, 12)

static func _monster(lm: LandmarkMesh) -> void:
	for raw in MONSTER_TRACKS:
		var path: Array = raw
		for i in path.size() - 1:
			var a: Vector3 = path[i]
			var b: Vector3 = path[i + 1]
			# The inverted coaster's track is one merged steel spine, with
			# pale support columns at regular mapped positions.
			lm.beam("CoasterTrack", a, b, 0.75, 0.7)
			if i % 3 == 0:
				lm.beam("CoasterSupport", Vector3(a.x, 0.3, a.z), a, 0.8, 0.8)

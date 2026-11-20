extends RefCounted

## Kallio Church (Lars Sonck, 1908-12), Itäinen Papinkatu 2. Origin at the OSM
## footprint centre, yaw -3 (entrance and tower south, +Z).
##
## From the photographs (visual-plan/refs/landmarks/kallio_church/): grey
## rough-hewn Uusikaupunki granite; a tall square tower closing
## Siltasaarenkatu with three tall louvred belfry openings under carved relief
## bands, a green copper dome over the half-round porch, a crenellated top with
## corner pinnacles, a smaller stone stage and a low green copper dome with a
## cross (no tall spire: the earlier model's pyramid spire was wrong).
##
## Measured: the 67.8 m height to the cross tip (LoD2; the registry said 65),
## the OSM 3D outline parts below. Estimated: the crown stage dimensions, the
## cross height, window details, copper colour.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "kallio_church", "skyline": true, "name": "Kallio Church", "lat": 60.18431, "lon": 24.94935,
	"radius_m": 5000.0, "wiki_title": "Kallio Church", "height_m": 67.8, "clear_m": 42.0,
	"yaw_deg": -3.0, "kind": "Church", "aliases": ["kallio church", "kallion kirkko", "kallio kyrka"]}


## Lars Sonck's church on the Kallio hill (1912), grey Uusikaupunki
## granite over brick, origin at the OSM footprint centre, entrance and
## tower south (+Z), parts after the OSM 3D outline: the tall 16 m nave
## (eaves 22.5 m, ridge 30.8 m) between lower aisles, the polygonal
## chancel, the 49 m wide transverse front block, the half-round porch
## under its copper half-dome (30 m) at the foot of the tower, and the
## 65 m tower: buttressed shaft, the tall belfry slits of the seven bells,
## the corner pinnacles and the steep copper spire with its cross.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8F8D", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#5E605F", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9D89", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	# Nave and its steep copper roof.
	FhU.blk(lm, "Granite", -0.5, 0.0, -2.4, 16.2, 22.5, 34.0)
	FhU.ridge_z(lm, "Copper", "Granite", Vector3(-0.5, 22.5, -2.4), 16.2, 34.0, 8.3, 0.5)
	FhP.box_band(lm, "Dark", -0.5, -2.4, 16.2, 34.0, 21.8, 0.7, 0.3)
	# Aisles under lean-to roofs, tall windows in each bay.
	for s in [-1.0, 1.0]:
		var ax: float = -0.5 + s * 11.1
		FhU.blk(lm, "Granite", ax, 0.0, -1.7, 6.0, 11.0, 27.4)
		lm.quad("Copper", Vector3(ax + s * 3.3, 11.0, -15.6), Vector3(ax + s * 3.3, 11.0, 12.2),
			Vector3(ax - s * 3.0, 14.5, 12.2), Vector3(ax - s * 3.0, 14.5, -15.6), Vector3(s * 0.5, 1.0, 0).normalized())
		var wx: float = -0.5 + s * 14.1
		FhP.win_row(lm, "Dark", "Glass", Vector3(wx, 0, -14.0), Vector3(wx, 0, 10.0), Vector3(s, 0, 0), 2.5, 6, 1.4,
			6.0, true, 0.3)
		FhP.strips(lm, "Granite", Vector3(wx, 0, -15.4), Vector3(wx, 0, 12.0), Vector3(s, 0, 0), 0.0, 10.0, 7, 0.9,
			0.6)
		# Clerestory: tall round-headed windows high in the nave walls.
		FhP.win_row(lm, "Dark", "Glass", Vector3(-0.5 + s * 8.1, 0, -14.0), Vector3(-0.5 + s * 8.1, 0, 10.0),
			Vector3(s, 0, 0), 15.0, 6, 1.6, 5.4, true, 0.3)
	# Chancel: polygonal apse at the north end.
	var ch := Vector3(-0.4, 0.0, -19.4)
	FhU.blk(lm, "Granite", -0.4, 0.0, -20.3, 10.8, 17.0, 1.8)
	lm.frustum("Granite", ch, 5.6, 5.6, 17.0, 8, PI / 8.0)
	lm.lathe("Copper", ch + Vector3(0, 17.0, 0), PackedVector2Array([Vector2(6.2, 0), Vector2(0.4, 5.0)]), 8, 1.0,
		1.0, PI / 8.0, false)
	for k in 3:
		var a := PI * (1.25 + 0.25 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Dark", "Glass", ch + d * 5.2 + Vector3(0, 8.0, 0), d, 1.3, 6.0, true, 0.3)
	# Transverse front block with its gabled ends and windows.
	FhU.blk(lm, "Granite", -0.25, 0.0, 18.5, 48.9, 18.0, 12.8)
	FhU.ridge_x(lm, "Copper", "Granite", Vector3(-0.25, 18.0, 18.5), 48.9, 12.8, 7.0, 0.5)
	for s in [-1.0, 1.0]:
		var ex: float = -0.25 + s * 24.45
		var o := Vector3(s, 0, 0)
		FhP.win_row(lm, "Dark", "Glass", Vector3(ex, 0, 14.0), Vector3(ex, 0, 23.0), o, 3.0, 2, 1.8, 9.0, true, 0.3)
		LandmarkDetail.window(lm, "Dark", "Glass", Vector3(ex, 21.0, 18.5) + o * 0.02, o, 1.2, 2.6, true)
		FhP.win_row(lm, "Dark", "Glass", Vector3(-0.25 + s * 8.0, 0, 24.9), Vector3(-0.25 + s * 22.0, 0, 24.9),
			Vector3(0, 0, 1), 3.0, 3, 1.6, 8.0, true, 0.3)
		for z in [12.4, 24.6]:
			lm.box("Granite", Vector3(ex - s * 0.3, 9.0, z), Vector3(1.6, 18.0, 1.4))
	# Half-round porch at the foot of the tower, copper half-dome.
	var pc := Vector3(-0.05, 0.0, 26.6)
	lm.frustum("Granite", pc, 5.75, 5.75, 22.0, 16)
	lm.frustum("Dark", pc + Vector3(0, 21.4, 0), 6.05, 6.05, 0.6, 16)
	lm.lathe("Copper", pc + Vector3(0, 22.0, 0), FhU.dome_prof(6.0, 8.0, 10), 16)
	LandmarkDetail.arch(lm, "Dark", pc + Vector3(0, 6.0, 5.75), Vector3(0, 0, 1), 4.0, 0.7, 0.5)
	lm.quad("Glass", pc + Vector3(-2.0, 0.0, 5.8), pc + Vector3(2.0, 0.0, 5.8), pc + Vector3(2.0, 6.0, 5.8),
		pc + Vector3(-2.0, 6.0, 5.8), Vector3(0, 0, 1))
	FhU.steps(lm, "Dark", pc + Vector3(0, 0, 5.7), Vector3(0, 0, 1), 7.0, 0.45, 0.17, 4)
	for k in 5:
		var a := PI * (0.15 + 0.175 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		if k != 2:
			LandmarkDetail.window(lm, "Dark", "Glass", pc + d * 5.76 + Vector3(0, 13.0, 0), d, 1.0, 4.6, true, 0.25)
	# The tower: buttressed granite shaft, bands, belfry slits, pinnacles,
	# copper spire and cross (65 m).
	var tc := Vector3(-0.1, 0.0, 19.7)
	FhU.blk(lm, "Granite", tc.x, 0.0, tc.z, 12.1, 54.0, 10.6)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Granite", Vector3(tc.x + sx * 5.6, 26.0, tc.z + sz * 4.85), Vector3(1.6, 52.0, 1.6))
	for y in [22.0, 36.0]:
		FhP.box_band(lm, "Dark", tc.x, tc.z, 12.1, 10.6, y, 0.6, 0.25)
	for face in FhP.faces(tc.x, tc.z, 12.1, 10.6):
		var fa: Vector3 = face[0]
		var fb: Vector3 = face[1]
		var fo: Vector3 = face[2]
		var m := (fa + fb) * 0.5
		var r := fa.direction_to(fb)
		if fo.z > -0.5:
			for k in 3:
				LandmarkDetail.window(lm, "Dark", "Glass", m + r * (float(k) - 1.0) * 2.4 + Vector3(0, 45.0, 0) + fo * 0.02,
					fo, 1.1, 12.0, true, 0.35)
			LandmarkDetail.window(lm, "Dark", "Glass", m + Vector3(0, 30.0, 0) + fo * 0.02, fo, 1.2, 5.0, true, 0.3)
		FhP.arch_frieze(lm, "Dark", fa + r * 0.8, fb - r * 0.8, fo, 53.4, 1.0, 0.25)
	FhU.blk(lm, "Dark", tc.x, 53.6, tc.z, 12.9, 0.8, 11.4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var pp := Vector3(tc.x + sx * 5.6, 54.4, tc.z + sz * 4.85)
			lm.frustum("Granite", pp, 0.85, 0.7, 1.4, 8)
			lm.spire("Granite", pp + Vector3(0, 1.4, 0), 0.7, 0.9, 0.0, 8)
	# Crown as photographed: a smaller stone stage with slit windows, a low
	# green copper dome and the cross (the real tower has no tall spire).
	FhU.blk(lm, "Granite", tc.x, 54.4, tc.z, 9.0, 5.6, 7.8)
	FhP.box_band(lm, "Dark", tc.x, tc.z, 9.0, 7.8, 59.4, 0.5, 0.25)
	for face in FhP.faces(tc.x, tc.z, 9.0, 7.8):
		var fa: Vector3 = face[0]
		var fb: Vector3 = face[1]
		var fo: Vector3 = face[2]
		var m := (fa + fb) * 0.5
		var r := fa.direction_to(fb)
		for k in 3:
			LandmarkDetail.window(lm, "Dark", "Glass", m + r * (float(k) - 1.0) * 2.0 + Vector3(0, 55.8, 0) + fo * 0.02, fo,
				0.7, 2.6, false, 0.2)
	lm.lathe("Copper", Vector3(tc.x, 60.0, tc.z), FhU.dome_prof(3.9, 3.0, 10), 16)
	FhP.latin_cross(lm, "Dark", Vector3(tc.x, 63.0, tc.z), 4.8, Vector3(0, 0, 1))
	lm.commit(model)

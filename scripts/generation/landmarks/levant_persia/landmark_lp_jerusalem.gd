class_name LandmarkLpJerusalem
extends RefCounted

## Two Old City landmarks of Jerusalem in true metres, built in compass
## frame (+X east, -Z north): the Church of the Holy Sepulchre and the
## Al-Aqsa Mosque on the Haram al-Sharif.

# --- Church of the Holy Sepulchre ---

## Crusader church seen from the parvis (south, +Z): the Romanesque
## transept facade with its double portal (three orders of marble
## colonnettes, archivolts, the east door walled up since 1187), the two
## arched windows above, string course and corbel-table cornice; the
## Chapel of the Franks on its outside stair; the truncated belfry at the
## west with paired arched openings on two stages; the Rotunda of the
## Anastasis (35 m across) with its windowed upper drum, ribbed lead dome
## and oculus lantern (35 m); the Catholicon's windowed drum and ribbed
## dome; the transept and nave roofs, the buttressed east apse, the dome
## of St Helena's chapel and the chapels lining the parvis.
static func holy_sepulchre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DCCBA6", 3.5))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#8A949C", 4.0))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#CFC1A0", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#26201A", 3.0, 0.92))
	lm.box("Court", Vector3(5, 0.1, 18), Vector3(52, 0.2, 32), Basis(), 0.0)
	_rotunda(lm, Vector3(-24, 0, -12))
	# Transept and nave block: buttresses, clerestory windows, gabled roof.
	lm.box("Stone", Vector3(12.5, 10.0, -13), Vector3(39, 20.0, 30))
	lm.gable("Lead", Vector3(12.5, 20.0, -13), 26.0, 38.0, 3.2, Basis(Vector3.UP, PI * 0.5), 0.2, "Stone")
	for i in 6:
		var x := -4.0 + 6.4 * float(i)
		lm.box("Stone", Vector3(x, 8.0, -28.6), Vector3(1.6, 16.0, 1.4))
		if i < 5:
			LandmarkLpParts.arch_panel(lm, "Dark", Vector3(x + 3.2, 12.0, -28.02), PI, 0.9, 2.4, 0.9)
	var cc := Vector3(14, 0, -12)
	_drum(lm, cc + Vector3(0, 20.0, 0), 7.0, 5.0, 12, 0.6)
	LandmarkLpParts.ribbed_dome(lm, "Lead", cc + Vector3(0, 25.0, 0),
		LandmarkLpParts.dome_profile(7.3, 6.4, 8, 0.3), 12, 0.04)
	lm.frustum("Stone", cc + Vector3(0, 31.2, 0), 1.2, 1.0, 1.6, 8)
	lm.spire("Lead", cc + Vector3(0, 32.8, 0), 1.1, 1.6, 0.0, 8)
	# East apse with buttresses and a conical lead roof; St Helena's dome.
	var ap := Vector3(32, 0, -13)
	lm.frustum("Stone", ap, 9.0, 9.0, 15.0, 8, PI / 8.0)
	for k in 5:
		var a := -PI * 0.5 + PI * float(k) / 4.0
		lm.box("Stone", ap + Vector3(cos(a) * 9.0, 6.5, sin(a) * 9.0), Vector3(1.4, 13.0, 1.6), Basis(Vector3.UP, -a))
	lm.lathe("Lead", ap + Vector3(0, 15.0, 0), PackedVector2Array([Vector2(9.4, 0), Vector2(6.0, 2.4),
		Vector2(0.2, 5.0)]), 8, 1.0, 1.0, PI / 8.0)
	var hc := Vector3(30, 0, 4.0)
	lm.box("Stone", hc + Vector3(0, 4.0, 0), Vector3(12, 8.0, 10))
	_drum(lm, hc + Vector3(0, 8.0, 0), 3.2, 3.0, 8, 0.4)
	lm.lathe("Lead", hc + Vector3(0, 11.0, 0), LandmarkLpParts.dome_profile(3.3, 3.0, 6, 0.1), 16)
	_facade(lm)
	_belfry(lm, Vector3(-11.0, 0, -2.0))
	# Chapels along the west and east sides of the parvis.
	for s in [-1.0, 1.0]:
		var x := 6.0 + float(s) * 17.0
		lm.box("Stone", Vector3(x, 4.5, 18.0), Vector3(6.0, 9.0, 26.0))
		lm.box("Stone", Vector3(x, 9.2, 18.0), Vector3(6.6, 0.4, 26.6))
		for k in 3:
			var z := 9.0 + 9.0 * float(k)
			LandmarkLpParts.arch_panel(lm, "Dark", Vector3(x - float(s) * 3.02, 0.2, z), -float(s) * PI * 0.5, 1.0,
				2.4, 1.0)
			lm.lathe("Lead", Vector3(x, 9.4, z), LandmarkLpParts.dome_profile(2.2, 1.9, 5), 12)
	lm.commit(model)

## Windowed drum: wall, `n` round-arched windows, base and cornice rings.
static func _drum(lm: LandmarkMesh, base: Vector3, r: float, h: float, n: int, win: float) -> void:
	lm.frustum("Stone", base, r, r, h, 24)
	lm.frustum("Stone", base, r + 0.25, r + 0.2, 0.5, 24)
	lm.frustum("Stone", base + Vector3(0, h - 0.4, 0), r + 0.15, r + 0.35, 0.4, 24)
	for k in n:
		var a := TAU * (float(k) + 0.5) / float(n)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkLpParts.arch_panel(lm, "Dark", base + d * (r + 0.02) + Vector3(0, h * 0.3, 0), PI * 0.5 - a,
			win, h * 0.35, win)

## Rotunda of the Anastasis: buttressed lower drum, windowed upper drum,
## ribbed lead dome, the open oculus ring and its lantern.
static func _rotunda(lm: LandmarkMesh, rc: Vector3) -> void:
	lm.frustum("Stone", rc, 17.5, 17.1, 21.0, 32)
	lm.frustum("Stone", rc + Vector3(0, 0.0, 0), 17.9, 17.8, 1.2, 32)
	lm.frustum("Stone", rc + Vector3(0, 20.4, 0), 17.4, 17.6, 0.6, 32)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.box("Stone", rc + Vector3(cos(a) * 17.4, 10.0, sin(a) * 17.4), Vector3(1.2, 20.0, 1.4),
			Basis(Vector3.UP, -a))
	_drum(lm, rc + Vector3(0, 21.0, 0), 15.2, 5.0, 16, 0.7)
	LandmarkLpParts.ribbed_dome(lm, "Lead", rc + Vector3(0, 26.0, 0),
		LandmarkLpParts.dome_profile(15.0, 6.4, 8, 0.35), 16, 0.03)
	lm.frustum("Stone", rc + Vector3(0, 31.8, 0), 2.4, 2.1, 2.2, 16)
	for k in 12:
		var a := TAU * float(k) / 12.0
		lm.box("Stone", rc + Vector3(cos(a) * 2.2, 32.9, sin(a) * 2.2), Vector3(0.25, 2.2, 0.5), Basis(Vector3.UP, -a), 0.0)
	lm.lathe("Lead", rc + Vector3(0, 34.0, 0), PackedVector2Array([Vector2(2.4, 0), Vector2(1.2, 0.5),
		Vector2(0.15, 1.0)]), 16)

## South transept facade (centre x = 6, face z = 3): two portals and two
## windows each with three orders of colonnettes and archivolts, the walled
## east door, string course, corbel-table cornice and the Chapel of the
## Franks with its stair at the east end.
static func _facade(lm: LandmarkMesh) -> void:
	var fz := 3.0
	var arches := [[-3.4, 2.0, 3.6, 2.0], [3.4, 2.0, 3.6, 2.0]]
	LandmarkLpParts.slab(lm, "Stone", LandmarkLpParts.arcade_outline(22.0, 17.0, arches), Vector3(6, 0.2, fz),
		0.0, 4.0)
	LandmarkLpParts.arch_panel(lm, "Dark", Vector3(2.6, 0.2, fz - 3.7), 0.0, 2.0, 3.6, 2.0)
	LandmarkLpParts.arch_panel(lm, "Stone", Vector3(9.4, 0.2, fz - 0.5), 0.0, 2.0, 3.6, 2.0)
	for d in [[2.6, 0.2, 2.0, 3.6], [9.4, 0.2, 2.0, 3.6], [2.2, 8.2, 1.4, 2.6], [9.8, 8.2, 1.4, 2.6]]:
		var x: float = d[0]
		var y: float = d[1]
		var a: float = d[2]
		var sp: float = d[3]
		if y > 1.0:
			LandmarkLpParts.arch_panel(lm, "Dark", Vector3(x, y, fz + 0.02), 0.0, a, sp, a)
		# Three orders of colonnettes stepping out, each under its archivolt.
		for k in 3:
			var off := a + 0.3 + 0.45 * float(k)
			var zc := fz + 0.25 + 0.35 * float(k)
			for s in [-1.0, 1.0]:
				LandmarkDetail.column(lm, "Stone", Vector3(x + float(s) * off, y, zc), 0.16, sp, "corinthian", 0)
			LandmarkDetail.arch(lm, "Stone", Vector3(x, y + sp, zc - 0.2), Vector3(0, 0, 1), off * 2.0, 0.34, 0.4)
		lm.box("Stone", Vector3(x, y + sp + 0.1, fz + 0.5), Vector3(a * 2.0 + 3.2, 0.2, 1.0))
	# String course, corbel table, cornice; corner pilasters.
	lm.box("Stone", Vector3(6, 7.8, fz + 0.4), Vector3(22.8, 0.6, 1.2))
	for i in 28:
		lm.box("Stone", Vector3(-4.5 + 21.0 * float(i) / 27.0, 16.2, fz + 0.25), Vector3(0.3, 0.5, 0.5), Basis(), 0.0)
	lm.box("Stone", Vector3(6, 16.75, fz + 0.4), Vector3(23.0, 0.6, 1.8))
	lm.box("Stone", Vector3(6, 17.25, fz + 0.2), Vector3(22.4, 0.5, 1.2))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(6.0 + float(s) * 10.4, 8.5, fz + 0.2), Vector3(1.2, 17.0, 1.2))
	# Chapel of the Franks: outside stair and the small domed chapel.
	LandmarkLpParts.steps(lm, "Stone", Vector3(17.2, 0.2, 16.0), Vector3(0, 0, -1), 3.2, 9.0, 5.0, 14)
	var fc := Vector3(19.0, 5.2, 0.5)
	lm.box("Stone", fc + Vector3(0, -2.5, 0), Vector3(5.0, 5.0, 5.0))
	lm.box("Stone", fc + Vector3(0, 2.0, 0), Vector3(5.0, 4.0, 5.0))
	LandmarkLpParts.arch_panel(lm, "Dark", fc + Vector3(0, 0, 2.52), 0.0, 0.9, 1.8, 0.9)
	lm.frustum("Stone", fc + Vector3(0, 4.0, 0), 1.9, 1.9, 1.0, 12)
	lm.lathe("Lead", fc + Vector3(0, 5.0, 0), LandmarkLpParts.dome_profile(2.0, 1.8, 5), 12)

## Belfry (now 26 m, its top stages lost): two stages each with paired
## arched openings on a central colonnette, corner pilasters, cornices.
static func _belfry(lm: LandmarkMesh, bt: Vector3) -> void:
	lm.box("Stone", bt + Vector3(0, 10.0, 0), Vector3(8.0, 20.0, 8.0))
	lm.box("Stone", bt + Vector3(0, 20.4, 0), Vector3(9.0, 0.8, 9.0))
	lm.box("Stone", bt + Vector3(0, 23.2, 0), Vector3(7.2, 4.8, 7.2))
	lm.box("Stone", bt + Vector3(0, 25.9, 0), Vector3(8.0, 0.6, 8.0))
	lm.box("Stone", bt + Vector3(0, 26.3, 0), Vector3(7.4, 0.2, 7.4))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Stone", bt + Vector3(float(sx) * 3.75, 10.0, float(sz) * 3.75), Vector3(1.0, 20.0, 1.0))
	lm.box("Stone", bt + Vector3(0, 11.8, 0), Vector3(8.6, 0.5, 8.6))
	for k in 4:
		var yaw := PI * 0.5 * float(k)
		var d := LandmarkLpParts.outward(yaw)
		var r := LandmarkLpParts.across(yaw)
		for st in [[4.04, 14.6, 0.7, 2.6], [3.64, 21.2, 0.55, 2.0]]:
			var off: float = st[0]
			var y: float = st[1]
			var a: float = st[2]
			var sp: float = st[3]
			for s in [-1.0, 1.0]:
				LandmarkLpParts.arch_panel(lm, "Dark", bt + d * off + r * (float(s) * (a + 0.2)) + Vector3(0, y, 0),
					yaw, a, sp, a)
			LandmarkDetail.column(lm, "Stone", bt + d * (off + 0.15) + Vector3(0, y, 0), 0.14, sp, "corinthian", 0)
			LandmarkDetail.arch(lm, "Stone", bt + d * off + Vector3(0, y + sp, 0), d, a * 4.0 + 0.6, 0.3, 0.2)
		LandmarkLpParts.arch_panel(lm, "Dark", bt + d * 4.04 + Vector3(0, 5.0, 0), yaw, 0.5, 1.4, 0.5)

# --- Al-Aqsa Mosque ---

## 83 x 56 m seven-aisled hall in compass frame: the Ayyubid porch of seven
## pointed arches (the central one higher) with its crenellated parapet on
## the north (-Z) front and the nave gable behind it; the high central
## nave with its gabled lead roof and arched clerestory, lower aisle roofs
## with buttresses and windows, the transept before the qibla wall and the
## ribbed lead dome on its windowed drum (about 35 m); the Fakhriyya
## minaret (1278, 23 m) towards the south-west corner of the Haram: a
## square three-storey shaft with a muqarnas balcony, the square upper
## chamber and its lead-covered dome.
static func al_aqsa(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E4DAC4", 4.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#99A3AA", 5.0, 0.4))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#D5CBB3", 6.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#262019", 3.0, 0.92))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Court", Vector3(-10, 0.1, -3), Vector3(116, 0.2, 100), Basis(), 0.0)
	lm.box("Stone", Vector3(0, 8.0, 0), Vector3(56, 16.0, 83))
	lm.box("Stone", Vector3(0, 16.2, 0), Vector3(56.6, 0.4, 83.6))
	for s in [-1.0, 1.0]:
		lm.box("Lead", Vector3(float(s) * 17.5, 16.5, 0), Vector3(21.0, 0.3, 82.0))
		# Aisle-wall buttresses and windows on the long sides.
		for i in 11:
			var z := -37.0 + 7.4 * float(i)
			lm.box("Stone", Vector3(float(s) * 28.4, 7.0, z), Vector3(0.8, 14.0, 1.4))
			if i < 10:
				var yaw := float(s) * PI * 0.5
				LandmarkLpParts.arch_panel(lm, "Dark", Vector3(float(s) * 28.02, 4.0, z + 3.7), yaw, 0.7, 2.2, 1.0)
				LandmarkLpParts.arch_panel(lm, "Dark", Vector3(float(s) * 28.02, 10.0, z + 3.7), yaw, 0.6, 1.6, 0.9)
	# Nave: clerestory, gabled lead roof.
	lm.box("Stone", Vector3(0, 10.5, 0), Vector3(14.0, 21.0, 83))
	lm.gable("Lead", Vector3(0, 21.0, 0), 14.0, 83.0, 3.6, Basis(), 0.3, "Stone")
	for s in [-1.0, 1.0]:
		for i in 9:
			var z := -36.0 + 6.4 * float(i)
			LandmarkLpParts.arch_panel(lm, "Dark", Vector3(float(s) * 7.02, 17.0, z), float(s) * PI * 0.5, 0.7, 1.8, 1.0)
	# Transept in front of the mihrab and the dome on its windowed drum.
	lm.box("Stone", Vector3(0, 10.5, 24.0), Vector3(56, 21.0, 16.0))
	lm.gable("Lead", Vector3(0, 21.0, 24.0), 16.0, 56.0, 3.2, Basis(Vector3.UP, PI * 0.5), 0.3, "Stone")
	var dc := Vector3(0, 0, 24.0)
	lm.box("Stone", dc + Vector3(0, 21.5, 0), Vector3(17.0, 3.0, 17.0))
	lm.frustum("Stone", dc + Vector3(0, 18.0, 0), 7.6, 7.6, 7.0, 32)
	lm.frustum("Stone", dc + Vector3(0, 24.4, 0), 7.8, 7.9, 0.6, 32)
	for k in 16:
		var a := TAU * (float(k) + 0.5) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkLpParts.arch_panel(lm, "Dark", dc + d * 7.62 + Vector3(0, 21.6, 0), PI * 0.5 - a, 0.55, 1.4, 0.75)
	LandmarkLpParts.ribbed_dome(lm, "Lead", dc + Vector3(0, 25.0, 0), LandmarkLpParts.dome_profile(8.0, 7.2, 8, 0.15),
		24, 0.02)
	LandmarkLpParts.needle(lm, "Gold", dc + Vector3(0, 32.2, 0),
		PackedVector2Array([Vector2(0, 0.35), Vector2(0.8, 0.12), Vector2(1.1, 0.3), Vector2(1.5, 0.08),
			Vector2(2.6, 0.06)]))
	# North porch: seven pointed arches on piers, archivolts, crenellated parapet.
	var arches: Array = []
	for i in 7:
		var cx := -17.7 + 5.9 * float(i)
		arches.append([cx, 2.0 if i != 3 else 2.4, 4.6 if i != 3 else 5.0, 2.9 if i != 3 else 3.4])
	var pz := -41.5 - 4.0
	LandmarkLpParts.slab(lm, "Stone", LandmarkLpParts.arcade_outline(42.0, 10.4, arches, 8),
		Vector3(0, 0.2, pz), PI, 4.0)
	lm.box("Dark", Vector3(0, 5.0, -41.55), Vector3(41.0, 10.0, 0.1), Basis(), 0.0)
	for ar in arches:
		LandmarkLpDetail.arch_band(lm, "Stone", Vector3(-float(ar[0]), 0.2, pz), PI, float(ar[1]), float(ar[2]),
			float(ar[3]), 0.35, 0.15)
	lm.box("Stone", Vector3(0, 10.4, pz - 0.15), Vector3(42.4, 0.4, 0.5))
	LandmarkLpParts.merlons(lm, "Stone", Vector3(-21.0, 10.6, pz + 0.3), Vector3(21.0, 10.6, pz + 0.3), 0.8, 1.0, 0.6, 1.6)
	# Nave front above the porch: gable end with a triple window.
	for s in [-1.0, 0.0, 1.0]:
		LandmarkLpParts.arch_panel(lm, "Dark", Vector3(float(s) * 2.6, 13.0, -41.52), PI, 0.9 if s == 0.0 else 0.7,
			3.0, 1.2)
	_fakhriyya(lm, Vector3(-62.0, 0, 36.0))
	lm.commit(model)

## The Fakhriyya minaret, 23 m: square shaft of three storeys divided by
## mouldings, blind arcades, a two-tier muqarnas balcony, the narrower
## square chamber and the lead-covered dome on a drum.
static func _fakhriyya(lm: LandmarkMesh, mp: Vector3) -> void:
	lm.box("Stone", mp + Vector3(0, 7.5, 0), Vector3(5.0, 15.0, 5.0))
	for y in [5.0, 10.0]:
		lm.box("Stone", mp + Vector3(0, float(y), 0), Vector3(5.4, 0.35, 5.4))
	for k in 4:
		var yaw := PI * 0.5 * float(k)
		var d := LandmarkLpParts.outward(yaw)
		LandmarkLpParts.arch_panel(lm, "Dark", mp + d * 2.52 + Vector3(0, 6.2, 0), yaw, 0.4, 2.0, 0.5)
		LandmarkLpParts.arch_panel(lm, "Dark", mp + d * 2.52 + Vector3(0, 11.4, 0), yaw, 0.45, 2.0, 0.55)
	# Muqarnas balcony: two corbel tiers, floor, pierced parapet.
	lm.box("Stone", mp + Vector3(0, 15.25, 0), Vector3(5.6, 0.5, 5.6))
	lm.box("Stone", mp + Vector3(0, 15.75, 0), Vector3(6.3, 0.5, 6.3))
	lm.box("Stone", mp + Vector3(0, 16.1, 0), Vector3(7.0, 0.2, 7.0))
	for k in 4:
		var yaw := PI * 0.5 * float(k)
		var d := LandmarkLpParts.outward(yaw)
		var r := LandmarkLpParts.across(yaw)
		for i in 7:
			lm.box("Stone", mp + d * 3.4 + r * (-3.0 + float(i)) + Vector3(0, 16.6, 0), Vector3(0.18, 0.8, 0.18),
				Basis(), 0.0)
		lm.box("Stone", mp + d * 3.4 + Vector3(0, 17.05, 0), Vector3(absf(r.x) * 7.0 + 0.2, 0.12, absf(r.z) * 7.0 + 0.2),
			Basis(), 0.0)
	# Upper chamber with arched openings, drum and lead dome.
	lm.box("Stone", mp + Vector3(0, 18.0, 0), Vector3(3.6, 3.8, 3.6))
	for k in 4:
		var yaw := PI * 0.5 * float(k)
		LandmarkLpParts.arch_panel(lm, "Dark", mp + LandmarkLpParts.outward(yaw) * 1.82 + Vector3(0, 16.6, 0), yaw,
			0.5, 1.4, 0.5)
	lm.box("Stone", mp + Vector3(0, 20.0, 0), Vector3(4.0, 0.3, 4.0))
	lm.frustum("Stone", mp + Vector3(0, 20.1, 0), 1.6, 1.6, 0.6, 16)
	lm.lathe("Lead", mp + Vector3(0, 20.7, 0), LandmarkLpParts.dome_profile(1.7, 1.6, 6, 0.1), 16)
	LandmarkLpParts.needle(lm, "Gold", mp + Vector3(0, 22.3, 0),
		PackedVector2Array([Vector2(0, 0.08), Vector2(0.7, 0.04)]), 6)

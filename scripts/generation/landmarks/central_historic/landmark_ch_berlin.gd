class_name LandmarkChBerlin
extends RefCounted

## Berlin Cathedral (Julius Raschdorff, 1894-1905) as rebuilt after
## the war (1975-93), in true metres: the dome and the four tower tops
## were simplified and lowered by 16 m, so the cross now stands at 98 m
## (114-116 m before 1944) and the building is 90 m long since the
## memorial church on the north side was demolished in 1975. The main
## front faces the Lustgarten (west, +Z here; yaw 90 in the registry):
## the great portal arch between paired giant Corinthian columns, the
## two west corner towers, the copper dome of 33 m diameter on its
## colonnaded drum; the baptism and wedding church to the south (+X).

const BERLIN_TOP := 98.0
const HW := 31.0
const EAVE := 38.0

static func berlin(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B9AE96", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#8C8574", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6A9482", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	_block(lm)
	_front(lm)
	_south_church(lm)
	_dome(lm)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_corner_tower(lm, Vector3(sx * 25.5, 0, sz * 25.5))
	lm.commit(model)

## The central preaching church block: rusticated base, giant pilasters,
## two orders of arched windows, the main cornice and the balustrade
## with statues; the east apse under a copper half dome.
static func _block(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(0, EAVE * 0.5, 0), Vector3(HW * 2.0, EAVE, HW * 2.0))
	LandmarkCeParts.hip(lm, "Copper", Vector3(0, EAVE + 2.0, 0), HW * 2.0, HW * 2.0, 6.0)
	LandmarkChParts.band(lm, "Dark", 0.0, HW, HW, 1.4, 0.4)
	LandmarkChParts.band(lm, "Dark", 9.0, HW, HW, 0.8, 0.3)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		LandmarkDetail.cornice(lm, "Stone", b * Vector3(-HW, EAVE - 1.6, HW), b * Vector3(HW, EAVE - 1.6, HW), n, 1.6)
		LandmarkChParts.roof_balustrade(lm, "Stone", b * Vector3(-HW + 6.0, EAVE, HW + 0.3), b * Vector3(HW - 6.0, EAVE, HW + 0.3),
			1.6, 4.0)
		if f == 0:
			continue
		for i in 5:
			var x := -12.0 + 6.0 * i
			lm.box("Stone", b * Vector3(x - 3.0, 23.0, HW + 0.4), Vector3(1.6, 27.0, 0.8), b)
			LandmarkChParts.arched_window(lm, "Dark", "Windows", b * Vector3(x, 2.4, HW), n, 2.6, 5.4, 0.3)
			LandmarkChParts.arched_window(lm, "Dark", "Windows", b * Vector3(x, 12.0, HW), n, 3.2, 10.0, 0.3)
			LandmarkChParts.arched_window(lm, "Dark", "Windows", b * Vector3(x, 26.0, HW), n, 2.8, 7.0, 0.3)
			LandmarkDetail.cornice(lm, "Stone", b * Vector3(x - 2.0, 33.6, HW), b * Vector3(x + 2.0, 33.6, HW), n, 0.5, false)
		lm.box("Stone", b * Vector3(12.0 + 3.0, 23.0, HW + 0.4), Vector3(1.6, 27.0, 0.8), b)
		for i in 4:
			LandmarkKits.statue_figure(lm, "Stone", b * Vector3(-9.0 + 6.0 * i, EAVE + 1.6, HW + 0.3), 2.8, i % 2 == 0)
	# East apse.
	var ac := Vector3(0, 0, -HW)
	lm.lathe("Stone", ac, PackedVector2Array([Vector2(11.0, 0), Vector2(11.0, 28.0)]), 24, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Copper", ac + Vector3(0, 28.0, 0), PackedVector2Array([Vector2(11.6, 0), Vector2(10.6, 4.0),
		Vector2(7.8, 8.0), Vector2(4.0, 10.6), Vector2(0.0, 11.4)]), 24)
	lm.frustum("Dark", ac + Vector3(0, 27.0, 0), 11.6, 11.6, 1.2, 24)
	for k in 5:
		var a := -PI * 0.5 - PI * 0.35 + PI * 0.175 * k
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.arched_window(lm, "Dark", "Windows", ac + d * 10.95 + Vector3(0, 10.0, 0), d, 2.6, 9.0, 0.3)

## West front to the Lustgarten: the portal block between the towers,
## the great arched entrance niche with its tympanum and doors, eight
## giant Corinthian columns in pairs on pedestals, entablature, attic
## with the central gable and statues.
static func _front(lm: LandmarkMesh) -> void:
	var z := HW
	lm.box("Stone", Vector3(0, 17.0, z + 2.5), Vector3(38.0, 34.0, 5.0))
	# Entrance niche and its archivolt.
	lm.box("Dark", Vector3(0, 11.0, z + 4.4), Vector3(13.0, 22.0, 1.4))
	lm.box("Windows", Vector3(0, 4.5, z + 5.12), Vector3(6.0, 9.0, 0.05), Basis(), 0.0)
	LandmarkChParts.arched_window(lm, "Stone", "Windows", Vector3(0, 10.5, z + 5.1), Vector3.BACK, 6.0, 8.0, 0.3)
	LandmarkChParts.arch_band(lm, "Stone", Vector3(0, 15.5, z + 5.0), Vector3.BACK, 13.0, 1.4, 0.8, 12)
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * 7.4, 8.0, z + 5.4), Vector3(1.8, 16.0, 0.8))
	# Giant order: pedestals, paired fluted Corinthian columns.
	for sx in [-1.0, 1.0]:
		for dx in [9.5, 12.0, 16.0, 18.5]:
			var x: float = sx * dx
			lm.box("Dark", Vector3(x, 2.5, z + 6.6), Vector3(2.6, 5.0, 2.6))
			LandmarkDetail.column(lm, "Stone", Vector3(x, 5.0, z + 6.6), 0.95, 21.0, "corinthian", 0)
	lm.box("Stone", Vector3(0, 27.0, z + 6.2), Vector3(41.0, 2.0, 3.4))
	lm.box("Stone", Vector3(0, 28.8, z + 6.0), Vector3(41.0, 1.6, 3.0))
	LandmarkDetail.cornice(lm, "Stone", Vector3(-20.5, 29.6, z + 7.5), Vector3(20.5, 29.6, z + 7.5), Vector3.BACK, 1.4)
	# Attic: panels, the central gable with relief field, statues.
	lm.box("Stone", Vector3(0, 33.0, z + 5.2), Vector3(38.0, 5.0, 2.0))
	lm.gable("Stone", Vector3(0, 35.5, z + 5.2), 16.0, 2.0, 5.0, Basis(), 0.4, "Stone")
	lm.box("Dark", Vector3(0, 32.8, z + 6.25), Vector3(12.0, 3.6, 0.1), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		for dx in [10.75, 17.25]:
			var x: float = sx * dx
			lm.box("Stone", Vector3(x, 30.8, z + 6.4), Vector3(1.6, 1.0, 1.6))
			LandmarkKits.statue_figure(lm, "Stone", Vector3(x, 31.3, z + 6.4), 3.2, sx > 0.0)
	LandmarkKits.statue_figure(lm, "Stone", Vector3(0, 41.0, z + 5.6), 3.6, true)
	lm.box("Stone", Vector3(0, 40.7, z + 5.6), Vector3(1.8, 0.6, 1.8))

## Baptism and wedding church on the south side: lower wing with arched
## windows, cornice, balustrade and a small copper dome.
static func _south_church(lm: LandmarkMesh) -> void:
	var c := Vector3(HW + 13.0, 0, 0)
	lm.box("Stone", c + Vector3(0, 13.0, 0), Vector3(26.0, 26.0, 44.0))
	LandmarkChParts.band(lm, "Dark", 0.0, 13.0, 22.0, 1.4, 0.4, c)
	for f in [0, 1, 2]:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		var hw := 22.0 if f % 2 == 0 else 13.0
		var face := c + b * Vector3(0, 0, hw)
		LandmarkDetail.cornice(lm, "Stone", face + b * Vector3(-hw, 24.8, 0), face + b * Vector3(hw, 24.8, 0), n, 1.2)
		LandmarkChParts.roof_balustrade(lm, "Stone", face + b * Vector3(-hw + 1.0, 26.0, 0.3), face + b * Vector3(hw - 1.0, 26.0, 0.3),
			1.3, 4.0)
		var cnt := int(hw * 2.0 / 7.0)
		for i in cnt:
			var x := hw * 2.0 * (float(i) + 0.5) / float(cnt) - hw
			LandmarkChParts.arched_window(lm, "Dark", "Windows", face + b * Vector3(x, 4.0, 0), n, 2.4, 6.0, 0.3)
			LandmarkChParts.arched_window(lm, "Dark", "Windows", face + b * Vector3(x, 14.0, 0), n, 2.4, 7.0, 0.3)
			lm.box("Stone", face + b * Vector3(x + hw / float(cnt), 13.0, 0.3), Vector3(1.2, 24.0, 0.6), b)
	LandmarkCeParts.hip(lm, "Copper", c + Vector3(0, 26.0, 0), 26.0, 44.0, 3.0)
	lm.frustum("Stone", c + Vector3(0, 28.0, 0), 6.0, 6.0, 4.0, 24)
	lm.lathe("Copper", c + Vector3(0, 32.0, 0), LandmarkChParts.swell(6.3, 6.0, 1.04), 24)
	LandmarkChParts.finial(lm, "Gilt", c + Vector3(0, 38.0, 0), 2.4, 0.4)

## The dome: drum of 16 bays with paired Corinthian columns and arched
## windows, the attic with oculi, the ribbed copper shell with its
## dormers, the lantern, gilt orb and cross at 98 m.
static func _dome(lm: LandmarkMesh) -> void:
	var r := 16.5
	var db := EAVE + 2.0
	lm.frustum("Stone", Vector3(0, db, 0), r, r, 15.0, 48)
	lm.frustum("Dark", Vector3(0, db, 0), r + 1.2, r + 1.2, 1.4, 48)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		var t := d.cross(Vector3.UP).normalized()
		for s in [-0.7, 0.7]:
			LandmarkChParts.ren_column(lm, "Stone", d * (r + 1.0) + t * float(s) + Vector3(0, db + 1.4, 0), 0.45, 12.0)
		var wa := a + TAU / 32.0
		var wd := Vector3(cos(wa), 0, sin(wa))
		LandmarkChParts.arched_window(lm, "Dark", "Windows", wd * (r - 0.05) + Vector3(0, db + 3.0, 0), wd, 2.2, 8.0, 0.25)
	lm.frustum("Stone", Vector3(0, db + 13.4, 0), r + 1.8, r + 1.8, 1.8, 48)
	lm.frustum("Dark", Vector3(0, db + 15.0, 0), r + 2.0, r + 2.2, 0.8, 48)
	# Attic with oculi.
	lm.frustum("Stone", Vector3(0, db + 15.8, 0), r, r, 3.0, 48)
	for k in 16:
		var a := TAU * (float(k) + 0.5) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.disc("Windows", d * (r + 0.03) + Vector3(0, db + 17.3, 0), d, 0.8, 12)
	var sb := db + 18.8
	var prof := PackedVector2Array([Vector2(16.4, 0), Vector2(16.0, 3.0), Vector2(14.9, 7.0), Vector2(12.8, 11.5),
		Vector2(10.0, 15.5), Vector2(7.0, 18.6), Vector2(4.6, 20.4), Vector2(3.6, 21.0)])
	lm.lathe("Copper", Vector3(0, sb, 0), prof, 48)
	for k in 16:
		var a := TAU * float(k) / 16.0
		for j in prof.size() - 1:
			var p0 := Vector3(cos(a) * (prof[j].x + 0.15), sb + prof[j].y, sin(a) * (prof[j].x + 0.15))
			var p1 := Vector3(cos(a) * (prof[j + 1].x + 0.15), sb + prof[j + 1].y, sin(a) * (prof[j + 1].x + 0.15))
			lm.beam("Gilt", p0, p1, 0.35, 0.2)
		# Round dormer between each pair of ribs.
		var da := a + TAU / 32.0
		var dd := Vector3(cos(da), 0, sin(da))
		var dp := dd * 15.2 + Vector3(0, sb + 5.6, 0)
		var bb := Basis(Vector3.UP, atan2(dd.x, dd.z))
		lm.box("Copper", dp, Vector3(1.4, 1.8, 1.6), bb)
		lm.lathe("Copper", dp + Vector3(0, 0.9, 0), LandmarkChParts.swell(0.8, 0.8), 8)
		lm.disc("Windows", dp + dd * 0.82, dd, 0.5, 10)
	# Lantern, cupola, orb and cross.
	var lb := sb + 21.0
	lm.frustum("Stone", Vector3(0, lb, 0), 3.6, 3.4, 6.0, 16)
	for k in 8:
		var a := TAU * float(k) / 8.0
		LandmarkDetail.column(lm, "Stone", Vector3(cos(a) * 3.7, lb, sin(a) * 3.7), 0.28, 5.6, "corinthian", 0)
		var wa := a + TAU / 16.0
		var wd := Vector3(cos(wa), 0, sin(wa))
		LandmarkChParts.arched_window(lm, "Dark", "Windows", Vector3(0, lb + 1.0, 0) + wd * 3.45, wd, 1.1, 3.8, 0.15)
	lm.frustum("Dark", Vector3(0, lb + 5.6, 0), 4.4, 4.4, 0.8, 16)
	lm.lathe("Copper", Vector3(0, lb + 6.4, 0), PackedVector2Array([Vector2(4.2, 0), Vector2(3.8, 0.6),
		Vector2(2.6, 2.2), Vector2(1.2, 3.4), Vector2(0.6, 3.8)]), 16)
	LandmarkChParts.finial(lm, "Gilt", Vector3(0, lb + 10.2, 0), 1.6, 0.9)
	var cb := lb + 11.8
	LandmarkCeParts.cross(lm, "Gilt", Vector3(0, cb, 0), BERLIN_TOP - cb)

## Corner tower: square shaft rising above the main cornice with its
## own pilasters and arched belfry openings, balustrade, an octagonal
## drum, the copper cupola and lantern.
static func _corner_tower(lm: LandmarkMesh, p: Vector3) -> void:
	var hw := 5.5
	lm.box("Stone", p + Vector3(0, EAVE + 7.0, 0), Vector3(hw * 2.0, 14.0, hw * 2.0))
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		var face := p + b * Vector3(0, 0, hw)
		for s in [-1.0, 1.0]:
			lm.box("Stone", face + b * Vector3(s * (hw - 0.5), EAVE + 6.5, 0.3), Vector3(1.0, 12.0, 0.6), b)
		LandmarkChParts.arched_window(lm, "Dark", "Windows", face + Vector3(0, EAVE + 3.0, 0), n, 2.4, 7.5, 0.3)
		LandmarkDetail.cornice(lm, "Stone", face + b * Vector3(-hw, EAVE + 13.0, 0), face + b * Vector3(hw, EAVE + 13.0, 0),
			n, 1.0)
	var y := EAVE + 14.0
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.wall(lm, "Stone", p + b * Vector3(-hw, 0, hw - 0.2), p + b * Vector3(hw, 0, hw - 0.2), y, y + 1.1, 0.5)
	lm.frustum("Stone", p + Vector3(0, y, 0), 4.2, 4.0, 6.0, 8, PI / 8.0)
	for k in 8:
		var a := PI * 0.25 * k
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.arched_window(lm, "Dark", "Windows", p + d * 3.75 + Vector3(0, y + 1.2, 0), d, 1.2, 3.6, 0.2)
	lm.frustum("Dark", p + Vector3(0, y + 6.0, 0), 4.6, 4.6, 0.6, 16)
	lm.lathe("Copper", p + Vector3(0, y + 6.6, 0), LandmarkChParts.swell(4.6, 6.4), 16)
	lm.frustum("Stone", p + Vector3(0, y + 13.0, 0), 1.3, 1.2, 2.6, 8)
	lm.lathe("Copper", p + Vector3(0, y + 15.6, 0), PackedVector2Array([Vector2(1.7, 0), Vector2(1.1, 0.8),
		Vector2(0.4, 1.6)]), 8)
	LandmarkCeParts.cross(lm, "Gilt", p + Vector3(0, y + 17.2, 0), 2.6)

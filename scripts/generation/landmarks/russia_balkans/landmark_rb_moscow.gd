class_name LandmarkRbMoscow
extends RefCounted

## Two Moscow landmarks in true metres: the Ivan the Great Bell Tower
## (1505-1508, raised to 81 m in 1600: whitewashed brick octagons with
## open bell arcades, the drum with its gold-on-blue inscription band and
## the gilded onion, with the Assumption Belfry, Filaret's tented annex
## and the five-domed Assumption Cathedral beside it) and the Cathedral of
## Christ the Saviour (rebuilt 1995-2000: a white marble Greek cross about
## 80 m across under the gilded helmet dome, 103 m).

const IVAN_TOP := 81.0
const ASSUMPTION_AT := Vector3(-64.6, 0.0, -41.1)
const BELFRY_AT := Vector3(-4.4, 0.0, -26.0)

## Gilded helm dome of base radius r and height h.
static func _helm(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float, seg: int = 16) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r * 0.92, 0), Vector2(r, h * 0.12), Vector2(r, h * 0.3),
		Vector2(r * 0.84, h * 0.55), Vector2(r * 0.5, h * 0.8), Vector2(r * 0.18, h * 0.95), Vector2(0, h)]), seg)

## Origin at the foot of the tower. The Assumption Belfry and Filaret's
## annex run north from it and the Assumption Cathedral stands 76 m to
## the west-north-west; the built frame is turned 15 degrees (yaw) so the
## cathedral keeps its real east-west axis.
static func ivan_great(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#EFEADB", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E6E1D2", 4.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#9A9486", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6F7E74", 3.0, 0.6, 0.2))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Blue", LandmarkMaterials.pbr("concrete", "#28407A", 2.0, 0.5, 0.2))
	# Tower: three octagonal tiers (36, 17 and 12 m), each ending in a
	# moulded cornice; the lowest with windows, the upper two open bell
	# arcades. Rows are r0, r1, y0, h and the opening bottom, width, height.
	var tiers := [[9.0, 8.7, 0.0, 36.0, 17.0, 3.0, 12.0], [7.2, 6.9, 37.2, 16.8, 41.0, 3.0, 10.0],
		[5.5, 5.3, 55.0, 12.0, 58.0, 2.0, 7.0]]
	for ti in tiers.size():
		var t: Array = tiers[ti]
		var r0: float = t[0]
		var r1: float = t[1]
		var y0: float = t[2]
		var h: float = t[3]
		var oy: float = t[4]
		var ow: float = t[5]
		var oh: float = t[6]
		lm.frustum("Wall", Vector3(0, y0, 0), r0, r1, h, 8, PI / 8.0)
		lm.lathe("Stone", Vector3(0, y0 + h - 0.2, 0), PackedVector2Array([Vector2(r1, 0), Vector2(r1 + 0.3, 0.3),
			Vector2(r1 + 0.5, 0.6), Vector2(r0 + 0.8, 1.0), Vector2(r0 + 0.8, 1.4), Vector2(r0 * 0.9, 1.4)]),
			8, 1.0, 1.0, PI / 8.0, false)
		SEuUtil.ring_openings(lm, "Windows", Vector3.ZERO, r1, 8, 8, oy, ow, oh, false)
		for k in 8:
			var a := PI / 8.0 + TAU * float(k) / 8.0
			lm.box("Stone", Vector3(cos(a) * (r0 + 0.1), y0 + h * 0.5, sin(a) * (r0 + 0.1)), Vector3(0.9, h, 0.9),
				Basis(Vector3.UP, -a))
			# Archivolt round each opening, and on the lowest tier a second
			# row of small windows.
			var fa := TAU * float(k) / 8.0
			var d := Vector3(cos(fa), 0, sin(fa))
			var fr := r1 * cos(PI / 8.0) + 0.05
			LandmarkDetail.arch(lm, "Stone", d * fr + Vector3(0, oy + oh - ow * 0.5, 0), d, ow, 0.45, 0.3)
			if ti == 0:
				LandmarkDetail.window(lm, "Stone", "Windows", d * (r0 * cos(PI / 8.0) + 0.02) + Vector3(0, 6.0, 0), d,
					1.4, 3.0, true, 0.2)
			else:
				# Bells hanging in the open arcades.
				lm.lathe("Gilt", d * (fr - 1.2) + Vector3(0, oy + oh * 0.45, 0), PackedVector2Array([
					Vector2(ow * 0.32, 0), Vector2(ow * 0.24, ow * 0.25), Vector2(ow * 0.16, ow * 0.5),
					Vector2(0.0, ow * 0.55)]), 8)
	lm.box("Plinth", Vector3(0, 0.6, 0), Vector3(25.0, 1.2, 25.0))
	for k in 4:
		var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
		SEuUtil.opening(lm, "Windows", out * 8.4 + Vector3(0, 1.2, 0), Vector3.UP.cross(out), Vector3.UP, 3.0, 7.0)
	# Kokoshnik band at the drum foot, the 1600 drum with eight slit
	# windows, the three-register inscription band, the onion and cross.
	for k in 8:
		var fa := TAU * float(k) / 8.0
		var d := Vector3(cos(fa), 0, sin(fa))
		LandmarkRbParts.kokoshnik(lm, "Stone", "Wall", d * 4.3 + Vector3(0, 68.2, 0), d, 3.2, 0.4, true)
	lm.frustum("Wall", Vector3(0, 67.0, 0), 4.6, 4.3, 1.2, 16)
	lm.frustum("Wall", Vector3(0, 68.2, 0), 3.9, 3.9, 4.6, 16)
	SEuUtil.ring_openings(lm, "Windows", Vector3(0, 68.2, 0), 3.9, 16, 8, 0.8, 0.4, 2.4, false, PI / 8.0)
	lm.frustum("Blue", Vector3(0, 71.4, 0), 4.0, 4.0, 1.4, 16)
	for reg in 3:
		lm.frustum("Stone", Vector3(0, 71.3 + reg * 0.5, 0), 4.08, 4.08, 0.08, 16)
	for i in 24:
		var a := TAU * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		for reg in 2:
			lm.box("Gilt", d * 4.02 + Vector3(0, 71.6 + reg * 0.55, 0), Vector3(0.35, 0.3, 0.05), Basis.looking_at(d), 0.0)
	lm.frustum("Stone", Vector3(0, 72.8, 0), 4.3, 4.3, 0.6, 16)
	LandmarkCeParts.onion(lm, "Gilt", Vector3(0, 73.4, 0), 4.4, 4.4, 20)
	LandmarkRbParts.cross(lm, "Gilt", Vector3(0, 77.8, 0), IVAN_TOP - 77.8)
	_belfry(lm)
	_assumption(lm, ASSUMPTION_AT)
	lm.commit(model)

## Assumption Belfry (1814-1815: a four-tier pedestal, the bell tier of
## three arched spans, a drum and gilded head; 36 m) and Filaret's annex
## under its tent roof north of the tower, turned 10 degrees off the
## built axes.
static func _belfry(lm: LandmarkMesh) -> void:
	var bb := Basis(Vector3.UP, -deg_to_rad(10.0))
	var bc := BELFRY_AT + bb * Vector3(0, 0, 10.5)
	# Pedestal tiers stepping in, then the open bell tier.
	var steps := [[0.0, 7.0, 24.0, 15.0], [7.0, 6.0, 23.4, 14.4], [13.0, 5.0, 22.8, 13.8], [18.0, 4.0, 22.2, 13.2]]
	for s in steps:
		var y0: float = s[0]
		var h: float = s[1]
		lm.box("Wall", bc + Vector3(0, y0 + h * 0.5, 0), Vector3(float(s[2]), h, float(s[3])), bb)
		lm.box("Stone", bc + Vector3(0, y0 + h - 0.2, 0), Vector3(float(s[2]) + 0.6, 0.4, float(s[3]) + 0.6), bb)
	for sx in [-1.0, 1.0]:
		var out := bb * Vector3(sx, 0, 0)
		var right := bb * Vector3(0, 0, 1)
		for i in 3:
			var z := (float(i) - 1.0) * 4.6
			LandmarkDetail.window(lm, "Stone", "Windows", bc + out * 12.02 + right * z + Vector3(0, 3.5, 0), out, 1.6, 3.6, true)
			LandmarkDetail.window(lm, "Stone", "Windows", bc + out * 11.72 + right * z + Vector3(0, 10.0, 0), out, 1.4, 3.2, true)
	# Bell tier: three spans a side between paired pilasters.
	var by := 22.0
	lm.box("Wall", bc + Vector3(0, by + 6.0, 0), Vector3(21.6, 12.0, 12.6), bb)
	for sx in [-1.0, 1.0]:
		var out := bb * Vector3(sx, 0, 0)
		var right := bb * Vector3(0, 0, 1)
		for i in 3:
			var z := (float(i) - 1.0) * 4.0
			SEuUtil.opening(lm, "Windows", bc + out * 10.85 + right * z + Vector3(0, by + 1.0, 0), right, Vector3.UP, 3.0, 9.0)
			LandmarkDetail.arch(lm, "Stone", bc + out * 10.8 + right * z + Vector3(0, by + 8.5, 0), out, 3.0, 0.45, 0.3)
		for i in 4:
			lm.box("Stone", bc + out * 10.9 + right * ((float(i) - 1.5) * 4.0) + Vector3(0, by + 6.0, 0),
				Vector3(0.7, 12.0, 0.4), bb)
	lm.box("Stone", bc + Vector3(0, by + 12.2, 0), Vector3(22.6, 0.8, 13.6), bb)
	LandmarkRbParts.balustrade(lm, "Stone", bc + bb * Vector3(-10.8, by + 12.6, -6.3), bc + bb * Vector3(10.8, by + 12.6, -6.3), 1.0)
	LandmarkRbParts.balustrade(lm, "Stone", bc + bb * Vector3(-10.8, by + 12.6, 6.3), bc + bb * Vector3(10.8, by + 12.6, 6.3), 1.0)
	LandmarkRbParts.onion_on_drum(lm, "Wall", "Gilt", "Gilt", bc + Vector3(0, by + 12.6, 0), 4.0, 4.0, 5.5, 2.6, 16)
	SEuUtil.ring_openings(lm, "Windows", bc + Vector3(0, by + 12.6, 0), 4.0, 16, 8, 0.8, 0.8, 2.2, false, 0.0)
	# Filaret's annex: two storeys, tented roof with a small cupola.
	var fc := BELFRY_AT + bb * Vector3(0, 0, -7.0)
	lm.box("Wall", fc + Vector3(0, 12.0, 0), Vector3(24.0, 24.0, 20.0), bb)
	lm.box("Stone", fc + Vector3(0, 24.4, 0), Vector3(25.0, 0.8, 21.0), bb)
	for sx in [-1.0, 1.0]:
		var out := bb * Vector3(sx, 0, 0)
		var right := bb * Vector3(0, 0, 1)
		for i in 3:
			for y in [4.0, 14.0]:
				LandmarkDetail.window(lm, "Stone", "Windows", fc + out * 12.02 + right * ((float(i) - 1.0) * 5.6)
					+ Vector3(0, y + 2.0, 0), out, 1.8, 4.2, true)
	var tent := PackedVector2Array([Vector2(16.0, 0), Vector2(1.4, 9.0)])
	lm.lathe("Roof", fc + Vector3(0, 24.8, 0), tent, 4, 1.0, 1.0, PI * 0.25 + deg_to_rad(10.0), false)
	LandmarkRbParts.onion_on_drum(lm, "Wall", "Gilt", "Gilt", fc + Vector3(0, 33.6, 0), 1.0, 1.6, 2.2, 1.4, 12)

## Assumption Cathedral centred at `c` (axis east-west, altar east;
## Fioravanti 1475-1479): white limestone, 38 x 35 m, its fronts split
## by pilasters into bays under semicircular zakomaras with the
## arcade-and-colonnette belt at mid-height, five apses on the east, and
## five gilded helmet domes on tall drums (38 m).
static func _assumption(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Plinth", c + Vector3(0, 0.6, 0), Vector3(39.0, 1.2, 36.0))
	lm.box("Stone", c + Vector3(0, 11.0, 0), Vector3(38.0, 22.0, 35.0))
	lm.box("Roof", c + Vector3(0, 22.2, 0), Vector3(36.0, 0.4, 33.0))
	# North and south fronts: four bays; west front: three.
	var fronts := [[Vector3(0, 0, 1), 17.5, 38.0, 4], [Vector3(0, 0, -1), 17.5, 38.0, 4], [Vector3(-1, 0, 0), 19.0, 35.0, 3]]
	for f in fronts:
		var out: Vector3 = f[0]
		var right := LandmarkRbParts.facing(out).x
		var o := c + out * float(f[1])
		var wl: float = f[2]
		var n: int = f[3]
		var bw := wl / float(n)
		for i in n + 1:
			lm.box("Stone", o + right * (-wl * 0.5 + bw * float(i)) + out * 0.25 + Vector3(0, 11.0, 0), Vector3(1.0, 21.0, 0.5),
				LandmarkRbParts.facing(out))
		for i in n:
			var x := -wl * 0.5 + bw * (float(i) + 0.5)
			# Zakomara: half-round gable over the bay with its moulding.
			LandmarkRbParts.kokoshnik(lm, "Stone", "Stone", o + right * x + Vector3(0, 22.0, 0) + out * 0.05, out, bw - 0.6, 0.5)
			LandmarkDetail.window(lm, "Stone", "Windows", o + right * x + Vector3(0, 15.5, 0) + out * 0.02, out, 1.2, 4.2, true, 0.3)
			LandmarkDetail.window(lm, "Stone", "Windows", o + right * x + Vector3(0, 4.5, 0) + out * 0.02, out, 1.2, 3.6, true, 0.3)
			# Arcade belt: colonnettes and small arches.
			for j in 4:
				var cx := x - bw * 0.5 + bw * (float(j) + 0.5) / 4.0
				lm.frustum("Stone", o + right * cx + out * 0.3 + Vector3(0, 9.0, 0), 0.14, 0.12, 1.8, 6)
				LandmarkDetail.arch(lm, "Stone", o + right * cx + out * 0.05 + Vector3(0, 10.8, 0), out, bw / 4.0 - 0.3, 0.2, 0.25)
		lm.box("Stone", o + out * 0.3 + Vector3(0, 8.9, 0), Vector3(wl, 0.3, 0.6), LandmarkRbParts.facing(out))
	# Five apses on the east.
	for z in [-13.0, -6.5, 0.0, 6.5, 13.0]:
		var r := 3.4
		lm.frustum("Stone", c + Vector3(19.0, 0, z), r, r, 18.0, 12, -PI * 0.5)
		lm.lathe("Roof", c + Vector3(19.0, 18.0, z), LandmarkRbParts.dome_profile(r + 0.2, r * 0.5, 4), 12)
		LandmarkDetail.window(lm, "Stone", "Windows", c + Vector3(19.0 + r - 0.05, 12.0, z), Vector3(1, 0, 0), 0.9, 3.0, true, 0.2)
	_drum_helm(lm, c + Vector3(0, 22.4, 0), 4.6, 7.4, 5.6, 3.2)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_drum_helm(lm, c + Vector3(sx * 12.0, 22.4, sz * 11.0), 2.8, 5.0, 4.0, 2.4)

## A tall drum with slit windows and an arcature belt, the gilded helmet
## dome and the cross.
static func _drum_helm(lm: LandmarkMesh, b: Vector3, r: float, h: float, dome_h: float, cross_h: float) -> void:
	lm.frustum("Stone", b, r + 0.3, r, 0.8, 16)
	lm.frustum("Wall", b + Vector3(0, 0.8, 0), r, r, h - 0.8, 16)
	SEuUtil.ring_openings(lm, "Windows", b + Vector3(0, 0.8, 0), r, 16, 8, h * 0.2, r * 0.18, h * 0.5, false, PI / 8.0)
	for i in 16:
		var a := TAU * float(i) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Stone", b + d * (r + 0.05) + Vector3(0, h * 0.45, 0), Vector3(0.22, h * 0.8, 0.12), Basis.looking_at(d), 0.0)
	lm.frustum("Stone", b + Vector3(0, h, 0), r * 1.08, r * 1.08, 0.5, 16)
	_helm(lm, "Gilt", b + Vector3(0, h + 0.5, 0), r * 1.05, dome_h, 16)
	LandmarkRbParts.cross(lm, "Gilt", b + Vector3(0, h + 0.5 + dome_h, 0), cross_h)

# --- Cathedral of Christ the Saviour ---

const CHRIST_TOP := 103.0

## Origin at the dome axis. Greek cross on a 5 m stylobate: a 46 m
## central cube with four arms ending in three-portal fronts under a
## great kokoshnik and two smaller ones, the drum with sixteen windows
## under the gilded helmet dome (8.5 m cross), and the four corner
## belfries with their gilded domes (6.5 m crosses).
static func christ_saviour(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E9E5D8", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F2EFE6", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8B85", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#B8995A", 3.0, 0.4, 0.75))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#5E4E33", 2.0, 0.45, 0.75))
	var y0 := 5.0
	lm.box("Granite", Vector3(0, 2.5, 0), Vector3(92.0, 5.0, 92.0))
	for k in 4:
		var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
		var right := LandmarkRbParts.facing(out).x
		# Terrace balustrade either side of the stair.
		for sgn in [-1.0, 1.0]:
			LandmarkRbParts.balustrade(lm, "Trim", out * 45.6 + right * (sgn * 20.0) + Vector3(0, y0, 0),
				out * 45.6 + right * (sgn * 45.6) + Vector3(0, y0, 0), 1.1, 0.6, 4.0)
	lm.box("Marble", Vector3(0, y0 + 18.0, 0), Vector3(46.0, 36.0, 46.0))
	lm.box("Trim", Vector3(0, y0 + 36.5, 0), Vector3(47.2, 1.0, 47.2))
	lm.box("Roof", Vector3(0, y0 + 37.2, 0), Vector3(42.0, 0.4, 42.0))
	for k in 4:
		_christ_arm(lm, Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k)), y0)
	# Central drum: sixteen windows between paired columns, cornice with
	# a kokoshnik crown, the gilded helmet dome, lantern and cross.
	var d0 := y0 + 37.7
	lm.frustum("Marble", Vector3(0, d0, 0), 17.5, 15.6, 3.0, 32)
	lm.frustum("Marble", Vector3(0, d0 + 3.0, 0), 15.6, 15.6, 19.0, 32)
	for i in 16:
		var a := TAU * float(i) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Trim", "Windows", d * 15.55 + Vector3(0, d0 + 12.0, 0), d, 2.2, 8.0, true, 0.3)
		var pa := a + PI / 16.0
		var pd := Vector3(cos(pa), 0, sin(pa))
		for s in [-0.6, 0.6]:
			var pp := pd * 15.9 + Vector3.UP.cross(pd) * float(s)
			LandmarkRbParts.order_column(lm, "Trim", pp + Vector3(0, d0 + 3.0, 0), 0.4, 18.4, "corinthian", pd, 8)
		LandmarkRbParts.kokoshnik(lm, "Trim", "Marble", d * 16.0 + Vector3(0, d0 + 23.6, 0), d, 4.6, 0.5, true)
	lm.frustum("Trim", Vector3(0, d0 + 21.4, 0), 16.8, 17.0, 2.2, 32)
	var dy := d0 + 23.6
	_helm(lm, "Gilt", Vector3(0, dy, 0), 15.6, 17.5, 40)
	var ly := dy + 17.0
	lm.frustum("Marble", Vector3(0, ly, 0), 3.6, 3.4, 4.0, 16)
	SEuUtil.ring_openings(lm, "Windows", Vector3(0, ly, 0), 3.4, 16, 8, 0.8, 0.9, 2.4, false, 0.0)
	lm.frustum("Trim", Vector3(0, ly + 4.0, 0), 4.0, 4.0, 0.6, 16)
	_helm(lm, "Gilt", Vector3(0, ly + 4.6, 0), 3.6, 4.6, 16)
	LandmarkRbParts.cross(lm, "Gilt", Vector3(0, ly + 9.2, 0), CHRIST_TOP - (ly + 9.2))
	# Corner belfries: open arched stage, drum, gilded dome, cross.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(sx * 19.5, y0 + 36.8, sz * 19.5)
			lm.box("Marble", c + Vector3(0, 5.0, 0), Vector3(10.0, 10.0, 10.0))
			for k in 4:
				var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
				var right := Vector3.UP.cross(out)
				for sgn in [-1.0, 1.0]:
					SEuUtil.opening(lm, "Windows", c + out * 5.05 + right * sgn * 2.0 + Vector3(0, 2.0, 0), right, Vector3.UP, 2.4, 6.5)
					LandmarkDetail.arch(lm, "Trim", c + out * 5.0 + right * sgn * 2.0 + Vector3(0, 7.3, 0), out, 2.4, 0.35, 0.3)
				LandmarkRbParts.kokoshnik(lm, "Trim", "Marble", c + out * 5.0 + Vector3(0, 10.0, 0), out, 8.0, 0.5, true)
			lm.frustum("Trim", c + Vector3(0, 10.0, 0), 5.6, 5.6, 0.8, 16)
			lm.frustum("Marble", c + Vector3(0, 10.8, 0), 4.4, 4.4, 5.2, 16)
			SEuUtil.ring_openings(lm, "Windows", c + Vector3(0, 10.8, 0), 4.4, 16, 8, 1.0, 1.0, 3.4, false, 0.0)
			lm.frustum("Trim", c + Vector3(0, 16.0, 0), 4.9, 4.9, 0.6, 16)
			_helm(lm, "Gilt", c + Vector3(0, 16.6, 0), 4.7, 8.5, 24)
			LandmarkRbParts.cross(lm, "Gilt", c + Vector3(0, 25.1, 0), 6.5)
	lm.commit(model)

## One arm of the cross facing `out`: 26 m wide, 14 m deep, its front of
## three bronze-doored portals between paired pilasters with relief
## panels above, the upper windows, the great central kokoshnik and the
## two lower side kokoshniks, the gilded roof and the stair.
static func _christ_arm(lm: LandmarkMesh, out: Vector3, y0: float) -> void:
	var b := LandmarkRbParts.facing(out)
	var right := b.x
	lm.box("Marble", out * 30.0 + Vector3(0, y0 + 14.0, 0), Vector3(26.0, 28.0, 14.0), b)
	lm.box("Trim", out * 30.0 + Vector3(0, y0 + 28.2, 0), Vector3(27.2, 0.9, 15.2), b)
	lm.gable("Roof", out * 30.0 + Vector3(0, y0 + 28.6, 0), 24.0, 14.0, 5.0, b, 0.4)
	var face := out * 37.0
	# Central projecting bay of the front.
	lm.box("Marble", face + out * 0.75 + Vector3(0, y0 + 14.0, 0), Vector3(14.0, 28.0, 1.5), b)
	for i in 3:
		var x := (float(i) - 1.0) * 4.6
		var big := i == 1
		var ow := 3.4 if big else 2.8
		var oh := 10.0 if big else 8.5
		var fp := face + out * 1.52 + right * x
		lm.box("Bronze", fp + Vector3(0, y0 + oh * 0.5 - ow * 0.25, 0) - out * 0.1, Vector3(ow, oh - ow * 0.5, 0.2), b, 0.0)
		SEuUtil.opening(lm, "Bronze", fp + Vector3(0, y0 + 0.1, 0), right, Vector3.UP, ow, oh)
		LandmarkDetail.arch(lm, "Trim", fp + Vector3(0, y0 + oh - ow * 0.5, 0), out, ow, 0.5, 0.4)
		# Relief panel over the portal.
		lm.box("Trim", fp + Vector3(0, y0 + oh + 2.6, 0) + out * 0.1, Vector3(ow + 0.6, 3.4, 0.25), b, 0.0)
		for j in 3:
			LandmarkRbParts.figure(lm, "Trim", fp + right * ((float(j) - 1.0) * ow * 0.3) + Vector3(0, y0 + oh + 1.0, 0)
				+ out * 0.3, 2.6, 0.0)
		LandmarkDetail.window(lm, "Trim", "Windows", fp + Vector3(0, y0 + 20.0, 0), out, 2.2, 6.0, true, 0.3)
	for x in [-6.9, -2.3, 2.3, 6.9]:
		for s in [-0.45, 0.45]:
			LandmarkRbParts.pilaster(lm, "Trim", face + out * 1.5 + right * (float(x) + float(s)) + Vector3(0, y0, 0), out,
				0.7, 27.0, 0.3)
	# Side bays: upper and lower windows.
	for sgn in [-1.0, 1.0]:
		var sp: Vector3 = face + right * (sgn * 10.0)
		LandmarkDetail.window(lm, "Trim", "Windows", sp + Vector3(0, y0 + 9.0, 0), out, 2.2, 6.0, true, 0.3)
		LandmarkDetail.window(lm, "Trim", "Windows", sp + Vector3(0, y0 + 20.0, 0), out, 2.0, 5.0, true, 0.3)
		lm.box("Trim", face + right * (sgn * 13.0) + out * 0.2 + Vector3(0, y0 + 14.0, 0), Vector3(1.4, 28.0, 0.8), b)
		# Lower side kokoshniks on the roofline.
		LandmarkRbParts.kokoshnik(lm, "Trim", "Marble", face + right * (sgn * 9.6) + Vector3(0, y0 + 28.6, 0), out, 6.4, 0.6)
		# Arm side walls: two windows each.
		var side: Vector3 = right * sgn
		for z in [26.5, 33.5]:
			LandmarkDetail.window(lm, "Trim", "Windows", out * z + side * 13.02 + Vector3(0, y0 + 16.0, 0), side, 2.0, 7.0,
				true, 0.3)
	# The great central kokoshnik with its relief.
	LandmarkRbParts.kokoshnik(lm, "Trim", "Marble", face + out * 1.55 + Vector3(0, y0 + 28.6, 0), out, 13.4, 0.8, true)
	lm.box("Marble", face + out * 0.75 + Vector3(0, y0 + 28.6 + 3.2, 0), Vector3(13.4, 6.4, 1.5), b)
	for j in 5:
		var fx := (float(j) - 2.0) * 2.2
		LandmarkRbParts.figure(lm, "Trim", face + out * 1.7 + right * fx + Vector3(0, y0 + 29.0, 0), 4.0 - absf(fx) * 0.35, 0.0)
	LandmarkRbParts.steps(lm, "Granite", out * 46.0, out, 34.0, 0.9, 0.5, 10)

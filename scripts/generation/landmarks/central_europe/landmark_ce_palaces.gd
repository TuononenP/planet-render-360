class_name LandmarkCePalaces
extends RefCounted

## Two imperial-era palaces in true metres: the Hungarian Parliament
## (Steindl's neo-Gothic block, 268 m along the Danube by 123 m, the
## river front facing west along Z, the sixteen-sided ribbed dome at
## 96 m between the twin chamber halls, a forest of pinnacles) and
## Schönbrunn Palace (the long Theresian-yellow baroque court front
## with its central risalit, double staircase and attic balustrade,
## forecourt wings and the eagle obelisks at the gate, facing north,
## 27 m).

const PARL_TOP := 96.0
const PARL_EAVE := 22.0

static func parliament(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E1DBCB", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6B7886", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#8794A2", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Steps", LandmarkMaterials.pbr("pavement", "#A39E94", 4.0))
	lm.box("Steps", Vector3(-62.0, 0.6, 0), Vector3(8.0, 1.2, 270.0))
	# Wings [centre x, centre z, size x, size z, eave]: river and rear
	# fronts, the two chamber blocks, the dome hall and both end wings.
	var wings := [[-47.0, 0.0, 24.0, 268.0, PARL_EAVE], [47.0, 0.0, 24.0, 268.0, PARL_EAVE],
		[0.0, -65.0, 70.0, 40.0, 26.0], [0.0, 65.0, 70.0, 40.0, 26.0],
		[0.0, 0.0, 70.0, 60.0, 27.0], [0.0, -122.0, 70.0, 24.0, PARL_EAVE], [0.0, 122.0, 70.0, 24.0, PARL_EAVE]]
	for w in wings:
		var c := Vector3(float(w[0]), 0, float(w[1]))
		var size := Vector3(float(w[2]), float(w[4]), float(w[3]))
		lm.box("Stone", c + Vector3(0, size.y * 0.5, 0), size)
		LandmarkCeParts.hip(lm, "Roof", c + Vector3(0, size.y, 0), size.x - 2.0, size.z - 2.0, 9.0 if size.y < 25.0 else 14.0)
	# Chamber halls: ridge cresting and pinnacles round their roofs.
	for sz in [-1.0, 1.0]:
		var hc := Vector3(0, 26.0, sz * 65.0)
		for sx in [-1.0, 1.0]:
			for k in 6:
				LandmarkCeParts.pinnacle(lm, "Stone", hc + Vector3(sx * 34.0, 0, -17.5 + 7.0 * k), 1.4, 9.0)
			for k in 9:
				LandmarkCeParts.pinnacle(lm, "Stone", hc + Vector3(-31.0 + 7.75 * k, 0, sx * 19.5), 1.4, 9.0)
		for k in 16:
			lm.box("Gilt", hc + Vector3(-16.0 + 2.1 * k, 14.3, 0), Vector3(0.2, 1.2, 0.2), Basis(), 0.0)
	# River and rear fronts: two storeys of windows, buttress strips,
	# a pinnacle on every strip, and the projecting pavilions.
	for sx in [-1.0, 1.0]:
		var n := Vector3(sx, 0, 0)
		var xf: float = sx * 59.0
		LandmarkDetail.pierced_face(lm, "Stone", "Windows", Vector3(xf, 1.0, 134.0 * sx),
			Vector3(0, 0, -sx), n, 268.0, PARL_EAVE - 2.0, 56, 3, Vector2(1.9, 4.2), 1.6, 6.4, 0.4)
		for i in 57:
			var z := -134.0 + 268.0 * float(i) / 56.0
			lm.box("Stone", Vector3(xf + sx * 0.7, PARL_EAVE * 0.5, z), Vector3(1.0, PARL_EAVE, 1.0))
			if i % 2 == 0:
				LandmarkCeParts.pinnacle(lm, "Stone", Vector3(xf + sx * 0.7, PARL_EAVE, z), 1.1, 7.0)
		LandmarkDetail.cornice(lm, "Stone", Vector3(xf + sx * 0.4, PARL_EAVE - 0.8, 134.0 * sx),
			Vector3(xf + sx * 0.4, PARL_EAVE - 0.8, -134.0 * sx), n, 0.8, false)
		for z in [-134.0, -100.0, -34.0, 34.0, 100.0, 134.0]:
			_parl_pavilion(lm, Vector3(sx * 56.0, 0, float(z)), n)
	# East entrance: steps and two slender towers flanking the portal.
	lm.box("Steps", Vector3(64.0, 0.5, 0), Vector3(8.0, 1.0, 30.0))
	for sz in [-1.0, 1.0]:
		var tc := Vector3(60.0, 0, sz * 14.0)
		lm.box("Stone", tc + Vector3(0, 21.0, 0), Vector3(6.0, 42.0, 6.0))
		for f in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * f)
			LandmarkCeParts.lancet(lm, "Stone", "Windows", tc + r * Vector3(0, 30.0, 3.0), r * Vector3(0, 0, 1), 1.6, 7.0, 1)
			LandmarkCeParts.pinnacle(lm, "Stone", tc + r * Vector3(2.8, 42.0, 2.8), 1.0, 6.0)
		lm.spire("Roof", tc + Vector3(0, 42.0, 0), 2.6, 18.0, 0.0, 8)
		lm.beam("Gilt", tc + Vector3(0, 59.0, 0), tc + Vector3(0, 62.0, 0), 0.15, 0.15)
	LandmarkCeParts.lancet(lm, "Stone", "Windows", Vector3(59.05, 1.2, 0), Vector3.RIGHT, 6.0, 12.0, 2, 0.6)
	LandmarkCeParts.wimperg(lm, "Stone", Vector3(59.2, 13.6, 0), Vector3.RIGHT, 9.0, 8.0, 0.6)
	_parl_dome(lm)
	lm.commit(model)

## Projecting pavilion on the long fronts: a taller bay with a lancet
## window pair, corner pinnacles and a steep pyramid roof.
static func _parl_pavilion(lm: LandmarkMesh, c: Vector3, n: Vector3) -> void:
	lm.box("Stone", c + Vector3(0, 15.0, 0), Vector3(12.0, 30.0, 12.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		var fn := r * Vector3(0, 0, 1)
		if fn.dot(n) < -0.5:
			continue
		for k in [-1.0, 1.0]:
			LandmarkCeParts.lancet(lm, "Stone", "Windows", c + r * Vector3(k * 2.4, 0, 6.0) + Vector3(0, 18.0, 0), fn,
				1.6, 7.5, 1)
		LandmarkCeParts.wimperg(lm, "Stone", c + fn * 6.0 + Vector3(0, 27.0, 0), fn, 8.0, 6.0)
		for s in [-1.0, 1.0]:
			LandmarkCeParts.pinnacle(lm, "Stone", c + r * Vector3(s * 5.6, 0, 5.6) + Vector3(0, 30.0, 0), 1.6, 10.0)
	lm.spire("Roof", c + Vector3(0, 30.0, 0), 5.6, 14.0, 0.0, 4)
	lm.beam("Gilt", c + Vector3(0, 43.5, 0), c + Vector3(0, 46.5, 0), 0.15, 0.15)

## Central dome: sixteen-sided drum with tall lancets, a gable and
## pinnacle on each face, sixteen ribs up the pointed shell, the
## lantern with its pinnacled ring and the gilt-tipped spire.
static func _parl_dome(lm: LandmarkMesh) -> void:
	var db := Vector3(0, 27.0, 0)
	lm.frustum("Stone", db, 14.5, 14.5, 20.0, 16)
	for k in 16:
		var a := TAU * (float(k) + 0.5) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkCeParts.lancet(lm, "Stone", "Windows", db + d * 14.3 + Vector3(0, 4.0, 0), d, 2.6, 12.0, 1)
		LandmarkCeParts.wimperg(lm, "Stone", db + d * 14.3 + Vector3(0, 17.0, 0), d, 4.0, 5.0)
		var ca := TAU * float(k) / 16.0
		var q := db + Vector3(cos(ca) * 15.2, 0, sin(ca) * 15.2)
		lm.box("Stone", q + Vector3(0, 10.0, 0), Vector3(1.6, 20.0, 1.6), Basis(Vector3.UP, -ca))
		LandmarkCeParts.pinnacle(lm, "Stone", q + Vector3(0, 20.0, 0), 1.6, 8.0)
	var top := db + Vector3(0, 20.0, 0)
	var prof := PackedVector2Array([Vector2(14.5, 0), Vector2(14.2, 4.0), Vector2(12.8, 10.0),
		Vector2(10.4, 17.0), Vector2(7.6, 24.0), Vector2(5.0, 30.0), Vector2(3.0, 35.0), Vector2(1.8, 38.0)])
	lm.lathe("Dome", top, prof, 16, 1.0, 1.0, 0.0, false)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 1:
			var p0 := top + d * (prof[j].x + 0.25) + Vector3(0, prof[j].y, 0)
			var p1 := top + d * (prof[j + 1].x + 0.25) + Vector3(0, prof[j + 1].y, 0)
			lm.beam("Stone", p0, p1, 0.7, 0.5, d.cross(Vector3.UP))
			if j % 2 == 1:
				lm.box("Stone", p1 + d * 0.4, Vector3(0.5, 0.6, 0.5), Basis(Vector3.UP, -a), 0.0)
	# Dormer lucarnes on the shell between the ribs.
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var p := top + d * 12.4 + Vector3(0, 10.0, 0)
		lm.box("Stone", p, Vector3(2.0, 3.0, 2.0), Basis(Vector3.UP, -a))
		lm.gable("Dome", p + Vector3(0, 1.5, 0), 2.0, 2.0, 1.4, Basis(Vector3.UP, -a + PI * 0.5), 0.15, "Stone")
	var lb := top + Vector3(0, 38.0, 0)
	lm.frustum("Stone", lb - Vector3(0, 1.0, 0), 2.4, 2.2, 4.0, 16)
	for k in 8:
		var a := TAU * float(k) / 8.0
		LandmarkCeParts.pinnacle(lm, "Stone", lb + Vector3(cos(a) * 2.6, 1.0, sin(a) * 2.6), 0.6, 4.0)
	lm.lathe("Gilt", lb + Vector3(0, 3.0, 0), PackedVector2Array([Vector2(1.8, 0), Vector2(1.4, 3.0),
		Vector2(0.9, 5.0), Vector2(0.2, PARL_TOP - lb.y - 3.0)]), 12)

# --- Schönbrunn Palace ---

const SCHOEN_TOP := 27.0
const SCHOEN_EAVE := 17.5

static func schoenbrunn(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E6C455", 3.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#EFEAD8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5A5E57", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gravel", LandmarkMaterials.pbr("gravel", "#C9B99A", 4.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.box("Gravel", Vector3(0, 0.05, -42.0), Vector3(150.0, 0.1, 70.0))
	# Main block, central pavilion and the two forecourt wings.
	lm.box("Wall", Vector3(0, SCHOEN_EAVE * 0.5, 0), Vector3(176.0, SCHOEN_EAVE, 40.0))
	LandmarkCeParts.hip(lm, "Roof", Vector3(0, SCHOEN_EAVE + 1.2, 0), 170.0, 38.0, 6.0)
	lm.box("Wall", Vector3(0, 10.0, 0), Vector3(48.0, 20.0, 46.0))
	LandmarkCeParts.hip(lm, "Roof", Vector3(0, 21.2, 0), 46.0, 44.0, SCHOEN_TOP - 21.2)
	lm.box("White", Vector3(0, 0.6, 0), Vector3(178.0, 1.2, 42.0))
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		var zf: float = sz * 20.0
		var zr: float = sz * 23.0
		# Long fronts either side of the risalit: pilasters, framed windows.
		for side in [-1.0, 1.0]:
			for i in 11:
				var x: float = side * (27.0 + 6.0 * i)
				lm.box("White", Vector3(x + side * 3.0, 9.0, zf + sz * 0.2), Vector3(1.0, 15.6, 0.4))
				lm.box("White", Vector3(x + side * 3.0, 16.9, zf + sz * 0.3), Vector3(1.4, 0.6, 0.6), Basis(), 0.0)
				for row in 3:
					var h := 2.4 if row == 0 else (3.2 if row == 1 else 2.2)
					var y: float = 3.2 + [0.0, 5.0, 10.2][row]
					LandmarkDetail.window(lm, "White", "Windows", Vector3(x, y, zf), n, 1.6, h, false, 0.2)
			LandmarkDetail.cornice(lm, "White", Vector3(side * 24.0, SCHOEN_EAVE - 0.4, zf), Vector3(side * 88.0, SCHOEN_EAVE - 0.4, zf),
				n, 0.9, true)
			lm.box("White", Vector3(side * 56.0, 7.4, zf + sz * 0.1), Vector3(64.0, 0.4, 0.3), Basis(), 0.0)
		# Central risalit: giant pilasters, tall arched windows of the
		# Great Gallery, cornice and the attic balustrade with vases.
		for i in 8:
			var x := -21.0 + 6.0 * i
			if i < 7:
				LandmarkDetail.window(lm, "White", "Windows", Vector3(x + 3.0, 10.4, zr), n, 1.9, 4.6, true, 0.25)
				LandmarkDetail.window(lm, "White", "Windows", Vector3(x + 3.0, 16.0, zr), n, 1.5, 2.0, false, 0.2)
				LandmarkDetail.window(lm, "White", "Windows", Vector3(x + 3.0, 3.6, zr), n, 1.6, 2.6, true, 0.2)
			lm.box("White", Vector3(x, 11.5, zr + sz * 0.25), Vector3(1.3, 17.0, 0.5))
			lm.box("White", Vector3(x, 20.2, zr + sz * 0.35), Vector3(1.7, 0.8, 0.7), Basis(), 0.0)
			lm.lathe("White", Vector3(x, 22.4, zr), PackedVector2Array([Vector2(0.25, 0), Vector2(0.45, 0.3),
				Vector2(0.55, 0.7), Vector2(0.3, 1.1), Vector2(0.15, 1.3), Vector2(0.0, 1.5)]), 10)
		LandmarkDetail.cornice(lm, "White", Vector3(-24.0, 20.2, zr), Vector3(24.0, 20.2, zr), n, 1.0, true)
		LandmarkDetail.balustrade(lm, "White", Vector3(-24.0, 21.2, zr - sz * 0.6), Vector3(24.0, 21.2, zr - sz * 0.6), 1.2, 6.0)
	# Court-side double staircase up to the piano nobile, over the
	# carriage passage.
	for side in [-1.0, 1.0]:
		for k in 12:
			var x: float = side * (6.0 + 1.0 * k)
			lm.box("White", Vector3(x, 0.3 + 0.45 * float(11 - k) * 0.5 + 0.2, -27.0), Vector3(1.0, 0.9 + 0.45 * float(11 - k), 4.0))
		LandmarkDetail.balustrade(lm, "White", Vector3(side * 17.5, 1.6, -29.2), Vector3(side * 5.5, 6.4, -29.2), 1.0, 12.0)
	lm.box("White", Vector3(0, 3.4, -27.0), Vector3(12.0, 6.8, 4.0))
	for k in 3:
		lm.box("Windows", Vector3(-3.6 + 3.6 * k, 2.4, -29.03), Vector3(2.4, 4.0, 0.05), Basis(), 0.0)
		LandmarkDetail.arch(lm, "White", Vector3(-3.6 + 3.6 * k, 4.4, -29.0), Vector3.FORWARD, 2.4, 0.4, 0.3)
	LandmarkDetail.balustrade(lm, "White", Vector3(-6.0, 6.8, -29.0), Vector3(6.0, 6.8, -29.0), 1.0, 6.0)
	# Forecourt wings, end pavilions and the gate obelisks with eagles.
	for sx in [-1.0, 1.0]:
		var wc := Vector3(sx * 76.0, 0, -42.0)
		lm.box("Wall", wc + Vector3(0, 7.5, 0), Vector3(24.0, 15.0, 50.0))
		LandmarkCeParts.hip(lm, "Roof", wc + Vector3(0, 15.0, 0), 22.0, 48.0, 5.5)
		for row in 3:
			for i in 8:
				LandmarkDetail.window(lm, "White", "Windows", wc + Vector3(-sx * 12.0, 2.8 + 4.2 * row, -19.25 + 5.5 * i),
					Vector3(-sx, 0, 0), 1.4, 2.2, false, 0.18)
		LandmarkDetail.cornice(lm, "White", wc + Vector3(-sx * 12.0, 14.4, -25.0 * sx), wc + Vector3(-sx * 12.0, 14.4, 25.0 * sx),
			Vector3(-sx, 0, 0), 0.7, false)
		lm.box("Wall", Vector3(sx * 96.0, 6.0, -20.0), Vector3(16.0, 12.0, 14.0))
		LandmarkCeParts.hip(lm, "Roof", Vector3(sx * 96.0, 12.0, -20.0), 14.0, 12.0, 4.0)
		var ob := Vector3(sx * 20.0, 0, -78.0)
		lm.box("White", ob + Vector3(0, 1.5, 0), Vector3(3.6, 3.0, 3.6))
		lm.box("White", ob + Vector3(0, 3.2, 0), Vector3(4.0, 0.4, 4.0), Basis(), 0.0)
		lm.spire("White", ob + Vector3(0, 3.4, 0), 1.3, 11.0, 0.45)
		lm.box("Gilt", ob + Vector3(0, 14.8, 0), Vector3(0.9, 0.8, 0.9))
		for s in [-1.0, 1.0]:
			lm.beam("Gilt", ob + Vector3(0, 15.4, 0), ob + Vector3(s * 1.2, 16.2, 0), 0.5, 0.12)
		lm.lathe("Gilt", ob + Vector3(0, 15.2, 0), PackedVector2Array([Vector2(0.3, 0), Vector2(0.35, 0.6),
			Vector2(0.15, 1.0), Vector2(0.0, 1.1)]), 8)
	# Chimneys along the main roof.
	for i in 10:
		for sz in [-1.0, 1.0]:
			var x := -80.0 + 17.6 * i
			if absf(x) < 26.0:
				continue
			lm.box("White", Vector3(x, SCHOEN_EAVE + 4.5, sz * 9.0), Vector3(1.4, 3.0, 1.0))
	lm.commit(model)

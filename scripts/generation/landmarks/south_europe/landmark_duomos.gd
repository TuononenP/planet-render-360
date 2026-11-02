class_name SEuDuomos
extends RefCounted

## Milan Cathedral and Florence Cathedral in true metres.

# --- Milan ----------------------------------------------------------------

## Duomo di Milano, origin under the octagonal tiburio, facade west (-X):
## the 158 m Gothic cross of five stepped aisles in pink-veined Candoglia
## marble, a buttress at every bay crowned by a pinnacle with its saint
## (135 spires in all), little flying arches over the aisle roofs, tall
## traceried windows, the polygonal apse with its three great windows;
## the 56.5 m facade of six buttress-piers carrying spires, five portals
## with Baroque pediments and windows below, Gothic windows above and the
## stepped gable lined with statues; the tiburio with its gallery of
## pinnacles and the openwork main spire with the gilded Madonnina at
## 108.5 m.
static func milan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E6E0D3", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("limestone", "#B9BCB7", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#55504A", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Statue", LandmarkMaterials.pbr("limestone", "#F0ECE4", 2.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#5E5038", 2.0, 0.4, 0.7))
	var along := Basis(Vector3.UP, PI * 0.5)
	# Five stepped aisles of the nave.
	lm.box("Marble", Vector3(-57.5, 21.0, 0), Vector3(95.0, 42.0, 17.0))
	lm.gable("Roof", Vector3(-57.5, 42.0, 0), 17.0, 95.0, 4.5, along, 0.3)
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(-57.5, 16.5, s * 13.5), Vector3(95.0, 33.0, 10.0))
		lm.gable("Roof", Vector3(-57.5, 33.0, s * 13.5), 10.0, 95.0, 2.0, along, 0.2)
		lm.box("Marble", Vector3(-57.5, 12.0, s * 24.0), Vector3(95.0, 24.0, 11.0))
		lm.gable("Roof", Vector3(-57.5, 24.0, s * 24.0), 11.0, 95.0, 2.0, along, 0.2)
		var out := Vector3(0, 0, s)
		for k in 15:
			var x := -102.0 + 6.2 * float(k)
			# Outer buttress, its pinnacle and saint, a flying arch to the
			# middle wall; middle and nave wall pinnacles above it.
			lm.box("Marble", Vector3(x, 12.5, s * 30.3), Vector3(1.6, 25.0, 1.6))
			SEuParts.pinnacle(lm, "Marble", Vector3(x, 25.0, s * 30.3), 1.1, 8.0, "Statue")
			lm.beam("Marble", Vector3(x, 27.0, s * 29.8), Vector3(x, 31.0, s * 18.9), 0.6, 0.9, Vector3(1, 0, 0))
			SEuParts.pinnacle(lm, "Marble", Vector3(x, 33.0, s * 18.6), 1.0, 9.0, "Statue")
			lm.beam("Marble", Vector3(x, 35.0, s * 18.2), Vector3(x, 39.6, s * 8.9), 0.5, 0.8, Vector3(1, 0, 0))
			SEuParts.pinnacle(lm, "Marble", Vector3(x, 42.0, s * 8.6), 0.9, 9.0, "Statue" if k % 2 == 0 else "")
			if k < 14:
				var xm := x + 3.1
				SEuParts.niche(lm, "Marble", "Shadow", Vector3(xm, 4.0, s * 29.55), out, 2.6, 15.0, SEuParts.POINTED, 0.35)
				lm.box("Marble", Vector3(xm, 11.0, s * 29.85), Vector3(0.18, 13.0, 0.18), Basis(), 0.0)
				SEuParts.niche(lm, "Marble", "Shadow", Vector3(xm, 26.0, s * 18.55), out, 2.2, 5.6, SEuParts.POINTED, 0.25)
				SEuParts.niche(lm, "Marble", "Shadow", Vector3(xm, 34.5, s * 8.55), out, 2.2, 6.0, SEuParts.POINTED, 0.25)
		# Pierced parapets along the three eaves.
		SEuParts.rail(lm, "Marble", Vector3(-104.0, 24.0, s * 29.4), Vector3(-11.0, 24.0, s * 29.4), 1.4, 6.2)
		SEuParts.rail(lm, "Marble", Vector3(-104.0, 33.0, s * 18.4), Vector3(-11.0, 33.0, s * 18.4), 1.2, 6.2)
		for k in 7:
			SEuParts.pinnacle(lm, "Marble", Vector3(s * 10.5, 38.0, -39.0 + 13.0 * float(k)), 1.0, 9.0, "Statue")
		SEuParts.pinnacle(lm, "Marble", Vector3(s * 10.5, 38.0, 47.0), 1.3, 11.0, "Statue")
		SEuParts.pinnacle(lm, "Marble", Vector3(s * 10.5, 38.0, -47.0), 1.3, 11.0, "Statue")
	# Crossing block, transept with its end windows, choir and apse.
	lm.box("Marble", Vector3(0, 23.0, 0), Vector3(22.0, 46.0, 22.0))
	lm.box("Marble", Vector3(0, 19.0, 0), Vector3(21.0, 38.0, 93.0))
	lm.gable("Roof", Vector3(0, 38.0, 0), 21.0, 93.0, 4.0, Basis(), 0.4, "Marble")
	for s in [-1.0, 1.0]:
		SEuParts.niche(lm, "Marble", "Shadow", Vector3(0, 6.0, s * 46.5), Vector3(0, 0, s), 6.0, 24.0, SEuParts.POINTED, 0.5)
		for m in 3:
			lm.box("Marble", Vector3(-1.5 + 1.5 * float(m), 15.0, s * 46.9), Vector3(0.22, 18.0, 0.22), Basis(), 0.0)
		for k in 6:
			var x := -9.0 + 3.6 * float(k)
			if absf(x) > 3.5:
				SEuParts.niche(lm, "Marble", "Shadow", Vector3(x, 4.0, s * 46.5), Vector3(0, 0, s), 1.2, 7.0, SEuParts.POINTED, 0.25)
	lm.box("Marble", Vector3(26.0, 18.0, 0), Vector3(32.0, 36.0, 40.0))
	lm.gable("Roof", Vector3(26.0, 36.0, 0), 40.0, 32.0, 5.0, along, 0.3)
	lm.frustum("Marble", Vector3(42.0, 0, 0), 21.0, 21.0, 36.0, 8, PI / 8.0)
	lm.spire("Roof", Vector3(42.0, 36.0, 0), 19.5, 6.0, 0.0, 8)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var am := a + PI / 8.0
		var dm := Vector3(cos(am), 0, sin(am))
		if dm.x > -0.5:
			# Apse buttresses with their pinnacles, and the great windows.
			lm.box("Marble", Vector3(42.0, 18.0, 0) + d * 19.7, Vector3(2.2, 36.0, 2.2), Basis(Vector3.UP, -a))
			SEuParts.pinnacle(lm, "Marble", Vector3(42.0, 36.0, 0) + d * 19.7, 1.4, 12.0, "Statue")
		var wall := Vector3(42.0, 0, 0) + dm * (21.0 * cos(PI / 8.0))
		if dm.x > 0.2:
			SEuParts.niche(lm, "Marble", "Shadow", wall + Vector3(0, 5.0, 0), dm, 6.4, 26.0, SEuParts.POINTED, 0.5)
			var rt := Vector3.UP.cross(dm)
			for m in 3:
				lm.box("Marble", wall + rt * (-1.6 + 1.6 * float(m)) + Vector3(0, 15.0, 0) + dm * 0.1, Vector3(0.22, 20.0, 0.22),
					Basis(Vector3.UP, -am), 0.0)
			lm.disc("Marble", wall + Vector3(0, 26.0, 0) + dm * 0.08, dm, 2.4, 16)
			lm.disc("Shadow", wall + Vector3(0, 26.0, 0) + dm * 0.12, dm, 1.9, 16)
	for k in 5:
		SEuParts.pinnacle(lm, "Marble", Vector3(14.0 + 6.0 * float(k), 36.0, 20.0), 1.0, 9.0, "Statue")
		SEuParts.pinnacle(lm, "Marble", Vector3(14.0 + 6.0 * float(k), 36.0, -20.0), 1.0, 9.0, "Statue")
	_milan_facade(lm)
	_milan_spire(lm)
	lm.commit(model)

## West facade: stepped wall, six buttress-piers with spires, five
## portals with Baroque pediments and windows, Gothic windows above, the
## stepped gable lined with statues.
static func _milan_facade(lm: LandmarkMesh) -> void:
	var fx := -107.0
	var along := Basis(Vector3.UP, PI * 0.5)
	lm.box("Marble", Vector3(fx, 14.0, 0), Vector3(4.0, 28.0, 59.0))
	lm.box("Marble", Vector3(fx, 20.0, 0), Vector3(4.0, 40.0, 37.0))
	lm.box("Marble", Vector3(fx, 24.5, 0), Vector3(4.0, 49.0, 17.0))
	lm.gable("Marble", Vector3(fx, 49.0, 0), 17.0, 4.0, 7.0, along, 0.0, "Marble")
	var face := fx - 2.0
	var nx := Vector3(-1, 0, 0)
	# Sloping gable edges stepped down to the aisles, each carrying statues.
	for s in [-1.0, 1.0]:
		lm.beam("Marble", Vector3(face + 1.0, 49.0, s * 8.5), Vector3(face + 1.0, 56.0, 0), 1.0, 4.0)
		for k in 4:
			var t := (float(k) + 0.5) / 4.0
			SEuParts.figure(lm, "Statue", Vector3(face + 0.8, lerpf(49.0, 56.0, t) + 0.4, s * 8.5 * (1.0 - t)), 1.8)
		lm.beam("Marble", Vector3(face + 1.0, 40.0, s * 18.5), Vector3(face + 1.0, 46.0, s * 8.5), 1.0, 4.0)
		lm.beam("Marble", Vector3(face + 1.0, 28.0, s * 29.5), Vector3(face + 1.0, 36.0, s * 18.5), 1.0, 4.0)
	SEuParts.figure(lm, "Statue", Vector3(face + 1.0, 56.0, 0), 3.0, true)
	# Portals: the great central door and two each side, bronze doors,
	# Baroque frames with triangular or segmental pediments.
	var doors := [[0.0, 5.0, 11.0], [-11.0, 3.6, 8.0], [11.0, 3.6, 8.0], [-22.0, 3.0, 7.0], [22.0, 3.0, 7.0]]
	for d in doors:
		var z: float = d[0]
		var w: float = d[1]
		var h: float = d[2]
		SEuParts.niche(lm, "Marble", "Bronze", Vector3(face, 0, z), nx, w, h, SEuParts.RECT, 0.6, 0.6, false)
		for s in [-1.0, 1.0]:
			SEuParts.col(lm, "Marble", Vector3(face - 0.8, 0, z + s * (w * 0.5 + 0.9)), 0.35, h + 0.6, "corinthian", 8)
		lm.box("Marble", Vector3(face - 0.6, h + 1.0, z), Vector3(1.4, 0.8, w + 3.0))
		lm.gable("Marble", Vector3(face - 0.6, h + 1.4, z), w + 3.0, 1.2, 1.6, along, 0.2, "Marble")
		# Baroque window over each portal, Gothic window above that.
		SEuParts.niche(lm, "Marble", "Shadow", Vector3(face, h + 5.0, z), nx, w * 0.6, 5.0, SEuParts.RECT, 0.4)
		lm.gable("Marble", Vector3(face - 0.4, h + 10.4, z), w * 0.6 + 1.2, 0.8, 1.0, along, 0.1, "Marble")
		var gw: float = 3.0 if absf(z) > 15.0 else 3.6
		var gy := 28.0 if absf(z) < 15.0 else 18.0
		if absf(z) < 1.0:
			gy = 31.0
			gw = 5.0
		SEuParts.niche(lm, "Marble", "Shadow", Vector3(face, gy, z), nx, gw, 10.0 if absf(z) > 15.0 else 13.0,
			SEuParts.POINTED, 0.4)
	# Six buttress-piers rising through the facade to their spires.
	var piers := [[-29.5, 32.0], [-18.5, 44.0], [-8.5, 52.0], [8.5, 52.0], [18.5, 44.0], [29.5, 32.0]]
	for pr in piers:
		var z: float = pr[0]
		var h: float = pr[1]
		lm.box("Marble", Vector3(face - 1.0, h * 0.5, z), Vector3(3.6, h, 3.2))
		for j in 4:
			var y := 6.0 + (h - 10.0) * float(j) / 3.0
			SEuParts.niche(lm, "Marble", "Shadow", Vector3(face - 2.8, y, z), nx, 1.0, 2.6, SEuParts.POINTED, 0.15, 0.15, false)
			SEuParts.figure(lm, "Statue", Vector3(face - 2.95, y, z), 2.0)
		SEuParts.pinnacle(lm, "Marble", Vector3(face - 1.0, h, z), 2.0, 14.0, "Statue")

## Tiburio, its gallery of pinnacles, the four lesser spires and the main
## openwork spire with the Madonnina.
static func _milan_spire(lm: LandmarkMesh) -> void:
	lm.frustum("Marble", Vector3(0, 44.0, 0), 15.5, 15.5, 22.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		SEuParts.niche(lm, "Marble", "Shadow", Vector3(0, 48.0, 0) + d * (15.5 * cos(PI / 8.0)), d, 3.6, 13.0,
			SEuParts.POINTED, 0.35)
		var ca := a + PI / 8.0
		var cd := Vector3(cos(ca), 0, sin(ca))
		lm.box("Marble", Vector3(0, 55.0, 0) + cd * 15.6, Vector3(1.8, 22.0, 1.8), Basis(Vector3.UP, -ca))
		SEuParts.pinnacle(lm, "Marble", Vector3(0, 66.0, 0) + cd * 15.6, 1.4, 12.0, "Statue")
	SEuParts.rail(lm, "Marble", Vector3(-6.0, 66.0, 14.3), Vector3(6.0, 66.0, 14.3), 1.2, 3.0)
	SEuParts.rail(lm, "Marble", Vector3(-6.0, 66.0, -14.3), Vector3(6.0, 66.0, -14.3), 1.2, 3.0)
	lm.frustum("Marble", Vector3(0, 66.0, 0), 9.6, 9.0, 12.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		SEuParts.niche(lm, "Marble", "Shadow", Vector3(0, 68.0, 0) + d * (9.3 * cos(PI / 8.0)), d, 2.2, 7.0,
			SEuParts.POINTED, 0.25)
	# Spire: octagonal needle with crocketed ribs and two balconies.
	lm.lathe("Marble", Vector3(0, 78.0, 0), PackedVector2Array([Vector2(8.0, 0), Vector2(5.4, 10.0),
		Vector2(2.2, 19.0), Vector2(0.35, 26.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	var prof := [Vector2(8.3, 0.0), Vector2(5.7, 10.0), Vector2(2.5, 19.0), Vector2(0.5, 25.6)]
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in 3:
			var p0: Vector2 = prof[j]
			var p1: Vector2 = prof[j + 1]
			lm.beam("Marble", Vector3(0, 78.0 + p0.y, 0) + d * p0.x, Vector3(0, 78.0 + p1.y, 0) + d * p1.x, 0.45, 0.45)
			for c in 3:
				var t := (float(c) + 0.5) / 3.0
				var q: Vector2 = p0.lerp(p1, t)
				lm.box("Marble", Vector3(0, 78.0 + q.y, 0) + d * (q.x + 0.3), Vector3(0.35, 0.5, 0.35), Basis(), 0.0)
	for y in [86.0, 95.0]:
		var rr: float = 5.4 if y < 90.0 else 3.6
		lm.frustum("Marble", Vector3(0, float(y), 0), rr + 1.0, rr + 1.0, 0.4, 16)
		for k in 16:
			var a := TAU * float(k) / 16.0
			lm.frustum("Marble", Vector3(cos(a) * (rr + 0.9), float(y) + 0.4, sin(a) * (rr + 0.9)), 0.08, 0.08, 1.0, 4)
	LandmarkKits.statue_figure(lm, "Gold", Vector3(0, 104.0, 0), 4.5, true)

# --- Florence -------------------------------------------------------------

## Santa Maria del Fiore, origin under the dome, facade west (-X): the
## nave of four great bays in white Carrara marble panelled with green
## Prato and red Maremma marble, with its pointed mullioned windows and
## side portals; the 19th-century neo-Gothic facade (De Fabris) of three
## gabled portals, rose windows, statue niches and the crowning gable;
## the three polygonal tribunes, each ringed by five chapels, and the
## four small exedrae round the octagonal drum with its eight oculi;
## Brunelleschi's double-shelled dome (54.8 m across) in red tile
## between eight white ribs; the lantern with its buttress volutes,
## cone, gilded ball and cross at 114.5 m; and Giotto's 84.7 m
## campanile by the south-west corner.
static func florence(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EAE5D9", 3.0))
	lm.use("Green", LandmarkMaterials.pbr("limestone", "#6E9078", 3.0))
	lm.use("Pink", LandmarkMaterials.pbr("limestone", "#D4A39B", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B4573B", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#8C8F8C", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4E4840", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	var along := Basis(Vector3.UP, PI * 0.5)
	# Nave and aisles, panelled in green between white pilasters.
	lm.box("Marble", Vector3(-61.0, 17.5, 0), Vector3(78.0, 35.0, 19.0))
	lm.gable("Tile", Vector3(-61.0, 35.0, 0), 19.0, 78.0, 6.0, along, 0.3)
	for s in [-1.0, 1.0]:
		var out := Vector3(0, 0, s)
		lm.box("Marble", Vector3(-61.0, 11.5, s * 14.25), Vector3(78.0, 23.0, 9.5))
		lm.gable("Tile", Vector3(-61.0, 23.0, s * 14.25), 9.5, 78.0, 2.4, along, 0.2)
		for k in 4:
			lm.box("Green", Vector3(-61.0, 4.0 + 5.0 * float(k), s * 19.03), Vector3(78.0, 0.6, 0.3))
		for k in 5:
			var x := -100.0 + 19.5 * float(k)
			lm.box("Marble", Vector3(x, 11.5, s * 19.25), Vector3(1.6, 23.0, 0.8))
			SEuParts.pinnacle(lm, "Marble", Vector3(x, 23.0, s * 19.25), 1.0, 3.6)
			lm.box("Marble", Vector3(x, 29.0, s * 9.75), Vector3(1.2, 12.0, 0.6))
		for k in 4:
			var xm := -90.25 + 19.5 * float(k)
			# Tall mullioned window in each bay, panels either side, oculi
			# in the clerestory.
			SEuParts.niche(lm, "Marble", "Shadow", Vector3(xm, 9.0, s * 19.1), out, 2.4, 11.0, SEuParts.POINTED, 0.35)
			lm.box("Marble", Vector3(xm, 13.0, s * 19.25), Vector3(0.16, 7.0, 0.16), Basis(), 0.0)
			for e in [-1.0, 1.0]:
				lm.box("Green", Vector3(xm + e * 5.5, 12.0, s * 19.06), Vector3(4.0, 7.0, 0.2))
				lm.box("Pink", Vector3(xm + e * 5.5, 12.0, s * 19.12), Vector3(2.6, 5.0, 0.2))
			lm.disc("Marble", Vector3(xm, 29.0, s * 9.55), out, 1.8, 16)
			lm.disc("Shadow", Vector3(xm, 29.0, s * 9.6), out, 1.4, 16)
			lm.box("Green", Vector3(xm, 29.0, s * 9.52), Vector3(17.0, 9.0, 0.1))
		# Side portals (Porta dei Canonici, Porta della Mandorla).
		SEuParts.niche(lm, "Marble", "Shadow", Vector3(-70.0, 0, s * 19.1), out, 2.6, 6.0, SEuParts.ROUND, 0.5, -1.0, false)
		lm.gable("Marble", Vector3(-70.0, 7.5, s * 19.6), 4.6, 1.0, 3.0, Basis(), 0.0, "Pink")
	# Octagonal tambour with oculi, the three tribunes and the four
	# exedrae, then the ribbed dome.
	lm.frustum("Marble", Vector3.ZERO, 29.66, 29.66, 55.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var out := Vector3(cos(a), 0, sin(a))
		var face := out * 27.4
		lm.disc("Marble", face + Vector3(0, 48.0, 0) + out * 0.05, out, 3.2, 20)
		lm.disc("Shadow", face + Vector3(0, 48.0, 0) + out * 0.1, out, 2.6, 20)
		lm.box("Green", face + Vector3(0, 42.0, 0), Vector3(22.0, 1.2, 0.2), Basis(Vector3.UP, atan2(out.x, out.z)))
		lm.box("Green", face + Vector3(0, 53.6, 0), Vector3(22.0, 0.8, 0.2), Basis(Vector3.UP, atan2(out.x, out.z)))
		for s in [-1.0, 1.0]:
			var rt := Vector3.UP.cross(out)
			lm.box("Pink", face + rt * 6.0 * s + Vector3(0, 48.0, 0), Vector3(3.4, 7.0, 0.2), Basis(Vector3.UP, atan2(out.x, out.z)))
		var ca := a + PI / 8.0
		lm.box("Marble", Vector3(cos(ca), 0, sin(ca)) * 29.6 + Vector3(0, 48.5, 0), Vector3(1.6, 13.0, 1.6),
			Basis(Vector3.UP, -ca))
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		var ec := d * 27.8 + Vector3(0, 34.0, 0)
		lm.frustum("Marble", ec, 4.2, 4.2, 6.0, 12)
		lm.lathe("Tile", ec + Vector3(0, 6.0, 0), SEuUtil.dome(4.4, 2.6, 4), 12)
		for i in 5:
			var b := TAU * float(i) / 10.0 + a - PI * 0.4
			SEuParts.col(lm, "Marble", ec + Vector3(cos(b), 0, sin(b)) * 4.4, 0.25, 5.4, "corinthian", 6)
	for p in [Vector3(26.0, 0, 0), Vector3(0, 0, 26.0), Vector3(0, 0, -26.0)]:
		var tc: Vector3 = p
		var away := tc.normalized()
		lm.frustum("Marble", tc, 17.5, 17.5, 30.0, 8, PI / 8.0)
		lm.spire("Tile", tc + Vector3(0, 30.0, 0), 16.2, 6.0, 0.0, 8)
		lm.frustum("Marble", tc + Vector3(0, 36.0, 0), 9.0, 8.4, 5.0, 8, PI / 8.0)
		lm.spire("Tile", tc + Vector3(0, 41.0, 0), 8.6, 3.5, 0.0, 8)
		lm.frustum("Marble", tc + Vector3(0, 44.5, 0), 2.0, 1.8, 3.0, 8, PI / 8.0)
		lm.lathe("Tile", tc + Vector3(0, 47.5, 0), SEuUtil.dome(2.0, 1.6, 4), 8)
		# Five radiating chapels round each tribune.
		for i in 5:
			var b := atan2(away.z, away.x) + (float(i) - 2.0) * PI / 4.0
			var d := Vector3(cos(b), 0, sin(b))
			var cc := tc + d * 17.0
			lm.frustum("Marble", cc, 5.0, 5.0, 16.0, 5, b + PI / 5.0)
			lm.spire("Tile", cc + Vector3(0, 16.0, 0), 4.6, 2.6, 0.0, 5)
			SEuParts.niche(lm, "Marble", "Shadow", cc + d * 4.1 + Vector3(0, 4.0, 0), d, 1.2, 7.0, SEuParts.POINTED, 0.2)
			lm.box("Green", cc + d * 4.15 + Vector3(0, 13.0, 0), Vector3(4.0, 0.6, 0.2), Basis(Vector3.UP, atan2(d.x, d.z)))
	var shell := SEuUtil.ogive(29.66, 36.5, 14)
	lm.lathe("Tile", Vector3(0, 55.0, 0), shell, 8, 1.0, 1.0, PI / 8.0, false)
	# The ballatoio (gallery) begun on one side only, and the eight ribs.
	lm.box("Marble", Vector3(0, 55.6, 0) + Vector3(cos(PI * 0.25), 0, sin(PI * 0.25)) * 28.2,
		Vector3(21.0, 1.2, 1.6), Basis(Vector3.UP, atan2(cos(PI * 0.25), sin(PI * 0.25))))
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		for j in shell.size() - 2:
			var r0 := shell[j].x / cos(PI / 8.0) * 1.0
			var r1 := shell[j + 1].x / cos(PI / 8.0) * 1.0
			lm.beam("Marble", Vector3(cos(a) * r0, 55.0 + shell[j].y, sin(a) * r0),
				Vector3(cos(a) * r1, 55.0 + shell[j + 1].y, sin(a) * r1), 1.8, 1.0)
		# Small oculi (lucarnes) in the tile between the ribs.
		var am := a + PI / 8.0
		var dm := Vector3(cos(am), 0, sin(am))
		for j in [4, 8]:
			var q := shell[j]
			lm.disc("Marble", dm * (q.x + 0.15) + Vector3(0, 55.0 + q.y, 0), dm + Vector3(0, 0.5, 0), 0.6, 8)
	lm.frustum("Marble", Vector3(0, 89.0, 0), 6.4, 6.0, 1.0, 8, PI / 8.0)
	# Lantern: octagonal core with arched windows, buttresses with
	# volutes at each corner, cornice, conical roof, ball and cross.
	lm.frustum("Marble", Vector3(0, 90.0, 0), 4.6, 4.4, 12.0, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Shadow", Vector3(0, 90.0, 0), 4.6, 8, 8, 2.5, 1.4, 7.5, false)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Marble", d * 7.0 + Vector3(0, 90.0, 0), d * 4.7 + Vector3(0, 99.0, 0), 0.9, 1.2, Vector3.UP.cross(d))
		lm.box("Marble", d * 5.0 + Vector3(0, 100.0, 0), Vector3(0.9, 3.0, 1.0), Basis(Vector3.UP, -a))
		lm.lathe("Marble", d * 6.8 + Vector3(0, 90.0, 0), SEuUtil.dome(0.7, 1.2, 3), 6)
	lm.frustum("Marble", Vector3(0, 102.0, 0), 5.6, 5.6, 0.8, 8, PI / 8.0)
	lm.lathe("Marble", Vector3(0, 102.8, 0), PackedVector2Array([Vector2(4.8, 0), Vector2(3.0, 2.0),
		Vector2(1.2, 5.0), Vector2(0.4, 6.4)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Gold", Vector3(0, 109.2, 0), PackedVector2Array([Vector2(0.0, 0), Vector2(0.9, 0.3),
		Vector2(1.2, 1.2), Vector2(0.9, 2.1), Vector2(0.0, 2.4)]), 12)
	lm.box("Gold", Vector3(0, 113.0, 0), Vector3(0.3, 3.0, 0.3))
	lm.box("Gold", Vector3(0, 113.6, 0), Vector3(0.3, 0.3, 1.6))
	_florence_facade(lm)
	_campanile(lm, Vector3(-92.0, 0, 31.0))
	lm.commit(model)

## De Fabris's neo-Gothic facade (1876-87): three gabled portals, the
## rose windows, statue niches between buttresses and the crowning gable.
static func _florence_facade(lm: LandmarkMesh) -> void:
	var along := Basis(Vector3.UP, PI * 0.5)
	var fx := -102.5
	lm.box("Marble", Vector3(fx, 18.0, 0), Vector3(5.0, 36.0, 40.0))
	lm.box("Marble", Vector3(fx, 23.0, 0), Vector3(5.0, 46.0, 20.0))
	lm.gable("Marble", Vector3(fx, 46.0, 0), 20.0, 5.0, 8.0, along, 0.0, "Marble")
	var face := fx - 2.5
	var nx := Vector3(-1, 0, 0)
	for k in 5:
		lm.box("Green" if k % 2 == 0 else "Pink", Vector3(face - 0.05, 8.0 + 8.0 * float(k), 0),
			Vector3(0.2, 0.8, 40.0 if k < 4 else 20.0))
	# Four buttress-piers with pinnacles and statue niches.
	for z in [-19.0, -9.5, 9.5, 19.0]:
		var h: float = 36.0 if absf(float(z)) > 15.0 else 46.0
		lm.box("Marble", Vector3(face - 0.6, h * 0.5, float(z)), Vector3(1.6, h, 2.0))
		SEuParts.pinnacle(lm, "Marble", Vector3(face - 0.6, h, float(z)), 1.6, 6.0)
		for j in 3:
			SEuParts.niche(lm, "Marble", "Green", Vector3(face - 1.4, 10.0 + 9.0 * float(j), float(z)), nx, 1.0, 2.8,
				SEuParts.POINTED, 0.2, 0.15, false)
			SEuParts.figure(lm, "Marble", Vector3(face - 1.55, 10.0 + 9.0 * float(j), float(z)), 2.2)
	# Portals: deep pointed doorways under gables with mosaic lunettes.
	for z in [-14.25, 0.0, 14.25]:
		var big: bool = absf(float(z)) < 1.0
		var w := 5.2 if big else 3.6
		var h := 12.0 if big else 9.0
		SEuParts.niche(lm, "Marble", "Shadow", Vector3(face, 0, float(z)), nx, w, h, SEuParts.POINTED, 0.8, 0.9, false)
		lm.gable("Marble", Vector3(face - 0.8, h + 0.4, float(z)), w + 2.4, 1.6, w * 0.9, along, 0.0, "Pink")
		lm.disc("Gold", Vector3(face - 0.85, h - w * 0.3, float(z)), nx, w * 0.32, 16)
		# Rose windows over the portals.
		var ry := 22.0 if big else 18.0
		var rr := 3.6 if big else 2.2
		lm.disc("Marble", Vector3(face - 0.05, ry, float(z)), nx, rr + 0.6, 24)
		lm.disc("Shadow", Vector3(face - 0.1, ry, float(z)), nx, rr, 24)
		for i in 8:
			var a := TAU * float(i) / 8.0
			lm.beam("Marble", Vector3(face - 0.15, ry, float(z)), Vector3(face - 0.15, ry + sin(a) * rr, float(z) + cos(a) * rr),
				0.18, 0.12)
	# Arcade of statues (Apostles and the Virgin) across the facade.
	for i in 13:
		var z := -9.0 + 18.0 * float(i) / 12.0
		SEuParts.niche(lm, "Marble", "Pink", Vector3(face, 28.0, z), nx, 1.2, 3.0, SEuParts.ROUND, 0.2, 0.12, false)
		SEuParts.figure(lm, "Marble", Vector3(face - 0.1, 28.0, z), 2.4)
	lm.disc("Gold", Vector3(face - 0.15, 40.0, 0), nx, 4.0, 20)
	SEuParts.figure(lm, "Marble", Vector3(face + 0.5, 54.0, 0), 3.0)

## Giotto's bell tower (1334-59): 14.45 m square, 84.7 m tall, octagonal
## corner buttresses; two lower storeys panelled with hexagonal and
## lozenge reliefs, a storey of statue niches, two storeys of paired
## two-light windows and the tall three-light belfry, banded in white,
## green and pink marble under a projecting cornice on corbels.
static func _campanile(lm: LandmarkMesh, c: Vector3) -> void:
	var w := 14.45
	lm.box("Marble", c + Vector3(0, 42.0, 0), Vector3(w, 84.0, w))
	lm.box("Marble", c + Vector3(0, 84.35, 0), Vector3(w + 1.4, 0.7, w + 1.4))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var f := c + out * (w * 0.5)
		for b in [4.0, 15.0, 26.0, 33.0, 46.0, 59.0, 82.0]:
			lm.box("Green", f + out * 0.1 + Vector3(0, float(b), 0), Vector3(w, 0.8, 0.2), r)
		# Corner buttress (octagonal in plan).
		lm.frustum("Marble", c + (out + right) * (w * 0.5) - Vector3(0, 0, 0), 1.1, 1.1, 84.0, 8, PI / 8.0)
		# Lower two storeys: hexagonal relief panels and lozenges.
		for i in 5:
			var x := -5.0 + 2.5 * float(i)
			lm.disc("Pink", f + right * x + Vector3(0, 9.5, 0) + out * 0.12, out, 0.9, 6)
			lm.box("Marble", f + right * x + Vector3(0, 20.5, 0) + out * 0.12, Vector3(1.1, 1.1, 0.12),
				r * Basis(Vector3.BACK, PI * 0.25), 0.0)
		# Statue niches.
		for i in 4:
			var x := -4.5 + 3.0 * float(i)
			SEuParts.niche(lm, "Marble", "Green", f + right * x + Vector3(0, 27.5, 0), out, 1.4, 4.4, SEuParts.POINTED, 0.25)
			SEuParts.figure(lm, "Marble", f + right * x + Vector3(0, 27.6, 0) + out * 0.1, 2.6)
		# Paired two-light windows on two storeys, the triple belfry.
		for y in [36.0, 49.0]:
			for s in [-1.0, 1.0]:
				SEuParts.niche(lm, "Marble", "Shadow", f + right * 2.6 * s + Vector3(0, float(y), 0), out, 2.2, 8.0,
					SEuParts.POINTED, 0.35)
				lm.box("Marble", f + right * 2.6 * s + Vector3(0, float(y) + 3.2, 0) + out * 0.2, Vector3(0.22, 6.4, 0.22), r, 0.0)
		SEuParts.niche(lm, "Marble", "Shadow", f + Vector3(0, 61.0, 0), out, 6.0, 18.0, SEuParts.POINTED, 0.5)
		for m in 2:
			lm.box("Marble", f + right * (-1.0 + 2.0 * float(m)) + Vector3(0, 69.0, 0) + out * 0.25, Vector3(0.3, 16.0, 0.3), r, 0.0)
		# Corbelled cornice under the terrace parapet.
		for i in 10:
			lm.box("Marble", f + right * (-6.3 + 1.4 * float(i)) + Vector3(0, 83.3, 0) + out * 0.35,
				Vector3(0.4, 1.0, 0.7), r, 0.0)

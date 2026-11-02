class_name LandmarkRmAArches
extends RefCounted

## The Arch of Constantine, the Arch of Titus and the Porta Maggiore in
## true metres, each facing +Z with its passage along Z (yaw_deg turns
## it onto the real bearing).

# --- Arch of Constantine --------------------------------------------

## 25.9 x 7.4 m, 21 m high: three barrel-vaulted passages (6.5 and 3.4 m
## wide, 11.5 and 7.4 m to the crown) with moulded imposts, archivolts,
## keystones and coffered soffits; Victories in the central spandrels;
## eight fluted giallo antico Corinthian columns on sculpted pedestals,
## pilasters behind them and the entablature breaking forward over each;
## the Constantinian frieze over the side passages and on the ends, the
## eight Hadrianic tondi on porphyry fields (Sol and Luna on the ends);
## the attic with the Dacian captives over the columns, the seven-line
## dedication and the eight Aurelian panels, Trajanic panels on the ends
## and in the central passage.
static func constantine(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#CFC6B0", 3.0))
	lm.use("Giallo", LandmarkMaterials.pbr("limestone", "#C9A862", 2.0))
	lm.use("Soffit", LandmarkMaterials.pbr("stone", "#7B715F", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#A99D85", 2.0))
	lm.use("Porphyry", LandmarkMaterials.pbr("stone", "#6E4442", 2.0))
	var w := 25.9
	var d := 7.4
	var hw := w * 0.5
	var hd := d * 0.5
	var passages := [[-8.45, 3.4, 5.7], [0.0, 6.5, 8.25], [8.45, 3.4, 5.7]]
	var opens: Array = []
	for p in passages:
		opens.append([p[0], p[1], p[2], 0.0])
	RmAUtil.arch_wall(lm, "Marble", "Soffit", Vector3(0, 0, hd), Vector3.RIGHT, Vector3.BACK,
		-hw, hw, 0.0, 14.4, opens, d, 12)
	# Socles under the piers, imposts, archivolts and coffered soffits.
	for px in [[-11.55, 2.8], [-5.0, 3.5], [5.0, 3.5], [11.55, 2.8]]:
		lm.box("Marble", Vector3(float(px[0]), 0.4, 0), Vector3(float(px[1]) + 0.3, 0.8, d + 0.3))
	for p in passages:
		var cx: float = p[0]
		var pw: float = p[1]
		var spring: float = p[2]
		for s in [-1.0, 1.0]:
			lm.box("Marble", Vector3(cx + float(s) * (pw * 0.5 - 0.06), spring - 0.22, 0),
				Vector3(0.3, 0.44, d + 0.24))
		for sz in [-1.0, 1.0]:
			LandmarkDetail.arch(lm, "Marble", Vector3(cx, spring, sz * hd), Vector3(0, 0, sz), pw,
				0.55 if pw > 5.0 else 0.4, 0.2)
		RmAUtil.barrel_vault(lm, "Marble", "Soffit", Vector3(cx, spring, hd), Vector3(0, 0, -1),
			Vector3.RIGHT, d, pw - 0.1, pw * 0.5 - 0.05, 0.02, 5 if pw > 5.0 else 3, 4, 12)
	# Trajanic battle panels on the walls of the central passage.
	for s in [-1.0, 1.0]:
		var jx: float = float(s) * 3.25
		RmADetail.panel(lm, "Marble", "Relief", Vector3(jx, 4.6, 0), Vector3(-s, 0, 0), 5.2, 3.0)
		RmADetail.figure_row(lm, "Relief", Vector3(jx - float(s) * 0.12, 3.25, -2.3),
			Vector3(jx - float(s) * 0.12, 3.25, 2.3), Vector3(-s, 0, 0), 2.5, 7)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		var face: float = sz * hd
		# Columns on pedestals, pilasters behind, the entablature ressauts.
		for cx in [-11.55, -5.0, 5.0, 11.55]:
			var x: float = cx
			var zf: float = sz * (hd + 0.95)
			RmADetail.pedestal(lm, "Marble", Vector3(x, 0.8, zf), 1.9, 1.9, 2.2)
			RmADetail.panel(lm, "Marble", "Relief", Vector3(x, 1.9, zf + sz * 0.95), n, 1.4, 1.1, 0.06, 0.12)
			RmADetail.relief_figure(lm, "Relief", Vector3(x - 0.3, 1.4, zf + sz * 1.0), n, 1.0)
			RmADetail.relief_figure(lm, "Relief", Vector3(x + 0.3, 1.4, zf + sz * 1.0), n, 0.95)
			LandmarkDetail.column(lm, "Giallo", Vector3(x, 3.0, zf), 0.55, 9.0, "corinthian", 24)
			lm.box("Marble", Vector3(x, 7.5, face + sz * 0.1), Vector3(1.0, 9.0, 0.2))
			lm.box("Marble", Vector3(x, 13.2, sz * (hd + 0.85)), Vector3(1.9, 2.4, 1.7))
			LandmarkDetail.cornice(lm, "Marble", Vector3(x - 0.95, 13.7, sz * (hd + 1.7)),
				Vector3(x + 0.95, 13.7, sz * (hd + 1.7)), n, 0.7, true)
			# Attic projection with the Dacian captive on its plinth.
			lm.box("Marble", Vector3(x, 14.85, sz * (hd + 0.85)), Vector3(1.8, 0.9, 1.7))
			lm.box("Marble", Vector3(x, 17.8, sz * (hd - 0.15)), Vector3(1.9, 5.0, 0.5))
			LandmarkKits.statue_figure(lm, "Marble", Vector3(x, 15.3, zf), 3.0)
		# Main cornice and the architrave fasciae between the ressauts.
		LandmarkDetail.cornice(lm, "Marble", Vector3(-hw, 13.7, face), Vector3(hw, 13.7, face), n, 0.7, true)
		for k in 2:
			lm.box("Marble", Vector3(0, 12.25 + 0.42 * float(k), face + sz * 0.05), Vector3(w, 0.36, 0.1))
		# Spandrel Victories over the central passage.
		for s in [-1.0, 1.0]:
			var vx: float = float(s) * 4.4
			RmADetail.victory(lm, "Relief", Vector3(vx, 10.6, face + sz * 0.15), n,
				-float(s) * signf(Vector3.UP.cross(n).x), 2.4)
		# Side bays: Constantinian frieze, tondi on porphyry fields.
		for sx in [-8.45, 8.45]:
			var bx: float = sx
			lm.box("Relief", Vector3(bx, 8.45, face + sz * 0.05), Vector3(5.4, 0.95, 0.1))
			RmADetail.figure_row(lm, "Relief", Vector3(bx - 2.6, 8.0, face + sz * 0.1),
				Vector3(bx + 2.6, 8.0, face + sz * 0.1), n, 0.85, 16)
			lm.box("Porphyry", Vector3(bx, 10.75, face + sz * 0.04), Vector3(5.6, 2.8, 0.08))
			for t in [-1.0, 1.0]:
				RmADetail.tondo(lm, "Relief", "Soffit", Vector3(bx + float(t) * 1.4, 10.75, face + sz * 0.08), n, 1.15)
		# Attic: base moulding, the inscription and the Aurelian panels.
		var af: float = sz * (hd - 0.4)
		RmADetail.panel(lm, "Marble", "Marble", Vector3(0, 17.8, af), n, 7.4, 3.8, 0.1, 0.3)
		RmADetail.inscription(lm, "Soffit", Vector3(0, 17.8, af + sz * 0.1), n, 6.8, 3.4, 7, sz)
		for px in [-9.6, -7.0, 7.0, 9.6]:
			var pc := Vector3(float(px), 17.75, af)
			RmADetail.panel(lm, "Marble", "Relief", pc, n, 2.3, 3.1, 0.08, 0.18)
			RmADetail.figure_row(lm, "Relief", pc + Vector3(-1.0, -1.35, sz * 0.1),
				pc + Vector3(1.0, -1.35, sz * 0.1), n, 2.4, 3)
	# The ends: frieze, Sol / Luna tondi and the Trajanic attic panels.
	for sx in [-1.0, 1.0]:
		var n := Vector3(sx, 0, 0)
		var ex: float = sx * hw
		lm.box("Relief", Vector3(ex + sx * 0.05, 8.45, 0), Vector3(0.1, 0.95, d))
		RmADetail.figure_row(lm, "Relief", Vector3(ex + sx * 0.1, 8.0, -hd + 0.2),
			Vector3(ex + sx * 0.1, 8.0, hd - 0.2), n, 0.85, 14)
		lm.box("Porphyry", Vector3(ex + sx * 0.04, 10.75, 0), Vector3(0.08, 2.8, 3.6))
		RmADetail.tondo(lm, "Relief", "Soffit", Vector3(ex + sx * 0.08, 10.75, 0), n, 1.15)
		LandmarkDetail.cornice(lm, "Marble", Vector3(ex, 13.7, -hd), Vector3(ex, 13.7, hd), n, 0.7, true)
		var ax: float = sx * (hw - 0.4)
		RmADetail.panel(lm, "Marble", "Relief", Vector3(ax, 17.8, 0), n, 5.4, 3.3, 0.1, 0.22)
		RmADetail.figure_row(lm, "Relief", Vector3(ax + sx * 0.12, 16.3, -2.4),
			Vector3(ax + sx * 0.12, 16.3, 2.4), n, 2.6, 6)
	# Attic body, its base moulding, crowning cornice and roof.
	lm.box("Marble", Vector3(0, 14.85, 0), Vector3(w + 0.6, 0.9, d + 0.6))
	lm.box("Marble", Vector3(0, 17.8, 0), Vector3(w - 0.8, 5.0, d - 0.8))
	var ahw := hw - 0.4
	var ahd := hd - 0.4
	var corners := [Vector3(-ahw, 20.3, ahd), Vector3(ahw, 20.3, ahd), Vector3(ahw, 20.3, -ahd), Vector3(-ahw, 20.3, -ahd)]
	var outs := [Vector3.BACK, Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT]
	for k in 4:
		LandmarkDetail.cornice(lm, "Marble", corners[k], corners[(k + 1) % 4], outs[k], 0.7, true)
	lm.box("Marble", Vector3(0, 20.65, 0), Vector3(w - 0.8, 0.7, d - 0.8))
	lm.commit(model)

# --- Arch of Titus --------------------------------------------------

## 13.5 x 4.75 m, 15.4 m high, one 5.36 x 8.3 m passage: four Composite
## half-columns a face on pedestals (the fluted marble pair by the
## passage original, the plain outer pair Valadier's travertine of
## 1821), blind aedicule windows between them, archivolt with the
## figured keystone and spandrel Victories, the small triumph frieze and
## the entablature broken over the columns, the attic with the
## dedication (four lines), and in the passage the coffered vault with
## Titus' apotheosis and the two Jerusalem reliefs.
static func titus(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#CDBFA3", 3.0))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#C4B592", 3.0))
	lm.use("Soffit", LandmarkMaterials.pbr("stone", "#76695A", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#A99D85", 2.0))
	var w := 13.5
	var d := 4.75
	var hw := w * 0.5
	var hd := d * 0.5
	var spring := 5.62
	RmAUtil.arch_wall(lm, "Marble", "Soffit", Vector3(0, 0, hd), Vector3.RIGHT, Vector3.BACK,
		-4.3, 4.3, 0.0, 9.0, [[0.0, 5.36, spring, 0.0]], d, 12)
	for s in [-1.0, 1.0]:
		RmAUtil.arch_wall(lm, "Travertine", "Soffit", Vector3(0, 0, hd), Vector3.RIGHT, Vector3.BACK,
			-hw if s < 0.0 else 4.3, -4.3 if s < 0.0 else hw, 0.0, 9.0, [], d, 4)
		lm.box("Marble", Vector3(float(s) * 2.62, spring - 0.2, 0), Vector3(0.24, 0.4, d + 0.2))
		lm.box("Travertine", Vector3(float(s) * 4.7, 0.5, 0), Vector3(4.2, 1.0, d + 0.3))
	RmAUtil.barrel_vault(lm, "Marble", "Soffit", Vector3(0, spring, hd), Vector3(0, 0, -1),
		Vector3.RIGHT, d, 5.26, 2.63, 0.02, 7, 4, 14)
	lm.box("Relief", Vector3(0, spring + 2.52, 0), Vector3(1.5, 0.08, 1.5), Basis(), 0.0)
	# The Jerusalem reliefs: spoils of the Temple (south), the triumph (north).
	for s in [-1.0, 1.0]:
		var jx: float = float(s) * 2.68
		RmADetail.panel(lm, "Marble", "Relief", Vector3(jx, 3.9, 0), Vector3(-s, 0, 0), 3.8, 2.0, 0.08, 0.18)
		RmADetail.figure_row(lm, "Relief", Vector3(jx - float(s) * 0.1, 2.95, -1.7),
			Vector3(jx - float(s) * 0.1, 2.95, 1.7), Vector3(-s, 0, 0), 1.8, 8)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		var face: float = sz * hd
		LandmarkDetail.arch(lm, "Marble", Vector3(0, spring, face), n, 5.36, 0.45, 0.2)
		RmADetail.relief_figure(lm, "Relief", Vector3(0, 8.15, face + sz * 0.3), n, 0.75)
		for s in [-1.0, 1.0]:
			RmADetail.victory(lm, "Relief", Vector3(float(s) * 2.4, 7.9, face + sz * 0.22), n,
				-float(s) * signf(Vector3.UP.cross(n).x), 1.5)
		for cx in [-5.85, -3.53, 3.53, 5.85]:
			var x: float = cx
			var inner := absf(x) < 4.0
			var key := "Marble" if inner else "Travertine"
			var zc: float = face + sz * 0.12
			RmADetail.pedestal(lm, key, Vector3(x, 1.0, zc + sz * 0.15), 1.2, 0.9, 1.5)
			LandmarkDetail.column(lm, key, Vector3(x, 2.5, zc), 0.42, 6.5, "corinthian", 24 if inner else 0)
			# Volutes of the Composite capital over the acanthus.
			for vs in [-1.0, 1.0]:
				lm.lathe(key, Vector3(x + float(vs) * 0.42, 8.55, zc + sz * 0.35), PackedVector2Array([
					Vector2(0.0, 0.0), Vector2(0.14, 0.02), Vector2(0.17, 0.12), Vector2(0.0, 0.16)]), 8)
			lm.box(key, Vector3(x, 9.5, face + sz * 0.3), Vector3(1.1, 1.0, 0.6))
			LandmarkDetail.cornice(lm, key, Vector3(x - 0.55, 10.3, face + sz * 0.6),
				Vector3(x + 0.55, 10.3, face + sz * 0.6), n, 0.7, true)
		# Blind aedicule windows on the piers between the columns.
		for s in [-1.0, 1.0]:
			LandmarkDetail.window(lm, "Travertine", "Soffit", Vector3(float(s) * 4.69, 6.7, face), n,
				0.8, 1.5, false, 0.18)
		# Entablature: fasciae, the triumph frieze, cornice.
		for k in 3:
			lm.box("Marble", Vector3(0, 9.1 + 0.18 * float(k), face + sz * (0.02 + 0.03 * float(k))),
				Vector3(w, 0.18, 0.06))
		lm.box("Relief", Vector3(0, 9.9, face + sz * 0.04), Vector3(6.4, 0.6, 0.08))
		RmADetail.figure_row(lm, "Relief", Vector3(-3.1, 9.62, face + sz * 0.08), Vector3(3.1, 9.62, face + sz * 0.08),
			n, 0.55, 22)
		LandmarkDetail.cornice(lm, "Marble", Vector3(-hw, 10.3, face), Vector3(hw, 10.3, face), n, 0.7, true)
		# Attic: projections over the column pairs, the dedication.
		var af: float = sz * (hd - 0.25)
		for s in [-1.0, 1.0]:
			lm.box("Travertine", Vector3(float(s) * 4.7, 12.85, af + sz * 0.2), Vector3(3.4, 3.7, 0.4))
		RmADetail.panel(lm, "Marble", "Marble", Vector3(0, 12.9, af), n, 5.6, 2.8, 0.08, 0.25)
		RmADetail.inscription(lm, "Soffit", Vector3(0, 12.9, af + sz * 0.08), n, 5.0, 2.4, 4, sz)
	for sx in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "Marble", Vector3(sx * hw, 10.3, -hd), Vector3(sx * hw, 10.3, hd),
			Vector3(sx, 0, 0), 0.7, true)
	lm.box("Marble", Vector3(0, 9.0 + 0.05, 0), Vector3(w + 0.1, 0.1, d + 0.1))
	lm.box("Marble", Vector3(0, 10.15, 0), Vector3(w, 2.3, d))
	lm.box("Marble", Vector3(0, 11.3, 0), Vector3(w + 0.2, 0.5, d + 0.2))
	lm.box("Travertine", Vector3(0, 12.85, 0), Vector3(w - 0.5, 3.7, d - 0.5))
	var ahw := hw - 0.25
	var ahd := hd - 0.25
	var corners := [Vector3(-ahw, 14.7, ahd), Vector3(ahw, 14.7, ahd), Vector3(ahw, 14.7, -ahd), Vector3(-ahw, 14.7, -ahd)]
	var outs := [Vector3.BACK, Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT]
	for k in 4:
		LandmarkDetail.cornice(lm, "Marble", corners[k], corners[(k + 1) % 4], outs[k], 0.7, true)
	lm.box("Travertine", Vector3(0, 15.05, 0), Vector3(w - 0.5, 0.7, d - 0.5))
	lm.commit(model)

# --- Porta Maggiore -------------------------------------------------

## Claudius' double arch of rusticated travertine (AD 52) carrying the
## Aqua Claudia and the Anio Novus: two 5.8 m passages with archivolts,
## three aedicules on the piers (rusticated half-columns, pediments,
## arched windows), the attic in three inscribed bands (Claudius 52,
## Vespasian 71, Titus 81) with the two channels showing in section at
## the ends, the brick stubs of the Aurelian Wall with its merlons, and
## outside the gate the Tomb of Eurysaces the baker (c. 30 BC), with
## its grain-measure cylinders, kneading-trough mouths and baking frieze.
static func porta_maggiore(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Rustic", LandmarkMaterials.pbr("stone", "#B7AA8C", 2.5))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#CFC4A5", 3.0))
	lm.use("Soffit", LandmarkMaterials.pbr("stone", "#6C6252", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#94684C", 2.5))
	var d := 5.6
	var hd := d * 0.5
	var hw := 12.1
	RmAUtil.arch_wall(lm, "Rustic", "Soffit", Vector3(0, 0, hd), Vector3.RIGHT, Vector3.BACK,
		-hw, hw, 0.0, 13.2, [[-4.8, 5.8, 5.1, 0.0], [4.8, 5.8, 5.1, 0.0]], d, 12)
	for cx in [-4.8, 4.8]:
		for s in [-1.0, 1.0]:
			lm.box("Travertine", Vector3(float(cx) + float(s) * 2.86, 4.9, 0), Vector3(0.36, 0.4, d + 0.3))
		for sz in [-1.0, 1.0]:
			LandmarkDetail.arch(lm, "Rustic", Vector3(float(cx), 5.1, sz * hd), Vector3(0, 0, sz), 5.8, 0.8, 0.3)
	lm.box("Travertine", Vector3(0, 13.5, 0), Vector3(hw * 2.0 + 0.8, 0.7, d + 0.6))
	# Attic: three inscribed bands over the two stacked channels.
	for k in 3:
		var y: float = 14.6 + 1.9 * float(k)
		lm.box("Travertine", Vector3(0, y, 0), Vector3(hw * 2.0 - 0.6, 1.5, d - 0.6))
		lm.box("Travertine", Vector3(0, y + 0.85, 0), Vector3(hw * 2.0 - 0.2, 0.3, d - 0.2))
		for sz in [-1.0, 1.0]:
			RmADetail.inscription(lm, "Soffit", Vector3(0, y, sz * (hd - 0.3)), Vector3(0, 0, sz),
				hw * 2.0 - 3.0, 1.2, 2, float(k) + sz)
		for sx in [-1.0, 1.0]:
			if k > 0:
				lm.box("Soffit", Vector3(sx * (hw - 0.28), y - 0.1, 0), Vector3(0.08, 1.0, 1.4))
	lm.box("Travertine", Vector3(0, 18.7, 0), Vector3(hw * 2.0 + 0.4, 0.5, d + 0.4))
	lm.box("Travertine", Vector3(0, 19.0, 0), Vector3(hw * 2.0 - 0.4, 0.2, d - 0.4))
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		var zf: float = sz * hd
		for k in 3:
			var tx: float = -9.6 + 9.6 * float(k)
			var big := k == 1
			RmADetail.niche(lm, "Rustic", "Soffit", Vector3(tx, 6.4, zf), n, 1.5 if big else 1.3,
				1.9, 0.35, 0.35)
			for s in [-1.0, 1.0]:
				RmADetail.rustic_column(lm, "Rustic", Vector3(tx + float(s) * 1.35, 5.6, zf + sz * 0.3), 0.32, 4.0, 6)
			lm.box("Travertine", Vector3(tx, 9.8, zf + sz * 0.35), Vector3(3.4, 0.4, 0.7))
			RmAUtil.pediment(lm, "Travertine", Vector3(tx, 10.0, zf + sz * 0.35), Vector3.RIGHT,
				n, 3.6, 1.0 if not big else 1.3, 0.6)
			lm.box("Travertine", Vector3(tx, 5.45, zf + sz * 0.35), Vector3(3.4, 0.3, 0.7))
	# The Aurelian Wall either side with its wall-walk merlons.
	for sx in [-1.0, 1.0]:
		RmAUtil.ruin_wall(lm, "Brick", Vector3(sx * (hw + 1.9), 0, 0), Vector3(sx * (hw + 15.0), 0, 0),
			3.8, 0.0, 6.0, 10.5, 1.8, sx)
		lm.box("Brick", Vector3(sx * (hw + 1.9), 6.0, 0), Vector3(3.8, 12.0, 3.8))
		RmADetail.merlons(lm, "Brick", Vector3(sx * (hw + 0.2), 12.0, 1.6), Vector3(sx * (hw + 3.6), 12.0, 1.6),
			0.8, 1.4, 0.6)
	_eurysaces(lm, Vector3(0, 0, 14.0))
	lm.commit(model)

## Tomb of Eurysaces, about 8.5 x 5 m and 9 m high on its plinth: the
## lower storey of paired upright cylinders (grain measures), the
## inscription band, the upper storey of round mouths in rows (kneading
## machines) and the bakery frieze under the cornice.
static func _eurysaces(lm: RmAMesh, c: Vector3) -> void:
	var w := 8.4
	var d := 5.0
	lm.box("Travertine", c + Vector3(0, 0.6, 0), Vector3(w + 0.4, 1.2, d + 0.4))
	lm.box("Travertine", c + Vector3(0, 3.0, 0), Vector3(w - 0.4, 3.6, d - 0.4))
	lm.box("Travertine", c + Vector3(0, 5.15, 0), Vector3(w, 0.7, d))
	lm.box("Travertine", c + Vector3(0, 7.1, 0), Vector3(w - 0.3, 3.2, d - 0.3))
	lm.box("Travertine", c + Vector3(0, 8.9, 0), Vector3(w + 0.3, 0.4, d + 0.3))
	for f in 4:
		var a := PI * 0.5 * float(f)
		var out := Vector3(sin(a), 0, cos(a))
		var right := Vector3.UP.cross(out)
		var half: float = (d if f % 2 == 0 else w) * 0.5
		var span: float = (w if f % 2 == 0 else d) - 1.0
		var n := int(span / 1.1)
		for i in n:
			var x := -span * 0.5 + span * (float(i) + 0.5) / float(n)
			lm.frustum("Travertine", c + out * (half - 0.1) + right * x + Vector3(0, 1.2, 0), 0.38, 0.38, 3.6, 12)
			for row in 2:
				var mc := c + out * (half - 0.15) + right * x + Vector3(0, 6.3 + 1.3 * float(row), 0)
				lm.disc("Soffit", mc + out * 0.02, out, 0.36, 12)
				RmADetail.ring_frame(lm, "Travertine", mc, out, 0.44, 0.14, 0.18, 12)
		RmADetail.inscription(lm, "Soffit", c + out * half + Vector3(0, 5.15, 0), out, span, 0.5, 1, float(f))
		RmADetail.figure_row(lm, "Travertine", c + out * (half - 0.15) - right * span * 0.5 + Vector3(0, 8.15, 0),
			c + out * (half - 0.15) + right * span * 0.5 + Vector3(0, 8.15, 0), out, 0.6, n * 2)

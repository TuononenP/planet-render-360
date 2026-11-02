class_name LandmarkLpJerash
extends RefCounted

## Roman Gerasa (Jerash) in true metres: the Oval Plaza with the start of
## the Cardo Maximus, and Hadrian's Arch south of the city.

# --- Jerash, Oval Plaza and Cardo ---

## Plaza centre (0, 0, 20): the 90 x 80 m oval paved forum ringed by 56
## unfluted Ionic columns (5.8 m) on a stepped stylobate, carrying an
## unbroken architrave, with the central altar podium, and the Cardo
## Maximus (805 m long) leaving north (-Z) between two Corinthian
## colonnades (10 m, entablature to 11.5 m), raised walks and the arched
## shopfronts behind them. Built along the Cardo axis; yaw turns it onto
## its NNW bearing.
static func jerash_plaza(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DCC9A2", 4.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#C9B791", 5.0))
	lm.use("Rubble", LandmarkMaterials.pbr("stone", "#B49A72", 5.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2218", 3.0, 0.92))
	var cz := 20.0
	var ea := 40.0
	var eb := 45.0
	var floor_poly := PackedVector2Array()
	for i in 56:
		var t := TAU * float(i) / 56.0
		floor_poly.append(Vector2(cos(t) * (ea + 4.0), cz + sin(t) * (eb + 4.0)))
	lm.poly_prism("Paving", floor_poly, 0.0, 0.15)
	lm.box("Paving", Vector3(0, 0.075, -50.0), Vector3(30, 0.15, 44), Basis(), 0.0)
	# Central podium (altar base) with its moulded plinth and cornice.
	lm.box("Stone", Vector3(0, 0.45, cz), Vector3(6.0, 0.6, 6.0))
	lm.box("Stone", Vector3(0, 1.45, cz), Vector3(5.0, 1.6, 5.0))
	lm.box("Stone", Vector3(0, 2.4, cz), Vector3(5.6, 0.35, 5.6))
	# Colonnade: stylobate steps under each column, Ionic order, architrave.
	var pos := PackedVector3Array()
	var keep: Array[bool] = []
	for i in 56:
		var t := TAU * float(i) / 56.0
		var p := Vector3(cos(t) * ea, 0.15, cz + sin(t) * eb)
		var gap := p.z < cz - eb * 0.86 and absf(p.x) < 14.0
		pos.append(p)
		keep.append(not gap)
	for i in 56:
		var j := (i + 1) % 56
		if keep[i] and keep[j]:
			var a := pos[i]
			var b := pos[j]
			var side := (b - a).cross(Vector3.UP)
			lm.beam("Stone", a + Vector3(0, 0.2, 0), b + Vector3(0, 0.2, 0), 2.4, 0.4, side)
			lm.beam("Stone", a + Vector3(0, 0.5, 0), b + Vector3(0, 0.5, 0), 1.6, 0.25, side)
			# Architrave in two fasciae with a crowning moulding.
			var top := Vector3(0, 0.6 + 5.8, 0)
			lm.beam("Stone", a + top + Vector3(0, 0.3, 0), b + top + Vector3(0, 0.3, 0), 0.85, 0.6, side)
			lm.beam("Stone", a + top + Vector3(0, 0.75, 0), b + top + Vector3(0, 0.75, 0), 0.95, 0.4, side)
			lm.beam("Stone", a + top + Vector3(0, 1.05, 0), b + top + Vector3(0, 1.05, 0), 1.15, 0.2, side)
	for i in 56:
		if keep[i]:
			LandmarkDetail.column(lm, "Stone", pos[i] + Vector3(0, 0.6, 0), 0.4, 5.8, "ionic", 0)
	# Cardo: two Corinthian colonnades on raised walks, entablature, shopfronts.
	for s in [-1.0, 1.0]:
		var x := float(s) * 7.5
		lm.box("Stone", Vector3(x + float(s) * 2.2, 0.3, -50.0), Vector3(5.4, 0.3, 42.0))
		for i in 8:
			LandmarkDetail.column(lm, "Stone", Vector3(x, 0.45, -30.0 - 38.0 * float(i) / 7.0), 0.45, 9.55,
				"corinthian", 0)
		var ey := 10.0
		lm.box("Stone", Vector3(x, ey + 0.35, -49.0), Vector3(1.1, 0.7, 40.0))
		lm.box("Stone", Vector3(x, ey + 0.85, -49.0), Vector3(1.0, 0.3, 40.0))
		LandmarkDetail.cornice(lm, "Stone", Vector3(x - float(s) * 0.5, ey + 1.0, -69.0), Vector3(x - float(s) * 0.5, ey + 1.0, -29.0),
			Vector3(-float(s), 0, 0), 0.5, false)
		var yaw := -float(s) * PI * 0.5
		var shop := LandmarkLpDetail.bays(8, 40.0, 1.3, 2.4)
		lm.box("Rubble", Vector3(float(s) * 13.6, 2.6, -49.0), Vector3(4.0, 5.2, 40.0))
		LandmarkLpDetail.arcade_skin(lm, "Rubble", "Dark", Vector3(float(s) * 11.0, 0.45, -49.0), yaw, 40.0, 4.75,
			shop, 0.6)
		for k in 9:
			lm.box("Stone", Vector3(float(s) * 10.85, 0.45 + 2.45, -69.0 + 5.0 * float(k)), Vector3(0.4, 4.9, 0.8))
	lm.box("Paving", Vector3(0, 0.2, -49.0), Vector3(0.6, 0.1, 40.0), Basis(), 0.0)
	lm.commit(model)

# --- Jerash, Hadrian's Arch ---

## Triple-arched gateway of AD 129-130, reconstructed 2005-2007 to about
## 21 m: 37.45 x 9.25 m with the lower end pavilions. The central passage
## (6 m wide, 11 m high) and two lower side passages; four engaged
## Corinthian columns on each face on 2.2 x 2.25 x 1.2 m pedestals, their
## bases crowned with a row of acanthus leaves; aedicule niches over the
## side arches; the attic with its acanthus frieze and the triangular
## pediment over the centre. Faces the road (north-south).
static func hadrians_arch(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9C49A", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2218", 3.0, 0.92))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#BFAE8A", 5.0))
	lm.box("Paving", Vector3(0, 0.1, 0), Vector3(46, 0.2, 24), Basis(), 0.0)
	var depth := 9.25
	var core := 25.0
	var eh := 13.4
	var arches := [[-8.6, 1.65, 5.0, 1.65], [0.0, 3.0, 8.0, 3.0], [8.6, 1.65, 5.0, 1.65]]
	LandmarkLpParts.slab(lm, "Stone", LandmarkLpParts.arcade_outline(core, eh, arches, 10),
		Vector3(0, 0.2, depth * 0.5), 0.0, depth)
	# Imposts and the archivolts on both faces.
	for fz in [-1.0, 1.0]:
		var zf := float(fz) * depth * 0.5
		for ar in arches:
			var cx: float = ar[0]
			var a: float = ar[1]
			var sp: float = ar[2]
			LandmarkDetail.arch(lm, "Stone", Vector3(cx, 0.2 + sp, zf), Vector3(0, 0, float(fz)), a * 2.0, 0.6, 0.25)
			for s in [-1.0, 1.0]:
				lm.box("Stone", Vector3(cx + float(s) * (a + 0.25), 0.2 + sp - 0.2, zf + float(fz) * 0.12),
					Vector3(0.9, 0.4, 0.3))
	# End pavilions: lower blocks with a blind niche and corner pilasters.
	for sx in [-1.0, 1.0]:
		var wx := float(sx) * (core * 0.5 + 3.1)
		lm.box("Stone", Vector3(wx, 0.2 + 5.2, 0), Vector3(6.2, 10.4, depth))
		lm.box("Stone", Vector3(wx, 0.2 + 10.7, 0), Vector3(6.8, 0.6, depth + 0.6))
		for fz in [-1.0, 1.0]:
			var zf := float(fz) * depth * 0.5
			LandmarkLpParts.arch_panel(lm, "Dark", Vector3(wx, 2.6, zf + float(fz) * 0.04), 0.0 if fz > 0.0 else PI,
				1.0, 2.6, 1.0)
			LandmarkDetail.arch(lm, "Stone", Vector3(wx, 5.2, zf), Vector3(0, 0, float(fz)), 2.0, 0.35, 0.15)
			for s in [-1.0, 1.0]:
				lm.box("Stone", Vector3(wx + float(s) * 2.7, 0.2 + 5.0, zf + float(fz) * 0.15), Vector3(0.7, 10.0, 0.3))
	# Columns on pedestals, acanthus-leaf bases, niches over the side arches.
	for fz in [-1.0, 1.0]:
		var zf := float(fz) * depth * 0.5
		var zc := zf + float(fz) * 0.4
		for x in [-11.6, -5.2, 5.2, 11.6]:
			lm.box("Stone", Vector3(x, 0.2 + 1.1, zf + float(fz) * 0.5), Vector3(2.25, 2.2, 1.2))
			lm.box("Stone", Vector3(x, 0.2 + 2.1, zf + float(fz) * 0.55), Vector3(2.45, 0.25, 1.35))
			var cb := Vector3(x, 2.4, zc)
			LandmarkDetail.column(lm, "Stone", cb, 0.55, 9.4, "corinthian", 0)
			for k in 10:
				var a := TAU * float(k) / 10.0
				var d := Vector3(cos(a), 0, sin(a))
				var lb := cb + d * 0.6 + Vector3(0, 0.5, 0)
				lm.beam("Stone", lb, lb + d * 0.22 + Vector3(0, 0.75, 0), 0.32, 0.08, d.cross(Vector3.UP))
		for sx in [-1.0, 1.0]:
			var nx := float(sx) * 8.6
			var ny := 0.2 + 5.0 + 1.65 + 1.2
			lm.box("Stone", Vector3(nx, ny, zf + float(fz) * 0.25), Vector3(3.0, 0.3, 0.5))
			LandmarkLpParts.arch_panel(lm, "Dark", Vector3(nx, ny + 0.15, zf + float(fz) * 0.04),
				0.0 if fz > 0.0 else PI, 0.65, 1.8, 0.65)
			for s in [-1.0, 1.0]:
				lm.box("Stone", Vector3(nx + float(s) * 1.0, ny + 1.4, zf + float(fz) * 0.15), Vector3(0.3, 2.6, 0.3))
			lm.box("Stone", Vector3(nx, ny + 2.9, zf + float(fz) * 0.2), Vector3(2.6, 0.4, 0.4))
		# Entablature over the columns: architrave, frieze, cornice.
		lm.box("Stone", Vector3(0, 2.4 + 9.4 + 0.35, zf + float(fz) * 0.35), Vector3(core + 0.4, 0.7, 0.7))
		lm.box("Stone", Vector3(0, 2.4 + 9.4 + 0.95, zf + float(fz) * 0.25), Vector3(core + 0.2, 0.5, 0.5))
		LandmarkDetail.cornice(lm, "Stone", Vector3(-core * 0.5 - 0.5, eh, zf + float(fz) * 0.4),
			Vector3(core * 0.5 + 0.5, eh, zf + float(fz) * 0.4), Vector3(0, 0, float(fz)), 0.6)
	# Attic: acanthus frieze at its foot, crowning cornice, central pediment.
	var at := eh + 0.6
	lm.box("Stone", Vector3(0, at + 2.2, 0), Vector3(core - 0.4, 4.4, depth - 0.4))
	for fz in [-1.0, 1.0]:
		var zf := float(fz) * (depth * 0.5 - 0.2)
		for i in 40:
			var x := -core * 0.5 + 0.6 + (core - 1.2) * float(i) / 39.0
			lm.beam("Stone", Vector3(x, at + 0.1, zf), Vector3(x, at + 0.75, zf + float(fz) * 0.18), 0.45, 0.08,
				Vector3.RIGHT)
		lm.box("Stone", Vector3(0, at + 2.6, zf + float(fz) * 0.05), Vector3(7.14, 1.03, 0.12), Basis(), 0.0)
		LandmarkDetail.cornice(lm, "Stone", Vector3(-core * 0.5, at + 4.4, zf), Vector3(core * 0.5, at + 4.4, zf),
			Vector3(0, 0, float(fz)), 0.5, false)
	var pb := at + 4.9
	lm.box("Stone", Vector3(0, pb + 0.2, 0), Vector3(13.4, 0.4, depth - 0.2))
	lm.gable("Stone", Vector3(0, pb + 0.4, 0), 13.0, depth - 0.4, 2.1, Basis(), 0.2, "Stone")
	lm.commit(model)

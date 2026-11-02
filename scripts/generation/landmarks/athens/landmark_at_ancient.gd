class_name LandmarkAtAncient
extends RefCounted

## The Temple of Olympian Zeus, Hadrian's Arch and the Temple of
## Hephaestus in true metres.

# --- Temple of Olympian Zeus ----------------------------------------

## Origin at the middle of the platform, long axis along X (east +X). The
## 107.75 x 41.1 m stylobate of the dipteral Corinthian temple (8 x 20
## columns, three deep at the ends, 104 in all) with the 15 columns that
## still stand: a block of 13 in the south-east corner joined by their
## three-fascia architraves and two at the south-west, 17.25 m tall and
## 1.7 m across, plus the drums of the column between them that fell in
## the storm of 1852. Sockets mark the lost columns on the stylobate.
static func olympieion(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#D6C29B", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9A9285", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E2D6BE", 3.0))
	var ys := 1.5
	AtUtil.steps(lm, "Stone", Vector3(0, ys, 0), 107.75, 41.1, 3, 0.5, 0.5)
	# Cella foundations: the 1.2 m walls outlining the naos and the pronaos.
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0, ys + 0.3, s * 9.5), Vector3(70.0, 0.6, 1.2))
		lm.box("Stone", Vector3(s * 34.4, ys + 0.3, 0), Vector3(1.2, 0.6, 19.0))
		lm.box("Stone", Vector3(s * 22.0, ys + 0.3, 0), Vector3(1.2, 0.6, 19.0))
	var keep: Array[Vector2i] = []
	for i in 3:
		for j in range(5, 8):
			keep.append(Vector2i(i, j))
	for i in range(3, 5):
		for j in range(6, 8):
			keep.append(Vector2i(i, j))
	keep.append(Vector2i(18, 5))
	keep.append(Vector2i(18, 7))
	var fallen := Vector2i(18, 6)
	# Sockets of the lost columns: three rows at each end, two on each flank.
	for i in 20:
		for j in 8:
			var k := Vector2i(i, j)
			var placed := i <= 2 or i >= 17 or j <= 1 or j >= 6
			if not placed or keep.has(k) or k == fallen:
				continue
			lm.frustum("Honey", Vector3(53.0 - 5.58 * float(i), ys, -19.7 + 5.63 * float(j)), 0.9, 0.9, 0.12, 12)
	for k in keep:
		var x := 53.0 - 5.58 * float(k.x)
		var z := -19.7 + 5.63 * float(k.y)
		AtUtil.corinthian(lm, "Honey", Vector3(x, ys, z), 17.25, 0.85, 24)
	# Architraves still lying on the south-east corner columns.
	var top := ys + 17.25
	for j in range(5, 8):
		var span := 2.0 if j == 5 else 4.0
		_architrave(lm, Vector3(53.0 - 5.58 * span * 0.5, top, -19.7 + 5.63 * float(j)), 5.58 * span + 2.0, false)
	for i in range(0, 5):
		var j0 := 5 if i < 3 else 6
		var z0 := -19.7 + 5.63 * float(j0)
		var z1 := -19.7 + 5.63 * 7.0
		_architrave(lm, Vector3(53.0 - 5.58 * float(i), top, (z0 + z1) * 0.5), z1 - z0 + 2.0, true)
	# The fallen column: its drums lying in a line where it fell, and the
	# capital at the far end.
	var fb := Vector3(53.0 - 5.58 * 18.0, ys, -19.7 + 5.63 * 6.0)
	for i in 9:
		var p := fb + Vector3(1.6 + 1.75 * float(i), 0.85, 0.12 * float(i % 3) - 0.1)
		AtUtil.cyl(lm, "Honey", p - Vector3(0.82, 0, 0), p + Vector3(0.82, 0, 0), 0.82 - 0.012 * float(i), 20)
	lm.box("Honey", fb + Vector3(18.4, 1.1, 0.3), Vector3(2.0, 2.2, 2.5), Basis(Vector3.UP, 0.3))
	lm.commit(model)

## Three-fascia architrave `ln` long on a column top at c (its middle),
## along Z when `along_z`.
static func _architrave(lm: LandmarkMesh, c: Vector3, ln: float, along_z: bool) -> void:
	var b := Basis(Vector3.UP, PI * 0.5) if along_z else Basis()
	for f in 3:
		lm.box("Marble", c + Vector3(0, 0.25 + 0.5 * float(f), 0), Vector3(ln, 0.5, 1.7 + 0.06 * float(f)), b)
	lm.box("Marble", c + Vector3(0, 1.62, 0), Vector3(ln + 0.1, 0.24, 1.95), b, 0.0)

# --- Arch of Hadrian -------------------------------------------------

## Origin at the foot of the gateway, broad face toward +Z (yaw_deg onto
## the road). 18 m high, 13.5 m wide and 2.3 m deep, the same both ways:
## a 6.5 m round arch between piers with Corinthian pilasters (taller
## ones at the outer corners) and the projecting pedestals of the lost
## columns, an Ionic architrave with dentils and geison; the attic tier
## divided by Corinthian columns and pilasters into three openings, the
## central aedicule under a pediment with its acroterion.
static func hadrians_arch(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4D8C0", 2.5))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#D5C19B", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#5C5246", 2.5))
	AtUtil.steps(lm, "Honey", Vector3(0, 0.5, 0), 13.8, 2.6, 2, 0.25, 0.3)
	var sp := 5.5
	var ar := 3.25
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 5.0, 0.5 + 4.35, 0), Vector3(3.5, 8.7, 2.3))
		for zz in [-1.0, 1.0]:
			var z: float = zz
			# Inner pilasters carry the arch, taller ones frame the corners.
			lm.box("Marble", Vector3(s * 3.55, 0.5 + sp * 0.5, z * 1.2), Vector3(0.65, sp, 0.25))
			lm.box("Honey", Vector3(s * 3.55, 0.5 + sp + 0.25, z * 1.25), Vector3(0.9, 0.5, 0.35))
			lm.box("Marble", Vector3(s * 6.4, 0.5 + 4.1, z * 1.2), Vector3(0.7, 8.2, 0.25))
			lm.box("Honey", Vector3(s * 6.4, 0.5 + 8.45, z * 1.25), Vector3(1.0, 0.5, 0.35))
			for k in 3:
				lm.box("Honey", Vector3(s * 6.4, 0.5 + 8.0 + 0.12 * float(k), z * (1.36 + 0.05 * float(k))),
					Vector3(0.8, 0.1, 0.06), Basis(), 0.0)
			# Pedestal of the lost free-standing column.
			lm.box("Marble", Vector3(s * 4.9, 0.5 + 1.0, z * 1.7), Vector3(1.3, 2.0, 1.1))
			lm.box("Honey", Vector3(s * 4.9, 0.5 + 2.1, z * 1.7), Vector3(1.5, 0.2, 1.3))
			# Drafted-edge ashlar courses between pilasters.
			for c in 6:
				lm.box("Marble", Vector3(s * 4.98, 0.5 + 2.6 + 0.9 * float(c), z * 1.17), Vector3(2.0, 0.06, 0.06),
					Basis(), 0.0)
	AtUtil.arch_wall(lm, "Marble", 0.0, 0.5 + sp, ar, 9.2, -1.15, 1.15)
	for zz in [-1.0, 1.0]:
		var z: float = zz
		LandmarkDetail.arch(lm, "Honey", Vector3(0, 0.5 + sp, z * 1.15), Vector3(0, 0, z), ar * 2.0, 0.55, 0.12)
	AtUtil.entab(lm, "Marble", "Marble", Vector3(0, 9.2, 0), 13.5, 2.3, 0.55, 0.3, 0.4)
	# Attic tier: three openings between pilasters and columns.
	var yu := 10.45
	var ch := 5.0
	lm.box("Marble", Vector3(0, yu - 0.0, 0), Vector3(13.5, 0.1, 2.3))
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 6.35, yu + ch * 0.5, 0), Vector3(0.8, ch, 2.3))
		lm.box("Marble", Vector3(s * 2.15, yu + ch * 0.5, 0), Vector3(0.6, ch, 2.3))
		for zz in [-1.0, 1.0]:
			var z: float = zz
			AtUtil.corinthian(lm, "Marble", Vector3(s * 3.0, yu, z * 0.85), ch, 0.3, 24)
			AtUtil.corinthian(lm, "Marble", Vector3(s * 2.15, yu, z * 1.15), ch, 0.26, 0)
			lm.box("Honey", Vector3(s * 6.35, yu + ch - 0.3, z * 1.18), Vector3(0.95, 0.6, 0.12))
		AtUtil.entab(lm, "Marble", "Marble", Vector3(s * 4.55, yu + ch, 0), 4.4, 2.3, 0.45, 0.3, 0.3)
	# Central aedicule: thin screen, entablature and pediment.
	lm.box("Shadow", Vector3(0, yu + ch * 0.5, 0), Vector3(3.7, ch, 0.07))
	var ty := AtUtil.entab(lm, "Marble", "Marble", Vector3(0, yu + ch, 0), 5.2, 2.5, 0.5, 0.35, 0.35)
	AtUtil.roof(lm, "Marble", "Honey", "Marble", Vector3(0, ty, 0), 5.4, 2.5, 1.15, 0.1,
		Basis(Vector3.UP, PI * 0.5))
	lm.lathe("Honey", Vector3(0, ty + 1.15, 0), PackedVector2Array([Vector2(0.25, 0), Vector2(0.18, 0.2),
		Vector2(0.3, 0.35), Vector2(0.0, 0.62)]), 8)
	lm.commit(model)

# --- Temple of Hephaestus --------------------------------------------

## Origin at the middle of the stylobate (13.71 x 31.78 m), entrance end
## toward +Z (yaw_deg turns it east). The best-preserved Doric temple:
## 6 x 13 fluted columns 5.7 m tall, the triglyph frieze (68 metopes),
## mutules and guttae, low pediments with akroteria, the cella with the
## pronaos and opisthodomos each distyle in antis carrying the Ionic
## sculpted friezes, and the tiled pitched roof (10.6 m to the ridge).
static func hephaestus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#DDD0B6", 2.5))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#CDB68A", 2.5))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#4F4A44", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A9745C", 2.5))
	var ys := 0.9
	AtUtil.steps(lm, "Marble", Vector3(0, ys, 0), 13.708, 31.775, 3, 0.3, 0.35)
	var cx := 6.35
	var cz := 15.39
	for i in 6:
		for s in [-1.0, 1.0]:
			AtUtil.doric(lm, "Marble", Vector3(-cx + 2.54 * float(i), ys, s * cz), 5.72, 0.5, 20)
	for i in range(1, 12):
		for s in [-1.0, 1.0]:
			AtUtil.doric(lm, "Marble", Vector3(s * cx, ys, -cz + 2.565 * float(i)), 5.72, 0.5, 20)
	var yt := ys + 5.72
	var rq := Basis(Vector3.UP, PI * 0.5)
	for s in [-1.0, 1.0]:
		AtUtil.entab(lm, "Marble", "Honey", Vector3(0, yt, s * cz), 13.4, 1.4, 0.95, 0.95, 0.55,
			Basis(), false, false)
		AtUtil.entab(lm, "Marble", "Honey", Vector3(s * cx, yt, 0), 31.0, 1.4, 0.95, 0.95, 0.55,
			rq, false, false)
		AtUtil.triglyphs(lm, "Dark", Vector3(-cx, yt + 1.425, s * 16.1), Vector3(cx, yt + 1.425, s * 16.1),
			11, Vector3(0, 0, s), 0.85, 0.42)
		AtUtil.triglyphs(lm, "Dark", Vector3(s * 7.05, yt + 1.425, -cz), Vector3(s * 7.05, yt + 1.425, cz),
			25, Vector3(s, 0, 0), 0.85, 0.42)
		# Regula and guttae strip under each triglyph on the architrave.
		for i in 11:
			lm.box("Marble", Vector3(-cx + 1.27 * float(i), yt + 0.88, s * 16.12), Vector3(0.42, 0.08, 0.1),
				Basis(), 0.0)
	AtUtil.roof(lm, "Roof", "Marble", "Honey", Vector3(0, yt + 2.45, 0), 14.0, 33.0, 1.55, 0.3)
	AtUtil.roof_tiles(lm, "Roof", Vector3(0, yt + 2.45, 0), 14.0, 33.0, 1.55, Basis(), 0.3, 0.75, true)
	# Cella: side walls ending in antae, cross walls, two columns in antis
	# under the sculpted Ionic frieze, the great door.
	for s in [-1.0, 1.0]:
		lm.box("Honey", Vector3(s * 3.25, ys + 3.8, 0), Vector3(0.9, 7.6, 20.0))
		lm.box("Marble", Vector3(s * 3.25, ys + 0.25, 0), Vector3(1.1, 0.5, 20.2))
		lm.box("Honey", Vector3(0, ys + 3.8, s * 6.5), Vector3(6.4, 7.6, 0.8))
		for t in [-1.0, 1.0]:
			lm.box("Marble", Vector3(s * 3.25, ys + 2.6, t * 9.85), Vector3(1.05, 5.2, 0.5))
		for x in [-1.4, 1.4]:
			AtUtil.doric(lm, "Marble", Vector3(x, ys, s * 9.7), 5.2, 0.42, 20)
		lm.box("Marble", Vector3(0, ys + 5.2 + 0.4, s * 9.7), Vector3(7.4, 0.8, 0.9))
		lm.box("Honey", Vector3(0, ys + 6.2, s * 9.7), Vector3(13.0, 0.8, 0.8))
		AtUtil.doorway(lm, "Marble", "Dark", Vector3(0, ys, s * 6.9), Vector3(0, 0, s), 2.2, 4.4)
	lm.commit(model)

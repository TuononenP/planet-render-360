class_name LandmarkKhAngkor
extends RefCounted

## Angkor Thom and Ta Prohm in true metres: the Bayon, the South Gate with
## its naga causeway, and Ta Prohm among the silk-cotton roots.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")
const BAYON = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_bayon.gd")
const TA_PROHM = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_taprohm.gd")

## Bayon (43 m): the three levels of gallery with bas-reliefs, the cruciform
## gopuras and 49 face towers round the central sanctuary; built by
## landmark_kh_bayon.gd. Built facing +X (east).
static func bayon(model: Node3D) -> void:
	BAYON.build(model)

## South Gate of Angkor Thom (23 m): the 8 m laterite city wall with its
## parapet, pierced by the 3.5 x 7 m gate passage; the gate block with the
## three-headed elephant of Indra at each corner, trunks plucking lotuses,
## the central four-faced tower and two lower flanking face towers; and
## the causeway over the moat lined with 54 devas on the left and 54 asuras
## on the right (seen from outside) hauling the naga, its seven-headed hood
## rearing at the outer end. The moat is not modelled: the causeway is a
## raised bank at ground level. Gate faces +Z (south).
static func south_gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#7E5A44", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7D7767", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#22201C", 2.0))
	lm.use("Naga", LandmarkMaterials.pbr("stone", "#6C675A", 3.0))
	# City wall with its parapet.
	for sx in [-1.0, 1.0]:
		U.wall_run(lm, "Laterite", "Stone", Vector3(sx * 72.0, 0, 0), Vector3(sx * 9.0, 0, 0), 8.0, 7.0, 0.3)
		lm.box("Laterite", Vector3(sx * 40.5, 8.8, 3.2), Vector3(63.0, 1.4, 0.6))
		lm.box("Stone", Vector3(sx * 40.5, 9.55, 3.2), Vector3(63.4, 0.2, 0.9), Basis(), 0.0)
	# Gate block: two piers either side of the 3.5 m x 7 m passage with a
	# corbelled head, moulded base and cornice.
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * 5.4, 4.25, 0), Vector3(7.2, 8.5, 9.0))
		lm.box("Stone", Vector3(sx * 5.4, 0.3, 0), Vector3(7.8, 0.6, 9.6))
		for q in 3:
			lm.box("Stone", Vector3(sx * (1.75 + 0.25 * float(q) + 0.12), 7.2 + 0.4 * float(q), 0),
				Vector3(0.5, 0.4, 9.0), Basis(), 0.0)
	lm.box("Stone", Vector3(0, 8.0, 0), Vector3(3.6, 1.0, 9.0))
	lm.box("Dark", Vector3(0, 3.5, 4.45), Vector3(3.5, 7.0, 0.2), Basis(), 0.0)
	lm.box("Dark", Vector3(0, 3.5, -4.45), Vector3(3.5, 7.0, 0.2), Basis(), 0.0)
	lm.box("Stone", Vector3(0, 8.7, 0), Vector3(19.0, 0.5, 9.8))
	lm.box("Stone", Vector3(0, 8.35, 0), Vector3(18.4, 0.2, 9.4), Basis(), 0.0)
	# Three-headed elephants at the four corners, Indra seated on the
	# middle head; the trunks reach down to pluck lotuses.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			for k in 3:
				var x: float = sx * (4.4 + 1.6 * float(k))
				var zf: float = sz * 4.7
				var head := Vector3(x, 6.6, zf)
				lm.box("Naga", head + Vector3(0, 0.3, 0), Vector3(1.4, 1.5, 1.0))
				for se in [-1.0, 1.0]:
					lm.box("Naga", head + Vector3(se * 0.75, 0.4, 0), Vector3(0.12, 1.3, 0.9), Basis(), 0.0)
				lm.beam("Naga", head + Vector3(0, -0.2, sz * 0.4), Vector3(x, 2.4, zf + sz * 0.9), 0.62, 0.62)
				lm.beam("Naga", Vector3(x, 2.4, zf + sz * 0.9), Vector3(x, 0.5, zf + sz * 0.7), 0.42, 0.42)
				lm.frustum("Naga", Vector3(x, 0.0, zf + sz * 0.7), 0.5, 0.25, 0.5, 6)
				for se in [-1.0, 1.0]:
					lm.beam("Naga", head + Vector3(se * 0.35, -0.3, sz * 0.4), head + Vector3(se * 0.4, -0.7, sz * 1.0),
						0.14, 0.14)
			LandmarkKits.statue_figure(lm, "Naga", Vector3(sx * 6.0, 7.5, sz * 4.8), 1.3)
	# Central four-faced tower and the two lower flanking towers.
	U.face_tower(lm, "Stone", "Dark", Vector3(0, 8.7, 0), 6.0, 14.3)
	for sx in [-1.0, 1.0]:
		U.face_tower(lm, "Stone", "Dark", Vector3(sx * 7.4, 8.7, 0), 3.4, 8.0)
	# Causeway: a raised laterite bank with moulded edges.
	var z0 := 4.6
	var clen := 96.0
	lm.box("Laterite", Vector3(0, 0.5, z0 + clen * 0.5), Vector3(14.0, 1.0, clen))
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * 7.0, 0.9, z0 + clen * 0.5), Vector3(0.6, 0.2, clen), Basis(), 0.0)
	# Devas (west, left from outside) and asuras (east): 54 figures a side
	# hauling the naga, whose hood fans out at the far end.
	for sx in [-1.0, 1.0]:
		var x: float = sx * 5.05
		var nb := Vector3(x, 2.7, z0 + 1.5)
		var ne := Vector3(x, 2.7, z0 + clen - 2.5)
		lm.beam("Naga", nb, ne, 0.55, 0.55)
		lm.beam("Naga", nb + Vector3(0, 0.3, 0), ne + Vector3(0, 0.3, 0), 0.2, 0.15, Vector3.RIGHT)
		U.naga_fan(lm, "Naga", Vector3(x, 1.0, z0 + clen - 1.5), Basis(), 7, 3.6)
		for i in 54:
			var z := z0 + 3.0 + (clen - 7.0) * float(i) / 53.0
			_tug_figure(lm, Vector3(sx * 5.6, 1.0, z), sx, sx < 0.0)
	lm.commit(model)

## One giant of the causeway, 2.6 m tall on its block at `base`, leaning
## back toward the gate (-Z) as it hauls the naga at chest height; `side`
## says which side it stands on (it faces the roadway). Devas wear the
## conical mukuta crown, asuras a domed helmet over a scowling brow.
static func _tug_figure(lm: LandmarkMesh, base: Vector3, side: float, deva: bool) -> void:
	lm.box("Stone", base + Vector3(0, 0.2, 0), Vector3(1.0, 0.4, 0.9), Basis(), 0.0)
	var lean := Basis(Vector3.RIGHT, -0.12)
	lm.box("Naga", base + Vector3(side * 0.15, 0.85, 0), Vector3(0.75, 0.9, 0.55), lean)
	lm.box("Naga", base + Vector3(side * 0.15, 1.6, -0.05), Vector3(0.9, 0.6, 0.55), lean)
	var head := base + Vector3(side * 0.15, 2.25, -0.12)
	lm.box("Naga", head, Vector3(0.62, 0.7, 0.6), lean)
	lm.box("Dark", head + Vector3(-side * 0.32, 0.05, 0), Vector3(0.04, 0.12, 0.36), lean, 0.0)
	if deva:
		lm.spire("Naga", head + Vector3(0, 0.35, 0), 0.26, 0.7, 0.05)
	else:
		lm.lathe("Naga", head + Vector3(0, 0.3, 0), PackedVector2Array([Vector2(0.36, 0),
			Vector2(0.34, 0.18), Vector2(0.2, 0.32), Vector2(0.0, 0.36)]), 6)
		lm.box("Naga", head + Vector3(-side * 0.3, 0.18, 0), Vector3(0.1, 0.12, 0.5), Basis(), 0.0)
	for dz in [-0.3, 0.3]:
		lm.beam("Naga", base + Vector3(side * 0.15, 1.75, dz * 0.6), base + Vector3(-side * 0.55, 1.7, dz),
			0.2, 0.2)

## Ta Prohm (18.5 m): the galleried enclosures among the silk-cotton roots,
## built by landmark_kh_taprohm.gd. Built facing +X (east).
static func ta_prohm(model: Node3D) -> void:
	TA_PROHM.build(model)

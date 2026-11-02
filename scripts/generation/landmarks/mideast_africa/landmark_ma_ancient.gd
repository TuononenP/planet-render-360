class_name LandmarkMaAncient
extends RefCounted

## Three ancient monuments in true metres: Petra's rock-cut Treasury
## (Al-Khazneh), the Abu Simbel temples and the Great Sphinx of Giza.

# --- Petra, Al-Khazneh (the Treasury) ---

## 39 m rose-sandstone facade cut into the Siq cliff (built facing +Z):
## six-column lower portico under a pediment, the upper storey with the
## central tholos, its conical roof and urn between two broken
## pediments.
static func petra(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Cliff", LandmarkMaterials.pbr("stone", "#B5755C", 6.0))
	lm.use("Facade", LandmarkMaterials.pbr("stone", "#D6A08A", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1E1612"))
	lm.box("Cliff", Vector3(0, 17.5, -14), Vector3(70, 41, 28))
	for s in [-1.0, 1.0]:
		lm.box("Cliff", Vector3(s * 22.0, 17.5, 5), Vector3(16, 41, 18))
	lm.box("Facade", Vector3(0, 17, 0.5), Vector3(26, 36, 1.0))
	lm.box("Facade", Vector3(0, 0.5, 5.5), Vector3(22, 1.4, 7))
	for x in [-9.0, -5.4, -1.8, 1.8, 5.4, 9.0]:
		lm.frustum("Facade", Vector3(x, 1.2, 4), 0.85, 0.8, 12.0, 12)
		lm.box("Facade", Vector3(x, 13.4, 4), Vector3(2.2, 0.8, 2.2))
	lm.box("Facade", Vector3(0, 14.6, 3.5), Vector3(22, 2.4, 4.5))
	lm.gable("Facade", Vector3(0, 15.8, 3.5), 22.0, 4.5, 4.0, Basis(), 0.0, "Facade")
	lm.box("Door", Vector3(0, 6, 1.2), Vector3(3.4, 8, 0.4))
	for s in [-1.0, 1.0]:
		lm.box("Door", Vector3(s * 6.8, 3.5, 1.2), Vector3(2, 5, 0.4))
		lm.box("Facade", Vector3(s * 12.3, 17, 1.8), Vector3(1.6, 36, 1.6))
		# Upper storey: flanking half-pediments on paired columns.
		for dx in [5.5, 11.0]:
			lm.frustum("Facade", Vector3(s * dx, 21, 3), 0.6, 0.55, 9.5, 10)
		lm.box("Facade", Vector3(s * 8.25, 31.1, 2.8), Vector3(6.5, 1.4, 3.5))
		lm.gable("Facade", Vector3(s * 8.25, 31.8, 2.8), 6.5, 3.5, 2.0, Basis(), 0.0, "Facade")
	lm.box("Facade", Vector3(0, 20.4, 1.8), Vector3(24, 1.2, 3.5))
	# Central tholos: drum, conical roof and the crowning urn.
	lm.frustum("Facade", Vector3(0, 21, 2.2), 3.6, 3.4, 10.0, 16)
	lm.box("Door", Vector3(0, 25.5, 5.85), Vector3(2.4, 5, 0.3))
	lm.spire("Facade", Vector3(0, 31, 2.2), 4.2, 5.5, 0.0, 8)
	lm.lathe("Facade", Vector3(0, 36.5, 2.2), PackedVector2Array([Vector2(0.8, 0), Vector2(1.2, 0.8),
		Vector2(0.9, 1.7), Vector2(0.45, 2.5)]), 10)
	lm.commit(model)
	model.rotation.y = deg_to_rad(-90.0)

# --- Abu Simbel ---

## Ramesses II's Great Temple (33 m rock facade, four seated 20 m
## colossi, cavetto cornice and baboon frieze) and, 95 m north (-Z),
## the Small Temple with six standing statues. Both face east (+X).
static func abu_simbel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sandstone", LandmarkMaterials.pbr("stone", "#C79B64", 4.0))
	lm.use("Hill", LandmarkMaterials.pbr("stone", "#A9825A", 8.0))
	lm.use("Door", LandmarkMaterials.glass("#1A1510"))
	lm.use("Terrace", LandmarkMaterials.pbr("sand", "#D9BE8A", 8.0))
	lm.box("Terrace", Vector3(12, -0.7, -45), Vector3(28, 1.4, 150))
	_hill(lm, 0.0, 26.0, 19.7, 33.0, 60.0)
	for z in [-15.0, -5.5, 5.5, 15.0]:
		_colossus(lm, 0.0, z)
	lm.box("Door", Vector3(0.05, 3.5, 0), Vector3(0.4, 7, 5))
	lm.box("Sandstone", Vector3(-0.2, 30, 0), Vector3(4.4, 2.2, 40))
	for i in 22:
		lm.box("Sandstone", Vector3(-1.6, 32, -19.1 + 1.82 * i), Vector3(1.2, 2.0, 1.1))
	lm.box("Door", Vector3(-1.35, 24, 0), Vector3(0.5, 6, 3.2))
	lm.box("Sandstone", Vector3(-1.1, 23.5, 0), Vector3(0.8, 4.5, 1.2))
	# Small Temple of Hathor and Nefertari.
	_hill(lm, -95.0, 20.0, 15.5, 12.0, 30.0)
	lm.box("Sandstone", Vector3(-0.2, 11.5, -95), Vector3(2.2, 1.0, 29))
	for i in 7:
		if i != 3:
			lm.box("Sandstone", Vector3(0.4, 6.5, -95.0 - 13.5 + 4.5 * i), Vector3(1.6, 13, 2.0))
	for i in 6:
		var z := -95.0 - 11.25 + 4.5 * i
		LandmarkKits.statue_figure(lm, "Sandstone", Vector3(0.7, 0, z), 10.0)
	lm.box("Door", Vector3(0.05, 2.6, -95), Vector3(0.4, 5, 3.5))
	lm.commit(model)

## Stepped rock mound whose front (x ~ 0) is the temple face: `n`
## layers narrowing from half-width `hw0` to `hw1` and shortening
## backwards, `h` high, `depth` m deep.
static func _hill(lm: LandmarkMesh, z0: float, hw0: float, hw1: float, h: float,
		depth: float) -> void:
	var n := 8
	for i in n:
		var hw := lerpf(hw0, hw1, float(i) / (n - 1))
		var front := -0.3 * i
		var back := -(depth - (depth - 18.0) * float(i) / (n - 1))
		var poly := PackedVector2Array([Vector2(front, z0 - hw), Vector2(back, z0 - hw),
			Vector2(back, z0 + hw), Vector2(front, z0 + hw)])
		lm.poly_prism("Hill", poly, h * i / n - (3.0 if i == 0 else 0.0), h * (i + 1) / n)

## Seated colossus of height 20 m at the facade (x = 0 front).
static func _colossus(lm: LandmarkMesh, x: float, z: float) -> void:
	lm.box("Sandstone", Vector3(x + 3.5, 5.5, z), Vector3(7, 11, 6.4))
	for s in [-1.0, 1.0]:
		lm.box("Sandstone", Vector3(x + 7.2, 4.0, z + s * 1.7), Vector3(2.8, 8, 2.6))
		lm.box("Sandstone", Vector3(x + 5.0, 9.5, z + s * 2.8), Vector3(3.6, 1.4, 1.4))
	lm.frustum("Sandstone", Vector3(x + 2.2, 11, z), 2.9, 2.3, 6.0, 8)
	lm.frustum("Sandstone", Vector3(x + 2.4, 17, z), 1.6, 1.3, 2.0, 8)
	lm.spire("Sandstone", Vector3(x + 2.4, 19, z), 1.3, 1.0, 0.6, 8)

# --- Great Sphinx of Giza ---

## 73 m long, 20 m high recumbent lion with the king's head in a nemes
## headdress, facing east (+X) out of its rock-cut pit; the granite
## Dream Stele stands between the paws.
static func sphinx(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sphinx", LandmarkMaterials.pbr("limestone", "#C9AE7C", 3.0))
	lm.use("Pit", LandmarkMaterials.pbr("limestone", "#A98F66", 6.0))
	lm.use("Stele", LandmarkMaterials.pbr("stone", "#8F6C5A", 1.5))
	for s in [-1.0, 1.0]:
		lm.box("Pit", Vector3(-5, 3.5, s * 23.0), Vector3(96, 11, 6))
	lm.box("Pit", Vector3(-47, 3.5, 0), Vector3(6, 11, 52))
	var side := Vector3(0, 0, 1)
	lm.frustum("Sphinx", Vector3(-31, 0, 0), 7.0, 6.6, 10.0, 14)
	lm.beam("Sphinx", Vector3(-34, 5.2, 0), Vector3(-6, 5.8, 0), 13.0, 10.4, side)
	lm.beam("Sphinx", Vector3(-6, 7.0, 0), Vector3(13, 7.5, 0), 11.0, 14.0, side)
	lm.box("Sphinx", Vector3(14, 12.5, 0), Vector3(7, 11, 8))
	lm.box("Sphinx", Vector3(14.5, 17.9, 0), Vector3(8, 4.2, 11))
	lm.box("Sphinx", Vector3(18.0, 15.0, 0), Vector3(1.6, 5.0, 4.1))
	lm.box("Sphinx", Vector3(19.3, 14.2, 0), Vector3(0.8, 1.6, 1.0))
	for s in [-1.0, 1.0]:
		lm.box("Sphinx", Vector3(14.5, 12.4, s * 5.0), Vector3(6, 8, 1.2))
		lm.beam("Sphinx", Vector3(12, 2.0, s * 4.6), Vector3(36.5, 1.8, s * 4.6), 3.6, 4.0, side)
	lm.box("Stele", Vector3(33.5, 1.8, 0), Vector3(0.8, 3.6, 2.4))
	lm.commit(model)

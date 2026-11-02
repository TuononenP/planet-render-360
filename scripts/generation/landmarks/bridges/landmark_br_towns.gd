class_name LandmarkBrTowns
extends RefCounted

## Two town bridges of the bridges batch in true metres, along +X with
## y = 0 at the river (LocationData `base: water`): Prague's Charles
## Bridge with its gate towers and saints and Florence's Ponte Vecchio
## with its overhanging shops and the Vasari Corridor. Their arches are
## solid masonry (LandmarkBrKit.arcade).

## Charles Bridge: 516 m on 16 arches of about 23 m on piers with
## upstream ice-breakers, the 9.5 m cobbled roadway 10 m over the Vltava
## between low parapets with thirty baroque statues, the Old Town Bridge
## Tower (57 m) at the east end and the Judith and Lesser Town towers
## at the west.
const CB_HALF := 258.0
const CB_DECK_M := 10.0

static func charles(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B9B09C", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#9C9588", 2.0))
	lm.use("Statue", LandmarkMaterials.pbr("stone", "#4A453E", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#56625C", 2.0))
	var piers := LandmarkBrKit.pier_line(-CB_HALF, CB_HALF, 16)
	LandmarkBrKit.arcade(lm, "Stone", piers, -3.0, CB_DECK_M, 0.5, 0.7, 9.5, 5.2, 12)
	for i in range(1, 16):
		var x := piers[i]
		lm.poly_prism("Stone", PackedVector2Array([Vector2(x - 4.75, 5.1), Vector2(x, 10.8),
			Vector2(x + 4.75, 5.1)]), -3.0, 8.0)
	lm.box("Paving", Vector3(0, CB_DECK_M + 0.1, 0), Vector3(2.0 * CB_HALF, 0.2, 9.0))
	for z in [-4.85, 4.85]:
		lm.box("Stone", Vector3(0, CB_DECK_M + 0.6, z), Vector3(2.0 * CB_HALF, 1.2, 0.5))
		for i in 15:
			var sx := -217.0 + 31.0 * i
			lm.box("Statue", Vector3(sx, CB_DECK_M + 1.5, z), Vector3(2.2, 2.6, 2.2))
			LandmarkBrKit.figure(lm, "Statue", Vector3(sx, CB_DECK_M + 2.8, z), 3.4)
	# Old Town Bridge Tower and the Lesser Town pair.
	_gate_tower(lm, 249.0, Vector2(12.5, 14.4), 36.0, "grand")
	_gate_tower(lm, -249.0, Vector2(11.0, 13.0), 36.0, "hip")
	_gate_tower(lm, -232.0, Vector2(8.0, 11.0), 26.0, "gable")
	lm.commit(model)

## A gate over the roadway at x: legs round an 8.4 m passage, the tower
## block up to `top` and a roof: "grand" adds an upper stage, corner
## turrets and a tall hip roof, "hip" a pyramid, "gable" a ridge roof.
static func _gate_tower(lm: LandmarkMesh, x: float, size: Vector2, top: float, roof: String) -> void:
	var leg := size.y * 0.5 - 4.2
	for z in [-(4.2 + leg * 0.5), 4.2 + leg * 0.5]:
		lm.box("Stone", Vector3(x, 7.0, z), Vector3(size.x, 20.0, leg))
	lm.box("Stone", Vector3(x, (17.0 + top) * 0.5, 0), Vector3(size.x, top - 17.0, size.y))
	match roof:
		"grand":
			lm.box("Stone", Vector3(x, top + 4.0, 0), Vector3(size.x - 1.2, 8.0, size.y - 1.2))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					var cx: float = x + sx * (size.x * 0.5 - 0.6)
					var cz: float = sz * (size.y * 0.5 - 0.6)
					lm.frustum("Stone", Vector3(cx, top, cz), 1.5, 1.5, 11.0, 10)
					lm.spire("Roof", Vector3(cx, top + 11.0, cz), 1.7, 6.0, 0.0, 8)
			lm.spire("Roof", Vector3(x, top + 8.0, 0), 6.2, 13.0, 0.5)
		"hip":
			lm.spire("Roof", Vector3(x, top, 0), size.x * 0.5 + 0.4, 9.0, 0.6)
		_:
			lm.gable("Roof", Vector3(x, top, 0), size.x, size.y, 6.5, Basis(), 0.6, "Stone")

## Ponte Vecchio: three segmental arches (24 to 30 m) in rusticated
## stone, the 9 m causeway between two rows of two- and three-storey
## shops in ochre, rose and cream under terracotta roofs, their back
## rooms on timber brackets over the Arno, the open central piazzetta
## and, on the east side, the Vasari Corridor with its three windows.
const PV_DECK_M := 9.0

static func ponte_vecchio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B3A689", 3.0))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#D9AB62", 3.0))
	lm.use("Rose", LandmarkMaterials.pbr("render", "#CC8A68", 3.0))
	lm.use("Cream", LandmarkMaterials.pbr("render", "#DFD0A8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A94F33", 3.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6B4F36", 2.0))
	lm.use("Shadow", LandmarkMaterials.paint("#32291F", 0.9, 0.0))
	LandmarkBrKit.arcade(lm, "Stone", PackedFloat32Array([-47.25, -17.75, 17.75, 47.25]), -2.0,
		PV_DECK_M, 3.3, 0.33, 5.5, 11.0, 14)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1345
	var walls: Array[String] = ["Ochre", "Rose", "Cream"]
	for row in [-1.0, 1.0]:
		var x := -48.0
		while x < 48.0:
			var bw := minf(rng.randf_range(4.2, 6.4), 48.0 - x)
			var xc := x + bw * 0.5
			x += bw
			if absf(xc) < 7.0:
				continue
			# East shops (-Z) stay low, the Vasari Corridor runs over them.
			var h := 7.0 if row < 0.0 else (6.8 if rng.randf() < 0.5 else 10.4)
			var key: String = walls[rng.randi() % 3]
			var zc: float = row * 8.8
			lm.box(key, Vector3(xc, PV_DECK_M + h * 0.5, zc), Vector3(bw - 0.15, h, 11.2))
			lm.gable("Roof", Vector3(xc, PV_DECK_M + h, zc), 11.2, bw - 0.15, 1.6,
				Basis(Vector3.UP, PI * 0.5), 0.5, key)
			for face in [row * 3.2, row * 14.4]:
				var zf: float = face
				lm.box("Shadow", Vector3(xc, PV_DECK_M + 1.5, zf), Vector3(bw - 1.4, 2.4, 0.2))
				for fy in range(1, int(h / 3.4)):
					lm.box("Shadow", Vector3(xc, PV_DECK_M + 1.6 + 3.4 * fy, zf), Vector3(1.2, 1.8, 0.2))
			for bx in [-0.3, 0.3]:
				lm.beam("Wood", Vector3(xc + bw * bx, PV_DECK_M - 3.4, row * 10.9),
					Vector3(xc + bw * bx, PV_DECK_M - 0.2, row * 14.2), 0.4, 0.6, Vector3(1, 0, 0))
	# Vasari Corridor over the east shops, three big windows to the street.
	lm.box("Ochre", Vector3(0, PV_DECK_M + 7.0 + 1.7, -6.2), Vector3(104.0, 3.4, 3.4))
	lm.gable("Roof", Vector3(0, PV_DECK_M + 10.4, -6.2), 3.4, 104.0, 0.9, Basis(Vector3.UP, PI * 0.5), 0.4, "Ochre")
	for wx in range(-48, 49, 8):
		lm.box("Shadow", Vector3(wx, PV_DECK_M + 8.9, -4.5), Vector3(1.0, 1.2, 0.2))
	for wx in [-6.0, 0.0, 6.0]:
		lm.box("Shadow", Vector3(wx, PV_DECK_M + 8.9, -4.47), Vector3(3.2, 1.8, 0.25))
	for z in [-11.0, 11.0]:
		lm.box("Stone", Vector3(0, PV_DECK_M + 0.55, z), Vector3(14.0, 1.1, 0.5))
	lm.commit(model)

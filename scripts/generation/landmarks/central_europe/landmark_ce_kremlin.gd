class_name LandmarkCeKremlin
extends RefCounted

## Red Square in true metres: Saint Basil's Cathedral (the tent-roofed
## central church ringed by eight chapels under striped onion domes,
## 47.2 m) and the Spasskaya Tower of the Kremlin wall (brick shaft with
## clock faces, belfry gallery, tent spire and ruby star, 71 m).

const BASIL_TOP := 47.2

static func basil(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B0493B", 3.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#EFE8DA", 3.0))
	lm.use("Tent", LandmarkMaterials.pbr("terracotta", "#A8442F", 2.5))
	lm.use("DomeRed", LandmarkMaterials.pbr("terracotta", "#B8362B", 2.0, 0.45, 0.2))
	lm.use("DomeGreen", LandmarkMaterials.pbr("concrete", "#3E8F55", 2.0, 0.45, 0.3))
	lm.use("DomeBlue", LandmarkMaterials.pbr("concrete", "#3A6FAE", 2.0, 0.45, 0.3))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Podium", LandmarkMaterials.pbr("stone", "#C2B8A6", 3.0))
	lm.box("Podium", Vector3(0, 3.0, 2.0), Vector3(54.0, 6.0, 60.0))
	# Central church: octagonal shaft, white-ribbed tent, gilded onion.
	lm.frustum("Brick", Vector3(0, 6.0, 0), 8.6, 8.0, 25.0, 8, PI / 8.0)
	lm.frustum("White", Vector3(0, 30.0, 0), 9.4, 9.0, 1.2, 8, PI / 8.0)
	lm.lathe("Tent", Vector3(0, 31.2, 0), PackedVector2Array([Vector2(8.8, 0), Vector2(6.2, 5.0),
		Vector2(3.2, 10.0), Vector2(2.2, 13.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + TAU * k / 8.0
		lm.beam("White", Vector3(cos(a) * 8.9, 31.2, sin(a) * 8.9), Vector3(cos(a) * 2.3, 44.0, sin(a) * 2.3), 0.5, 0.35)
	lm.frustum("White", Vector3(0, 44.2, 0), 2.3, 1.9, 1.3, 8)
	LandmarkCeParts.onion(lm, "Gilt", Vector3(0, 45.5, 0), 2.2, 1.7, 12)
	lm.beam("Gilt", Vector3(0, 46.6, 0), Vector3(0, BASIL_TOP, 0), 0.12, 0.12)
	# Four cardinal chapels (tall, r 7) and four diagonal ones (small, r 4.8).
	var big := ["DomeGreen", "Gilt", "DomeBlue", "DomeRed"]
	var small := ["DomeRed", "DomeGreen", "Gilt", "DomeBlue"]
	var heights := [27.0, 29.0, 25.0, 28.0]
	for k in 4:
		var a := PI * 0.5 * k
		_chapel(lm, Vector3(cos(a) * 18.0, 6.0, sin(a) * 18.0), 7.0, heights[k], big[k], 11.0, 15.0)
		var b := a + PI * 0.25
		_chapel(lm, Vector3(cos(b) * 15.5, 6.0, sin(b) * 15.5), 4.8, 19.0 + k, small[k], 7.0, 10.0)
	# Bell tower beside the south-west chapel.
	var bt := Vector3(-8.0, 6.0, 24.0)
	lm.box("Brick", bt + Vector3(0, 8.0, 0), Vector3(6.0, 16.0, 6.0))
	lm.frustum("White", bt + Vector3(0, 16.0, 0), 3.4, 3.2, 5.0, 8, PI / 8.0)
	lm.lathe("Tent", bt + Vector3(0, 21.0, 0), PackedVector2Array([Vector2(3.8, 0), Vector2(0.4, 9.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.commit(model)

## One chapel: brick octagon under a drum and an onion dome of `dome` key.
static func _chapel(lm: LandmarkMesh, base: Vector3, r: float, h: float, dome: String,
		dome_r: float, dome_h: float) -> void:
	lm.frustum("Brick", base, r, r * 0.92, h, 8, PI / 8.0)
	lm.frustum("White", base + Vector3(0, h * 0.62, 0), r * 1.04, r * 1.04, 0.8, 8, PI / 8.0)
	lm.frustum("Windows", base + Vector3(0, h * 0.3, 0), r * 0.985, r * 0.97, h * 0.2, 8, PI / 8.0)
	lm.frustum("White", base + Vector3(0, h, 0), r * 0.5, r * 0.5, 3.0, 12)
	var dr := dome_r * 0.52
	LandmarkCeParts.onion(lm, dome, base + Vector3(0, h + 3.0, 0), dr, dome_h * 0.52, 16, false)
	lm.beam("Gilt", base + Vector3(0, h + 3.0 + dome_h * 0.5, 0), base + Vector3(0, h + 3.0 + dome_h * 0.62, 0), 0.12, 0.12)

# --- Spasskaya Tower ---

const SPAS_TOP := 71.0

static func spasskaya(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A8443A", 3.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#EDE6D6", 3.0))
	lm.use("Tent", LandmarkMaterials.pbr("terracotta", "#B0472F", 2.5))
	lm.use("Face", LandmarkMaterials.pbr("render", "#F3EEDF", 2.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Star", LandmarkMaterials.lit("#C3262E", 0.7))
	# The Kremlin wall: crenellated brick curtain running east-west.
	lm.box("Brick", Vector3(0, 3.5, 0), Vector3(90.0, 7.0, 6.0))
	for sx in [-1.0, 1.0]:
		LandmarkCeParts.merlons(lm, "Brick", Vector3(sx * 10.0, 7.0, 0), Vector3(sx * 44.5, 7.0, 0), 2.4, 1.2, 1.8, 2.0)
	# Gate shaft, clock stage, belfry gallery and tent.
	lm.box("Brick", Vector3(0, 17.0, 0), Vector3(14.0, 34.0, 14.0))
	lm.box("White", Vector3(0, 34.4, 0), Vector3(15.0, 0.8, 15.0))
	lm.box("Brick", Vector3(0, 44.0, 0), Vector3(11.5, 19.0, 11.5))
	for f in 2:
		var r := Basis(Vector3.UP, PI * f)
		lm.box("Windows", r * Vector3(0, 8.0, 7.05), Vector3(4.0, 8.0, 0.2), r)
		lm.disc("Face", Vector3(0, 40.0, 0) + r * Vector3(0, 0, 5.92), r * Vector3(0, 0, 1), 3.2, 24)
		lm.box("White", Vector3(0, 40.0, 0) + r * Vector3(0, 0, 5.825), Vector3(7.4, 7.4, 0.15), r)
	lm.box("White", Vector3(0, 53.8, 0), Vector3(13.0, 0.9, 13.0))
	lm.frustum("Brick", Vector3(0, 54.2, 0), 5.9, 5.3, 4.6, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + TAU * k / 8.0
		lm.box("Windows", Vector3(cos(a) * 5.3, 56.6, sin(a) * 5.3), Vector3(1.5, 3.0, 1.5), Basis(Vector3.UP, PI * 0.5 - a))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var q := Vector3(sx * 5.4, 53.8, sz * 5.4)
			lm.frustum("White", q, 0.9, 0.7, 4.0, 6)
			lm.spire("Tent", q + Vector3(0, 4.0, 0), 1.0, 3.5, 0.0, 6)
	lm.box("White", Vector3(0, 59.2, 0), Vector3(11.0, 0.6, 11.0))
	lm.lathe("Tent", Vector3(0, 59.0, 0), PackedVector2Array([Vector2(6.4, 0), Vector2(5.6, 3.0), Vector2(3.0, 7.0),
		Vector2(1.6, 9.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Gilt", Vector3(0, 67.5, 0), 0.5, 0.35, 2.0, 8)
	# Ruby star (five points in the N-S plane) on the finial.
	var sc := Vector3(0, 69.4, 0)
	for k in 5:
		var a := TAU * k / 5.0
		lm.beam("Star", sc, sc + Vector3(sin(a), cos(a), 0) * 1.6, 0.7, 0.4)
	lm.commit(model)

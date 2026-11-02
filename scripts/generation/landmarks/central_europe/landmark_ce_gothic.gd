class_name LandmarkCeGothic
extends RefCounted

## Two Gothic cathedrals of the Danube in true metres, axes along X
## with the west front at -X: St Vitus in Prague (nave and choir under
## copper, twin west spires and the baroque-helmed south tower, 96.5 m)
## and St Stephen's in Vienna (tall tiled roof with chevron bands, the
## 136.4 m south spire and the stump of the north tower).

const VITUS_TOP := 96.5

static func vitus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A29C8E", 3.0))
	lm.use("Pale", LandmarkMaterials.pbr("limestone", "#B7AE98", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#6F8F7B", 2.5, 0.55, 0.25))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Nave, transept and the chevet of the choir.
	lm.box("Stone", Vector3(-15.0, 11.0, 0), Vector3(48.0, 22.0, 24.0))
	lm.gable("Roof", Vector3(-15.0, 22.0, 0), 24.0, 48.0, 11.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Stone")
	lm.box("Stone", Vector3(-4.0, 11.0, 0), Vector3(22.0, 22.0, 62.0))
	lm.gable("Roof", Vector3(-4.0, 22.0, 0), 22.0, 62.0, 10.0, Basis(), 0.5, "Stone")
	lm.box("Stone", Vector3(30.0, 11.0, 0), Vector3(52.0, 22.0, 24.0))
	lm.gable("Roof", Vector3(30.0, 22.0, 0), 24.0, 52.0, 11.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Stone")
	lm.lathe("Stone", Vector3(56.0, 0, 0), PackedVector2Array([Vector2(12.0, 0), Vector2(12.0, 22.0)]), 12, 1.0, 1.0, 0.0, false)
	lm.lathe("Roof", Vector3(56.0, 22.0, 0), PackedVector2Array([Vector2(12.6, 0), Vector2(0.0, 11.0)]), 12, 1.0, 1.0, 0.0, false)
	for sz in [-1.0, 1.0]:
		for i in 12:
			var x := -34.0 + 8.5 * i
			lm.box("Pale", Vector3(x, 12.0, sz * 15.5), Vector3(1.8, 24.0, 6.0))
			lm.spire("Pale", Vector3(x, 24.0, sz * 15.5), 0.9, 7.0)
			lm.beam("Pale", Vector3(x, 22.5, sz * 14.0), Vector3(x, 26.0, sz * 12.5), 1.2, 1.2)
			LandmarkCeParts.windows(lm, "Windows", Vector3(x + 4.2, 12.0, sz * 12.1), Vector3(0, 0, 1), 1, 1.0,
				Vector3(2.0, 13.0, 0.2))
	# West front: two towers with spires and a pierced gable between.
	for sz in [-1.0, 1.0]:
		var c := Vector3(-42.0, 0, sz * 9.5)
		lm.box("Pale", c + Vector3(0, 29.0, 0), Vector3(10.0, 58.0, 10.0))
		lm.box("Windows", c + Vector3(-5.05, 44.0, 0), Vector3(0.2, 9.0, 3.2))
		lm.spire("Pale", c + Vector3(0, 58.0, 0), 5.4, 24.0, 0.0, 8)
		for k in 4:
			var q := Basis(Vector3.UP, PI * 0.5 * k) * Vector3(4.8, 0, 4.8)
			lm.spire("Pale", c + q + Vector3(0, 58.0, 0), 0.9, 7.0)
	lm.box("Pale", Vector3(-42.0, 20.0, 0), Vector3(10.0, 40.0, 9.0))
	lm.gable("Roof", Vector3(-42.0, 40.0, 0), 9.0, 10.0, 8.0, Basis(), 0.3, "Pale")
	lm.disc("Windows", Vector3(-47.1, 28.0, 0), Vector3.LEFT, 3.6)
	# South tower: stone shaft, Renaissance gallery, baroque helm.
	var t := Vector3(-14.0, 0, 21.0)
	lm.box("Stone", t + Vector3(0, 28.0, 0), Vector3(14.5, 56.0, 14.5))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkCeParts.windows(lm, "Windows", t + r * Vector3(0, 40.0, 7.3), Vector3(1, 0, 0), 2, 4.4,
			Vector3(2.0, 12.0, 0.2), r)
	lm.box("Pale", t + Vector3(0, 62.0, 0), Vector3(11.0, 12.0, 11.0))
	LandmarkCeParts.windows(lm, "Windows", t + Vector3(0, 62.0, 5.6), Vector3(1, 0, 0), 3, 3.0, Vector3(1.6, 8.0, 0.2))
	lm.box("Pale", t + Vector3(0, 68.2, 0), Vector3(13.0, 0.8, 13.0))
	lm.lathe("Roof", t + Vector3(0, 68.0, 0), PackedVector2Array([Vector2(7.0, 0), Vector2(8.0, 2.5),
		Vector2(7.0, 6.0), Vector2(4.2, 9.0), Vector2(2.8, 11.0)]), 12)
	lm.frustum("Pale", t + Vector3(0, 79.0, 0), 2.4, 2.2, 6.0, 8)
	lm.lathe("Roof", t + Vector3(0, 85.0, 0), PackedVector2Array([Vector2(3.4, 0), Vector2(3.0, 1.0),
		Vector2(1.9, 3.4), Vector2(0.8, 5.4), Vector2(0.2, 6.6)]), 12)
	lm.frustum("Gilt", t + Vector3(0, 91.5, 0), 0.9, 0.0, 1.5, 8)
	LandmarkCeParts.cross(lm, "Gilt", t + Vector3(0, 92.5, 0), VITUS_TOP - 92.5)
	var pivot := Node3D.new()
	pivot.position = Vector3(-10.0, 0, 0)
	model.add_child(pivot)
	lm.commit(pivot)

# --- St Stephen's Cathedral ---

const STEPH_TOP := 136.4

static func stephansdom(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#9A9382", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#6F695F", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#B5643A", 2.5))
	lm.use("Chevron", LandmarkMaterials.pbr("terracotta", "#D8B556", 2.5))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6F9A86", 2.0, 0.55, 0.3))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.box("Stone", Vector3(0, 12.0, 0), Vector3(106.0, 24.0, 34.0))
	lm.gable("Roof", Vector3(0, 24.0, 0), 34.0, 106.0, 36.0, Basis(Vector3.UP, PI * 0.5), 0.8, "Stone")
	# Chevron bands on both roof slopes.
	for sz in [-1.0, 1.0]:
		var dir := Vector3(0, 36.0, -sz * 17.0).normalized()
		var out := Vector3(0, 17.0, sz * 36.0).normalized() * 0.25
		for t in [0.25, 0.5, 0.75]:
			var mid := Vector3(0, 24.0 + 36.0 * t, sz * 17.8 * (1.0 - t))
			var prev := mid + out - dir * 1.6
			for i in range(1, 26):
				var x := -50.0 + 4.0 * i
				var p := Vector3(x, mid.y, mid.z) + out + dir * (1.6 if i % 2 == 0 else -1.6)
				lm.beam("Chevron", prev, p, 0.7, 0.2, out)
				prev = p
	# Choir apse and buttresses along the nave.
	lm.lathe("Stone", Vector3(50.0, 0, 0), PackedVector2Array([Vector2(15.0, 0), Vector2(15.0, 24.0)]), 10, 1.0, 1.0, 0.0, false)
	lm.lathe("Roof", Vector3(50.0, 24.0, 0), PackedVector2Array([Vector2(16.0, 0), Vector2(0.0, 22.0)]), 10, 1.0, 1.0, 0.0, false)
	for sz in [-1.0, 1.0]:
		for i in 11:
			var x := -45.0 + 9.0 * i
			lm.box("Stone", Vector3(x, 13.0, sz * 18.5), Vector3(2.0, 26.0, 3.0))
			lm.spire("Stone", Vector3(x, 26.0, sz * 18.5), 1.0, 7.0)
			LandmarkCeParts.windows(lm, "Windows", Vector3(x + 4.5, 12.0, sz * 17.1), Vector3(0, 0, 1), 1, 1.0,
				Vector3(2.6, 14.0, 0.2))
	# West front: the two Pagan Towers with their octagonal caps.
	for sz in [-1.0, 1.0]:
		var c := Vector3(-46.0, 0, sz * 13.0)
		lm.box("Dark", c + Vector3(0, 25.0, 0), Vector3(12.0, 50.0, 12.0))
		lm.lathe("Copper", c + Vector3(0, 50.0, 0), PackedVector2Array([Vector2(6.0, 0), Vector2(5.4, 4.0),
			Vector2(3.0, 10.0), Vector2(0.4, 15.0)]), 8, 1.0, 1.0, PI / 8.0, false)
		lm.box("Windows", c + Vector3(-6.05, 36.0, 0), Vector3(0.2, 8.0, 3.0))
	lm.disc("Windows", Vector3(-53.2, 36.0, 0), Vector3.LEFT, 5.0)
	# North tower stump with its Renaissance cap.
	var n := Vector3(-14.0, 0, -24.0)
	lm.box("Dark", n + Vector3(0, 28.0, 0), Vector3(20.0, 56.0, 20.0))
	lm.box("Stone", n + Vector3(0, 61.0, 0), Vector3(15.0, 10.0, 15.0))
	lm.lathe("Copper", n + Vector3(0, 66.0, 0), PackedVector2Array([Vector2(8.2, 0), Vector2(8.8, 1.4),
		Vector2(5.0, 4.0), Vector2(2.6, 5.4)]), 12)
	lm.frustum("Copper", n + Vector3(0, 71.4, 0), 1.8, 1.4, 4.0, 8)
	lm.lathe("Copper", n + Vector3(0, 75.4, 0), PackedVector2Array([Vector2(1.9, 0), Vector2(1.0, 1.4), Vector2(0.0, 3.0)]), 8)
	lm.beam("Gilt", n + Vector3(0, 78.0, 0), n + Vector3(0, 80.0, 0), 0.2, 0.2)
	# South tower: shaft, octagonal belfry stage and the 64 m stone spire.
	var s := Vector3(-14.0, 0, 24.0)
	lm.box("Stone", s + Vector3(0, 28.0, 0), Vector3(20.0, 56.0, 20.0))
	lm.box("Stone", s + Vector3(0, 63.0, 0), Vector3(16.0, 14.0, 16.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkCeParts.windows(lm, "Windows", s + r * Vector3(0, 38.0, 10.05), Vector3(1, 0, 0), 2, 5.0,
			Vector3(2.2, 14.0, 0.2), r)
		LandmarkCeParts.windows(lm, "Windows", s + r * Vector3(0, 63.0, 8.05), Vector3(1, 0, 0), 2, 5.0,
			Vector3(2.0, 9.0, 0.2), r)
		for k in [-1.0, 1.0]:
			var cp := s + r * Vector3(k * 7.6, 70.0, 7.6)
			lm.spire("Stone", cp, 0.9, 9.0)
	lm.frustum("Stone", s + Vector3(0, 70.0, 0), 8.2, 6.6, 2.0, 8, PI / 8.0)
	lm.lathe("Stone", s + Vector3(0, 72.0, 0), PackedVector2Array([Vector2(6.6, 0), Vector2(5.6, 12.0),
		Vector2(3.6, 28.0), Vector2(2.0, 42.0), Vector2(0.9, 54.0), Vector2(0.15, STEPH_TOP - 72.0)]),
		8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + TAU * k / 8.0
		lm.beam("Dark", s + Vector3(cos(a) * 6.2, 72.0, sin(a) * 6.2),
			s + Vector3(cos(a) * 1.0, 72.0 + 54.0, sin(a) * 1.0), 0.5, 0.5)
	lm.commit(model)

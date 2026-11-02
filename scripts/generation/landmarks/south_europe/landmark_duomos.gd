class_name SEuDuomos
extends RefCounted

## Milan Cathedral and Florence Cathedral in true metres.

# --- Milan ----------------------------------------------------------------

## Duomo di Milano, origin under the octagonal tiburio, facade west (-X):
## the 158 m Gothic cross of five stepped aisles in pale marble, the
## pinnacled buttress facade with its steep gable and five portals, the
## transept, the polygonal apse and the long files of spires, with the
## main spire and the gilded Madonnina at 108.5 m.
static func milan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E6E0D3", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("limestone", "#B9BCB7", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#55504A", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	var along := Basis(Vector3.UP, PI * 0.5)
	lm.box("Marble", Vector3(-57.5, 21.0, 0), Vector3(95.0, 42.0, 17.0))
	lm.gable("Roof", Vector3(-57.5, 42.0, 0), 17.0, 95.0, 7.0, along, 0.3)
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(-57.5, 16.5, s * 13.5), Vector3(95.0, 33.0, 10.0))
		lm.gable("Roof", Vector3(-57.5, 33.0, s * 13.5), 10.0, 95.0, 3.0, along, 0.2)
		lm.box("Marble", Vector3(-57.5, 12.0, s * 24.0), Vector3(95.0, 24.0, 11.0))
		lm.gable("Roof", Vector3(-57.5, 24.0, s * 24.0), 11.0, 95.0, 3.0, along, 0.2)
		SEuUtil.face_row(lm, "Shadow", Vector3(-57.5, 0, s * 29.55), Vector3.RIGHT, Vector3(0, 0, s),
			6.0, 15, 6.2, 2.2, 13.0, true)
		for k in 15:
			var x := -102.0 + 6.2 * float(k)
			_pin(lm, Vector3(x, 24.0, s * 29.5), 8.0)
			_pin(lm, Vector3(x, 33.0, s * 18.5), 10.0)
			_pin(lm, Vector3(x, 42.0, s * 8.5), 12.0)
		for k in 7:
			_pin(lm, Vector3(s * 10.5, 38.0, -39.0 + 13.0 * float(k)), 9.0)
		_pin(lm, Vector3(s * 10.5, 38.0, 47.0), 11.0)
		_pin(lm, Vector3(s * 10.5, 38.0, -47.0), 11.0)
	# Crossing block, transept, choir and apse.
	lm.box("Marble", Vector3(0, 23.0, 0), Vector3(22.0, 46.0, 22.0))
	lm.box("Marble", Vector3(0, 19.0, 0), Vector3(21.0, 38.0, 93.0))
	lm.gable("Roof", Vector3(0, 38.0, 0), 21.0, 93.0, 6.0, Basis(), 0.4, "Marble")
	lm.box("Marble", Vector3(26.0, 18.0, 0), Vector3(32.0, 36.0, 40.0))
	lm.gable("Roof", Vector3(26.0, 36.0, 0), 40.0, 32.0, 7.0, along, 0.3)
	lm.frustum("Marble", Vector3(42.0, 0, 0), 21.0, 21.0, 36.0, 8, PI / 8.0)
	lm.spire("Roof", Vector3(42.0, 36.0, 0), 19.5, 9.0, 0.0, 8)
	SEuUtil.ring_openings(lm, "Shadow", Vector3(42.0, 0, 0), 21.0, 8, 8, 6.0, 2.4, 14.0, true)
	for k in 5:
		_pin(lm, Vector3(14.0 + 6.0 * float(k), 36.0, 20.0), 9.0)
		_pin(lm, Vector3(14.0 + 6.0 * float(k), 36.0, -20.0), 9.0)
	# West facade: stepped wall, six pinnacled buttresses, portals, gable.
	var fx := -107.0
	lm.box("Marble", Vector3(fx, 14.0, 0), Vector3(4.0, 28.0, 59.0))
	lm.box("Marble", Vector3(fx, 20.0, 0), Vector3(4.0, 40.0, 37.0))
	lm.box("Marble", Vector3(fx, 24.5, 0), Vector3(4.0, 49.0, 17.0))
	lm.gable("Marble", Vector3(fx, 49.0, 0), 17.0, 4.0, 7.0, along, 0.0, "Marble")
	var face := Vector3(fx - 2.0, 0, 0)
	var zv := Vector3(0, 0, 1)
	var nx := Vector3(-1, 0, 0)
	SEuUtil.face_row(lm, "Shadow", face, zv, nx, 0.0, 1, 1.0, 4.4, 11.0, true)
	SEuUtil.face_row(lm, "Shadow", face, zv, nx, 0.0, 2, 27.0, 3.6, 9.0, true)
	SEuUtil.face_row(lm, "Shadow", face, zv, nx, 0.0, 2, 48.0, 3.0, 8.0, true)
	SEuUtil.face_row(lm, "Shadow", face, zv, nx, 14.0, 2, 27.0, 2.4, 14.0, true)
	SEuUtil.face_row(lm, "Shadow", face, zv, nx, 14.0, 2, 48.0, 2.2, 11.0, true)
	SEuUtil.face_row(lm, "Shadow", face, zv, nx, 28.0, 1, 1.0, 4.8, 15.0, true)
	for s in [-1.0, 1.0]:
		for k in 3:
			var h := 50.0 + 4.0 * float(k)
			var z: float = s * (29.5 - 10.5 * float(k))
			lm.box("Marble", Vector3(fx - 2.4, h * 0.5, z), Vector3(3.2, h, 3.2))
			lm.spire("Roof", Vector3(fx - 2.4, h, z), 1.3, 11.0, 0.0)
	# Tiburio and the main spire with the Madonnina.
	lm.frustum("Marble", Vector3(0, 44.0, 0), 15.5, 15.5, 22.0, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Shadow", Vector3(0, 44.0, 0), 15.5, 8, 8, 5.0, 3.0, 13.0, true)
	lm.frustum("Marble", Vector3(0, 66.0, 0), 9.6, 9.0, 12.0, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Shadow", Vector3(0, 66.0, 0), 9.6, 8, 8, 3.0, 2.2, 7.0, true)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		_pin(lm, Vector3(cos(a) * 15.5, 66.0, sin(a) * 15.5), 12.0)
	lm.lathe("Marble", Vector3(0, 78.0, 0), PackedVector2Array([Vector2(8.0, 0), Vector2(5.4, 10.0),
		Vector2(2.2, 19.0), Vector2(0.35, 26.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	LandmarkKits.statue_figure(lm, "Gold", Vector3(0, 104.0, 0), 4.5, true)
	lm.commit(model)

## A pinnacle: square shaft and a needle spire, `h` tall from `base`.
static func _pin(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	lm.box("Marble", base + Vector3(0, h * 0.2, 0), Vector3(1.3, h * 0.4, 1.3))
	lm.spire("Marble", base + Vector3(0, h * 0.4, 0), 0.8, h * 0.6, 0.0)

# --- Florence -------------------------------------------------------------

## Santa Maria del Fiore, origin under the dome, facade west (-X): the
## nave in white marble banded with green and pink, the neo-Gothic
## polychrome facade, the three tribunes round Brunelleschi's octagonal
## dome (red tiles between eight white ribs, 114.5 m with lantern, ball
## and cross), and Giotto's 84.7 m campanile at the south-west corner.
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
	# Nave and aisles, banded in green marble.
	lm.box("Marble", Vector3(-61.0, 17.5, 0), Vector3(78.0, 35.0, 19.0))
	lm.gable("Roof", Vector3(-61.0, 35.0, 0), 19.0, 78.0, 7.0, along, 0.3)
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(-61.0, 11.0, s * 14.25), Vector3(78.0, 22.0, 9.5))
		lm.gable("Roof", Vector3(-61.0, 22.0, s * 14.25), 9.5, 78.0, 3.0, along, 0.2)
		for k in 4:
			lm.box("Green", Vector3(-61.0, 4.0 + 5.0 * float(k), s * 19.03), Vector3(78.0, 0.8, 0.3))
		SEuUtil.face_row(lm, "Shadow", Vector3(-61.0, 0, s * 19.1), Vector3.RIGHT, Vector3(0, 0, s),
			5.0, 8, 9.2, 2.0, 12.0, true)
	# Octagonal tambour with oculi, the three tribunes and the ribbed dome.
	lm.frustum("Marble", Vector3.ZERO, 29.66, 29.66, 55.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var out := Vector3(cos(a), 0, sin(a))
		lm.disc("Shadow", out * 27.5 + Vector3(0, 46.0, 0), out, 2.6, 16)
		lm.box("Green", out * 27.45 + Vector3(0, 40.0, 0), Vector3(22.0, 1.2, 0.2), Basis(Vector3.UP, atan2(out.x, out.z)))
	for p in [Vector3(26.0, 0, 0), Vector3(0, 0, 26.0), Vector3(0, 0, -26.0)]:
		lm.frustum("Marble", p, 17.5, 17.5, 36.0, 8, PI / 8.0)
		lm.spire("Roof", p + Vector3(0, 36.0, 0), 16.2, 9.0, 0.0, 8)
		lm.frustum("Marble", p + Vector3(0, 46.0, 0), 4.0, 3.6, 5.0, 8, PI / 8.0)
	var shell := SEuUtil.ogive(29.66, 36.5, 12)
	lm.lathe("Tile", Vector3(0, 55.0, 0), shell, 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		for j in shell.size() - 2:
			lm.beam("Marble", Vector3(cos(a) * shell[j].x, 55.0 + shell[j].y, sin(a) * shell[j].x),
				Vector3(cos(a) * shell[j + 1].x, 55.0 + shell[j + 1].y, sin(a) * shell[j + 1].x), 1.4, 0.9)
	lm.frustum("Marble", Vector3(0, 89.5, 0), 5.4, 4.6, 16.0, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Shadow", Vector3(0, 89.5, 0), 5.3, 8, 8, 4.0, 1.4, 8.0, true)
	lm.lathe("Roof", Vector3(0, 105.5, 0), PackedVector2Array([Vector2(4.8, 0), Vector2(3.4, 2.0),
		Vector2(0.3, 4.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	SEuUtil.finial(lm, "Gold", Vector3(0, 109.5, 0), 5.0)
	# Polychrome west facade (x = -100) with portals, lunettes and gable.
	var fx := -102.5
	lm.box("Marble", Vector3(fx, 18.0, 0), Vector3(5.0, 36.0, 40.0))
	lm.box("Marble", Vector3(fx, 23.0, 0), Vector3(5.0, 46.0, 20.0))
	lm.gable("Marble", Vector3(fx, 46.0, 0), 20.0, 5.0, 9.0, along, 0.0, "Marble")
	var face := Vector3(fx - 2.5, 0, 0)
	for k in 5:
		lm.box("Green" if k % 2 == 0 else "Pink", Vector3(fx - 2.55, 8.0 + 8.0 * float(k), 0),
			Vector3(0.2, 1.0, 40.0 if k < 4 else 20.0))
	SEuUtil.face_row(lm, "Shadow", face, Vector3(0, 0, 1), Vector3(-1, 0, 0), 0.0, 3, 11.0, 4.6, 12.0, true)
	for z in [-11.0, 0.0, 11.0]:
		lm.disc("Gold", face + Vector3(-0.15, 17.0, z), Vector3(-1, 0, 0), 3.0, 16)
	lm.disc("Gold", face + Vector3(-0.15, 40.0, 0), Vector3(-1, 0, 0), 4.0, 20)
	_campanile(lm, Vector3(-66.0, 0, 31.0))
	lm.commit(model)

## Giotto's bell tower: 14.45 m square, 84.7 m, banded in white, green
## and pink marble with tall mullioned windows on the upper stages.
static func _campanile(lm: LandmarkMesh, c: Vector3) -> void:
	var w := 14.45
	lm.box("Marble", c + Vector3(0, 42.0, 0), Vector3(w, 84.0, w))
	lm.box("Marble", c + Vector3(0, 84.35, 0), Vector3(w + 1.4, 0.7, w + 1.4))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		for b in 7:
			lm.box("Green" if b % 2 == 0 else "Pink", c + out * (w * 0.5 + 0.1) + Vector3(0, 6.0 + 12.0 * float(b), 0),
				Vector3(w, 1.0, 0.2), r)
		lm.box("Marble", c + out * (w * 0.5) + right * (w * 0.5) + Vector3(0, 42.0, 0), Vector3(1.6, 84.0, 1.6), r)
		SEuUtil.face_row(lm, "Shadow", c + out * (w * 0.5), right, out, 15.0, 2, 4.4, 1.6, 6.5, true)
		SEuUtil.face_row(lm, "Shadow", c + out * (w * 0.5), right, out, 30.0, 1, 1.0, 3.4, 11.0, true)
		SEuUtil.face_row(lm, "Shadow", c + out * (w * 0.5), right, out, 48.0, 1, 1.0, 3.6, 14.0, true)
		SEuUtil.face_row(lm, "Shadow", c + out * (w * 0.5), right, out, 66.0, 3, 3.8, 2.4, 15.0, true)

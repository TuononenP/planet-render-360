class_name SEuRomeCivic
extends RefCounted

## Castel Sant'Angelo, the Trevi Fountain and the Vittoriano in true
## metres.

# --- Castel Sant'Angelo ---------------------------------------------

## Hadrian's Mausoleum turned papal fortress, origin at its axis: the
## brick drum (64 m across) on the square base with four corner
## bastions, the cornice, the upper drum and lantern, and the bronze
## angel on the top (48 m); Ponte Sant'Angelo of five arches runs east.
static func castel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F6A52", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CBB899", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4C4439", 3.0))
	lm.use("Bridge", LandmarkMaterials.pbr("limestone", "#BDAE92", 3.0))
	lm.use("Angel", LandmarkMaterials.paint("#5E6B4F", 0.5, 0.5))
	lm.box("Brick", Vector3(0, 8.0, 0), Vector3(80.0, 16.0, 80.0))
	lm.box("Stone", Vector3(0, 16.5, 0), Vector3(82.0, 1.0, 82.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.frustum("Brick", Vector3(sx * 44.0, -2.0, sz * 44.0), 21.0, 17.0, 24.0, 4, PI * 0.25)
			lm.box("Stone", Vector3(sx * 44.0, 22.4, sz * 44.0), Vector3(25.0, 1.0, 25.0))
	SEuUtil.crenels(lm, "Stone", Vector3(-40.0, 17.0, 40.0), Vector3(40.0, 17.0, 40.0), 1.6, 1.4, 1.2)
	SEuUtil.crenels(lm, "Stone", Vector3(-40.0, 17.0, -40.0), Vector3(40.0, 17.0, -40.0), 1.6, 1.4, 1.2)
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 40.05), Vector3.RIGHT, Vector3(0, 0, 1), 5.0, 9, 8.0, 2.0, 5.0)
	# Drum, cornice, upper drum, lantern, pedestal and angel.
	lm.frustum("Brick", Vector3(0, 16.0, 0), 32.0, 32.0, 20.0, 32)
	lm.frustum("Stone", Vector3(0, 36.0, 0), 32.8, 32.8, 1.2, 32)
	SEuUtil.ring_openings(lm, "Shadow", Vector3(0, 16.0, 0), 32.0, 32, 16, 8.0, 1.2, 4.0, false, 0.2)
	lm.frustum("Brick", Vector3(0, 37.2, 0), 20.0, 20.0, 3.3, 24)
	lm.frustum("Stone", Vector3(0, 40.5, 0), 10.5, 10.0, 2.0, 16)
	SEuUtil.ring_openings(lm, "Shadow", Vector3(0, 37.2, 0), 20.0, 24, 8, 0.6, 2.0, 2.2, false)
	lm.box("Stone", Vector3(0, 43.0, 0), Vector3(3.4, 1.0, 3.4))
	LandmarkKits.statue_figure(lm, "Angel", Vector3(0, 43.5, 0), 4.6, true)
	lm.box("Angel", Vector3(0, 46.6, 0), Vector3(0.3, 2.4, 4.2), Basis(Vector3.UP, 0.4))
	SEuUtil.arch_bridge(lm, "Bridge", 62.0, 196.0, 1.5, -14.0, 5, 5.5, 3.2)
	for i in 6:
		for s in [-1.0, 1.0]:
			LandmarkKits.statue_figure(lm, "Stone", Vector3(76.0 + 22.0 * float(i), 2.0, s * 5.2), 3.6)
	lm.commit(model)

# --- Trevi Fountain -------------------------------------------------

## The Baroque wall-fountain against Palazzo Poli, origin at the centre
## of its basin, facade facing +Z: 49 m wide, 26.3 m to the top of the
## attic statues. Four giant Corinthian columns frame the niche of
## Oceanus, flanked by niches, over a travertine rock and a pool.
static func trevi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#CDBB98", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E0D2B0", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#51493C", 3.0))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#B7AA8E", 4.0))
	lm.use("Water", LandmarkMaterials.glass("#2A6C78"))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EFEADF", 2.0))
	var f := -10.0
	# Palazzo Poli wings and the central attic.
	lm.box("Travertine", Vector3(0, 8.75, f - 6.0), Vector3(49.15, 17.5, 12.0))
	lm.box("Trim", Vector3(0, 18.0, f - 5.5), Vector3(50.2, 1.0, 13.0))
	lm.box("Travertine", Vector3(0, 20.1, f - 6.0), Vector3(26.0, 3.2, 12.0))
	lm.box("Trim", Vector3(0, 21.9, f - 5.5), Vector3(27.0, 0.6, 13.0))
	for s in [-1.0, 1.0]:
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 18.5, 0, f + 0.05), Vector3.RIGHT, Vector3(0, 0, 1),
			9.0, 3, 5.0, 1.3, 3.2)
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 18.5, 0, f + 0.05), Vector3.RIGHT, Vector3(0, 0, 1),
			3.0, 3, 5.0, 1.3, 3.0)
	# Triumphal arch: protruding central bay, niche, columns, entablature.
	lm.box("Travertine", Vector3(0, 8.75, f + 1.5), Vector3(24.0, 17.5, 3.0))
	SEuUtil.opening(lm, "Shadow", Vector3(0, 3.0, f + 3.08), Vector3.RIGHT, Vector3.UP, 8.0, 13.0)
	for s in [-1.0, 1.0]:
		SEuUtil.opening(lm, "Shadow", Vector3(s * 9.4, 4.0, f + 3.08), Vector3.RIGHT, Vector3.UP, 3.6, 8.0)
	SEuUtil.column_row(lm, "Trim", Vector3(-11.0, 0, f + 4.2), Vector3(11.0, 0, f + 4.2), 4, 15.5, 0.8, 12)
	lm.box("Trim", Vector3(0, 16.6, f + 3.2), Vector3(26.0, 1.8, 3.4))
	lm.gable("Trim", Vector3(0, 17.5, f + 3.2), 24.0, 3.6, 1.4, Basis(), 0.0, "Trim")
	for k in 4:
		var sx := -11.0 + 22.0 * float(k) / 3.0
		lm.box("Trim", Vector3(sx, 22.5, f - 3.0), Vector3(2.2, 1.2, 2.2))
		LandmarkKits.statue_figure(lm, "Marble", Vector3(sx, 23.1, f - 3.0), 3.2)
	# Rock base with Oceanus and the sea horses.
	SEuUtil.blob(lm, "Rock", Vector3(0, 0, f + 6.0), 19.0, 5.0, 7.0, Vector3.ZERO, true, 8, 20)
	lm.box("Marble", Vector3(0, 5.2, f + 4.0), Vector3(4.0, 1.0, 3.0))
	LandmarkKits.statue_figure(lm, "Marble", Vector3(0, 5.7, f + 4.0), 7.0, true)
	for s in [-1.0, 1.0]:
		SEuUtil.blob(lm, "Marble", Vector3(s * 7.0, 0.8, f + 9.5), 2.4, 2.8, 1.8, Vector3(0, 0, 0.3), true, 6, 10)
	# Basin: rim, water, steps.
	lm.box("Water", Vector3(0, 0.55, f + 14.0), Vector3(48.0, 0.1, 24.0))
	lm.box("Travertine", Vector3(0, 0.6, f + 26.2), Vector3(50.0, 1.2, 0.8))
	for s in [-1.0, 1.0]:
		lm.box("Travertine", Vector3(s * 24.6, 0.6, f + 14.0), Vector3(0.8, 1.2, 25.0))
	SEuUtil.steps_up(lm, "Travertine", Vector3(0, 0, f + 26.6), Vector3(0, 0, 1), 50.0, 1.0, 0.18, 3)
	lm.commit(model)

# --- Vittoriano ---------------------------------------------------------

## Altare della Patria in Botticino marble, origin at the monument axis,
## facing +Z (yaw_deg turns it onto Piazza Venezia): stepped terraces
## 135 m wide with the great stairs and the equestrian statue, the
## 16-column Portico della Libertà at 70 m, and the two propylaea with
## their gilded bronze quadrigae at 81 m.
static func vittoriano(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E8E4DA", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F1EDE3", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#58514A", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#D2CCBE", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#58684F", 0.5, 0.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Marble", Vector3(0, 6.5, 27.0), Vector3(135.0, 13.0, 26.0))
	lm.box("Marble", Vector3(0, 13.0, 2.0), Vector3(135.0, 26.0, 24.0))
	lm.box("Marble", Vector3(0, 24.0, -25.0), Vector3(135.0, 48.0, 30.0))
	lm.box("Trim", Vector3(0, 13.3, 27.0), Vector3(136.0, 0.6, 27.0))
	lm.box("Trim", Vector3(0, 26.3, 2.0), Vector3(136.0, 0.6, 25.0))
	SEuUtil.face_row(lm, "Shadow", Vector3(-40.0, 0, 40.05), Vector3.RIGHT, Vector3(0, 0, 1), 3.0, 5, 8.0, 2.4, 7.0)
	SEuUtil.face_row(lm, "Shadow", Vector3(40.0, 0, 40.05), Vector3.RIGHT, Vector3(0, 0, 1), 3.0, 5, 8.0, 2.4, 7.0)
	SEuUtil.steps_up(lm, "Steps", Vector3(0, 0, 40.0), Vector3(0, 0, 1), 34.0, 1.4, 1.0, 13)
	SEuUtil.steps_up(lm, "Steps", Vector3(0, 13.0, 14.0), Vector3(0, 0, 1), 36.0, 1.1, 1.0, 13)
	SEuUtil.steps_up(lm, "Steps", Vector3(0, 26.0, -10.0), Vector3(0, 0, 1), 36.0, 1.0, 1.0, 22)
	# Equestrian statue of Victor Emmanuel II.
	lm.box("Marble", Vector3(0, 17.0, 34.0), Vector3(8.0, 8.0, 14.0))
	lm.box("Bronze", Vector3(0, 23.2, 34.0), Vector3(3.4, 4.4, 9.0))
	lm.box("Bronze", Vector3(0, 27.2, 36.4), Vector3(2.2, 3.6, 3.2))
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0, 25.6, 33.0), 6.0)
	# Portico della Libertà on top of the back terrace.
	SEuUtil.column_row(lm, "Trim", Vector3(-48.0, 48.0, -36.0), Vector3(48.0, 48.0, -36.0), 16, 15.0, 0.95, 12)
	lm.box("Marble", Vector3(0, 59.0, -42.0), Vector3(110.0, 22.0, 3.0))
	lm.box("Trim", Vector3(0, 65.0, -37.0), Vector3(110.0, 4.0, 12.0))
	lm.box("Marble", Vector3(0, 68.5, -37.0), Vector3(112.0, 3.0, 12.5))
	# Propylaea at both ends, each crowned by a quadriga.
	for s in [-1.0, 1.0]:
		var px: float = s * 57.0
		SEuUtil.column_row(lm, "Trim", Vector3(px - 8.0, 48.0, -12.5), Vector3(px + 8.0, 48.0, -12.5), 6, 15.0, 0.95, 12)
		lm.box("Marble", Vector3(px, 59.0, -27.0), Vector3(22.0, 22.0, 3.0))
		lm.box("Marble", Vector3(px - s * 10.5, 59.0, -19.0), Vector3(1.0, 22.0, 18.0))
		lm.box("Marble", Vector3(px + s * 10.5, 59.0, -19.0), Vector3(1.0, 22.0, 18.0))
		lm.box("Trim", Vector3(px, 65.0, -19.0), Vector3(23.0, 4.0, 19.0))
		lm.box("Marble", Vector3(px, 68.6, -19.0), Vector3(23.5, 3.2, 19.5))
		_quadriga(lm, Vector3(px, 70.2, -19.0))
	lm.commit(model)

## Winged Victory driving four horses abreast (gilded bronze), 10.8 m.
static func _quadriga(lm: LandmarkMesh, base: Vector3) -> void:
	lm.box("Marble", base + Vector3(0, 0.6, 0), Vector3(12.0, 1.2, 6.0))
	lm.box("Gold", base + Vector3(0, 2.4, -1.2), Vector3(3.2, 2.4, 3.0))
	for k in 4:
		var x := -4.2 + 2.8 * float(k)
		lm.box("Gold", base + Vector3(x, 3.0, 1.4), Vector3(1.4, 2.6, 3.8))
		lm.box("Gold", base + Vector3(x, 4.6, 2.8), Vector3(1.0, 2.6, 1.2), Basis(Vector3.RIGHT, 0.3))
	LandmarkKits.statue_figure(lm, "Gold", base + Vector3(0, 3.5, -1.2), 7.3, true)
	for s in [-1.0, 1.0]:
		lm.box("Gold", base + Vector3(s * 1.4, 7.4, -1.6), Vector3(0.3, 4.4, 2.6), Basis(Vector3.BACK, s * 0.35))

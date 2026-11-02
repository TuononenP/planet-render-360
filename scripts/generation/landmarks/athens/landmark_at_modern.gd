class_name LandmarkAtModern
extends RefCounted

## Neoclassical Athens in true metres: the Hellenic Parliament (Old
## Royal Palace), the Zappeion and the Academy of Athens.

## Three rows of arched windows (ground, piano nobile, upper) along a
## wall face: `o` the face centre at ground, `right` along the wall.
static func _window_rows(lm: LandmarkMesh, o: Vector3, right: Vector3, out: Vector3, n: int,
		pitch: float, ys: Array[float], hs: Array[float]) -> void:
	for r in ys.size():
		SEuUtil.face_row(lm, "Shadow", o, right, out, ys[r], n, pitch, 1.9, hs[r])

# --- Hellenic Parliament ----------------------------------------------

## Origin at the middle of the palace, the Syntagma front toward +Z
## (yaw_deg turns it west). Otto's Old Royal Palace of 1843: an 80 x 62 m
## block of three floors (rusticated ground floor, cream ashlar above),
## the 8-column Ionic portico on a terrace and a broad stair, projecting
## end pavilions, a cornice with a balustrade and a low hipped roof. 24 m.
static func parliament(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rust", LandmarkMaterials.pbr("limestone", "#D2C09E", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E3D7BD", 4.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#ECE3D0", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4339", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6F7479", 3.0))
	lm.box("Rust", Vector3(0, 3.75, 0), Vector3(80.0, 10.5, 62.0))
	lm.box("Stone", Vector3(0, 14.25, 0), Vector3(80.0, 10.5, 62.0))
	lm.box("Marble", Vector3(0, 20.25, 0), Vector3(81.4, 1.5, 63.4))
	lm.box("Stone", Vector3(0, 21.6, 0), Vector3(80.0, 1.2, 62.0))
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 40.0, 22.15, 0), Vector3(0.8, 1.5, 62.4))
		lm.box("Marble", Vector3(0, 22.15, s * 31.0), Vector3(80.8, 1.5, 0.8))
		lm.box("Rust", Vector3(s * 33.0, 3.75, 32.0), Vector3(14.0, 10.5, 2.0))
		lm.box("Stone", Vector3(s * 33.0, 14.25, 32.0), Vector3(14.0, 10.5, 2.0))
		lm.box("Marble", Vector3(s * 33.0, 20.25, 32.0), Vector3(14.8, 1.5, 2.8))
	lm.gable("Roof", Vector3(0, 22.8, 0), 56.0, 76.0, 1.2, Basis(Vector3.UP, PI * 0.5), 0.0, "Stone")
	# Terrace stair and the Ionic portico (floor at 2.2 m).
	for k in range(1, 9):
		var top := 2.2 - 0.27 * float(k)
		lm.box("Marble", Vector3(0, (top - 3.0) * 0.5, 37.5 + 0.8 * (float(k) - 0.5)), Vector3(38.0, top + 3.0, 0.8))
	lm.box("Marble", Vector3(0, -0.4, 34.25), Vector3(38.0, 5.2, 6.5))
	for i in 8:
		AtUtil.ionic(lm, "Marble", Vector3(-15.4 + 4.4 * float(i), 2.2, 35.5), 14.5, 0.8, 16, 0.0)
	lm.box("Marble", Vector3(0, 17.3, 35.5), Vector3(33.6, 1.2, 1.8))
	lm.box("Stone", Vector3(0, 18.5, 35.5), Vector3(33.6, 1.2, 1.6))
	lm.box("Marble", Vector3(0, 19.5, 35.5), Vector3(34.2, 0.8, 2.4))
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 16.8, 18.5, 33.0), Vector3(1.8, 3.2, 5.0))
		lm.box("Marble", Vector3(s * 16.9, 20.4, 33.0), Vector3(0.5, 1.0, 5.0))
	lm.box("Marble", Vector3(0, 20.4, 36.5), Vector3(34.2, 1.0, 0.5))
	lm.box("Shadow", Vector3(0, 5.2, 31.06), Vector3(5.0, 6.0, 0.12))
	# Window rows on all four faces and the pavilions.
	var ys: Array[float] = [3.0, 10.6, 16.2]
	var hs: Array[float] = [5.2, 4.6, 3.0]
	_window_rows(lm, Vector3(0, 0, 31.0), Vector3.RIGHT, Vector3(0, 0, 1), 11, 4.4, ys, hs)
	_window_rows(lm, Vector3(0, 0, -31.0), Vector3.RIGHT, Vector3(0, 0, -1), 17, 4.6, ys, hs)
	for s in [-1.0, 1.0]:
		_window_rows(lm, Vector3(s * 33.0, 0, 33.0), Vector3.RIGHT, Vector3(0, 0, 1), 3, 4.4, ys, hs)
		_window_rows(lm, Vector3(s * 40.0, 0, 0), Vector3(0, 0, 1), Vector3(s, 0, 0), 12, 4.8, ys, hs)
	lm.commit(model)

# --- Zappeion ----------------------------------------------------------

## Origin at the middle of the hall, the Ionic portico toward +Z
## (yaw_deg). Theophil Hansen's Zappeion Megaron: a 70 x 52 m block with
## a hexastyle Ionic portico under a pediment, pilastered fronts, and
## behind it the circular peristyle hall as a glazed drum and low dome
## rising to 19.9 m.
static func zappeion(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E4D9C2", 4.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EEE6D3", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4339", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#7B8588", 3.0))
	lm.box("Stone", Vector3(0, 6.0, 0), Vector3(70.0, 13.0, 52.0))
	lm.box("Marble", Vector3(0, 12.1, 0), Vector3(71.2, 0.8, 53.2))
	lm.box("Stone", Vector3(0, 12.9, 0), Vector3(70.0, 0.8, 52.0))
	# Portico on a stylobate of three steps.
	AtUtil.steps(lm, "Marble", Vector3(0, 1.2, 29.0), 20.0, 6.0, 3, 0.4, 0.5, 2.0)
	for i in 6:
		AtUtil.ionic(lm, "Marble", Vector3(-8.0 + 3.2 * float(i), 1.2, 30.0), 9.0, 0.62, 16, 0.0)
	lm.box("Marble", Vector3(0, 10.5, 30.0), Vector3(18.4, 0.6, 1.5))
	lm.box("Stone", Vector3(0, 11.1, 30.0), Vector3(18.3, 0.7, 1.4))
	lm.box("Marble", Vector3(0, 11.6, 30.0), Vector3(19.0, 0.3, 2.1))
	AtUtil.roof(lm, "Marble", "Marble", "Stone", Vector3(0, 11.7, 28.0), 18.6, 6.0, 2.0, 0.2)
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 9.1, 6.0, 26.5), Vector3(1.6, 12.0, 1.4))
	lm.box("Shadow", Vector3(0, 4.5, 26.06), Vector3(3.6, 7.0, 0.12))
	for i in 11:
		var x := -25.0 + 5.0 * float(i)
		lm.box("Marble", Vector3(x, 6.5, 26.1), Vector3(0.8, 10.0, 0.3))
	var ys: Array[float] = [2.0, 7.6]
	var hs: Array[float] = [4.6, 3.9]
	_window_rows(lm, Vector3(-22.5, 0, 26.0), Vector3.RIGHT, Vector3(0, 0, 1), 2, 5.0, ys, hs)
	_window_rows(lm, Vector3(22.5, 0, 26.0), Vector3.RIGHT, Vector3(0, 0, 1), 2, 5.0, ys, hs)
	_window_rows(lm, Vector3(0, 0, -26.0), Vector3.RIGHT, Vector3(0, 0, -1), 13, 5.0, ys, hs)
	for s in [-1.0, 1.0]:
		_window_rows(lm, Vector3(s * 35.0, 0, 0), Vector3(0, 0, 1), Vector3(s, 0, 0), 9, 5.2, ys, hs)
	# The circular peristyle hall: drum, ring of windows, cornice, glazed dome.
	lm.frustum("Stone", Vector3(0, 13.3, 0), 14.5, 14.5, 3.3, 32)
	SEuUtil.ring_openings(lm, "Shadow", Vector3(0, 13.3, 0), 14.5, 32, 16, 0.6, 1.6, 2.1, false, 0.1)
	lm.frustum("Marble", Vector3(0, 16.6, 0), 15.1, 15.1, 0.6, 32)
	lm.lathe("Dome", Vector3(0, 17.2, 0), SEuUtil.dome(14.2, 2.7, 8), 32)
	lm.commit(model)

# --- Academy of Athens ---------------------------------------------------

## Origin at the middle of the building, the Ionic portico toward +Z
## (yaw_deg onto Panepistimiou Street). Hansen's marble Academy: a 64 m
## front with the hexastyle portico and pediment (blue tympanum) over
## five steps, two lower wings, and before the steps the two 14 m Ionic
## columns carrying Athena with her spear and Apollo with his lyre
## (19.2 m to the top of the statues).
static func academy(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EAE0CB", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DCCFB4", 4.0))
	lm.use("Blue", LandmarkMaterials.pbr("render", "#2F5C8A", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4339", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	var y0 := 1.5
	AtUtil.steps(lm, "Marble", Vector3(0, y0, 20.25), 19.4, 4.5, 5, 0.3, 0.45, 3.0)
	lm.box("Marble", Vector3(0, 7.75, 0), Vector3(19.0, 12.5, 36.0))
	# Shoulders between the portico block and the wings.
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 14.25, 7.25, 0), Vector3(9.5, 11.5, 36.0))
		lm.box("Marble", Vector3(s * 14.25, 13.2, 0), Vector3(10.1, 0.5, 36.6))
		lm.box("Stone", Vector3(s * 14.25, 13.6, 0), Vector3(9.5, 0.4, 36.0))
	for i in 6:
		AtUtil.ionic(lm, "Marble", Vector3(-7.5 + 3.0 * float(i), y0, 21.0), 10.4, 0.6, 16, 0.0)
	lm.box("Marble", Vector3(0, y0 + 10.8, 21.0), Vector3(18.6, 0.8, 1.4))
	lm.box("Blue", Vector3(0, y0 + 11.6, 21.0), Vector3(18.5, 0.8, 1.3))
	lm.box("Marble", Vector3(0, y0 + 12.25, 21.0), Vector3(19.2, 0.5, 2.1))
	AtUtil.roof(lm, "Stone", "Marble", "Blue", Vector3(0, y0 + 12.5, 0.9), 19.0, 42.4, 3.0, 0.2)
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 9.5, y0 + 6.0, 20.0), Vector3(1.4, 12.0, 4.4))
		lm.box("Stone", Vector3(s * 25.5, 7.5, 0), Vector3(13.0, 12.0, 26.0))
		lm.box("Marble", Vector3(s * 25.5, 13.4, 0), Vector3(13.8, 0.8, 26.8))
		lm.box("Stone", Vector3(s * 25.5, 14.0, 0), Vector3(13.0, 0.4, 26.0))
	lm.box("Shadow", Vector3(0, y0 + 3.5, 18.06), Vector3(3.4, 7.0, 0.12))
	var ys: Array[float] = [y0 + 1.0, y0 + 6.6]
	var hs: Array[float] = [4.2, 3.8]
	for s in [-1.0, 1.0]:
		_window_rows(lm, Vector3(s * 14.25, 0, 18.0), Vector3.RIGHT, Vector3(0, 0, 1), 2, 4.0, ys, hs)
		_window_rows(lm, Vector3(s * 25.5, 0, 13.0), Vector3.RIGHT, Vector3(0, 0, 1), 3, 3.6, ys, hs)
		_window_rows(lm, Vector3(s * 32.0, 0, 0), Vector3(0, 0, 1), Vector3(s, 0, 0), 5, 4.8, ys, hs)
	# The two statue columns before the steps: Athena (left) and Apollo.
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 14.5, 0.5, 27.0), Vector3(2.2, 1.0, 2.2))
		AtUtil.ionic(lm, "Marble", Vector3(s * 14.5, 1.0, 27.0), 13.0, 0.75, 16, 0.0)
		lm.box("Marble", Vector3(s * 14.5, 14.4, 27.0), Vector3(1.8, 0.8, 1.8))
		LandmarkKits.statue_figure(lm, "Marble", Vector3(s * 14.5, 14.8, 27.0), 4.4, s < 0.0)
	lm.beam("Gold", Vector3(-14.0, 14.9, 27.0), Vector3(-14.0, 19.2, 27.0), 0.1, 0.1)
	lm.box("Gold", Vector3(15.1, 17.4, 27.0), Vector3(0.1, 0.9, 0.5))
	lm.commit(model)

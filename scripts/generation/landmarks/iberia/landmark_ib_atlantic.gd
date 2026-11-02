class_name LandmarkIbAtlantic
extends RefCounted

## Three landmarks of the Atlantic west: Santiago de Compostela
## Cathedral, the Pena Palace on its Sintra crag and the Jeronimos
## Monastery of Lisbon, in true metres, each with its main front
## toward +Z (the registry yaw_deg turns it onto the real bearing).

# --- Santiago de Compostela Cathedral ---

const SAN_TOP := 75.0

## The pilgrim cathedral, origin at the middle of its 97 m length: the
## Obradoiro facade toward +Z (Casas y Novoa's baroque front, a stepped
## central pediment between the Berenguela and Carraca towers of 75 m
## with their stone caps) above the double flight of the Obradoiro
## stair, the 21 m Romanesque nave with aisles, the 62 m transept and
## the crossing lantern, the polygonal apse ringed by chapels and,
## south (+X) of the western nave, the Renaissance cloister. The golden
## granite of the front against the greyer stone of the body.
static func santiago(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Light", LandmarkMaterials.pbr("limestone", "#CDBFA0", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B6AE9E", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("stone", "#8C8A83", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3833", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Steps", LandmarkMaterials.pbr("pavement", "#B5AD9D", 3.0))
	# Nave with aisles, transept, crossing lantern.
	lm.box("Granite", Vector3(0, 10.5, 0), Vector3(20.0, 21.0, 80.0))
	lm.gable("Roof", Vector3(0, 21.0, 0), 20.0, 80.0, 5.0, Basis(), 0.5)
	for s in [-1.0, 1.0]:
		lm.box("Granite", Vector3(s * 14.75, 6.5, 0), Vector3(9.5, 13.0, 76.0))
		LandmarkCeParts.hip(lm, "Roof", Vector3(s * 14.75, 13.0, 0), 9.5, 76.0, 1.6)
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 19.5, 0, 0), Vector3(0, 0, 1), Vector3(s, 0, 0), 4.0, 7, 9.5, 1.6, 6.0)
		for z in [-33.25, -23.75, -14.25, -4.75, 4.75, 14.25, 23.75, 33.25]:
			lm.box("Granite", Vector3(s * 19.9, 8.0, z), Vector3(1.2, 16.0, 1.6))
	lm.box("Granite", Vector3(0, 10.5, 5.0), Vector3(62.0, 21.0, 18.0))
	lm.gable("Roof", Vector3(0, 21.0, 5.0), 18.0, 62.0, 4.5, Basis(Vector3.UP, PI * 0.5), 0.5)
	for s in [-1.0, 1.0]:
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 31.0, 0, 5.0), Vector3(0, 0, 1), Vector3(s, 0, 0), 4.0, 2, 8.0, 3.0, 11.0, true)
	var cc := Vector3(0, 0, 5.0)
	lm.frustum("Granite", cc + Vector3(0, 21.0, 0), 7.8, 7.8, 13.0, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Shadow", cc + Vector3(0, 21.0, 0), 7.8, 8, 8, 3.0, 1.8, 7.0, true)
	lm.frustum("Roof", cc + Vector3(0, 34.0, 0), 8.6, 1.0, 9.0, 8, PI / 8.0)
	lm.box("Gilt", cc + Vector3(0, 44.6, 0), Vector3(0.3, 3.0, 0.3))
	lm.box("Gilt", cc + Vector3(0, 45.0, 0), Vector3(1.4, 0.3, 0.3))
	# Apse and radiating chapels (east end, -Z).
	lm.frustum("Granite", Vector3(0, 0, -36.0), 13.0, 13.0, 21.0, 10, PI / 10.0)
	lm.frustum("Roof", Vector3(0, 21.0, -36.0), 13.8, 0.6, 7.0, 10, PI / 10.0)
	for a in [-72.0, -36.0, 0.0, 36.0, 72.0]:
		var ang := deg_to_rad(a)
		var p := Vector3(sin(ang) * 14.8, 0, -36.0 - cos(ang) * 14.8)
		var b := Basis(Vector3.UP, -ang)
		lm.box("Granite", p + Vector3(0, 5.0, 0), Vector3(6.4, 10.0, 6.4), b)
		lm.frustum("Roof", p + Vector3(0, 10.0, 0), 4.2, 0.4, 3.6, 8, ang)
	# Cloister south of the western nave.
	LandmarkIbUtil.ring_walls(lm, "Granite", Vector3(39.0, 0, 27.0), 19.0, 19.0, 8.0, -0.5, 13.0)
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		SEuUtil.face_row(lm, "Shadow", Vector3(39.0, 0, 27.0) + out * 11.0, right, -out, 1.5, 4, 4.8, 3.0, 6.0)
		SEuUtil.face_row(lm, "Shadow", Vector3(39.0, 0, 27.0) + out * 19.05, right, out, 3.0, 5, 6.8, 1.6, 5.0)
	# Obradoiro facade: central body, stepped pediment and the stair.
	lm.box("Light", Vector3(0, 23.0, 42.5), Vector3(25.0, 46.0, 12.0))
	lm.box("Light", Vector3(0, 3.0, 42.5), Vector3(27.0, 6.0, 12.6))
	var steps := [[25.0, 46.0, 49.5], [19.0, 49.5, 52.5], [13.0, 52.5, 55.5], [8.0, 55.5, 58.0]]
	for st in steps:
		lm.box("Light", Vector3(0, (float(st[1]) + float(st[2])) * 0.5, 44.5), Vector3(float(st[0]), float(st[2]) - float(st[1]), 8.0))
	lm.box("Light", Vector3(0, 58.5, 44.5), Vector3(5.0, 1.0, 6.0))
	lm.box("Gilt", Vector3(0, 60.8, 44.5), Vector3(0.9, 3.6, 0.9))
	lm.box("Gilt", Vector3(0, 61.8, 44.5), Vector3(2.0, 0.5, 0.5))
	for x in [-9.0, 9.0]:
		lm.spire("Light", Vector3(x, 46.0, 46.5), 0.9, 7.0, 0.0)
	for x in [-8.5, -4.0, 4.0, 8.5]:
		lm.frustum("Light", Vector3(x, 6.0, 49.2), 0.7, 0.62, 13.0, 10)
		lm.frustum("Light", Vector3(x, 20.0, 49.2), 0.6, 0.52, 12.0, 10)
	for cy in [19.6, 32.6, 45.6]:
		lm.box("Light", Vector3(0, cy, 49.0), Vector3(26.4, 0.9, 1.8))
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 48.55), Vector3.RIGHT, Vector3(0, 0, 1), 6.0, 1, 1.0, 4.6, 9.5, true)
	LandmarkIbUtil.panes(lm, "Shadow", Vector3(0, 0, 48.55), Vector3.RIGHT, Vector3(0, 0, 1), 18.0, 1, 1.0, 7.0, 13.5)
	LandmarkIbUtil.panes(lm, "Shadow", Vector3(0, 0, 48.55), Vector3.RIGHT, Vector3(0, 0, 1), 34.0, 2, 8.0, 2.4, 6.0)
	for k in 6:
		lm.box("Steps", Vector3(0, 0.5 * float(5 - k) * 0.5, 50.5 + 1.4 * float(k)), Vector3(22.0 + 3.0 * float(k), 0.5 * float(5 - k) + 0.3, 1.4))
	# Berenguela and Carraca towers.
	for s in [-1.0, 1.0]:
		var t := Vector3(s * 19.0, 0, 42.25)
		lm.box("Light", t + Vector3(0, 15.5, 0), Vector3(12.5, 32.0, 12.5))
		lm.box("Light", t + Vector3(0, 32.5, 0), Vector3(13.5, 1.0, 13.5))
		lm.box("Light", t + Vector3(0, 40.0, 0), Vector3(11.4, 14.0, 11.4))
		lm.box("Light", t + Vector3(0, 47.6, 0), Vector3(12.6, 1.2, 12.6))
		lm.box("Light", t + Vector3(0, 53.0, 0), Vector3(8.8, 10.0, 8.8))
		lm.box("Light", t + Vector3(0, 58.3, 0), Vector3(10.0, 0.6, 10.0))
		for k in 4:
			var r2 := Basis(Vector3.UP, PI * 0.5 * float(k))
			var out2 := r2 * Vector3(0, 0, 1)
			var right2 := r2 * Vector3(1, 0, 0)
			SEuUtil.face_row(lm, "Shadow", t + out2 * 6.2, right2, out2, 9.0, 1, 1.0, 1.6, 4.4)
			SEuUtil.face_row(lm, "Shadow", t + out2 * 6.2, right2, out2, 21.0, 1, 1.0, 1.6, 4.4)
			SEuUtil.face_row(lm, "Shadow", t + out2 * 5.75, right2, out2, 34.0, 3, 3.6, 1.8, 8.0)
			SEuUtil.face_row(lm, "Shadow", t + out2 * 4.45, right2, out2, 49.0, 1, 1.0, 2.0, 7.0, true)
			var cn := (out2 + right2) * 5.9
			lm.spire("Light", t + cn + Vector3(0, 48.2, 0), 0.8, 5.0, 0.0)
		lm.lathe("Light", t + Vector3(0, 58.6, 0), PackedVector2Array([Vector2(4.6, 0), Vector2(4.9, 1.2),
			Vector2(4.2, 3.0), Vector2(3.0, 5.0), Vector2(2.0, 6.8), Vector2(1.5, 8.0), Vector2(1.0, 9.0),
			Vector2(0.0, 9.8)]), 8, 1.0, 1.0, PI / 8.0)
		lm.frustum("Light", t + Vector3(0, 68.4, 0), 1.1, 0.9, 3.0, 8)
		lm.frustum("Light", t + Vector3(0, 71.4, 0), 1.3, 0.2, 1.8, 8)
		lm.box("Gilt", t + Vector3(0, 73.8, 0), Vector3(0.28, 2.4, 0.28))
		lm.box("Gilt", t + Vector3(0, 74.2, 0), Vector3(1.3, 0.28, 0.28))
	lm.commit(model)

# --- Pena Palace ---

const PENA_TOP := 36.0

## Ferdinand II's Romantic palace on its crag above Sintra, origin at the
## middle of the 120 m ridge (long axis along Z, north at -Z): the
## yellow New Palace with its square tower and the round bastion under
## the Moorish dome, the Arches Yard wall of horseshoe arches and the
## chapel, the lilac Old Convent with the red Clock Tower (36 m), the
## great gate with its twin towers and the crenellated Queen's terrace.
## The rock under it drops 30 m; walls are the Romanticist yellow,
## red and lilac.
static func pena(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Yellow", LandmarkMaterials.pbr("render", "#E3B136", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("render", "#B93A32", 3.0))
	lm.use("Purple", LandmarkMaterials.pbr("render", "#A27294", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EFE7D5", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A6503A", 2.5))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#7E6F5C", 5.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3329", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	var crag := PackedVector2Array([Vector2(-34, -66), Vector2(-8, -72), Vector2(22, -68), Vector2(36, -50),
		Vector2(34, -20), Vector2(40, 10), Vector2(34, 44), Vector2(38, 68), Vector2(10, 76), Vector2(-24, 72),
		Vector2(-38, 50), Vector2(-32, 14), Vector2(-40, -20), Vector2(-36, -46)])
	lm.poly_prism("Rock", crag, -30.0, -0.1)
	LandmarkIbUtil.ring_walls(lm, "Rock", Vector3(0, 0, 2.0), 31.0, 64.0, 2.0, -6.0, 8.0)
	SEuUtil.crenels(lm, "Rock", Vector3(-31, 2.0, -62), Vector3(-31, 2.0, 66), 1.2, 1.2, 1.4)
	SEuUtil.crenels(lm, "Rock", Vector3(31, 2.0, -62), Vector3(31, 2.0, 66), 1.2, 1.2, 1.4)
	# New Palace (north): yellow block, square tower, round bastion and dome.
	lm.box("Yellow", Vector3(-6.0, 10.0, -40.0), Vector3(32.0, 20.0, 32.0))
	LandmarkCeParts.hip(lm, "Tile", Vector3(-6.0, 20.0, -40.0), 33.0, 33.0, 4.0)
	SEuUtil.crenels(lm, "Trim", Vector3(-22, 20.0, -56), Vector3(10, 20.0, -56), 1.0, 1.4, 1.0)
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var c := Vector3(-6.0, 0, -40.0) + out * 16.05
		SEuUtil.face_row(lm, "Shadow", c, right, out, 5.0, 4, 7.0, 2.0, 4.4, true)
		SEuUtil.face_row(lm, "Shadow", c, right, out, 12.0, 4, 7.0, 2.0, 4.0, true)
	lm.box("Yellow", Vector3(-20.0, 15.0, -52.0), Vector3(9.0, 30.0, 9.0))
	SEuUtil.crenels(lm, "Trim", Vector3(-24.5, 30.0, -47.5), Vector3(-15.5, 30.0, -47.5), 0.9, 1.4, 1.0)
	SEuUtil.crenels(lm, "Trim", Vector3(-24.5, 30.0, -56.5), Vector3(-15.5, 30.0, -56.5), 0.9, 1.4, 1.0)
	lm.spire("Tile", Vector3(-20.0, 30.0, -52.0), 3.6, 5.0, 0.0, 4)
	lm.frustum("Yellow", Vector3(14.0, 0, -36.0), 8.6, 8.0, 24.0, 16)
	SEuUtil.ring_openings(lm, "Shadow", Vector3(14.0, 0, -36.0), 8.0, 16, 7, 12.0, 1.8, 4.4, true)
	lm.box("Trim", Vector3(14.0, 24.4, -36.0), Vector3(18.0, 0.8, 18.0))
	LandmarkCeParts.onion(lm, "Gilt", Vector3(14.0, 24.8, -36.0), 8.4, 10.0, 16)
	lm.box("Gilt", Vector3(14.0, 35.4, -36.0), Vector3(0.25, 1.2, 0.25))
	# Arches Yard: the wall of horseshoe arches and the chapel.
	lm.box("Yellow", Vector3(-6.0, 7.0, -12.0), Vector3(40.0, 14.0, 2.4))
	SEuUtil.crenels(lm, "Trim", Vector3(-26, 14.0, -12), Vector3(14, 14.0, -12), 1.0, 1.3, 1.2)
	for s in [-1.0, 1.0]:
		for i in 7:
			var hx := -6.0 + (float(i) - 3.0) * 5.4
			LandmarkIbUtil.horseshoe(lm, "Shadow", Vector3(hx, 0.3, -12.0 + s * 1.25), Vector3(s, 0, 0), Vector3.UP, 2.6, 8.4)
			LandmarkIbUtil.horseshoe(lm, "Trim", Vector3(hx, 9.4, -12.0 + s * 1.27), Vector3(s, 0, 0), Vector3.UP, 1.6, 3.2)
	lm.box("Trim", Vector3(22.0, 6.0, -6.0), Vector3(14.0, 12.0, 22.0))
	lm.gable("Tile", Vector3(22.0, 12.0, -6.0), 14.0, 22.0, 4.0, Basis(), 0.6)
	LandmarkIbUtil.horseshoe(lm, "Shadow", Vector3(14.95, 0.3, -6.0), Vector3(0, 0, 1), Vector3.UP, 3.0, 6.0)
	# Old Convent (south): lilac block with its terrace and the Clock Tower.
	lm.box("Purple", Vector3(4.0, 8.0, 30.0), Vector3(40.0, 16.0, 38.0))
	LandmarkCeParts.hip(lm, "Tile", Vector3(4.0, 16.0, 30.0), 41.0, 39.0, 4.2)
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var half := 19.0 if k % 2 == 0 else 20.0
		var c := Vector3(4.0, 0, 30.0) + out * (half + 0.05)
		SEuUtil.face_row(lm, "Shadow", c, right, out, 3.0, 5, 7.0, 1.8, 4.0)
		LandmarkIbUtil.panes(lm, "Trim", c, right, out, 9.6, 5, 7.0, 1.6, 3.6)
	lm.box("Rock", Vector3(2.0, -2.0, 58.0), Vector3(54.0, 8.0, 10.0))
	lm.box("Trim", Vector3(2.0, 2.3, 58.0), Vector3(54.0, 0.6, 10.0))
	SEuUtil.crenels(lm, "Trim", Vector3(-25.0, 2.6, 63.0), Vector3(29.0, 2.6, 63.0), 1.0, 1.2, 1.0)
	var ct := Vector3(-14.0, 0, 52.0)
	lm.box("Red", ct + Vector3(0, 13.5, 0), Vector3(8.4, 27.0, 8.4))
	lm.box("Trim", ct + Vector3(0, 27.4, 0), Vector3(10.4, 0.8, 10.4))
	lm.box("Red", ct + Vector3(0, 29.0, 0), Vector3(8.8, 2.4, 8.8))
	SEuUtil.crenels(lm, "Trim", ct + Vector3(-5.2, 30.2, 5.2), ct + Vector3(5.2, 30.2, 5.2), 0.9, 1.3, 1.0)
	SEuUtil.crenels(lm, "Trim", ct + Vector3(-5.2, 30.2, -5.2), ct + Vector3(5.2, 30.2, -5.2), 0.9, 1.3, 1.0)
	SEuUtil.crenels(lm, "Trim", ct + Vector3(-5.2, 30.2, -5.2), ct + Vector3(-5.2, 30.2, 5.2), 0.9, 1.3, 1.0)
	SEuUtil.crenels(lm, "Trim", ct + Vector3(5.2, 30.2, -5.2), ct + Vector3(5.2, 30.2, 5.2), 0.9, 1.3, 1.0)
	lm.spire("Red", ct + Vector3(0, 30.4, 0), 2.6, 5.6, 0.0, 8)
	lm.disc("Trim", ct + Vector3(0, 21.0, 4.26), Vector3(0, 0, 1), 1.7, 20)
	LandmarkIbUtil.panes(lm, "Shadow", ct + Vector3(0, 0, 4.3), Vector3.RIGHT, Vector3(0, 0, 1), 8.0, 1, 1.0, 1.2, 3.6)
	LandmarkIbUtil.panes(lm, "Shadow", ct + Vector3(0, 0, 4.3), Vector3.RIGHT, Vector3(0, 0, 1), 12.0, 1, 1.0, 1.2, 3.6)
	# Great gate: twin round towers and the Triton arch.
	for x in [8.0, 18.0]:
		lm.frustum("Red", Vector3(x, 0, 66.0), 3.3, 3.0, 15.0, 12)
		lm.frustum("Yellow", Vector3(x, 15.0, 66.0), 3.7, 3.7, 1.2, 12)
		lm.frustum("Tile", Vector3(x, 16.2, 66.0), 3.9, 0.3, 4.6, 12)
	lm.box("Yellow", Vector3(13.0, 5.5, 66.0), Vector3(7.0, 11.0, 5.0))
	LandmarkIbUtil.horseshoe(lm, "Shadow", Vector3(13.0, 0.3, 68.55), Vector3.RIGHT, Vector3.UP, 4.0, 7.5)
	lm.commit(model)

# --- Jeronimos Monastery ---

const JER_TOP := 56.0

## The Manueline monastery of Belem, origin at the middle of its 295 m
## front (+X along the front, bearing 75 degrees, front toward +Z): the
## west wing end pavilion with its green dome, the church with the south
## portal (a 32 m Manueline frame of niches, archivolts and pinnacles
## round the trumeau doorway), buttresses and pinnacles, its transept
## lantern and the 56 m church tower at the west end, the long two-storey
## conventual front of Lioz limestone to the east with its central and
## end pavilions, and the cloister behind them.
static func jeronimos(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Lioz", LandmarkMaterials.pbr("limestone", "#D9CCA8", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EADFC3", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#7B7F7E", 3.0))
	lm.use("Dome", LandmarkMaterials.paint("#6E9283", 0.5, 0.3))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3329", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#BFB6A3", 4.0))
	lm.box("Paving", Vector3(0, -0.2, 56.0), Vector3(296.0, 1.4, 32.0))
	# Church: nave and aisles under one roof, buttresses and pinnacles.
	lm.box("Lioz", Vector3(-76.0, 11.0, 27.0), Vector3(84.0, 22.0, 26.0))
	LandmarkCeParts.hip(lm, "Roof", Vector3(-76.0, 22.0, 27.0), 82.0, 25.0, 3.4)
	for i in 11:
		var bx := -114.0 + 7.6 * float(i)
		lm.box("Lioz", Vector3(bx, 9.0, 40.6), Vector3(1.4, 18.0, 1.4))
		lm.spire("Trim", Vector3(bx, 18.0, 40.6), 0.6, 5.5, 0.0, 4)
		if i < 10 and absf(bx + 76.0) > 9.0:
			SEuUtil.face_row(lm, "Shadow", Vector3(bx + 3.8, 0, 40.05), Vector3.RIGHT, Vector3(0, 0, 1), 7.0, 1, 1.0, 2.8, 11.0, true)
	lm.box("Trim", Vector3(-76.0, 21.2, 40.5), Vector3(84.0, 1.0, 1.6))
	lm.box("Lioz", Vector3(-72.0, 11.0, 2.0), Vector3(26.0, 22.0, 20.0))
	lm.gable("Roof", Vector3(-72.0, 22.0, 2.0), 20.0, 26.0, 3.0, Basis(Vector3.UP, PI * 0.5), 0.5)
	lm.frustum("Lioz", Vector3(-72.0, 22.0, 6.0), 6.0, 6.0, 10.0, 8, PI / 8.0)
	lm.frustum("Roof", Vector3(-72.0, 32.0, 6.0), 6.6, 0.4, 8.0, 8, PI / 8.0)
	# South portal: frame, door, archivolts, canopy and pinnacles.
	var pc := Vector3(-76.0, 0, 41.0)
	lm.box("Trim", pc + Vector3(0, 13.5, 0.8), Vector3(15.0, 27.0, 3.2))
	lm.box("Lioz", pc + Vector3(0, 13.5, 0.4), Vector3(17.0, 27.0, 2.4))
	var tones: Array[String] = ["Lioz", "Trim", "Lioz", "Shadow"]
	for k in 4:
		SEuUtil.opening(lm, tones[k], pc + Vector3(0, 0.3, 2.45 + 0.02 * float(k)), Vector3.RIGHT, Vector3.UP,
			12.0 - 2.2 * float(k), 17.0 - 2.4 * float(k), true)
	lm.frustum("Trim", pc + Vector3(0, 0.3, 2.7), 0.55, 0.45, 8.0, 8)
	for s in [-1.0, 1.0]:
		lm.box("Trim", pc + Vector3(s * 6.4, 14.0, 2.5), Vector3(1.8, 28.0, 1.8))
		lm.spire("Trim", pc + Vector3(s * 6.4, 28.0, 2.5), 0.85, 6.5, 0.0, 6)
		LandmarkIbUtil.panes(lm, "Shadow", pc + Vector3(s * 5.4, 0, 2.45), Vector3.RIGHT, Vector3(0, 0, 1), 17.0, 1, 1.0, 0.9, 2.6)
		LandmarkIbUtil.panes(lm, "Shadow", pc + Vector3(s * 5.4, 0, 2.45), Vector3.RIGHT, Vector3(0, 0, 1), 21.0, 1, 1.0, 0.9, 2.6)
	lm.box("Lioz", pc + Vector3(0, 21.0, 1.6), Vector3(11.0, 1.2, 4.0))
	lm.gable("Trim", pc + Vector3(0, 21.6, 1.6), 9.0, 3.4, 5.0, Basis(), 0.0, "Trim")
	lm.spire("Trim", pc + Vector3(0, 26.6, 1.6), 0.9, 4.8, 0.0, 6)
	lm.box("Gilt", pc + Vector3(0, 31.9, 1.6), Vector3(0.18, 0.9, 0.18))
	# Church tower, west end of the church.
	var tw := Vector3(-114.0, 0, 36.0)
	lm.box("Lioz", tw + Vector3(0, 19.0, 0), Vector3(9.6, 38.0, 9.6))
	lm.box("Trim", tw + Vector3(0, 38.4, 0), Vector3(10.6, 0.8, 10.6))
	lm.frustum("Lioz", tw + Vector3(0, 38.8, 0), 4.6, 4.4, 9.0, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Shadow", tw + Vector3(0, 38.8, 0), 4.6, 8, 8, 1.8, 1.4, 5.4, false)
	lm.frustum("Trim", tw + Vector3(0, 47.8, 0), 5.0, 4.8, 0.8, 8, PI / 8.0)
	lm.lathe("Roof", tw + Vector3(0, 48.6, 0), PackedVector2Array([Vector2(4.8, 0), Vector2(4.4, 2.0),
		Vector2(3.0, 4.0), Vector2(1.6, 5.4), Vector2(0.6, 6.4), Vector2(0.0, 7.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.box("Gilt", tw + Vector3(0, 54.6, 0), Vector3(0.25, 2.8, 0.25))
	lm.box("Gilt", tw + Vector3(0, 55.2, 0), Vector3(1.3, 0.25, 0.25))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		SEuUtil.face_row(lm, "Shadow", tw + out * 4.85, right, out, 10.0, 1, 1.0, 1.4, 4.4, true)
		SEuUtil.face_row(lm, "Shadow", tw + out * 4.85, right, out, 26.0, 1, 1.0, 1.4, 4.4, true)
	# West wing with its domed end pavilion.
	lm.box("Lioz", Vector3(-134.0, 10.0, 28.0), Vector3(26.0, 20.0, 24.0))
	LandmarkCeParts.hip(lm, "Roof", Vector3(-134.0, 20.0, 28.0), 25.0, 23.0, 3.0)
	SEuUtil.face_row(lm, "Shadow", Vector3(-134.0, 0, 40.05), Vector3.RIGHT, Vector3(0, 0, 1), 2.0, 3, 8.0, 2.0, 4.4)
	LandmarkIbUtil.panes(lm, "Trim", Vector3(-134.0, 0, 40.05), Vector3.RIGHT, Vector3(0, 0, 1), 11.0, 3, 8.0, 2.0, 4.4)
	lm.box("Lioz", Vector3(-141.0, 13.0, 30.0), Vector3(12.0, 26.0, 12.0))
	lm.frustum("Lioz", Vector3(-141.0, 26.0, 30.0), 5.0, 5.0, 5.0, 12)
	lm.lathe("Dome", Vector3(-141.0, 31.0, 30.0), SEuUtil.dome(5.2, 5.0, 6), 12)
	lm.box("Gilt", Vector3(-141.0, 36.4, 30.0), Vector3(0.22, 1.8, 0.22))
	# Long conventual front (east), central and end pavilions.
	lm.box("Lioz", Vector3(55.0, 9.5, 29.0), Vector3(180.0, 19.0, 22.0))
	LandmarkCeParts.hip(lm, "Roof", Vector3(55.0, 19.0, 29.0), 178.0, 21.0, 3.8)
	lm.box("Trim", Vector3(55.0, 11.2, 40.2), Vector3(181.0, 0.7, 1.0))
	lm.box("Trim", Vector3(55.0, 18.6, 40.4), Vector3(182.0, 1.2, 1.6))
	SEuUtil.face_row(lm, "Shadow", Vector3(55.0, 0, 40.05), Vector3.RIGHT, Vector3(0, 0, 1), 1.6, 32, 5.5, 2.2, 5.6, true)
	LandmarkIbUtil.panes(lm, "Shadow", Vector3(55.0, 0, 40.05), Vector3.RIGHT, Vector3(0, 0, 1), 12.6, 32, 5.5, 1.8, 4.2)
	for px in [45.0, 135.0]:
		lm.box("Lioz", Vector3(px, 12.0, 30.5), Vector3(14.0, 24.0, 22.0))
		LandmarkCeParts.hip(lm, "Roof", Vector3(px, 24.0, 30.5), 14.6, 22.6, 4.5)
		SEuUtil.face_row(lm, "Shadow", Vector3(px, 0, 41.55), Vector3.RIGHT, Vector3(0, 0, 1), 1.6, 2, 5.0, 2.4, 6.0, true)
		LandmarkIbUtil.panes(lm, "Shadow", Vector3(px, 0, 41.55), Vector3.RIGHT, Vector3(0, 0, 1), 14.0, 2, 5.0, 2.0, 6.0)
	lm.box("Trim", Vector3(45.0, 12.0, 41.0), Vector3(15.0, 24.0, 1.0))
	lm.box("Trim", Vector3(135.0, 12.0, 41.0), Vector3(15.0, 24.0, 1.0))
	# Cloister behind the front: two storeys of arcades round a court.
	LandmarkIbUtil.ring_walls(lm, "Lioz", Vector3(6.0, 0, -17.0), 35.0, 33.0, 9.0, -0.5, 15.0)
	lm.box("Paving", Vector3(6.0, -0.2, -17.0), Vector3(52.0, 1.4, 48.0))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var hx := 24.0 if k % 2 == 0 else 26.0
		var n := 8 if k % 2 == 0 else 7
		var c := Vector3(6.0, 0, -17.0) + out * hx
		SEuUtil.face_row(lm, "Shadow", c - out * 0.0, right, -out, 1.0, n, 6.0, 3.6, 5.6)
		SEuUtil.face_row(lm, "Shadow", c, right, -out, 8.0, n, 6.0, 3.6, 5.6)
		SEuUtil.face_row(lm, "Shadow", Vector3(6.0, 0, -17.0) + out * (hx + 9.05), right, out, 4.0, 8, 8.0, 1.8, 4.0)
	lm.commit(model)

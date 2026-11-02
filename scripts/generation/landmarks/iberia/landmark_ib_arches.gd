class_name LandmarkIbArches
extends RefCounted

## Three landmarks of arches in true metres: the Roman aqueduct of
## Segovia, the Mosque-Cathedral of Cordoba and the Real Alcazar of
## Seville.

# --- Aqueduct of Segovia ---

const SEG_TOP := 28.5
const SEG_X0 := -75.0
const SEG_LEN := 728.0

## Ground height at x, metres over the Azoguejo valley floor (y = 0):
## steep out of the plaza, then a long gentle climb to the south-east.
static func _seg_ground(x: float) -> float:
	if x >= 0.0:
		return 22.0 * pow(x / (SEG_X0 + SEG_LEN), 0.39)
	return 15.0 * pow(-x / -SEG_X0, 0.8)

## The aqueduct arcade, +X along its run (north-west to south-east), the
## origin at the Plaza del Azoguejo where the arches stand tallest. 728 m
## of unmortared granite arches under a continuous attic that carries
## the water channel: 28.5 m of two tiers in the hollow (44 double
## arches of 5.3 m span, 7.2 m to a bay) thinning to 79 single arches of
## 3.6 m span (5.2 m to a bay) as the ground rises to the south-east,
## 123 bays and 167 arches in all. The foundations go 6 m down, as they
## do in the valley.
static func segovia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B3A68F", 3.0))
	lm.use("Cap", LandmarkMaterials.pbr("stone", "#C4B9A3", 3.0))
	var crown := SEG_TOP - 1.9
	var top := SEG_TOP - 1.2
	var end := SEG_X0 + SEG_LEN
	var x := SEG_X0
	while x < end - 0.5:
		var tall := _seg_ground(x + 3.6) < 15.0
		var xr := minf(x + (7.2 if tall else 5.2), end)
		if end - xr < 2.6:
			xr = end
		var pw := 1.9 if tall else 1.6
		var r := (xr - x - pw) * 0.5
		var spring_u := crown - r
		if tall:
			var y_mid := spring_u - 3.2
			_bay(lm, "Granite", x, xr, -6.0, y_mid - 0.9 - r, r, y_mid, pw, 1.4)
			_bay(lm, "Granite", x, xr, y_mid, spring_u, r, top, pw, 1.25)
			lm.box("Cap", Vector3((x + xr) * 0.5, y_mid, 0), Vector3(xr - x + 0.02, 0.4, 3.0))
		else:
			_bay(lm, "Granite", x, xr, -6.0, spring_u, r, top, pw, 1.3)
		x = xr
	lm.box("Cap", Vector3(SEG_X0 + SEG_LEN * 0.5, SEG_TOP - 0.6, 0), Vector3(SEG_LEN, 1.2, 2.6))
	for ex in [SEG_X0 - 2.0, SEG_X0 + SEG_LEN + 2.0]:
		lm.box("Granite", Vector3(ex, (top - 6.0) * 0.5, 0), Vector3(4.0, top + 6.0, 2.8))
	lm.commit(model)

## One masonry bay between the pier lines xl and xr: a round arch of
## radius r springing at `spring`, solid up to `top`, from y0 down.
static func _bay(lm: LandmarkMesh, key: String, xl: float, xr: float, y0: float, spring: float,
		r: float, top: float, pw: float, hz: float) -> void:
	var poly := PackedVector2Array([Vector2(xl, y0), Vector2(xl + pw * 0.5, y0)])
	poly.append_array(LandmarkBrKit.arch_pts((xl + xr) * 0.5, spring, r, r, 7))
	poly.append_array(PackedVector2Array([Vector2(xr - pw * 0.5, y0), Vector2(xr, y0),
		Vector2(xr, top), Vector2(xl, top)]))
	LandmarkBrKit.extrude_xy(lm, key, poly, -hz, hz)

# --- Mosque-Cathedral of Cordoba ---

const MEZ_HX := 64.5
const MEZ_HZ := 89.5
const MEZ_WALL := 10.5
const MEZ_AISLE := 6.45

## The Mezquita on the Guadalquivir, origin at the middle of its 129 x
## 179 m rectangle, the Patio de los Naranjos to the north (-Z) and the
## qibla wall to the south: the crenellated sandstone wall with its
## buttress towers and horseshoe gates, the orange court with its side
## galleries and the 54 m Torre del Alminar (the minaret cased in a
## Renaissance bell tower under the archangel), the long hall of 19
## aisles under rows of tiled gabled roofs, the Renaissance cathedral
## nave and crossing lantern rising from its middle and, where the roof
## is cut away beside the court, the forest of red-and-white double
## arches on slender columns. Gate fronts face outward.
static func mezquita(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#CDB48A", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E9E1CC", 2.5))
	lm.use("Red", LandmarkMaterials.pbr("brick", "#B5503C", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A85A3A", 2.5))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#7C8387", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3329", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#BDB19A", 4.0))
	lm.use("Leaf", LandmarkMaterials.pbr("lawn", "#4E7A3A", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	var hx := MEZ_HX
	var hz := MEZ_HZ
	var t := 1.8
	var wy := (MEZ_WALL + 0.5) * 0.5 - 0.5
	lm.box("Paving", Vector3(0, -0.2, 0), Vector3(2.0 * hx, 1.4, 2.0 * hz))
	# Perimeter and dividing wall with merlons, buttresses and gates.
	for z in [-hz + t * 0.5, hz - t * 0.5, -29.5]:
		lm.box("Wall", Vector3(0, wy, z), Vector3(2.0 * hx, MEZ_WALL + 0.5, t))
		SEuUtil.crenels(lm, "Wall", Vector3(-hx, MEZ_WALL, z), Vector3(hx, MEZ_WALL, z), 1.5, 1.5, 1.0)
	for x in [-hx + t * 0.5, hx - t * 0.5]:
		lm.box("Wall", Vector3(x, wy, 0), Vector3(t, MEZ_WALL + 0.5, 2.0 * hz - 2.0 * t))
		SEuUtil.crenels(lm, "Wall", Vector3(x, MEZ_WALL, -hz + t), Vector3(x, MEZ_WALL, hz - t), 1.5, 1.5, 1.0)
	for i in 18:
		var z := -hz + 9.0 + 9.9 * float(i)
		for s in [-1.0, 1.0]:
			lm.box("Wall", Vector3(s * (hx + 0.6), 6.0, z), Vector3(1.4, 12.2, 1.6))
	for i in 12:
		var x := -hx + 9.0 + 10.1 * float(i)
		lm.box("Wall", Vector3(x, 6.0, hz + 0.6), Vector3(1.6, 12.2, 1.4))
		if i != 4:
			lm.box("Wall", Vector3(x, 6.0, -hz - 0.6), Vector3(1.6, 12.2, 1.4))
	# Gates: San Esteban (west), the Perdon (north) and the east door.
	for g in [[-1.0, 15.0], [1.0, -20.0]]:
		var s: float = g[0]
		var gz: float = g[1]
		lm.box("Stone", Vector3(s * (hx + 0.2), 4.2, gz), Vector3(0.6, 8.4, 6.0))
		LandmarkIbUtil.horseshoe(lm, "Shadow", Vector3(s * (hx + 0.52), 0.35, gz), Vector3(0, 0, -s),
			Vector3.UP, 3.4, 6.2)
	lm.box("Stone", Vector3(-14.0, 4.6, -hz - 0.2), Vector3(7.0, 9.2, 0.6))
	LandmarkIbUtil.horseshoe(lm, "Shadow", Vector3(-14.0, 0.35, -hz - 0.52), Vector3(-1, 0, 0), Vector3.UP, 3.8, 6.8)
	# Patio de los Naranjos: orange trees, side galleries, hall doors.
	LandmarkIbUtil.tree_grid(lm, "Leaf", Vector3(0, 0.35, -59.0), 8, 5, 7.2, 9.0, 2.1, 4.4)
	for s in [-1.0, 1.0]:
		var gx: float = s * (hx - t - 2.0)
		for i in 12:
			var z := -86.0 + 4.4 * float(i) + 2.2
			lm.box("Stone", Vector3(gx - s * 1.7, 1.9, z - 2.2), Vector3(0.9, 3.8, 0.9))
			LandmarkIbUtil.wedge_arch(lm, "Stone", "Stone", Vector3(gx - s * 1.7, 3.8, z), Vector3(0, 0, 1),
				Vector3(1, 0, 0), 1.5, 0.4, 0.8, 0.0, 180.0, 6)
		lm.box("Stone", Vector3(gx - s * 1.7, 1.9, -86.0 + 4.4 * 12.0), Vector3(0.9, 3.8, 0.9))
		lm.box("Tile", Vector3(gx - s * 0.2, 5.4, -59.0), Vector3(3.6, 0.4, 52.8))
	for i in 19:
		var dx := -61.275 + MEZ_AISLE * (float(i) + 0.5)
		LandmarkIbUtil.horseshoe(lm, "Shadow", Vector3(dx, 0.35, -30.45), Vector3(-1, 0, 0), Vector3.UP, 3.2, 6.0)
	_alminar(lm, Vector3(8.0, 0, -83.9))
	# Hall roofs: gabled rows over the 19 aisles, cut back beside the court.
	for k in 19:
		var cx := -61.275 + MEZ_AISLE * (float(k) + 0.5)
		var segs: Array = [[-3.5, 88.5]]
		if absf(cx) < 11.6:
			segs = [[-3.5, 4.0], [66.0, 88.5]]
		elif absf(cx) < 27.5:
			segs = [[-3.5, 30.0], [44.0, 88.5]]
		for sg in segs:
			var z0: float = sg[0]
			var z1: float = sg[1]
			lm.gable("Tile", Vector3(cx, MEZ_WALL, (z0 + z1) * 0.5), MEZ_AISLE, z1 - z0, 2.4, Basis(), 0.0)
	_nave(lm)
	_forest(lm)
	lm.commit(model)

## The Torre del Alminar: stone shaft, two Renaissance stages, the
## belfry with its round-arched openings, a lead dome and lantern, and
## the gilded archangel on top (54 m).
static func _alminar(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Wall", c + Vector3(0, 12.0, 0), Vector3(10.4, 25.0, 10.4))
	lm.box("Stone", c + Vector3(0, 25.3, 0), Vector3(11.4, 0.7, 11.4))
	lm.box("Wall", c + Vector3(0, 31.5, 0), Vector3(9.2, 11.0, 9.2))
	lm.box("Stone", c + Vector3(0, 37.3, 0), Vector3(10.2, 0.6, 10.2))
	lm.box("Wall", c + Vector3(0, 41.5, 0), Vector3(8.0, 8.0, 8.0))
	lm.box("Stone", c + Vector3(0, 46.0, 0), Vector3(9.2, 1.0, 9.2))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		SEuUtil.face_row(lm, "Shadow", c + out * 5.25, right, out, 14.0, 1, 1.0, 1.4, 6.0)
		SEuUtil.face_row(lm, "Shadow", c + out * 5.25, right, out, 5.0, 1, 1.0, 1.0, 3.2)
		SEuUtil.face_row(lm, "Shadow", c + out * 4.65, right, out, 27.0, 2, 4.2, 1.6, 7.0)
		SEuUtil.face_row(lm, "Shadow", c + out * 4.1, right, out, 38.5, 1, 1.0, 3.2, 6.4)
		LandmarkIbUtil.pilasters(lm, "Stone", c + out * 4.0, right, out, 2, 7.2, 0.8, 0.4, 37.6, 46.0)
	var base := c + Vector3(0, 46.5, 0)
	lm.lathe("Lead", base, SEuUtil.dome(4.6, 3.0, 6), 12)
	lm.frustum("Stone", base + Vector3(0, 3.0, 0), 1.3, 1.1, 1.2, 8)
	lm.lathe("Lead", base + Vector3(0, 4.2, 0), SEuUtil.dome(1.4, 1.0, 4), 8)
	LandmarkKits.statue_figure(lm, "Gilt", base + Vector3(0, 5.2, 0), 2.3, true)

## Renaissance cathedral inside the hall: nave, transept and the crossing
## lantern, over the roof rows.
static func _nave(lm: LandmarkMesh) -> void:
	lm.box("Wall", Vector3(0, 12.0, 35.0), Vector3(22.0, 24.5, 62.0))
	lm.gable("Lead", Vector3(0, 24.5, 35.0), 22.0, 62.0, 6.5, Basis(), 0.4)
	lm.box("Wall", Vector3(0, 12.0, 37.0), Vector3(54.0, 24.5, 14.0))
	lm.gable("Lead", Vector3(0, 24.5, 37.0), 14.0, 54.0, 5.5, Basis(Vector3.UP, PI * 0.5), 0.4)
	for s in [-1.0, 1.0]:
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 11.0, 0, 15.0), Vector3(0, 0, 1), Vector3(s, 0, 0), 13.5, 2, 10.0, 2.0, 7.0, true)
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 11.0, 0, 55.0), Vector3(0, 0, 1), Vector3(s, 0, 0), 13.5, 2, 10.0, 2.0, 7.0, true)
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 27.0, 0, 37.0), Vector3(0, 0, 1), Vector3(s, 0, 0), 12.0, 1, 1.0, 2.6, 9.0, true)
	var c := Vector3(0, 0, 37.0)
	lm.frustum("Wall", c + Vector3(0, 24.5, 0), 8.5, 8.5, 11.0, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Shadow", c + Vector3(0, 24.5, 0), 8.5, 8, 8, 3.0, 1.8, 6.5, true)
	lm.lathe("Lead", c + Vector3(0, 35.5, 0), SEuUtil.dome(8.9, 7.0, 6), 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Wall", c + Vector3(0, 42.5, 0), 2.4, 2.2, 3.6, 8)
	lm.frustum("Tile", c + Vector3(0, 46.1, 0), 2.8, 0.2, 3.0, 8)
	lm.box("Gilt", c + Vector3(0, 49.8, 0), Vector3(0.3, 1.8, 0.3))

## The forest of red-and-white arches: 20 column lines running north to
## south, six columns deep, each carrying a horseshoe arch and above it
## a round arch on pillars.
static func _forest(lm: LandmarkMesh) -> void:
	var col_h := 3.0
	var prof := PackedVector2Array([Vector2(0.28, 0), Vector2(0.22, col_h - 0.3)])
	for i in 20:
		var x := -61.275 + MEZ_AISLE * float(i)
		for j in 6:
			var z := -27.0 + 4.4 * float(j)
			lm.lathe("Stone", Vector3(x, 0.35, z), prof, 6, 1.0, 1.0, 0.0, true, false)
			lm.box("Stone", Vector3(x, 0.35 + col_h - 0.1, z), Vector3(0.75, 0.35, 0.75))
			lm.box("Stone", Vector3(x, 0.35 + col_h + 2.1, z), Vector3(0.7, 3.9, 0.7))
		for j in 5:
			var zc := -27.0 + 4.4 * (float(j) + 0.5)
			var cl := Vector3(x, 0.35 + 3.84, zc)
			LandmarkIbUtil.wedge_arch(lm, "Red", "Stone", cl, Vector3(0, 0, 1), Vector3(1, 0, 0), 1.75, 0.42,
				0.7, -22.0, 202.0, 7)
			var cu := Vector3(x, 0.35 + 6.9, zc)
			LandmarkIbUtil.wedge_arch(lm, "Red", "Stone", cu, Vector3(0, 0, 1), Vector3(1, 0, 0), 1.85, 0.4,
				0.7, 0.0, 180.0, 5, true)

# --- Real Alcazar of Seville ---

const ALC_TOP := 25.8

## The Mudejar palace of Pedro I and its courts, origin at the Patio de
## las Doncellas, the facade toward +Z over the Patio de la Monteria and
## the gardens behind it (-Z): ochre plastered walls under a great
## carved wooden eaves, the horseshoe-arched portal, the Court of the
## Maidens with its long pool and double galleries, the Hall of
## Ambassadors under its stepped tile roof, the Gothic palace of Alfonso
## X, the Montería court with its walls, the Lion Gate, and the
## gardens as gravel parterres, hedges and pools with the Grotesque
## gallery and Charles V's pavilion.
static func seville_alcazar(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#DCC79E", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("render", "#B5573D", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EFE6CF", 2.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B2623E", 2.5))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6B4A2E", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3E342A", 3.0))
	lm.use("Water", LandmarkMaterials.glass("#2C6670"))
	lm.use("Hedge", LandmarkMaterials.pbr("lawn", "#4E7A3A", 3.0))
	lm.use("Gravel", LandmarkMaterials.pbr("gravel", "#CDB68D", 4.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Pedro I palace: front block, Maidens' court wings, rear range.
	lm.box("Wall", Vector3(0, 5.25, 7.0), Vector3(54.0, 10.5, 30.0))
	lm.box("Red", Vector3(0, 1.5, 22.1), Vector3(54.0, 3.0, 0.3))
	LandmarkCeParts.hip(lm, "Tile", Vector3(0, 10.5, 7.0), 54.0, 30.0, 2.2)
	for s in [-1.0, 1.0]:
		lm.box("Wall", Vector3(s * 19.25, 5.5, -19.0), Vector3(15.5, 11.0, 22.0))
		LandmarkCeParts.hip(lm, "Tile", Vector3(s * 19.25, 11.0, -19.0), 15.5, 22.0, 2.0)
	lm.box("Wall", Vector3(0, 5.5, -35.0), Vector3(54.0, 11.0, 10.0))
	LandmarkCeParts.hip(lm, "Tile", Vector3(0, 11.0, -35.0), 54.0, 10.0, 2.0)
	# Facade: portal, tile panels, blind arches and the great eaves.
	lm.box("Trim", Vector3(0, 5.2, 22.35), Vector3(12.0, 10.4, 0.5))
	LandmarkIbUtil.horseshoe(lm, "Shadow", Vector3(0, 0.35, 22.62), Vector3.RIGHT, Vector3.UP, 4.2, 6.6)
	for x in [-3.2, 0.0, 3.2]:
		LandmarkIbUtil.horseshoe(lm, "Shadow", Vector3(x, 7.4, 22.62), Vector3.RIGHT, Vector3.UP, 1.8, 2.6)
	for s in [-1.0, 1.0]:
		for i in 3:
			LandmarkIbUtil.horseshoe(lm, "Shadow", Vector3(s * (11.0 + 6.0 * float(i)), 6.0, 22.28),
				Vector3.RIGHT, Vector3.UP, 1.5, 2.6)
			LandmarkIbUtil.panes(lm, "Shadow", Vector3(s * (11.0 + 6.0 * float(i)), 0, 22.28), Vector3.RIGHT,
				Vector3(0, 0, 1), 1.6, 1, 1.0, 1.4, 2.4)
	lm.box("Wood", Vector3(0, 10.9, 23.0), Vector3(48.0, 1.0, 4.4))
	for i in 38:
		lm.box("Wood", Vector3(-22.2 + 1.2 * float(i), 10.2, 23.4), Vector3(0.5, 0.7, 2.2))
	lm.box("Wood", Vector3(0, 11.6, 23.2), Vector3(48.4, 0.5, 4.8))
	# Court of the Maidens: floor, pool, double galleries.
	lm.box("Gravel", Vector3(0, -0.2, -19.0), Vector3(23.0, 1.4, 22.0))
	lm.box("Water", Vector3(0, 0.0, -19.0), Vector3(3.4, 0.8, 15.0))
	for s in [-1.0, 1.0]:
		for i in 9:
			var z := -28.0 + 2.2 * float(i)
			lm.lathe("Trim", Vector3(s * 10.6, 0.35, z), PackedVector2Array([Vector2(0.2, 0), Vector2(0.17, 3.4)]), 6, 1.0, 1.0, 0.0, true, false)
			LandmarkIbUtil.wedge_arch(lm, "Trim", "Trim", Vector3(s * 10.6, 3.6, z + 1.1), Vector3(0, 0, 1),
				Vector3(1, 0, 0), 0.95, 0.25, 0.5, 0.0, 180.0, 5)
		lm.box("Trim", Vector3(s * 10.6, 5.2, -19.0), Vector3(0.7, 0.9, 22.0))
		LandmarkIbUtil.panes(lm, "Shadow", Vector3(s * 11.45, 0, -19.0), Vector3(0, 0, 1), Vector3(-s, 0, 0), 6.0, 7, 2.9, 1.2, 2.4)
	for i in 8:
		var x := -9.5 + 2.7 * float(i)
		lm.lathe("Trim", Vector3(x, 0.35, -29.5), PackedVector2Array([Vector2(0.2, 0), Vector2(0.17, 3.4)]), 6, 1.0, 1.0, 0.0, true, false)
		LandmarkIbUtil.wedge_arch(lm, "Trim", "Trim", Vector3(x + 1.35, 3.6, -29.5), Vector3(1, 0, 0),
			Vector3(0, 0, 1), 1.1, 0.25, 0.5, 0.0, 180.0, 5)
	# Hall of Ambassadors: square block under a stepped tile roof and lantern.
	lm.box("Wall", Vector3(0, 9.5, -48.0), Vector3(15.0, 19.0, 15.0))
	LandmarkCeParts.hip(lm, "Tile", Vector3(0, 19.0, -48.0), 15.6, 15.6, 3.6)
	lm.box("Wall", Vector3(0, 23.0, -48.0), Vector3(4.6, 2.0, 4.6))
	LandmarkCeParts.hip(lm, "Tile", Vector3(0, 24.0, -48.0), 5.2, 5.3, 1.2)
	lm.box("Gilt", Vector3(0, 25.5, -48.0), Vector3(0.3, 0.6, 0.3))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, -48.0) + out * 7.5, right, out, 11.0, 3, 4.0, 1.4, 4.4, true)
		LandmarkIbUtil.horseshoe(lm, "Shadow", Vector3(0, 0.35, -48.0) + out * 7.52, right, Vector3.UP, 3.2, 5.2)
	# Gothic palace of Alfonso X and the Montería court's buildings.
	lm.box("Wall", Vector3(50.0, 7.0, -20.0), Vector3(40.0, 14.0, 30.0))
	lm.box("Red", Vector3(50.0, 2.5, -4.9), Vector3(40.0, 5.0, 0.3))
	LandmarkCeParts.hip(lm, "Tile", Vector3(50.0, 14.0, -20.0), 40.0, 30.0, 3.0)
	SEuUtil.face_row(lm, "Shadow", Vector3(50.0, 0, -4.9), Vector3.RIGHT, Vector3(0, 0, 1), 6.0, 5, 7.0, 2.0, 7.0, true)
	lm.box("Wall", Vector3(-41.0, 5.5, 47.0), Vector3(14.0, 11.0, 46.0))
	lm.box("Red", Vector3(-41.0, 1.5, 47.0), Vector3(14.2, 3.0, 46.2))
	LandmarkCeParts.hip(lm, "Tile", Vector3(-41.0, 11.0, 47.0), 14.0, 46.0, 2.4)
	SEuUtil.face_row(lm, "Shadow", Vector3(-34.0, 0, 47.0), Vector3(0, 0, 1), Vector3(1, 0, 0), 6.0, 7, 6.4, 1.4, 3.2)
	lm.box("Gravel", Vector3(0, -0.2, 47.0), Vector3(68.0, 1.4, 50.0))
	lm.box("Wall", Vector3(35.0, 4.5, 47.0), Vector3(2.0, 9.0, 50.0))
	SEuUtil.crenels(lm, "Wall", Vector3(35.0, 9.0, 22.0), Vector3(35.0, 9.0, 72.0), 1.1, 1.3, 1.0)
	for z in [30.0, 50.0, 70.0]:
		lm.box("Wall", Vector3(35.5, 6.5, z), Vector3(4.0, 13.0, 4.0))
		SEuUtil.crenels(lm, "Wall", Vector3(33.5, 13.0, z), Vector3(37.5, 13.0, z), 0.8, 1.2, 1.0)
	lm.box("Wall", Vector3(-12.0, 7.0, 71.0), Vector3(26.0, 14.0, 4.0))
	SEuUtil.crenels(lm, "Wall", Vector3(-25.0, 14.0, 71.0), Vector3(1.0, 14.0, 71.0), 1.1, 1.3, 1.0)
	LandmarkIbUtil.horseshoe(lm, "Shadow", Vector3(-12.0, 0.35, 73.05), Vector3.RIGHT, Vector3.UP, 4.4, 8.0)
	# Gardens: gravel floor, hedged parterres, pools, gallery, pavilion.
	lm.box("Gravel", Vector3(55.0, -0.2, -88.0), Vector3(150.0, 1.4, 82.0))
	for i in 6:
		for j in 4:
			var bx := 5.0 + 15.0 * float(i)
			var bz := -58.0 - 15.0 * float(j)
			if (i == 4 and j == 1) or (i == 1 and j == 3):
				lm.box("Water", Vector3(bx, 0.1, bz), Vector3(9.0, 0.6, 9.0))
			else:
				lm.box("Hedge", Vector3(bx, 0.7, bz), Vector3(11.0, 0.7, 11.0))
	lm.box("Wall", Vector3(55.0, 3.5, -129.0), Vector3(150.0, 7.0, 3.0))
	SEuUtil.face_row(lm, "Shadow", Vector3(55.0, 0, -127.4), Vector3.RIGHT, Vector3(0, 0, 1), 0.4, 22, 6.4, 3.0, 5.4)
	SEuUtil.crenels(lm, "Wall", Vector3(-20.0, 7.0, -129.0), Vector3(130.0, 7.0, -129.0), 1.2, 1.4, 1.0)
	lm.box("Wall", Vector3(130.0, 3.5, -88.0), Vector3(2.0, 7.0, 82.0))
	var pv := Vector3(100.0, 0, -62.0)
	lm.box("Wall", pv + Vector3(0, 3.5, 0), Vector3(10.0, 7.0, 10.0))
	LandmarkCeParts.hip(lm, "Tile", pv + Vector3(0, 7.0, 0), 10.6, 10.6, 3.0)
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		SEuUtil.face_row(lm, "Shadow", pv + out * 5.0, r * Vector3(1, 0, 0), out, 0.4, 2, 4.0, 2.0, 4.2)
	lm.commit(model)

class_name LandmarkIbCordoba
extends RefCounted

## The Mosque-Cathedral of Cordoba in true metres, the qibla wall toward
## +Z (the registry yaw_deg turns it onto the real bearing, about 151
## degrees: the qibla faces south-south-east).

const MEZ_HX := 64.5
const MEZ_HZ := 89.5
const MEZ_WALL := 10.5
const MEZ_AISLE := 6.45

## The Mezquita on the Guadalquivir, origin at the middle of its 129 x
## 179 m rectangle, the Patio de los Naranjos to the north (-Z) and the
## qibla wall to the south: the sandstone wall crowned with stepped
## merlons, its buttresses, and the decorated gates of al-Hakam II (west)
## and al-Mansur (east), each a horseshoe door in an alfiz under a blind
## arcade between lattice windows; the orange court with its arcaded
## side galleries; the 54 m Renaissance bell tower (1593-1617) round the
## old minaret under the archangel; the hall of 19 aisles (11 of the
## original mosque, 8 of al-Mansur's extension) under rows of tiled
## gabled roofs; the cathedral nave (Hernan Ruiz, 1523-1607) with its
## buttresses, pinnacles and balustrades and the crossing lantern; and,
## where the roof is cut away beside the court, the forest of
## red-and-white double arches on slender columns.
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
	lm.use("Glass", LandmarkMaterials.glass())
	var hx := MEZ_HX
	var hz := MEZ_HZ
	var t := 1.8
	lm.box("Paving", Vector3(0, 0.175, 0), Vector3(2.0 * hx, 0.35, 2.0 * hz))
	# Perimeter and dividing wall, crowned with stepped merlons.
	for z in [-hz + t * 0.5, hz - t * 0.5, -29.5]:
		lm.box("Wall", Vector3(0, MEZ_WALL * 0.5, z), Vector3(2.0 * hx, MEZ_WALL, t))
		LandmarkIbParts.stepped_merlons(lm, "Wall", Vector3(-hx, MEZ_WALL, z), Vector3(hx, MEZ_WALL, z), 1.3, 1.6, 0.9)
	for x in [-hx + t * 0.5, hx - t * 0.5]:
		lm.box("Wall", Vector3(x, MEZ_WALL * 0.5, 0), Vector3(t, MEZ_WALL, 2.0 * hz - 2.0 * t))
		LandmarkIbParts.stepped_merlons(lm, "Wall", Vector3(x, MEZ_WALL, -hz + t), Vector3(x, MEZ_WALL, hz - t), 1.3, 1.6, 0.9)
	# Buttresses, each crowned with a pair of merlons; the gates between.
	for i in 18:
		var z := -hz + 9.0 + 9.9 * float(i)
		for s in [-1.0, 1.0]:
			var bx: float = s * (hx + 0.7)
			lm.box("Wall", Vector3(bx, 5.9, z), Vector3(1.6, 11.8, 2.2))
			LandmarkIbParts.stepped_merlons(lm, "Wall", Vector3(bx, 11.8, z - 1.1), Vector3(bx, 11.8, z + 1.1), 0.9, 1.3, 1.4)
	for i in 12:
		var x := -hx + 9.0 + 10.1 * float(i)
		lm.box("Wall", Vector3(x, 5.9, hz + 0.7), Vector3(2.2, 11.8, 1.6))
		if i != 4:
			lm.box("Wall", Vector3(x, 5.9, -hz - 0.7), Vector3(2.2, 11.8, 1.6))
	# Gates: al-Hakam II's on the west front (San Esteban among them),
	# al-Mansur's row on the east, the court gates.
	for gz in [-6.95, 12.85, 32.65, 52.45]:
		_gate(lm, Vector3(-hx, 0, gz), Vector3(-1, 0, 0), gz < 0.0)
	for i in 9:
		_gate(lm, Vector3(hx, 0, -6.95 + 9.9 * float(i)), Vector3(1, 0, 0), false)
	for g in [[-1.0, -65.65], [1.0, -65.65]]:
		var s: float = g[0]
		_gate(lm, Vector3(s * hx, 0, float(g[1])), Vector3(s, 0, 0), false)
	LandmarkIbParts.portal(lm, "Stone", "Shadow", Vector3(-14.0, 0.35, -hz), Vector3(1, 0, 0), Vector3(0, 0, -1),
		3.8, 6.8, 2, 0.7, true)
	# Patio de los Naranjos: rows of orange trees, palms, fountains, the
	# arcaded side galleries and the hall doors.
	LandmarkIbUtil.tree_grid(lm, "Leaf", Vector3(0, 0.35, -59.0), 8, 5, 7.2, 9.0, 2.1, 4.4)
	for p in [Vector3(-30.0, 0.35, -44.0), Vector3(30.0, 0.35, -44.0), Vector3(-30.0, 0.35, -74.0),
			Vector3(30.0, 0.35, -74.0)]:
		var pp: Vector3 = p
		lm.frustum("Wall", pp, 0.25, 0.18, 12.0, 6)
		for k in 7:
			var a := TAU * float(k) / 7.0
			lm.beam("Leaf", pp + Vector3(0, 12.0, 0), pp + Vector3(cos(a) * 3.2, 11.0, sin(a) * 3.2), 0.9, 0.08)
	for p in [Vector3(0, 0.35, -44.0), Vector3(0, 0.35, -74.0)]:
		var fp: Vector3 = p
		lm.frustum("Stone", fp, 2.4, 2.4, 0.6, 16)
		lm.frustum("Stone", fp + Vector3(0, 0.6, 0), 0.3, 0.25, 0.9, 8)
		lm.lathe("Stone", fp + Vector3(0, 1.5, 0), SEuUtil.dome(0.7, 0.3, 4), 12)
	for s in [-1.0, 1.0]:
		var gx: float = s * (hx - t - 2.0)
		for i in 12:
			var z := -86.0 + 4.4 * float(i) + 2.2
			LandmarkIbParts.post(lm, "Stone", Vector3(gx - s * 1.7, 0.35, z - 2.2), 0.3, 3.45, 8)
			LandmarkIbUtil.wedge_arch(lm, "Stone", "Stone", Vector3(gx - s * 1.7, 3.8, z), Vector3(0, 0, 1),
				Vector3(1, 0, 0), 1.5, 0.4, 0.8, 0.0, 180.0, 6)
		LandmarkIbParts.post(lm, "Stone", Vector3(gx - s * 1.7, 0.35, -86.0 + 4.4 * 12.0), 0.3, 3.45, 8)
		lm.box("Wall", Vector3(gx - s * 1.7, 5.0, -59.0), Vector3(0.8, 1.0, 52.8))
		lm.box("Tile", Vector3(gx - s * 0.2, 5.6, -59.0), Vector3(3.6, 0.3, 52.8))
	for i in 19:
		var dx := -61.275 + MEZ_AISLE * (float(i) + 0.5)
		LandmarkIbParts.portal(lm, "Stone", "Shadow", Vector3(dx, 0.35, -30.4), Vector3(-1, 0, 0), Vector3(0, 0, -1),
			3.0, 5.6, 2, 0.4)
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
	# Al-Hakam's mihrab domes rise over the roof by the qibla wall.
	for dx in [-17.5, -11.05, -4.6]:
		lm.box("Wall", Vector3(dx, 12.0, 82.0), Vector3(6.0, 3.0, 6.0))
		lm.lathe("Tile", Vector3(dx, 13.5, 82.0), SEuUtil.dome(3.2, 2.2, 5), 8, 1.0, 1.0, PI / 8.0, false)
	_nave(lm)
	_forest(lm)
	lm.commit(model)

## A decorated gate on the outer wall at `p` (wall line, ground) facing
## `out`: a projecting panel, the horseshoe door in its alfiz, a blind
## arcade of three lobed arches above and a lattice window either side.
static func _gate(lm: LandmarkMesh, p: Vector3, out: Vector3, grand: bool) -> void:
	var right := Vector3.UP.cross(out)
	var w := 7.6 if grand else 6.6
	var f := p + out * 0.4
	lm.box("Stone", p + out * 0.2 + Vector3(0, 5.0, 0), Vector3(w, 10.0, 0.4), Basis(right, Vector3.UP, out))
	LandmarkIbParts.portal(lm, "Red", "Shadow", f + Vector3(0, 0.35, 0), right, out, 2.8, 5.2, 2, 0.35, true)
	for i in 3:
		LandmarkIbParts.portal(lm, "Stone", "Shadow", f + right * (float(i - 1) * 1.6) + Vector3(0, 7.2, 0),
			right, out, 1.0, 1.8, 2, 0.2)
	for s in [-1.0, 1.0]:
		LandmarkIbParts.portal(lm, "Red", "Shadow", f + right * (float(s) * (w * 0.5 - 1.1)) + Vector3(0, 2.6, 0),
			right, out, 1.0, 2.4, 2, 0.25, true)
	lm.box("Red", f + Vector3(0, 9.6, 0) + out * 0.1, Vector3(w, 0.5, 0.2), Basis(right, Vector3.UP, out), 0.0)

## The bell tower round the old minaret (Hernan Ruiz III, 1593-1617):
## the cased minaret shaft with its paired horseshoe windows, the
## belfry with arched bell openings between pilasters and a balustrade,
## the clock stage, the lantern, the lead cupola and the gilded
## archangel Raphael at 54 m; the Puerta del Perdon at its foot.
static func _alminar(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Wall", c + Vector3(0, 11.5, 0), Vector3(10.4, 23.0, 10.4))
	lm.box("Stone", c + Vector3(0, 0.8, 0), Vector3(11.0, 1.6, 11.0))
	lm.box("Stone", c + Vector3(0, 23.3, 0), Vector3(11.6, 0.8, 11.6))
	lm.box("Wall", c + Vector3(0, 29.0, 0), Vector3(9.2, 10.6, 9.2))
	lm.box("Stone", c + Vector3(0, 34.6, 0), Vector3(10.2, 0.6, 10.2))
	lm.box("Wall", c + Vector3(0, 38.6, 0), Vector3(8.0, 7.4, 8.0))
	lm.box("Stone", c + Vector3(0, 42.6, 0), Vector3(9.0, 0.6, 9.0))
	lm.box("Wall", c + Vector3(0, 44.3, 0), Vector3(5.6, 2.8, 5.6))
	lm.box("Stone", c + Vector3(0, 45.9, 0), Vector3(6.4, 0.5, 6.4))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var f := c + out * 5.2
		# Minaret shaft: two tiers of paired horseshoe windows, a door.
		for wy in [6.0, 14.0]:
			for s in [-1.0, 1.0]:
				LandmarkIbParts.portal(lm, "Stone", "Shadow", f + right * (float(s) * 1.0) + Vector3(0, wy, 0), right, out,
					1.2, 3.0, 2, 0.25, false)
			lm.box("Stone", f + out * 0.2 + Vector3(0, wy + 1.4, 0), Vector3(0.35, 2.8, 0.4), r)
		LandmarkIbParts.band(lm, "Stone", f, right, out, 10.4, 19.6, 0.35, 0.15)
		LandmarkIbParts.rail(lm, "Stone", f + out * 0.3 - right * 5.4 + Vector3(0, 23.7, 0),
			f + out * 0.3 + right * 5.4 + Vector3(0, 23.7, 0), 1.0, 5.4, true)
		# Belfry: two arched bell openings, pilasters, balustrade.
		var fb := c + out * 4.6
		for s in [-1.0, 1.0]:
			LandmarkIbParts.portal(lm, "Stone", "Shadow", fb + right * (float(s) * 2.0) + Vector3(0, 26.0, 0), right, out,
				2.0, 5.6, 1, 0.3)
		LandmarkIbParts.pilaster_row(lm, "Stone", fb, right, out, 3, 4.0, 0.6, 0.3, 23.7, 34.3)
		LandmarkIbParts.rail(lm, "Stone", fb + out * 0.3 - right * 4.8 + Vector3(0, 34.9, 0),
			fb + out * 0.3 + right * 4.8 + Vector3(0, 34.9, 0), 0.9, 4.8, true)
		# Clock stage: one arch and a dial; the lantern's small arches.
		var fc := c + out * 4.0
		LandmarkIbParts.portal(lm, "Stone", "Shadow", fc + Vector3(0, 35.6, 0), right, out, 2.4, 4.6, 1, 0.3)
		lm.disc("Stone", fc + out * 0.05 + Vector3(0, 41.0, 0), out, 0.9, 16)
		LandmarkIbParts.pilaster_row(lm, "Stone", fc, right, out, 2, 7.4, 0.6, 0.3, 34.9, 42.3)
		LandmarkIbParts.portal(lm, "Stone", "Shadow", c + out * 2.8 + Vector3(0, 43.2, 0), right, out, 1.2, 2.2, 1, 0.2)
		LandmarkIbParts.urn(lm, "Stone", c + out * 4.3 + right * 4.3 + Vector3(0, 42.9, 0), 1.2)
	var base := c + Vector3(0, 46.15, 0)
	lm.lathe("Lead", base, SEuUtil.dome(3.1, 3.0, 8), 16)
	for i in 8:
		var a := TAU * float(i) / 8.0
		lm.beam("Lead", base + Vector3(cos(a) * 3.15, 0, sin(a) * 3.15), base + Vector3(cos(a) * 0.9, 2.8, sin(a) * 0.9), 0.25, 0.15)
	lm.frustum("Stone", base + Vector3(0, 2.9, 0), 1.0, 0.9, 1.4, 8)
	lm.lathe("Lead", base + Vector3(0, 4.3, 0), SEuUtil.dome(1.1, 0.9, 4), 8)
	lm.frustum("Stone", base + Vector3(0, 5.2, 0), 0.5, 0.4, 0.4, 8)
	LandmarkKits.statue_figure(lm, "Gilt", base + Vector3(0, 5.6, 0), 2.25, true)
	# Puerta del Perdon at the tower's foot, facing the street.
	LandmarkIbParts.portal(lm, "Stone", "Shadow", c + Vector3(0, 0, -5.6), Vector3(-1, 0, 0), Vector3(0, 0, -1),
		4.0, 8.4, 2, 0.6, true)

## Renaissance cathedral inside the hall: the nave with buttresses,
## pinnacles, arched windows and a balustrade at the eaves, the transept
## with portals, and the crossing lantern over the roof rows.
static func _nave(lm: LandmarkMesh) -> void:
	lm.box("Wall", Vector3(0, 12.25, 35.0), Vector3(22.0, 24.5, 62.0))
	lm.gable("Lead", Vector3(0, 24.5, 35.0), 22.0, 62.0, 6.5, Basis(), 0.4)
	lm.box("Wall", Vector3(0, 12.25, 37.0), Vector3(54.0, 24.5, 14.0))
	lm.gable("Lead", Vector3(0, 24.5, 37.0), 14.0, 54.0, 5.5, Basis(Vector3.UP, PI * 0.5), 0.4)
	for s in [-1.0, 1.0]:
		var sn := Vector3(s, 0, 0)
		for z in [6.0, 14.5, 23.0, 51.0, 59.5, 66.0]:
			LandmarkIbParts.buttress(lm, "Wall", Vector3(s * 11.0, 10.0, z), sn, 1.3, 1.6, 14.5)
			LandmarkCeParts.pinnacle(lm, "Stone", Vector3(s * 11.6, 24.5, z), 0.8, 3.6)
		for z in [10.25, 18.75, 55.25, 62.75]:
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(s * 11.0, 16.5, z), sn, 2.2, 6.0, true)
		LandmarkIbParts.rail(lm, "Stone", Vector3(s * 11.3, 24.5, 4.5), Vector3(s * 11.3, 24.5, 29.5), 0.9, 4.25)
		LandmarkIbParts.rail(lm, "Stone", Vector3(s * 11.3, 24.5, 44.5), Vector3(s * 11.3, 24.5, 65.5), 0.9, 4.25)
		# Transept ends: a portal under a big arched window.
		var ef := Vector3(s * 27.0, 10.0, 37.0)
		LandmarkDetail.window(lm, "Stone", "Glass", ef + Vector3(0, 6.5, 0), sn, 3.0, 8.0, true)
		LandmarkIbParts.band(lm, "Stone", ef - Vector3(0, 10.0, 0), Vector3(0, 0, 1), sn, 14.0, 22.0, 0.6, 0.4)
		for z in [-6.0, 6.0]:
			LandmarkCeParts.pinnacle(lm, "Stone", ef + Vector3(s * 0.3, 14.5, z), 0.9, 4.0)
	var c := Vector3(0, 0, 37.0)
	lm.frustum("Wall", c + Vector3(0, 24.5, 0), 8.5, 8.5, 11.0, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Shadow", c + Vector3(0, 24.5, 0), 8.5, 8, 8, 3.0, 1.8, 6.5, true)
	lm.frustum("Stone", c + Vector3(0, 35.0, 0), 9.2, 9.2, 0.6, 8, PI / 8.0)
	for i in 8:
		var a := PI / 8.0 + TAU * float(i) / 8.0
		LandmarkCeParts.pinnacle(lm, "Stone", c + Vector3(cos(a) * 8.9, 35.6, sin(a) * 8.9), 0.7, 3.0)
	lm.lathe("Lead", c + Vector3(0, 35.5, 0), SEuUtil.dome(8.9, 7.0, 6), 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Wall", c + Vector3(0, 42.5, 0), 2.4, 2.2, 3.6, 8)
	SEuUtil.ring_openings(lm, "Shadow", c + Vector3(0, 42.5, 0), 2.4, 8, 4, 0.8, 0.8, 2.2, false)
	lm.frustum("Tile", c + Vector3(0, 46.1, 0), 2.8, 0.2, 3.0, 8)
	LandmarkCeParts.cross(lm, "Gilt", c + Vector3(0, 48.9, 0), 1.8)

## The forest of red-and-white arches: 20 column lines running north to
## south, six columns deep, each column on a base under a capital and
## impost block, carrying a horseshoe arch and above it a round arch on
## pillars.
static func _forest(lm: LandmarkMesh) -> void:
	var col_h := 3.0
	var prof := PackedVector2Array([Vector2(0.28, 0), Vector2(0.22, col_h - 0.3)])
	for i in 20:
		var x := -61.275 + MEZ_AISLE * float(i)
		for j in 6:
			var z := -27.0 + 4.4 * float(j)
			lm.box("Stone", Vector3(x, 0.5, z), Vector3(0.62, 0.3, 0.62), Basis(), 0.0)
			lm.lathe("Stone", Vector3(x, 0.35, z), prof, 6, 1.0, 1.0, 0.0, true, false)
			lm.lathe("Stone", Vector3(x, 0.35 + col_h - 0.35, z), PackedVector2Array([Vector2(0.22, 0),
				Vector2(0.3, 0.2), Vector2(0.38, 0.35)]), 6, 1.0, 1.0, 0.0, true, false)
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

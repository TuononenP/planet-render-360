class_name LandmarkCeGothic
extends RefCounted

## Two Gothic cathedrals of the Danube in true metres, axes along X
## with the west front at -X: St Vitus in Prague (124 m long, a tall
## central vessel braced by Parler's flying buttresses, twin 82 m west
## spires and the 96.5 m great south tower with its Renaissance gallery
## and baroque helm beside the Golden Gate) and St Stephen's in Vienna
## (107 m hall church under the 38 m chevron-tiled roof with the
## double-headed eagle, gables along the nave, the 136.4 m south spire,
## the 68 m north tower and the 65 m Heathen Towers).

const VITUS_TOP := 96.5
const V_EAVE := 36.0
const V_AISLE := 17.0
const V_HALF := 7.0
const V_WEST := -47.0
const V_APSE := 50.0

static func vitus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A29C8E", 3.0))
	lm.use("Pale", LandmarkMaterials.pbr("limestone", "#B7AE98", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#6F8F7B", 2.5, 0.55, 0.25))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Central vessel (nave and choir), transept, aisles under lean-to roofs.
	var nl := V_APSE - V_WEST
	var mx := (V_APSE + V_WEST) * 0.5
	lm.box("Stone", Vector3(mx, V_EAVE * 0.5, 0), Vector3(nl, V_EAVE, V_HALF * 2.0))
	lm.gable("Roof", Vector3(mx, V_EAVE, 0), V_HALF * 2.0, nl, 15.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Stone")
	lm.box("Stone", Vector3(-4.0, V_EAVE * 0.5, 0), Vector3(V_HALF * 2.0, V_EAVE, 58.0))
	lm.gable("Roof", Vector3(-4.0, V_EAVE, 0), V_HALF * 2.0, 58.0, 15.0, Basis(), 0.5, "Stone")
	for sz in [-1.0, 1.0]:
		for seg in [[V_WEST, -11.0], [3.0, V_APSE]]:
			var x0: float = seg[0]
			var x1: float = seg[1]
			lm.box("Stone", Vector3((x0 + x1) * 0.5, V_AISLE * 0.5, sz * 11.0), Vector3(x1 - x0, V_AISLE, 8.0))
			lm.quad("Roof", Vector3(x0, V_AISLE, sz * 15.2), Vector3(x1, V_AISLE, sz * 15.2),
				Vector3(x1, V_AISLE + 5.0, sz * V_HALF), Vector3(x0, V_AISLE + 5.0, sz * V_HALF),
				Vector3(0, 1.0, sz * 0.6).normalized())
	# Bays: aisle lancets, clerestory lancets under wimpergs, buttresses,
	# pinnacles and flyers (richest on Parler's choir).
	var bays: Array[float] = []
	for i in 5:
		bays.append(V_WEST + 3.0 + 7.0 * i)
	for i in 6:
		bays.append(3.0 + 3.6 + 7.2 * i)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for i in bays.size():
			var x: float = bays[i]
			var mid := x + 3.5
			if i != 4 and i != 10:
				LandmarkCeParts.lancet(lm, "Pale", "Windows", Vector3(mid, 4.0, sz * 15.05), n, 3.6, 11.0, 1)
				LandmarkCeParts.lancet(lm, "Pale", "Windows", Vector3(mid, V_AISLE + 6.0, sz * V_HALF), n, 4.6, 12.0, 2)
				LandmarkCeParts.wimperg(lm, "Pale", Vector3(mid, V_EAVE - 1.4, sz * (V_HALF + 0.2)), n, 5.0, 4.2)
			lm.box("Pale", Vector3(x, 11.0, sz * 16.4), Vector3(1.8, 22.0, 3.2))
			LandmarkCeParts.pinnacle(lm, "Pale", Vector3(x, 22.0, sz * 16.4), 1.6, 8.0)
			lm.beam("Pale", Vector3(x, 20.0, sz * 16.0), Vector3(x, 27.0, sz * (V_HALF + 0.3)), 0.9, 1.2)
			if i >= 5:
				lm.beam("Pale", Vector3(x, 25.0, sz * 16.0), Vector3(x, 32.0, sz * (V_HALF + 0.3)), 0.9, 1.2)
			lm.box("Pale", Vector3(x, V_EAVE - 2.5, sz * (V_HALF + 0.4)), Vector3(1.2, 5.0, 0.8))
			LandmarkCeParts.pinnacle(lm, "Pale", Vector3(x, V_EAVE, sz * (V_HALF + 0.4)), 0.9, 4.5)
		# Transept front: rose window over the portal.
		var zf: float = sz * 29.05
		lm.disc("Windows", Vector3(-4.0, 24.0, zf + sz * 0.02), n, 4.2, 24)
		for k in 12:
			var a := TAU * float(k) / 12.0
			lm.beam("Pale", Vector3(-4.0, 24.0, zf + sz * 0.15), Vector3(-4.0 + cos(a) * 4.4, 24.0 + sin(a) * 4.4, zf + sz * 0.15),
				0.25, 0.3)
		LandmarkCeParts.lancet(lm, "Pale", "Windows", Vector3(-4.0, 6.0, zf), n, 6.0, 12.0, 3)
	_vitus_chevet(lm)
	_vitus_west(lm)
	_vitus_south_tower(lm)
	var pivot := Node3D.new()
	pivot.position = Vector3(-8.0, 0, 0)
	model.add_child(pivot)
	lm.commit(pivot)

## Choir apse with its ring of radiating chapels and flyers.
static func _vitus_chevet(lm: LandmarkMesh) -> void:
	var c := Vector3(V_APSE, 0, 0)
	lm.lathe("Stone", c, PackedVector2Array([Vector2(V_HALF * 1.05, 0), Vector2(V_HALF * 1.05, V_EAVE)]),
		10, 1.0, 1.0, PI / 10.0, false)
	lm.lathe("Roof", c + Vector3(0, V_EAVE, 0), PackedVector2Array([Vector2(V_HALF * 1.12, 0), Vector2(0.0, 15.0)]),
		10, 1.0, 1.0, PI / 10.0, false)
	lm.lathe("Stone", c, PackedVector2Array([Vector2(13.0, 0), Vector2(13.0, V_AISLE)]), 14, 1.0, 1.0, 0.0, false)
	lm.lathe("Roof", c + Vector3(0, V_AISLE, 0), PackedVector2Array([Vector2(13.4, 0), Vector2(V_HALF, 5.0)]),
		14, 1.0, 1.0, 0.0, false)
	for k in 5:
		var a := PI * (-0.5 + (float(k) + 0.5) / 5.0)
		var d := Vector3(cos(a), 0, sin(a))
		var cc := c + d * 15.5
		lm.lathe("Pale", cc, PackedVector2Array([Vector2(3.8, 0), Vector2(3.8, 13.0)]), 7, 1.0, 1.0, a, false)
		lm.lathe("Roof", cc + Vector3(0, 13.0, 0), PackedVector2Array([Vector2(4.2, 0), Vector2(0.0, 5.5)]), 7, 1.0, 1.0, a, false)
		LandmarkCeParts.lancet(lm, "Pale", "Windows", cc + d * 3.7 + Vector3(0, 3.0, 0), d, 2.2, 8.0, 1)
		var pa := a + PI / 10.0
		var pd := Vector3(cos(pa), 0, sin(pa))
		if k < 4:
			lm.box("Pale", c + pd * 18.0 + Vector3(0, 11.0, 0), Vector3(1.8, 22.0, 2.4), Basis(Vector3.UP, -pa))
			LandmarkCeParts.pinnacle(lm, "Pale", c + pd * 18.0 + Vector3(0, 22.0, 0), 1.6, 8.0)
			lm.beam("Pale", c + pd * 17.0 + Vector3(0, 20.0, 0), c + pd * (V_HALF + 0.5) + Vector3(0, 28.0, 0), 0.9, 1.2)
			lm.beam("Pale", c + pd * 17.0 + Vector3(0, 25.0, 0), c + pd * (V_HALF + 0.5) + Vector3(0, 33.0, 0), 0.9, 1.2)
		LandmarkCeParts.lancet(lm, "Pale", "Windows", c + d * V_HALF + Vector3(0, V_AISLE + 6.0, 0), d, 3.0, 12.0, 1)
		LandmarkCeParts.wimperg(lm, "Pale", c + d * V_HALF + Vector3(0, V_EAVE - 1.4, 0), d, 3.4, 3.6)

## West front: two square towers with octagonal spires to 82 m, three
## portals, the rose window and the gable between them.
static func _vitus_west(lm: LandmarkMesh) -> void:
	var x := V_WEST - 5.0
	for sz in [-1.0, 1.0]:
		var c := Vector3(x, 0, sz * 10.0)
		lm.box("Pale", c + Vector3(0, 29.0, 0), Vector3(10.0, 58.0, 10.0))
		for f in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * f)
			var n := r * Vector3(0, 0, 1)
			LandmarkCeParts.lancet(lm, "Stone", "Windows", c + n * 5.0 + Vector3(0, 40.0, 0), n, 2.6, 11.0, 1)
			LandmarkCeParts.wimperg(lm, "Pale", c + n * 5.0 + Vector3(0, 51.4, 0), n, 3.2, 4.0)
			lm.box("Pale", c + n * 5.0 + Vector3(0, 36.0, 0), Vector3(10.6, 0.5, 0.6), r, 0.0)
		for s in [-1.0, 1.0]:
			for t in [-1.0, 1.0]:
				var q := c + Vector3(s * 5.0, 0, t * 5.0)
				lm.box("Pale", q + Vector3(0, 27.0, 0), Vector3(1.6, 54.0, 1.6))
				LandmarkCeParts.pinnacle(lm, "Pale", q + Vector3(0, 54.0, 0), 1.6, 10.0)
		lm.lathe("Pale", c + Vector3(0, 58.0, 0), PackedVector2Array([Vector2(4.6, 0), Vector2(3.0, 10.0),
			Vector2(1.2, 20.0), Vector2(0.0, 24.0)]), 8, 1.0, 1.0, PI / 8.0, false)
		for k in 8:
			var a := PI / 8.0 + TAU * float(k) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			for j in 6:
				var t := (float(j) + 0.5) / 7.0
				lm.box("Pale", c + Vector3(0, 58.0 + 24.0 * t, 0) + d * (4.6 * (1.0 - t) + 0.3), Vector3(0.5, 0.4, 0.5),
					Basis(Vector3.UP, -a), 0.0)
		lm.box("Gilt", c + Vector3(0, 82.3, 0), Vector3(0.25, 1.0, 0.25), Basis(), 0.0)
	lm.box("Pale", Vector3(x, 20.0, 0), Vector3(10.0, 40.0, 10.0))
	lm.gable("Roof", Vector3(x, 40.0, 0), 10.0, 10.0, 8.0, Basis(), 0.3, "Pale")
	var n := Vector3.LEFT
	lm.disc("Windows", Vector3(x - 5.05, 29.0, 0), n, 4.0, 32)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.beam("Pale", Vector3(x - 5.2, 29.0, 0), Vector3(x - 5.2, 29.0 + sin(a) * 4.2, cos(a) * 4.2), 0.25, 0.3)
	lm.frustum("Pale", Vector3(x - 5.15, 29.0, 0), 4.4, 4.4, 0.01, 32)
	for k in 3:
		var z := (float(k) - 1.0) * 10.0
		var w := 4.0 if k == 1 else 3.0
		LandmarkCeParts.lancet(lm, "Stone", "Windows", Vector3(x - 5.0, 0.5, z), n, w, 9.0, 0, 0.6)
		LandmarkCeParts.wimperg(lm, "Pale", Vector3(x - 5.0, 9.2, z), n, w + 1.4, 5.0, 0.5)

## The great south tower beside the Golden Gate: Gothic shaft with
## tall belfry lancets and the clock, Renaissance gallery, baroque
## copper helm with two lanterns.
static func _vitus_south_tower(lm: LandmarkMesh) -> void:
	var t := Vector3(-18.0, 0, 21.0)
	lm.box("Stone", t + Vector3(0, 28.0, 0), Vector3(14.5, 56.0, 14.5))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		var n := r * Vector3(0, 0, 1)
		for k in [-1.0, 1.0]:
			LandmarkCeParts.lancet(lm, "Pale", "Windows", t + r * Vector3(k * 2.8, 0, 7.25) + Vector3(0, 34.0, 0), n,
				2.2, 14.0, 1)
		LandmarkCeParts.wimperg(lm, "Pale", t + n * 7.3 + Vector3(0, 48.4, 0), n, 8.0, 6.0)
		for s in [-1.0, 1.0]:
			lm.box("Pale", t + r * Vector3(s * 7.0, 0, 7.0) + Vector3(0, 27.0, 0), Vector3(2.0, 54.0, 2.0))
			LandmarkCeParts.pinnacle(lm, "Pale", t + r * Vector3(s * 7.0, 0, 7.0) + Vector3(0, 54.0, 0), 1.8, 8.0)
	# The two clock faces (hours and quarters) on the south side.
	for k in 2:
		var cc := t + Vector3(0, 24.0 - 5.5 * k, 7.32)
		lm.disc("Gilt", cc, Vector3.BACK, 1.8 - 0.4 * k, 24)
		lm.frustum("Pale", cc - Vector3(0, 0, 0.05), 2.0 - 0.4 * k, 2.0 - 0.4 * k, 0.01, 24)
	# Golden Gate: triple arcade under the gold mosaic of the Last Judgement.
	var gg := Vector3(-4.0, 0, 29.05)
	lm.box("Gilt", gg + Vector3(0, 13.5, 0.05), Vector3(10.0, 6.0, 0.1), Basis(), 0.0)
	lm.box("Pale", gg + Vector3(0, 5.0, 1.5), Vector3(12.0, 10.0, 3.0))
	for k in 3:
		LandmarkDetail.arch(lm, "Pale", gg + Vector3((float(k) - 1.0) * 3.8, 6.5, 3.0), Vector3.BACK, 3.0, 0.5, 0.5)
		lm.box("Windows", gg + Vector3((float(k) - 1.0) * 3.8, 3.3, 3.02), Vector3(3.0, 6.5, 0.05), Basis(), 0.0)
	# Renaissance gallery stage with balustrade and arcades.
	var gy := 56.0
	lm.box("Pale", t + Vector3(0, gy + 6.0, 0), Vector3(11.0, 12.0, 11.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		var n := r * Vector3(0, 0, 1)
		LandmarkDetail.balustrade(lm, "Pale", t + r * Vector3(-7.0, gy, 7.0), t + r * Vector3(7.0, gy, 7.0), 1.1, 3.5)
		for k in 3:
			var p := t + r * Vector3((float(k) - 1.0) * 3.2, 0, 5.5) + Vector3(0, gy + 3.0, 0)
			lm.box("Windows", p + n * 0.02, Vector3(1.6, 5.0, 0.05), r, 0.0)
			LandmarkDetail.arch(lm, "Pale", p + Vector3(0, 5.0, 0), n, 1.6, 0.3, 0.3)
		LandmarkDetail.cornice(lm, "Pale", t + r * Vector3(-5.5, gy + 11.4, 5.5), t + r * Vector3(5.5, gy + 11.4, 5.5), n, 0.8)
	lm.box("Pale", t + Vector3(0, gy - 0.3, 0), Vector3(15.0, 0.6, 15.0))
	# Baroque helm: bell, lantern, second bell, spike, gilt cross.
	var hb := t + Vector3(0, gy + 12.2, 0)
	lm.lathe("Roof", hb, PackedVector2Array([Vector2(6.6, 0), Vector2(7.4, 1.0), Vector2(7.2, 2.6),
		Vector2(6.0, 4.6), Vector2(4.2, 7.0), Vector2(3.0, 8.4), Vector2(2.6, 9.4)]), 16)
	var lb := hb + Vector3(0, 9.4, 0)
	lm.frustum("Pale", lb, 2.4, 2.3, 5.6, 16)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		lm.box("Windows", lb + Vector3(cos(a) * 2.38, 2.8, sin(a) * 2.38), Vector3(0.9, 3.0, 0.05),
			Basis(Vector3.UP, PI * 0.5 - a), 0.0)
	lm.frustum("Pale", lb + Vector3(0, 5.4, 0), 2.7, 2.7, 0.4, 16)
	lm.lathe("Roof", lb + Vector3(0, 5.8, 0), PackedVector2Array([Vector2(3.0, 0), Vector2(2.9, 0.8),
		Vector2(2.0, 2.6), Vector2(1.0, 4.2), Vector2(0.9, 4.6)]), 16)
	lm.frustum("Pale", lb + Vector3(0, 10.4, 0), 0.9, 0.8, 1.6, 12)
	lm.lathe("Roof", lb + Vector3(0, 12.0, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(0.9, 0.5),
		Vector2(0.4, 1.4), Vector2(0.15, 2.0)]), 12)
	var ct := lb + Vector3(0, 14.0, 0)
	lm.lathe("Gilt", ct - Vector3(0, 0.1, 0), PackedVector2Array([Vector2(0.15, 0), Vector2(0.55, 0.4),
		Vector2(0.4, 0.9), Vector2(0.0, 1.1)]), 12)
	LandmarkCeParts.cross(lm, "Gilt", ct + Vector3(0, 1.0, 0), VITUS_TOP - ct.y - 1.0)

# --- St Stephen's Cathedral ---

const STEPH_TOP := 136.4
const ST_EAVE := 24.0

static func stephansdom(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#9A9382", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#6F695F", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#B5643A", 2.5))
	lm.use("Chevron", LandmarkMaterials.pbr("terracotta", "#D8B556", 2.5))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6F9A86", 2.0, 0.55, 0.3))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.box("Stone", Vector3(0, ST_EAVE * 0.5, 0), Vector3(106.0, ST_EAVE, 34.0))
	lm.gable("Roof", Vector3(0, ST_EAVE, 0), 34.0, 106.0, 36.0, Basis(Vector3.UP, PI * 0.5), 0.8, "Stone")
	_steph_tiles(lm)
	# Choir apse.
	lm.lathe("Stone", Vector3(50.0, 0, 0), PackedVector2Array([Vector2(15.0, 0), Vector2(15.0, ST_EAVE)]), 10, 1.0, 1.0, 0.0, false)
	lm.lathe("Roof", Vector3(50.0, ST_EAVE, 0), PackedVector2Array([Vector2(16.0, 0), Vector2(0.0, 22.0)]), 10, 1.0, 1.0, 0.0, false)
	for k in 4:
		var a := PI * (-0.3 + 0.2 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkCeParts.lancet(lm, "Stone", "Windows", Vector3(50.0, 4.0, 0) + d * 14.6, d, 3.0, 15.0, 1)
		lm.box("Stone", Vector3(50.0, 12.0, 0) + Vector3(cos(a + 0.31), 0, sin(a + 0.31)) * 15.5, Vector3(2.0, 24.0, 2.6),
			Basis(Vector3.UP, -(a + 0.31)))
	# Bays: buttresses with pinnacles, tall tracery windows, and the
	# row of steep gables in front of the roof on both sides.
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for i in 11:
			var x := -45.0 + 9.0 * i
			lm.box("Stone", Vector3(x, 13.0, sz * 18.5), Vector3(2.0, 26.0, 3.0))
			LandmarkCeParts.pinnacle(lm, "Stone", Vector3(x, 26.0, sz * 18.5), 1.8, 9.0)
			if i < 10:
				var mx := x + 4.5
				LandmarkCeParts.lancet(lm, "Stone", "Windows", Vector3(mx, 5.0, sz * 17.0), n, 3.4, 16.0, 2)
				# Gable: solid triangle with tracery frame and crockets.
				var gb := Vector3(mx, ST_EAVE, sz * 17.2)
				lm.tri("Stone", gb - Vector3(3.8, 0, 0), gb + Vector3(3.8, 0, 0), gb + Vector3(0, 7.0, 0), n, n, n,
					Vector2.ZERO, Vector2(7.6, 0), Vector2(3.8, -7.0))
				lm.tri("Stone", gb - Vector3(3.8, 0, 0) - n * 0.6, gb + Vector3(3.8, 0, 0) - n * 0.6, gb + Vector3(0, 7.0, 0) - n * 0.6,
					-n, -n, -n, Vector2.ZERO, Vector2(7.6, 0), Vector2(3.8, -7.0))
				LandmarkCeParts.wimperg(lm, "Stone", gb, n, 7.6, 7.0, 0.5)
				lm.disc("Windows", gb + Vector3(0, 2.6, 0) + n * 0.05, n, 1.2, 12)
		LandmarkDetail.cornice(lm, "Stone", Vector3(-53.0, ST_EAVE - 1.0, sz * 17.0), Vector3(50.0, ST_EAVE - 1.0, sz * 17.0),
			n, 0.9, false)
	_steph_west(lm)
	_steph_north(lm, Vector3(-14.0, 0, -24.0))
	_steph_south(lm, Vector3(-14.0, 0, 24.0))
	lm.commit(model)

## Glazed tile pattern: six zigzag bands up each slope and the double-
## headed eagle laid in dark tiles on the south slope over the choir.
static func _steph_tiles(lm: LandmarkMesh) -> void:
	for sz in [-1.0, 1.0]:
		var dir := Vector3(0, 36.0, -sz * 17.0).normalized()
		var out := Vector3(0, 17.0, sz * 36.0).normalized() * 0.25
		for t in [0.12, 0.26, 0.4, 0.54, 0.68, 0.82]:
			var mid := Vector3(0, ST_EAVE + 36.0 * t, sz * 17.8 * (1.0 - t))
			var prev := mid + out - dir * 1.4 + Vector3(-52.0, 0, 0)
			for i in range(1, 27):
				if sz > 0.0 and i > 15 and t > 0.2 and t < 0.75:
					prev = Vector3(-52.0 + 4.0 * i, mid.y, mid.z) + out + dir * (1.4 if i % 2 == 0 else -1.4)
					continue
				var p := Vector3(-52.0 + 4.0 * i, mid.y, mid.z) + out + dir * (1.4 if i % 2 == 0 else -1.4)
				lm.beam("Chevron", prev, p, 0.9, 0.2, out)
				prev = p
	# Eagle on the south slope: body, two heads and spread wings.
	var dir_s := Vector3(0, 36.0, -17.0).normalized()
	var out_s := Vector3(0, 17.0, 36.0).normalized()
	var ec := Vector3(28.0, ST_EAVE + 36.0 * 0.45, 17.8 * 0.55) + out_s * 0.3
	var basis := Basis(Vector3.RIGHT, dir_s, out_s)
	lm.box("Dark", ec, Vector3(3.0, 6.0, 0.2), basis, 0.0)
	for s in [-1.0, 1.0]:
		for k in 4:
			lm.box("Dark", ec + Vector3(s * (3.0 + 2.0 * k), 0, 0) + dir_s * (2.0 - 0.7 * k), Vector3(2.2, 4.4 - 0.8 * k, 0.2),
				basis, 0.0)
		lm.box("Dark", ec + Vector3(s * 1.6, 0, 0) + dir_s * 4.8, Vector3(1.0, 2.2, 0.2), basis, 0.0)
		lm.box("Dark", ec + Vector3(s * 1.0, 0, 0) - dir_s * 4.4, Vector3(0.8, 2.8, 0.2), basis, 0.0)
	lm.box("Chevron", ec + dir_s * 0.5 + out_s * 0.1, Vector3(1.8, 2.4, 0.2), basis, 0.0)

## West front: Giant's Door (Riesentor) and the two 65 m Heathen Towers.
static func _steph_west(lm: LandmarkMesh) -> void:
	for sz in [-1.0, 1.0]:
		var c := Vector3(-49.0, 0, sz * 12.0)
		lm.box("Dark", c + Vector3(0, 23.0, 0), Vector3(10.0, 46.0, 10.0))
		for f in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * f)
			var n := r * Vector3(0, 0, 1)
			for k in 3:
				LandmarkDetail.window(lm, "Stone", "Windows", c + n * 5.0 + Vector3(0, 16.0 + 9.0 * k, 0), n, 1.0, 2.8, true, 0.2)
			lm.box("Stone", c + n * 5.0 + Vector3(0, 12.0, 0), Vector3(10.4, 0.4, 0.4), r, 0.0)
		lm.lathe("Dark", c + Vector3(0, 46.0, 0), PackedVector2Array([Vector2(5.0, 0), Vector2(5.0, 4.0)]),
			8, 1.0, 1.0, PI / 8.0, false)
		for k in 8:
			var a := TAU * float(k) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			LandmarkDetail.window(lm, "Stone", "Windows", c + d * 4.62 + Vector3(0, 47.6, 0), d, 0.8, 2.0, true, 0.15)
		lm.lathe("Copper", c + Vector3(0, 50.0, 0), PackedVector2Array([Vector2(5.4, 0), Vector2(4.6, 3.0),
			Vector2(2.6, 9.0), Vector2(0.3, 15.0)]), 8, 1.0, 1.0, PI / 8.0, false)
		lm.beam("Gilt", c + Vector3(0, 64.8, 0), c + Vector3(0, 65.6, 0), 0.15, 0.15)
	var x := -53.0
	lm.box("Stone", Vector3(x - 1.0, 8.0, 0), Vector3(3.0, 16.0, 13.0))
	for k in 5:
		var w := 6.0 - 0.8 * k
		lm.box("Dark", Vector3(x - 2.55 + 0.25 * k, 4.0, 0), Vector3(0.3, 8.0 - 0.6 * k, w + 1.0))
		LandmarkDetail.arch(lm, "Stone", Vector3(x - 2.5 + 0.25 * k, 7.6 - 0.3 * k, 0), Vector3.LEFT, w, 0.4, 0.4)
	lm.box("Windows", Vector3(x - 1.45, 3.4, 0), Vector3(0.05, 6.4, 2.6), Basis(), 0.0)
	LandmarkCeParts.wimperg(lm, "Stone", Vector3(x - 2.6, 14.0, 0), Vector3.LEFT, 9.0, 6.0, 0.5)
	LandmarkCeParts.lancet(lm, "Stone", "Windows", Vector3(x, 24.0, 0), Vector3.LEFT, 4.4, 12.0, 2)
	lm.disc("Windows", Vector3(x - 0.05, 40.0, 0), Vector3.LEFT, 2.6, 24)

## North tower: left unfinished at 68 m under its Renaissance cap.
static func _steph_north(lm: LandmarkMesh, n: Vector3) -> void:
	lm.box("Dark", n + Vector3(0, 25.0, 0), Vector3(20.0, 50.0, 20.0))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		var fn := r * Vector3(0, 0, 1)
		for k in [-1.0, 1.0]:
			LandmarkCeParts.lancet(lm, "Stone", "Windows", n + r * Vector3(k * 4.5, 0, 10.0) + Vector3(0, 30.0, 0), fn,
				3.0, 13.0, 1)
		for s in [-1.0, 1.0]:
			var cp := n + r * Vector3(s * 9.8, 0, 9.8)
			lm.box("Stone", cp + Vector3(0, 24.0, 0), Vector3(2.4, 48.0, 2.4))
			LandmarkCeParts.pinnacle(lm, "Stone", cp + Vector3(0, 48.0, 0), 2.2, 9.0)
		LandmarkDetail.balustrade(lm, "Stone", n + r * Vector3(-9.0, 50.0, 9.6), n + r * Vector3(9.0, 50.0, 9.6), 1.2, 4.5)
	lm.box("Stone", n + Vector3(0, 52.0, 0), Vector3(15.0, 4.0, 15.0))
	lm.lathe("Copper", n + Vector3(0, 54.0, 0), PackedVector2Array([Vector2(8.2, 0), Vector2(8.8, 1.4),
		Vector2(5.0, 4.0), Vector2(2.6, 5.4)]), 16)
	lm.frustum("Copper", n + Vector3(0, 59.4, 0), 1.8, 1.6, 3.0, 12)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		lm.box("Windows", n + Vector3(cos(a) * 1.75, 61.0, sin(a) * 1.75), Vector3(0.6, 1.6, 0.05),
			Basis(Vector3.UP, PI * 0.5 - a), 0.0)
	lm.lathe("Copper", n + Vector3(0, 62.4, 0), PackedVector2Array([Vector2(1.9, 0), Vector2(1.6, 0.8),
		Vector2(0.9, 2.2), Vector2(0.3, 3.4)]), 12)
	lm.lathe("Gilt", n + Vector3(0, 65.6, 0), PackedVector2Array([Vector2(0.2, 0), Vector2(0.5, 0.5),
		Vector2(0.3, 1.0), Vector2(0.0, 1.2)]), 10)
	lm.beam("Gilt", n + Vector3(0, 66.6, 0), n + Vector3(0, 68.3, 0), 0.12, 0.12)

## South tower ("Steffl"): one continuous taper from the square base
## through stacked gabled stages to the octagonal stone spire.
static func _steph_south(lm: LandmarkMesh, s: Vector3) -> void:
	var stages := [[0.0, 26.0, 20.0], [26.0, 50.0, 18.0], [50.0, 64.0, 16.0]]
	for st in stages:
		var y0: float = st[0]
		var y1: float = st[1]
		var w: float = st[2]
		lm.box("Stone", s + Vector3(0, (y0 + y1) * 0.5, 0), Vector3(w, y1 - y0, w))
		for f in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * f)
			var n := r * Vector3(0, 0, 1)
			var hh := (y1 - y0) * 0.55
			for k in [-1.0, 1.0]:
				var p := s + r * Vector3(k * w * 0.22, 0, w * 0.5) + Vector3(0, y0 + 3.0, 0)
				LandmarkCeParts.lancet(lm, "Stone", "Windows", p, n, w * 0.16, hh, 1)
				LandmarkCeParts.wimperg(lm, "Stone", p + Vector3(0, hh + 0.4, 0), n, w * 0.22, (y1 - y0) * 0.3)
			for e in [-1.0, 1.0]:
				var cp := s + r * Vector3(e * w * 0.5, 0, w * 0.5)
				lm.box("Stone", cp + Vector3(0, (y0 + y1) * 0.5, 0), Vector3(1.6, y1 - y0, 1.6))
				LandmarkCeParts.pinnacle(lm, "Stone", cp + Vector3(0, y1, 0), 1.6, 7.0)
	# Octagonal belfry and the 64 m spire.
	lm.lathe("Stone", s + Vector3(0, 64.0, 0), PackedVector2Array([Vector2(7.6, 0), Vector2(7.0, 8.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkCeParts.lancet(lm, "Stone", "Windows", s + d * 6.6 + Vector3(0, 64.6, 0), d, 2.2, 6.4, 1)
		LandmarkCeParts.wimperg(lm, "Stone", s + d * 6.6 + Vector3(0, 71.2, 0), d, 2.8, 4.2)
		var ca := a + PI / 8.0
		LandmarkCeParts.pinnacle(lm, "Stone", s + Vector3(cos(ca), 0, sin(ca)) * 7.0 + Vector3(0, 72.0, 0), 1.0, 6.0)
	lm.lathe("Stone", s + Vector3(0, 72.0, 0), PackedVector2Array([Vector2(6.6, 0), Vector2(5.6, 12.0),
		Vector2(3.6, 28.0), Vector2(2.0, 42.0), Vector2(0.9, 54.0), Vector2(0.4, 59.0)]),
		8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + TAU * k / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var p0 := s + d * 6.4 + Vector3(0, 72.0, 0)
		var p1 := s + d * 0.9 + Vector3(0, 126.0, 0)
		lm.beam("Dark", p0, p1, 0.5, 0.5)
		for j in 10:
			lm.box("Stone", p0.lerp(p1, (float(j) + 0.5) / 10.0) + d * 0.35, Vector3(0.5, 0.4, 0.5), Basis(Vector3.UP, -a), 0.0)
	for j in 4:
		var y := 72.0 + 12.0 * (j + 1)
		var rr := LandmarkMesh.profile_at(PackedVector2Array([Vector2(0, 6.6), Vector2(12, 5.6), Vector2(28, 3.6),
			Vector2(42, 2.0), Vector2(54, 0.9)]), y - 72.0)
		lm.frustum("Stone", s + Vector3(0, y, 0), rr + 0.3, rr + 0.25, 0.6, 8, PI / 8.0)
	# Finial: stone ball, the double eagle and the cross.
	lm.lathe("Stone", s + Vector3(0, 131.0, 0), PackedVector2Array([Vector2(0.4, 0), Vector2(0.9, 0.8),
		Vector2(0.6, 1.6), Vector2(0.2, 2.0)]), 10)
	lm.box("Gilt", s + Vector3(0, 133.6, 0), Vector3(1.8, 0.9, 0.2), Basis(), 0.0)
	LandmarkCeParts.cross(lm, "Gilt", s + Vector3(0, 133.0, 0), STEPH_TOP - 133.0)

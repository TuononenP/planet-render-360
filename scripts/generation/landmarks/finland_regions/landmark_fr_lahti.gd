class_name LandmarkFrLahti
extends RefCounted

## Salpausselka ski jumping hills, Lahti, in true metres: the three hills
## of the stadium side by side along the ridge, the large hill
## (Suurmaki, 1970-72, K116 / HS130, inrun 89.9 m at 38.6 degrees, table
## 6.45 m long at 10.5 degrees) on the west with its tower and summer
## observation deck, the normal hill (1976, K90 / HS100, inrun 83.25 m at
## 37.5 degrees) and the medium hill (1977, K64 / HS70, inrun 61 m at 37
## degrees). Each has its concrete start tower, the steel in-run on its
## trussed bridge and trestles, transition curve and take-off table, the
## covered landing slope with its side fences falling to the outrun and
## floodlight masts, and the judges' tower beside the slope. Slopes face
## north (-Z); y = 0 is the outrun, so the tables stand on built-up ground.
const LAHTI_TOP := 73.0
# Hill rows: x, tower height, tower z, start y, table y, landing length,
# in-run angle (degrees).
const LAHTI_HILLS := [[-132.0, 73.0, 56.0, 66.0, 25.0, 128.0, 38.6], [0.0, 52.0, 44.0, 46.0, 18.0, 98.0, 37.5],
	[122.0, 34.0, 28.0, 30.0, 11.0, 70.0, 37.0]]
## The built frame is shifted so the origin sits at the middle of the hills.
const LAHTI_ZOFF := 35.0

static func lahti(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BDBAB1", 4.0))
	lm.use("Steel", LandmarkMaterials.paint("#CFD2D3", 0.5, 0.4))
	lm.use("Glass", LandmarkMaterials.glass("#2A3A44"))
	lm.use("Slope", LandmarkMaterials.pbr("lawn", "#58944A", 4.0))
	lm.use("Rail", LandmarkMaterials.paint("#8E9A9F", 0.5, 0.4))
	for row in LAHTI_HILLS:
		_hill(lm, row[0] as float, row[1] as float, row[2] as float, row[3] as float, row[4] as float,
			row[5] as float, row[6] as float)
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0, LAHTI_ZOFF)
	model.add_child(pivot)
	lm.commit(pivot)

## In-run profile: the straight at `deg` easing into the 10.5 degree
## table through the transition curve; t 0..1 from the start to the table.
static func _inrun_y(t: float, start_y: float, table_y: float) -> float:
	var s := 1.0 - pow(1.0 - t, 1.35)
	return lerpf(start_y, table_y, s)

static func _hill(lm: LandmarkMesh, cx: float, th: float, tz: float, start_y: float, table_y: float,
		slope_len: float, _deg: float) -> void:
	# Tower: tapering square concrete shaft with a window strip, the glass
	# cabin with mullions, the roof slab and the deck railing on top.
	lm.frustum("Concrete", Vector3(cx, 0.0, tz), 7.2, 4.9, th - 6.0, 4, PI / 4.0)
	for k in int((th - 10.0) / 3.5):
		var y := 3.0 + 3.5 * float(k)
		var hwk := lerpf(7.2, 4.9, y / (th - 6.0)) * 0.7071
		lm.box("Glass", Vector3(cx, y + 1.0, tz + hwk + 0.02), Vector3(1.2, 1.6, 0.1))
	lm.box("Concrete", Vector3(cx, th - 6.6, tz), Vector3(9.4, 1.0, 6.4))
	lm.box("Glass", Vector3(cx, th - 4.6, tz), Vector3(11.0, 3.0, 6.4))
	for k in 12:
		var mx := cx - 5.5 + 11.0 * float(k) / 11.0
		for s: float in [-1.0, 1.0]:
			lm.box("Steel", Vector3(mx, th - 4.6, tz + s * 3.22), Vector3(0.12, 3.0, 0.1))
	for k2 in 6:
		var mz := tz - 3.2 + 6.4 * float(k2) / 5.0
		for s2: float in [-1.0, 1.0]:
			lm.box("Steel", Vector3(cx + s2 * 5.52, th - 4.6, mz), Vector3(0.1, 3.0, 0.12))
	lm.box("Concrete", Vector3(cx, th - 2.25, tz), Vector3(12.4, 2.3, 7.6))
	var r0 := Vector3(cx - 6.0, th - 1.16, tz - 3.6)
	var r1 := Vector3(cx + 6.0, th - 1.16, tz - 3.6)
	var r2 := Vector3(cx + 6.0, th - 1.16, tz + 3.6)
	var r3 := Vector3(cx - 6.0, th - 1.16, tz + 3.6)
	for e in [[r0, r1], [r1, r2], [r2, r3], [r3, r0]]:
		LandmarkFrParts.railing(lm, "Rail", e[0] as Vector3, e[1] as Vector3, 1.1, 1.6, 0.07)
	# In-run: the track on two trussed side girders following the profile,
	# trestle frames down to the ground with cross bracing, and the stair.
	var z0 := tz - 4.0
	var z1 := 3.0
	var n := 12
	var hwt := 1.6
	var prev := Vector3(cx, start_y, z0)
	for k in range(1, n + 1):
		var t := float(k) / float(n)
		var p := Vector3(cx, _inrun_y(t, start_y, table_y), lerpf(z0, z1, t))
		lm.beam("Steel", prev, p, 2.6, 0.5, Vector3.RIGHT)
		for s3: float in [-1.0, 1.0]:
			var sx := Vector3(s3 * hwt, 0, 0)
			lm.beam("Rail", prev + sx + Vector3(0, 0.6, 0), p + sx + Vector3(0, 0.6, 0), 0.12, 0.12)
			lm.lattice_panel("Rail", prev + sx - Vector3(0, 2.6, 0), p + sx - Vector3(0, 2.6, 0), prev + sx, p + sx,
				0.22, 1)
			lm.beam("Rail", prev + sx - Vector3(0, 2.6, 0), p + sx - Vector3(0, 2.6, 0), 0.4, 0.4)
			# Stair treads beside the track.
			if s3 > 0.0:
				var steps := int(prev.distance_to(p) / 1.2)
				for j in steps:
					var q := prev.lerp(p, (float(j) + 0.5) / float(steps)) + Vector3(hwt + 0.9, 0.0, 0)
					lm.box("Rail", q, Vector3(1.1, 0.06, 0.3), Basis(), 0.0)
				lm.beam("Rail", prev + Vector3(hwt + 1.45, 1.0, 0), p + Vector3(hwt + 1.45, 1.0, 0), 0.06, 0.06)
		if k < n:
			var foot := p - Vector3(0, 2.6, 0)
			for s4: float in [-1.0, 1.0]:
				lm.beam("Rail", foot + Vector3(s4 * hwt, 0, 0), Vector3(p.x + s4 * 2.8, 0.3, p.z), 0.5, 0.5, Vector3.RIGHT)
			if foot.y > 6.0:
				var mid_y := foot.y * 0.5
				lm.beam("Rail", Vector3(p.x - 2.2, mid_y, p.z), Vector3(p.x + 2.2, mid_y, p.z), 0.25, 0.25)
				lm.beam("Rail", Vector3(p.x - 2.6, 0.5, p.z), Vector3(p.x + 1.8, foot.y - 0.5, p.z), 0.18, 0.18)
		prev = p
	# Take-off table on its support, then the landing slope in strips with
	# the side fences, the K-point marks and the outrun.
	lm.box("Concrete", Vector3(cx, table_y * 0.5 - 1.0, -1.0), Vector3(7.0, table_y - 2.0, 6.0))
	lm.box("Concrete", Vector3(cx, table_y - 1.0, -1.0), Vector3(5.0, 1.2, 6.2))
	for s5: float in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(cx + s5 * 3.2, table_y - 0.2, -1.0), Vector3(0.4, 1.0, 6.2))
	var segs := 16
	var half0 := 7.0
	var half1 := 17.0 + slope_len * 0.05
	for k in segs:
		var ta := float(k) / float(segs)
		var tb := float(k + 1) / float(segs)
		var ya := table_y * pow(1.0 - ta, 1.7) + 0.02
		var yb := table_y * pow(1.0 - tb, 1.7) + 0.02
		var za := -4.0 - slope_len * ta
		var zb := -4.0 - slope_len * tb
		var ha := lerpf(half0, half1, ta)
		var hb := lerpf(half0, half1, tb)
		LandmarkFrKit.face(lm, "Slope", [Vector3(cx - ha, ya, za), Vector3(cx + ha, ya, za), Vector3(cx + hb, yb, zb),
			Vector3(cx - hb, yb, zb)])
		for s6: float in [-1.0, 1.0]:
			var side := Vector3(s6, 0, 0)
			lm.quad("Concrete", Vector3(cx + s6 * ha, ya, za), Vector3(cx + s6 * hb, yb, zb),
				Vector3(cx + s6 * hb, 0.0, zb), Vector3(cx + s6 * ha, 0.0, za), side)
			LandmarkFrParts.railing(lm, "Rail", Vector3(cx + s6 * ha, ya, za), Vector3(cx + s6 * hb, yb, zb), 1.2, 2.0,
				0.06)
		if k == int(segs * 0.62):
			lm.box("Rail", Vector3(cx, ya + 0.05, za), Vector3(2.0 * ha, 0.06, 0.4), Basis(), 0.0)
	# Floodlight masts each side of the landing slope.
	for s7: float in [-1.0, 1.0]:
		var mp := Vector3(cx + s7 * (half1 + 6.0), 0, -slope_len * 0.35)
		lm.frustum("Steel", mp, 0.35, 0.2, 24.0, 8)
		lm.box("Steel", mp + Vector3(0, 24.0, 0), Vector3(3.0, 1.2, 0.4))
		lm.box("Glass", mp + Vector3(0, 24.0, -s7 * 0.25), Vector3(2.6, 0.9, 0.1))
	# Judges' tower beside the landing slope: storeys of glazing.
	var jp := Vector3(cx + half1 + 4.0, 0, -slope_len * 0.55)
	lm.box("Concrete", jp + Vector3(0, 7.0, 0), Vector3(5.0, 14.0, 4.0))
	lm.box("Concrete", jp + Vector3(0, 14.3, 0), Vector3(5.8, 0.6, 4.8))
	for k in 3:
		lm.box("Glass", jp + Vector3(0, 7.5 + 2.4 * float(k), 2.05), Vector3(4.4, 1.8, 0.15))
		lm.box("Concrete", jp + Vector3(0, 6.4 + 2.4 * float(k), 2.2), Vector3(5.0, 0.2, 0.5))
	lm.box("Glass", jp + Vector3(-2.55, 9.9, 0), Vector3(0.15, 6.0, 3.0))

class_name LandmarkSsCivic
extends RefCounted

## Civic landmarks of the sweden_stockholm batch in true metres, origin at
## ground level at the footprint centre, front toward +Z (the registry
## yaw_deg turns it onto its real compass facing). Footprints are traced
## from the OpenStreetMap outlines and building parts in the model frame.
## This class holds the Nordic Museum; the Riksdag lives in LandmarkSsCivic2.

## Nordic Museum (Nordiska museet, Isak Gustaf Clason, 1888-1907) on
## Djurgården: the Danish-Renaissance palace of Roslagen sandstone with
## Öland and Gotland limestone dressings on a Sundbyberg granite base,
## 153 m long overall, the 126.5 m great hall under a steep slate roof
## (ridge 39 m) with glazed roof lights, octagonal copper-capped corner
## turrets, low hipped end pavilions, crow-stepped wall dormers and end
## gables, the polygonal apse at the back, the temple-fronted main gate
## between two spired towers on the front (toward Djurgårdsvägen, ENE),
## and the central tower: an octagonal stone stage with arched belfry
## windows, a copper helm, an open lantern, an onion and the gilded
## spire, 81 m above the ground.
## Sources: nordiskamuseet.se "The history of the building" (153 m long,
## tower 81 m, hall 126.5 x 15 x 24 m, materials); OSM way 348345482 and
## its building parts (outline 153.7 x 51.2 m, ridge 39 m, corner
## turrets 34 m, front towers 44 m, end pavilions 24 m).
const NM_TOP := 81.0
const NM_EAVE := 22.0
const NM_RIDGE := 39.0
const NM_X0 := -59.0
const NM_X1 := 58.5
const NM_Z0 := -16.5
const NM_Z1 := 17.5

static func nordic(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B79A82", 3.0))
	lm.use("Dressing", LandmarkMaterials.pbr("limestone", "#D3C2A9", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6C6864", 2.5))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#59616A", 2.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#1F262A"))
	lm.use("Skylight", LandmarkMaterials.paint("#9DAAB3", 0.3, 0.3))
	lm.use("Gilt", LandmarkMaterials.gold())
	var cx := (NM_X0 + NM_X1) * 0.5
	var cz := (NM_Z0 + NM_Z1) * 0.5
	var lx := NM_X1 - NM_X0
	var dz := NM_Z1 - NM_Z0
	# The hall block on its granite base, string courses and pilasters.
	LandmarkFhUtil.blk(lm, "Stone", cx, 0.0, cz, lx, NM_EAVE, dz)
	LandmarkFhUtil.blk(lm, "Granite", cx, 0.0, cz, lx + 0.9, 2.4, dz + 0.9)
	for y in [9.0, 15.5]:
		LandmarkFhParts.box_band(lm, "Dressing", cx, cz, lx, dz, float(y), 0.45, 0.55)
	var runs := [[Vector3(NM_X0, 0, NM_Z1), Vector3(-14.0, 0, NM_Z1), Vector3(0, 0, 1)],
		[Vector3(13.0, 0, NM_Z1), Vector3(NM_X1, 0, NM_Z1), Vector3(0, 0, 1)],
		[Vector3(-13.2, 0, NM_Z0), Vector3(NM_X0, 0, NM_Z0), Vector3(0, 0, -1)],
		[Vector3(NM_X1, 0, NM_Z0), Vector3(12.6, 0, NM_Z0), Vector3(0, 0, -1)]]
	for r in runs:
		var a: Vector3 = r[0]
		var b: Vector3 = r[1]
		var o: Vector3 = r[2]
		var cols := int(a.distance_to(b) / 4.5)
		LandmarkFhParts.pierce(lm, "Stone", "Windows", a, b, o, 2.4, NM_EAVE - 2.9, cols, 3, Vector2(1.7, 3.6),
			1.4, 6.3, 0.35)
		LandmarkFhParts.strips(lm, "Dressing", a, b, o, 2.4, NM_EAVE - 3.0, cols + 1, 0.6, 0.55)
	# Cornice along both long fronts.
	for s in [-1.0, 1.0]:
		var z: float = NM_Z1 if s > 0.0 else NM_Z0
		LandmarkDetail.cornice(lm, "Dressing", Vector3(NM_X0 - 0.4, NM_EAVE - 0.9, z), Vector3(NM_X1 + 0.4, NM_EAVE - 0.9, z),
			Vector3(0, 0, s), 0.9, true)
	_nm_roof(lm, cx, cz, lx, dz)
	_nm_ends(lm, cz)
	_nm_front(lm)
	_nm_apse(lm)
	_nm_tower(lm, Vector3(-0.2, 0, 0.5))
	lm.commit(model)

## The steep slate roof: crow-stepped end gables, wall dormers with their
## own little roofs on both long sides, small dormers and the glazed roof
## lights (two long bands along the ridge) over the great hall, a copper
## ridge roll.
static func _nm_roof(lm: LandmarkMesh, cx: float, cz: float, lx: float, dz: float) -> void:
	var rise := NM_RIDGE - NM_EAVE
	LandmarkFhUtil.ridge_x(lm, "Slate", "Stone", Vector3(cx, NM_EAVE, cz), lx, dz, rise, 0.5)
	lm.box("Copper", Vector3(cx, NM_RIDGE + 0.15, cz), Vector3(lx + 0.4, 0.4, 0.5))
	for s in [-1.0, 1.0]:
		var x: float = NM_X1 + 0.2 if s > 0.0 else NM_X0 - 0.2
		LandmarkFhParts.crow_gable(lm, "Dressing", "Copper", Vector3(x, 0, cz), Vector3(s, 0, 0), dz, NM_EAVE,
			rise + 0.6, 7, 1.0)
	var half := dz * 0.5 + 0.5
	for s in [-1.0, 1.0]:
		var face: float = NM_Z1 if s > 0.0 else NM_Z0
		var o := Vector3(0, 0, s)
		# Wall dormers: stepped gables rising from the eave, a window each.
		for x in [-42.0, -21.0, 21.0, 42.0]:
			var c := Vector3(float(x), 0, face)
			LandmarkFhParts.crow_gable(lm, "Dressing", "Copper", c, o, 8.0, NM_EAVE, 9.0, 4, 1.2)
			lm.gable("Slate", Vector3(float(x), NM_EAVE, face - s * 3.4), 8.0, 6.8, 8.0, Basis(), 0.3)
			LandmarkDetail.window(lm, "Dressing", "Windows", Vector3(float(x), NM_EAVE + 4.3, face + s * 0.6), o,
				2.2, 3.8, true, 0.25)
		# Small slate dormers on the lower slope.
		for k in 12:
			var x := NM_X0 + 6.0 + (lx - 12.0) * float(k) / 11.0
			if absf(x - 0.0) < 9.0 or absf(absf(x) - 21.0) < 6.0 or absf(absf(x) - 42.0) < 6.0:
				continue
			var t := 0.3
			var dc := Vector3(x, NM_EAVE + rise * t, cz + s * half * (1.0 - t))
			var fb := Basis(Vector3.UP, 0.0 if s > 0.0 else PI)
			lm.box("Slate", dc + Vector3(0, 1.0, 0), Vector3(1.8, 2.0, 2.2), fb)
			lm.box("Windows", dc + fb * Vector3(0, 1.0, 1.12), Vector3(1.0, 1.2, 0.05), fb, 0.0)
			lm.gable("Copper", dc + Vector3(0, 2.0, 0), 1.9, 2.2, 0.9, fb, 0.1, "Slate")
		# Two long glazed roof lights over the great hall, either side of
		# the tower, running along the ridge on both slopes.
		for run in [[-54.0, -9.0], [9.0, 54.0]]:
			var x0: float = run[0]
			var x1: float = run[1]
			var p0 := Vector3(x0, NM_EAVE + rise * 0.5, cz + s * half * 0.5)
			var p1 := Vector3(x1, NM_EAVE + rise * 0.5, cz + s * half * 0.5)
			var q1 := Vector3(x1, NM_EAVE + rise * 0.94, cz + s * half * 0.06)
			var q0 := Vector3(x0, NM_EAVE + rise * 0.94, cz + s * half * 0.06)
			var n := Vector3(0, half, s * rise).normalized()
			lm.quad("Skylight", p0 + n * 0.08, p1 + n * 0.08, q1 + n * 0.08, q0 + n * 0.08, n)
			var nb := int((x1 - x0) / 2.5)
			for k in nb + 1:
				var bx := lerpf(x0, x1, float(k) / float(nb))
				lm.beam("Copper", Vector3(bx, p0.y, p0.z) + n * 0.12, Vector3(bx, q0.y, q0.z) + n * 0.12, 0.12, 0.1)

## The ends: short wings between the corner turrets, the octagonal
## turrets with copper caps, and the low hipped end pavilions.
static func _nm_ends(lm: LandmarkMesh, cz: float) -> void:
	for s in [-1.0, 1.0]:
		var wx: float = (NM_X1 + 3.0) if s > 0.0 else (NM_X0 - 3.0)
		LandmarkFhUtil.blk(lm, "Stone", wx, 0.0, cz, 6.4, NM_EAVE, 21.0)
		LandmarkFhUtil.blk(lm, "Granite", wx, 0.0, cz, 7.0, 2.4, 21.6)
		LandmarkFhUtil.ridge_z(lm, "Slate", "Stone", Vector3(wx, NM_EAVE, cz), 6.4, 21.0, 4.0, 0.3)
		# End pavilion.
		var px: float = (NM_X1 + 12.2) if s > 0.0 else (NM_X0 - 12.2)
		LandmarkFhUtil.blk(lm, "Stone", px, 0.0, cz, 12.0, 14.0, 16.8)
		LandmarkFhUtil.blk(lm, "Granite", px, 0.0, cz, 12.6, 2.4, 17.4)
		LandmarkFhParts.box_band(lm, "Dressing", px, cz, 12.0, 16.8, 7.6, 0.4, 0.3)
		LandmarkFhUtil.hip(lm, "Slate", Vector3(px, 14.0, cz), 12.8, 17.6, 10.0, 0.25)
		var ex: float = px + s * 6.0
		LandmarkFhParts.pierce(lm, "Stone", "Windows", Vector3(ex, 0, cz - 8.4 * s), Vector3(ex, 0, cz + 8.4 * s),
			Vector3(s, 0, 0), 2.4, 11.4, 4, 2, Vector2(1.6, 3.2), 1.2, 5.4, 0.3)
		for side in [-1.0, 1.0]:
			var fz: float = cz + float(side) * 8.4
			LandmarkFhParts.win_row(lm, "Dressing", "Windows", Vector3(px - 5.0, 0, fz), Vector3(px + 5.0, 0, fz),
				Vector3(0, 0, side), 3.6, 3, 1.5, 3.0)
			LandmarkFhParts.win_row(lm, "Dressing", "Windows", Vector3(px - 5.0, 0, fz), Vector3(px + 5.0, 0, fz),
				Vector3(0, 0, side), 9.0, 3, 1.5, 3.0)
		# Corner turrets.
		for zc in [-15.0, 16.0]:
			var tc := Vector3(s * 62.6, 0, float(zc))
			lm.frustum("Stone", tc, 4.3, 4.3, 25.0, 8, PI / 8.0)
			lm.frustum("Granite", tc, 4.6, 4.6, 2.4, 8, PI / 8.0)
			lm.frustum("Dressing", tc + Vector3(0, 24.4, 0), 4.6, 4.8, 0.8, 8, PI / 8.0)
			for k in 8:
				var a := PI * 0.25 * float(k + 1)
				var d := Vector3(cos(a), 0, sin(a))
				for y in [12.0, 18.0]:
					lm.box("Windows", tc + d * 4.0 + Vector3(0, float(y), 0), Vector3(0.8, 2.6, 0.05),
						Basis(Vector3.UP, -a + PI * 0.5), 0.0)
			lm.lathe("Copper", tc + Vector3(0, 25.2, 0), PackedVector2Array([Vector2(4.9, 0), Vector2(4.2, 1.6),
				Vector2(2.6, 4.2), Vector2(0.9, 6.6), Vector2(0.0, 8.0)]), 8, 1.0, 1.0, PI / 8.0, false)
			lm.frustum("Gilt", tc + Vector3(0, 32.8, 0), 0.12, 0.03, 1.2, 6)

## The front toward Djurgårdsvägen: the projecting centre with its tall
## stepped gable and the temple-like main gate (columns and pediment, an
## arched window over it), flanked by two square towers with copper
## spires, and the granite steps.
static func _nm_front(lm: LandmarkMesh) -> void:
	var zf := 24.0
	var gw := 10.9
	var gx := -0.25
	LandmarkFhUtil.blk(lm, "Stone", gx, 0.0, (NM_Z1 + zf) * 0.5, gw, NM_EAVE, zf - NM_Z1)
	LandmarkFhUtil.blk(lm, "Granite", gx, 0.0, (NM_Z1 + zf) * 0.5, gw + 0.6, 2.4, zf - NM_Z1 + 0.6)
	LandmarkFhParts.crow_gable(lm, "Dressing", "Copper", Vector3(gx, 0, zf), Vector3(0, 0, 1), gw, NM_EAVE, 12.0, 5, 1.0)
	lm.gable("Slate", Vector3(gx, NM_EAVE, (NM_Z1 + zf) * 0.5 - 0.5), gw, zf - NM_Z1 + 1.0, 11.0, Basis(), 0.2)
	LandmarkFhParts.band(lm, "Dressing", Vector3(gx - gw * 0.5, 0, zf), Vector3(gx + gw * 0.5, 0, zf), Vector3(0, 0, 1),
		NM_EAVE - 1.0, 1.0, 0.5)
	LandmarkDetail.window(lm, "Dressing", "Windows", Vector3(gx, 15.6, zf + 0.02), Vector3(0, 0, 1), 3.4, 7.6, true, 0.3)
	LandmarkDetail.window(lm, "Dressing", "Windows", Vector3(gx, NM_EAVE + 5.0, zf + 0.02), Vector3(0, 0, 1), 2.0, 3.6,
		true, 0.25)
	# Main gate: four columns, entablature and pediment, the doors.
	var dz := zf + 1.0
	for x in [-4.0, -2.5, 2.0, 3.5]:
		LandmarkDetail.column(lm, "Dressing", Vector3(gx + float(x), 2.4, dz), 0.42, 6.6, "ionic", 0, 12)
	lm.box("Dressing", Vector3(gx, 9.5, dz - 0.2), Vector3(9.4, 1.0, 1.8))
	lm.gable("Dressing", Vector3(gx, 10.0, dz - 0.2), 9.4, 1.8, 2.6, Basis(), 0.25, "Dressing")
	lm.box("Gilt", Vector3(gx, 10.9, dz + 0.72), Vector3(2.4, 1.0, 0.1), Basis(), 0.0)
	lm.box("Windows", Vector3(gx, 5.6, zf + 0.05), Vector3(3.2, 6.4, 0.1), Basis(), 0.0)
	LandmarkDetail.arch(lm, "Dressing", Vector3(gx, 7.2, zf + 0.05), Vector3(0, 0, 1), 3.2, 0.45, 0.35)
	LandmarkFhUtil.steps(lm, "Granite", Vector3(gx, 0, zf + 2.2), Vector3(0, 0, 1), 13.0, 0.45, 0.48, 5)
	lm.box("Granite", Vector3(gx, 1.2, zf + 1.1), Vector3(13.0, 2.4, 2.2))
	# The two front towers and their spires.
	for x in [-9.8, 8.8]:
		var tc := Vector3(float(x), 0, 21.55)
		LandmarkFhUtil.blk(lm, "Stone", tc.x, 0.0, tc.z, 7.8, 30.0, 8.1)
		LandmarkFhUtil.blk(lm, "Granite", tc.x, 0.0, tc.z, 8.4, 2.4, 8.7)
		for y in [9.0, 15.5, NM_EAVE - 0.5, 29.4]:
			LandmarkFhParts.box_band(lm, "Dressing", tc.x, tc.z, 7.8, 8.1, float(y), 0.5, 0.3)
		for side in [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
			var o: Vector3 = side
			var fc := tc + Vector3(o.x * 3.9, 0, o.z * 4.05)
			for y in [4.2, 11.0]:
				LandmarkDetail.window(lm, "Dressing", "Windows", fc + Vector3(0, float(y) + 1.6, 0), o, 1.3, 3.2, false, 0.2)
			LandmarkDetail.window(lm, "Dressing", "Windows", fc + Vector3(0, 25.6, 0), o, 1.6, 4.4, true, 0.25)
		LandmarkFhUtil.hip(lm, "Copper", tc + Vector3(0, 30.0, 0), 8.4, 8.6, 1.6, 0.62)
		lm.spire("Copper", tc + Vector3(0, 31.6, 0), 2.7, 11.4)
		lm.frustum("Gilt", tc + Vector3(0, 42.8, 0), 0.1, 0.02, 1.2, 6)
		lm.lathe("Gilt", tc + Vector3(0, 41.6, 0), LandmarkFhUtil.ball(0.3), 8)

## The polygonal apse at the back of the hall, its tall windows and roof.
static func _nm_apse(lm: LandmarkMesh) -> void:
	var poly := PackedVector2Array([Vector2(12.5, -15.0), Vector2(9.9, -20.3), Vector2(6.4, -23.8),
		Vector2(2.4, -25.5), Vector2(-2.5, -25.5), Vector2(-6.4, -24.0), Vector2(-9.8, -20.6),
		Vector2(-13.1, -15.0)])
	lm.poly_prism("Stone", poly, 0.0, NM_EAVE)
	var plinth := PackedVector2Array()
	var cen := Vector2(-0.3, -15.0)
	for p in poly:
		plinth.append(cen + (p - cen) * 1.04)
	lm.poly_prism("Granite", plinth, 0.0, 2.4)
	LandmarkFhParts.slope_roof(lm, "Slate", poly, cen, 0.12, NM_EAVE, NM_RIDGE - 2.0)
	for i in poly.size() - 1:
		var a := Vector3(poly[i].x, 0, poly[i].y)
		var b := Vector3(poly[i + 1].x, 0, poly[i + 1].y)
		var o := LandmarkFhParts.edge_out(poly, i)
		if o.z > 0.5:
			continue
		LandmarkFhParts.win_row(lm, "Dressing", "Windows", a, b, o, 4.0, 1, 1.5, 3.2)
		LandmarkFhParts.win_row(lm, "Dressing", "Windows", a, b, o, 10.6, 1, 1.8, 8.6, true)

## Central tower over the crossing: octagonal stone stage with string
## courses and arched belfry windows, corner pinnacles, the copper helm,
## an open lantern, the onion and the gilded spire to NM_TOP.
static func _nm_tower(lm: LandmarkMesh, t: Vector3) -> void:
	var r := 6.0
	var ap := r * cos(PI / 8.0)
	lm.frustum("Stone", t + Vector3(0, NM_EAVE, 0), r, r, 28.0, 8, PI / 8.0)
	for y in [NM_RIDGE + 0.4, 43.4]:
		lm.frustum("Dressing", t + Vector3(0, float(y), 0), r + 0.3, r + 0.3, 0.5, 8, PI / 8.0)
	for k in 8:
		var a := PI * 0.25 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Dressing", "Windows", t + d * (ap + 0.02) + Vector3(0, 46.6, 0), d, 1.6, 4.6, true, 0.3)
		LandmarkDetail.window(lm, "Dressing", "Windows", t + d * (ap + 0.02) + Vector3(0, 41.4, 0), d, 1.0, 1.6, false, 0.2)
	lm.frustum("Dressing", t + Vector3(0, 50.0, 0), r + 0.4, r + 0.6, 0.8, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * float(k)
		var p := t + Vector3(cos(a), 0, sin(a)) * (r + 0.2) + Vector3(0, 50.8, 0)
		lm.frustum("Dressing", p, 0.4, 0.4, 1.0, 6)
		lm.frustum("Copper", p + Vector3(0, 1.0, 0), 0.42, 0.0, 2.4, 6)
	# Copper helm: a bell swelling out and drawn in to the lantern's neck.
	var hy := 50.8
	lm.lathe("Copper", t + Vector3(0, hy, 0), PackedVector2Array([Vector2(5.9, 0), Vector2(6.1, 1.2),
		Vector2(5.6, 3.0), Vector2(4.2, 5.0), Vector2(2.6, 6.6), Vector2(2.0, 8.0), Vector2(2.0, 8.6)]),
		8, 1.0, 1.0, PI / 8.0, false)
	var helm := PackedVector2Array([Vector2(6.1, 1.2), Vector2(5.6, 3.0), Vector2(4.2, 5.0), Vector2(2.6, 6.6),
		Vector2(2.0, 8.0)])
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		for j in helm.size() - 1:
			lm.beam("Gilt", t + d * (helm[j].x + 0.05) + Vector3(0, hy + helm[j].y, 0),
				t + d * (helm[j + 1].x + 0.05) + Vector3(0, hy + helm[j + 1].y, 0), 0.22, 0.12)
	# Open lantern: posts round a glazed octagon, ring, onion, spire.
	var ly := hy + 8.6
	lm.frustum("Windows", t + Vector3(0, ly, 0), 1.6, 1.6, 5.0, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + PI * 0.25 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Copper", t + d * 1.95 + Vector3(0, ly, 0), t + d * 1.95 + Vector3(0, ly + 5.0, 0), 0.35, 0.35)
	lm.frustum("Copper", t + Vector3(0, ly + 5.0, 0), 2.4, 2.2, 0.5, 8, PI / 8.0)
	LandmarkFhParts.onion(lm, "Copper", t + Vector3(0, ly + 5.5, 0), 1.9, 4.2, 8, 12)
	var sy := ly + 9.7
	lm.lathe("Gilt", t + Vector3(0, sy, 0), LandmarkFhUtil.ball(0.5), 10)
	lm.frustum("Gilt", t + Vector3(0, sy + 0.9, 0), 0.34, 0.05, NM_TOP - sy - 1.7, 8)
	lm.lathe("Gilt", t + Vector3(0, NM_TOP - 4.6, 0), LandmarkFhUtil.ball(0.32), 8)
	lm.frustum("Gilt", t + Vector3(0, NM_TOP - 0.8, 0), 0.06, 0.0, 0.8, 4)

## Riksdag Building: built in LandmarkSsCivic2 (the Public Library is
## StoHeroLibrary and the Concert Hall StoHeroConcert, in hero/).
static func riksdag(model: Node3D) -> void:
	LandmarkSsCivic2.riksdag(model)

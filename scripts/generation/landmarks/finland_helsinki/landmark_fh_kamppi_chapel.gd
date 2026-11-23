extends RefCounted

## Kamppi Chapel of Silence (K2S Architects, 2012), Narinkkatori.
## Built on its mapped 19.8 x 13.1 m ellipse (OSM way 185401488, yaw -5.6):
## oiled warm spruce-slat vessel flaring to a sculpted tilted rim (10.2 m at
## the rear sweeping up to 12.1 m at the prow), grey roof cap, low grey
## concrete entrance lobby wing with glazed doorway, and upward base floodlights.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "kamppi_chapel", "name": "Kamppi Chapel", "lat": 60.16945, "lon": 24.93592,
	"radius_m": 1500.0, "wiki_title": "Kamppi Chapel", "height_m": 12.1, "clear_m": 18.0,
	"yaw_deg": -5.6, "kind": "Chapel", "aliases": ["kamppi chapel", "kampin kappeli", "kampens kapell"]}

const H_REAR := 10.2
const H_PROW := 12.1
const SX := 9.9
const SZ := 6.55

static func _rim_y(a: float) -> float:
	var prow_t := 0.5 + 0.5 * cos(a)
	return lerpf(H_REAR, H_PROW, prow_t)

static func _kamppi_radius(t: float) -> float:
	return 0.80 + 0.20 * pow(clampf(t, 0.0, 1.0), 1.6)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("concrete", "#8B8D8B", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#3B4E56"))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#B87338", 1.8))
	lm.use("Seam", LandmarkMaterials.pbr("wood", "#7C4820", 1.8))
	lm.use("Roof", LandmarkMaterials.paint("#626668", 0.72))
	lm.use("Door", LandmarkMaterials.paint("#2A2D30", 0.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE0A6", 0.5))
	_timber_vessel(lm)
	_entrance_lobby(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.84, 0.58)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(13.5, 0.6, 0.0), Vector3(8.5, 8.0, 0.0), 48.0, 1.0, 26.0, warm],
		[Vector3(0.0, 0.6, 10.0), Vector3(0.0, 8.0, 5.5), 50.0, 0.9, 24.0, warm],
		[Vector3(0.0, 0.6, -10.0), Vector3(0.0, 8.0, -5.5), 50.0, 0.9, 24.0, warm],
		[Vector3(-13.0, 0.6, 0.0), Vector3(-8.5, 7.5, 0.0), 48.0, 0.9, 24.0, warm],
	])

static func _timber_vessel(lm: LandmarkMesh) -> void:
	var seg_v := 14
	var seg_a := 96
	var rows: Array = []
	for j in seg_v + 1:
		var v := float(j) / float(seg_v)
		var r := _kamppi_radius(v)
		var ring := PackedVector3Array()
		for k in seg_a + 1:
			var a := TAU * float(k) / float(seg_a)
			ring.append(Vector3(cos(a) * SX * r, _rim_y(a) * v, sin(a) * SZ * r))
		rows.append(ring)
	lm.grid("Wood", rows, Vector3(0, 5.0, 0), true)
	# Thickened top timber rim and tilted grey roof cap nested inside.
	var outer_top: PackedVector3Array = rows[seg_v]
	var inner_top := PackedVector3Array()
	var roof_ring := PackedVector3Array()
	for k in seg_a + 1:
		var p := outer_top[k]
		inner_top.append(Vector3(p.x * 0.96, p.y, p.z * 0.96))
		roof_ring.append(Vector3(p.x * 0.96, p.y - 0.14, p.z * 0.96))
	lm.grid("Wood", [outer_top, inner_top], Vector3.UP)
	lm.grid("Wood", [inner_top, roof_ring], Vector3.ZERO, true)
	var roof_center := Vector3(0.0, (H_REAR + H_PROW) * 0.5 - 0.14, 0.0)
	for k in seg_a:
		lm.tri("Roof", roof_center, roof_ring[k + 1], roof_ring[k],
			Vector3.UP, Vector3.UP, Vector3.UP,
			Vector2.ZERO, Vector2(roof_ring[k + 1].x, roof_ring[k + 1].z),
			Vector2(roof_ring[k].x, roof_ring[k].z))
	# Horizontal spruce plank seams wrapping the flared hull.
	for i in int(H_PROW / 0.25):
		var y := 0.25 + float(i) * 0.25
		for k in seg_a:
			var a0 := TAU * float(k) / float(seg_a)
			var a1 := TAU * float(k + 1) / float(seg_a)
			var rm0 := _rim_y(a0)
			var rm1 := _rim_y(a1)
			if y > rm0 - 0.18 or y > rm1 - 0.18:
				continue
			var r0 := _kamppi_radius(y / rm0) + 0.002
			var r1 := _kamppi_radius(y / rm1) + 0.002
			var p0 := Vector3(cos(a0) * SX * r0, y, sin(a0) * SZ * r0)
			var p1 := Vector3(cos(a1) * SX * r1, y, sin(a1) * SZ * r1)
			var n := Vector3(cos((a0 + a1) * 0.5) / SX, 0, sin((a0 + a1) * 0.5) / SZ).normalized()
			lm.quad("Seam", p0, p1, p1 + Vector3(0, 0.018, 0), p0 + Vector3(0, 0.018, 0), n)

## Low grey concrete entrance lobby wing on the Narinkkatori (+X) prow side.
static func _entrance_lobby(lm: LandmarkMesh) -> void:
	U.blk(lm, "Stone", 9.6, 0.0, 0.0, 4.2, 3.5, 7.4)
	U.blk(lm, "Roof", 9.6, 3.5, 0.0, 4.4, 0.2, 7.6)
	# Recessed glazed doorway and warm interior lobby glow.
	U.blk(lm, "Door", 11.72, 0.0, 0.0, 0.12, 3.0, 3.8)
	U.blk(lm, "Glass", 11.79, 0.12, 0.0, 0.06, 2.75, 3.4)
	U.blk(lm, "Lamp", 11.74, 0.25, 0.0, 0.04, 2.4, 2.8)
	for sz in [-2.6, 2.6]:
		U.blk(lm, "Door", 11.72, 0.4, sz, 0.1, 2.2, 1.0)
		U.blk(lm, "Glass", 11.78, 0.45, sz, 0.05, 2.1, 0.85)
	U.blk(lm, "Stone", 12.2, 0.0, 0.0, 1.4, 0.12, 4.8)

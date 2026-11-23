class_name StupaBuilder
extends RefCounted

## A mapped Buddhist chedi / stupa / prang (`OsmTags.is_stupa`: `man_made=stupa`
## or `building=stupa`) drawn as a true bell chedi or stepped Khmer prang sized
## from its mapped OSM outline (BK-3.5): never a windowed building box, costs
## no landmark slot, and skips sites cleared by bespoke landmarks via
## `BuildingBuilder._accepted`.

const MIN_RADIUS_M := 1.4
const MAX_RADIUS_M := 13.5
const SEGMENTS := 16
const FAR_SEGMENTS := 8

static func accepts(b: Dictionary) -> bool:
	return bool(b.get("stupa", false))

## {centre: Vector2, r_m: float, h_m: float, gold: bool, prang: bool}
static func shape(b: Dictionary) -> Dictionary:
	var m := WorldScale.metres_to_units()
	var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
	var centre := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
	var area_u2 := absf(RingGeometry.signed_area(ring)) if ring.size() >= 3 \
		else float(b.get("size_x", 6.0)) * float(b.get("size_z", 6.0))
	var r_m := clampf(sqrt(area_u2 / PI) / m, MIN_RADIUS_M, MAX_RADIUS_M)
	var src := str(b.get("height_source", ""))
	var h_m := float(b.get("height", 0.0)) if src in ["tag_height", "levels", "reference"] \
		else clampf(r_m * 3.35, 6.8, 38.0)
	h_m = maxf(h_m, r_m * 2.1)
	var col := str(b.get("colour", "")).strip_edges().to_lower()
	var nm := str(b.get("name", "")).to_lower()
	var seed_v := fposmod(sin((centre.x * 12.9898 + centre.y * 78.233) / m) * 43758.5453, 1.0)
	var is_gold := col in ["gold", "golden", "yellow", "#ffd700", "#d4af37"] \
		or (col == "" and seed_v < 0.36)
	var is_prang := nm.contains("prang") or nm.contains("ปรางค์") or (col == "" and seed_v > 0.86)
	return {"centre": centre, "r_m": r_m, "h_m": h_m, "gold": is_gold, "prang": is_prang}

static func mesh(b: Dictionary, foot_y_u: float, segments: int = SEGMENTS) -> LandmarkMesh:
	var s := shape(b)
	var m := WorldScale.metres_to_units()
	var c: Vector2 = s["centre"]
	var r := float(s["r_m"]) * m
	var h := float(s["h_m"]) * m
	var is_gold := bool(s["gold"])
	var is_prang := bool(s["prang"])

	var lm := LandmarkMesh.new()
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#F4EFE2", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	var body := "Gold" if is_gold else "Stucco"
	var base := Vector3(c.x, foot_y_u, c.y)

	# Octagonal/square stepped plinth
	lm.frustum(body, base, r * 1.12, r * 1.04, h * 0.14, 8, PI / 8.0)
	lm.frustum(body, base + Vector3(0, h * 0.14, 0), r * 0.96, r * 0.86, h * 0.10, 8, PI / 8.0)

	if is_prang:
		# Stepped Ayutthaya/Rattanakosin corncob prang + golden nophasun trident finial
		var prof := PackedVector2Array([
			Vector2(r * 0.78, h * 0.24), Vector2(r * 0.72, h * 0.42),
			Vector2(r * 0.66, h * 0.56), Vector2(r * 0.54, h * 0.70),
			Vector2(r * 0.36, h * 0.81), Vector2(r * 0.16, h * 0.89),
			Vector2(0.0, h * 0.92),
		])
		lm.lathe(body, base, prof, mini(segments, 12), 1.0, 1.0, PI / 8.0, false)
		lm.frustum("Gold", base + Vector3(0, h * 0.89, 0), r * 0.08, 0.0, h * 0.11, 6)
	else:
		# Classic Thai bell chedi: lotus rings -> flared bell -> harmika -> ringed spire -> gold tip
		var bell := PackedVector2Array([
			Vector2(r * 0.82, h * 0.24), Vector2(r * 0.72, h * 0.30),
			Vector2(r * 0.68, h * 0.35), Vector2(r * 0.62, h * 0.46),
			Vector2(r * 0.46, h * 0.56), Vector2(r * 0.28, h * 0.62),
			Vector2(r * 0.31, h * 0.66), Vector2(r * 0.24, h * 0.70),
			Vector2(r * 0.17, h * 0.78), Vector2(r * 0.10, h * 0.86),
		])
		lm.lathe(body, base, bell, segments)
		lm.lathe("Gold", base, PackedVector2Array([
			Vector2(r * 0.10, h * 0.86), Vector2(r * 0.05, h * 0.94), Vector2(0.0, h)]), 10)
	return lm

static func build(root: Node3D, b: Dictionary, ground: GroundTruth, sea_y: float = -INF) -> bool:
	if not accepts(b):
		return false
	var s := shape(b)
	var m := WorldScale.metres_to_units()
	var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
	if ring.size() < 3:
		var r_u: float = float(s["r_m"]) * m
		ring = BuildingWalls._rect_ring(s["centre"], Vector2(r_u, r_u) * 2.0, 0.0)
	var footing := BuildingFoundation.sample(ground, ring, s["centre"], sea_y)
	var foot := float(footing["low"]) - BuildingFoundation.SINK_M * m
	for part in mesh(b, foot).commit(root, "Stupa_"):
		part.set_meta("mapped_stupa", true)
		part.set_meta("osm_id", str(b.get("osm_id", "")))
	return true

static func append_far(batch: MassBatch, key: String, b: Dictionary, base_y: float) -> void:
	mesh(b, base_y, FAR_SEGMENTS).append_to_batch(batch, key)

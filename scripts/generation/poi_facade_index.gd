class_name PoiFacadeIndex
extends RefCounted

## Spatial lookup for mapped businesses at a facade edge. Per-build and
## immutable after construction, so the building worker owns all state.
const CELL_M := 32.0
const REACH_M := 3.0
const AMENITIES := ["restaurant", "cafe", "bar", "pub", "fast_food", "bakery",
	"pharmacy", "bank", "clinic", "dentist", "post_office", "veterinary"]
const COLOURS := ["#2e3b34", "#703932", "#334d69", "#6a5736", "#494248", "#53604e"]

var _cells := {}

func _init(pois: Array = []) -> void:
	for raw in pois:
		if not (raw is Dictionary):
			continue
		var poi: Dictionary = raw
		if not poi.has("x") or not poi.has("z") \
				or not is_finite(float(poi["x"])) or not is_finite(float(poi["z"])):
			continue
		var category := str(poi.get("category", ""))
		if category not in ["shop", "craft"] \
				and not (category == "amenity" and str(poi.get("kind", "")) in AMENITIES):
			continue
		var p := Vector2(float(poi.get("x", 0.0)), float(poi.get("z", 0.0)))
		var cell := Vector2i(floori(p.x / CELL_M), floori(p.y / CELL_M))
		if not _cells.has(cell):
			_cells[cell] = []
		_cells[cell].append(poi)

## Closest eligible business per edge; equal distances keep source order.
func for_ring(ring: PackedVector2Array) -> Dictionary:
	var out := {}
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var ab := b - a
		var len2 := ab.length_squared()
		if len2 < 0.0001:
			continue
		var lo := Vector2i(floori((minf(a.x, b.x) - REACH_M) / CELL_M),
			floori((minf(a.y, b.y) - REACH_M) / CELL_M))
		var hi := Vector2i(floori((maxf(a.x, b.x) + REACH_M) / CELL_M),
			floori((maxf(a.y, b.y) + REACH_M) / CELL_M))
		var best := REACH_M * REACH_M
		for x in range(lo.x, hi.x + 1):
			for z in range(lo.y, hi.y + 1):
				for poi in _cells.get(Vector2i(x, z), []):
					var p := Vector2(float(poi.get("x", 0.0)), float(poi.get("z", 0.0)))
					var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0)
					var distance := p.distance_squared_to(a + ab * t)
					if distance <= REACH_M * REACH_M and (not out.has(i) or distance < best):
						best = distance
						out[i] = poi
	return out

## A small shared palette bounds the number of ground-floor materials.
static func colour(poi: Dictionary) -> Color:
	var key := str(poi.get("brand", ""))
	if key.is_empty():
		key = str(poi.get("name", ""))
	if key.is_empty():
		key = str(poi.get("kind", ""))
	return ArchitectureStyle._lin(COLOURS[posmod(hash(key), COLOURS.size())])

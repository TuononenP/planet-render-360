class_name OmtToOverpass
extends RefCounted

## The terrain-shaping part of a detailed OSM layer, rebuilt from z14
## OpenMapTiles vector tiles (OpenFreeMap, the same tiles the map shows):
## water (the sea included), waterways, building footprints with their
## heights, roads, railways, plazas and land cover. It is the map tier
## for when Overpass does not answer, so the ground still gets its water
## carving, sea datum, roof stripping and road grading (GroundTruth)
## instead of bare elevation.
##
## convert() writes Overpass-shaped JSON (ways with inline geometry,
## multipolygon relations with member geometry), so OsmParser and
## everything after it run unchanged. Street furniture, tree nodes,
## barriers, building parts, roof shapes, lanes and widths are not in
## the tiles; those views are plainer, not wrong.
##
## Tiles clip their features with a buffer, so every piece is cut back to
## its own tile here. Water pieces get a hair of overlap and are joined
## across tiles into whole bodies: a lake cut along a tile edge would
## otherwise get one bank level per piece. Pure data; runs on a worker.

const ZOOM := 14
## Local frame units per tile: tile extents are rescaled to this.
const EXTENT := 4096.0
## Header generator, so callers and the log can tell this tier apart.
const GENERATOR := "pr360-omt"
## Overlap given to water pieces (frame units, ~1 m at z14) so neighbours
## join into one body.
const SEAM := 2.0
## OpenMapTiles fills render_height with 5 m when OSM has no height; that
## default is left out, so building heights fall back to the app's own.
const DEFAULT_RENDER_HEIGHT := 5.0

## Layer -> tag keys MvtReader keeps.
const LAYERS := {
	"water": ["class", "brunnel"],
	"waterway": ["class", "brunnel"],
	"building": ["render_height", "render_min_height", "hide_3d", "colour"],
	"transportation": ["class", "subclass", "brunnel", "ramp", "layer", "surface"],
	"landcover": ["class", "subclass"],
	"landuse": ["class"],
}

## OpenMapTiles water class -> OSM water=*. Pools are not carved ground.
const WATER := {"ocean": "sea", "lake": "lake", "river": "river", "pond": "pond", "dock": "dock"}
const ROADS := {"motorway": "motorway", "trunk": "trunk", "primary": "primary",
	"secondary": "secondary", "tertiary": "tertiary", "minor": "residential",
	"service": "service", "track": "track", "busway": "busway", "pedestrian": "pedestrian"}
const RAMPS := ["motorway", "trunk", "primary", "secondary", "tertiary"]
const PATHS := ["footway", "path", "cycleway", "steps", "bridleway", "pedestrian"]
const LANDUSE := ["residential", "commercial", "industrial", "retail", "cemetery", "quarry"]

## The z14 tiles covering +-radius_m around the centre.
static func tiles_for(lat: float, lon: float, radius_m: float) -> Array[Vector2i]:
	return FarFieldFetcher.window_tiles(FarFieldFetcher.window_px(lat, lon, ZOOM, radius_m))

## Overpass-shaped JSON from `bodies` (Vector2i tile -> MVT bytes, gzip or
## not; an empty body is a tile of open sea). Tiles missing from `bodies`
## are left out. "" when nothing was mapped.
static func convert(tiles: Array[Vector2i], bodies: Dictionary) -> String:
	if tiles.is_empty():
		return ""
	var origin := tiles[0]
	for t in tiles:
		origin = Vector2i(mini(origin.x, t.x), mini(origin.y, t.y))
	var out := {"elements": [], "next_id": 1, "origin": origin}
	var water: Dictionary = {}  # water=* value -> {"outers": [], "holes": []}
	for t in tiles:
		if not bodies.has(t):
			continue
		var offset := Vector2(t - origin) * EXTENT
		var rect := _rect(offset, 0.0)
		var body: PackedByteArray = bodies[t]
		if body.is_empty():
			_water_bin(water, "sea")["outers"].append(_rect(offset, SEAM))
			continue
		var layers := MvtReader.read(VectorTileFetcher.inflate(body), LAYERS)
		for name in layers:
			var layer: Dictionary = layers[name]
			var k := EXTENT / float(layer.get("extent", 4096))
			for f: Dictionary in layer["features"]:
				_feature(out, water, str(name), f, k, offset, rect)
	for value in water:
		var bin: Dictionary = water[value]
		var tags := {"natural": "water", "water": value}
		var outers := _union(bin["outers"])
		var holes := _union(bin["holes"])
		for outer: PackedVector2Array in outers:
			var inner: Array = []
			for h: PackedVector2Array in holes:
				if Geometry2D.is_point_in_polygon(h[0], outer):
					inner.append(h)
			_area(out, tags, outer, inner)
	if (out["elements"] as Array).is_empty():
		return ""
	return JSON.stringify({"version": 0.6, "generator": GENERATOR,
		"osm3s": {"copyright": "© OpenMapTiles © OpenStreetMap contributors"},
		"elements": out["elements"]}, "", false, true)

static func _water_bin(water: Dictionary, value: String) -> Dictionary:
	if not water.has(value):
		water[value] = {"outers": [], "holes": []}
	return water[value]

static func _rect(offset: Vector2, grow: float) -> PackedVector2Array:
	var a := offset - Vector2(grow, grow)
	var b := offset + Vector2(EXTENT + grow, EXTENT + grow)
	return PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)])

static func _moved(points: PackedVector2Array, k: float, offset: Vector2) -> PackedVector2Array:
	var moved := PackedVector2Array()
	moved.resize(points.size())
	for i in points.size():
		moved[i] = points[i] * k + offset
	return moved

static func _feature(out: Dictionary, water: Dictionary, layer: String, f: Dictionary,
		k: float, offset: Vector2, rect: PackedVector2Array) -> void:
	var tags: Dictionary = f.get("tags", {})
	var kind := int(f.get("type", 0))
	var cls := str(tags.get("class", ""))
	if str(tags.get("brunnel", "")) == "tunnel" and layer != "transportation":
		return  # Culverted water: nothing at the surface.
	if kind == MvtReader.POLYGON:
		if layer == "water":
			if not WATER.has(cls):
				return
			var bin := _water_bin(water, WATER[cls])
			for poly: Array in f["geom"]:
				for i in poly.size():
					var ring := _moved(poly[i], k, offset)
					for piece in Geometry2D.intersect_polygons(ring, _grown(rect)):
						if not Geometry2D.is_polygon_clockwise(piece):
							bin["holes" if i > 0 else "outers"].append(piece)
			return
		var area_tags := _area_tags(layer, cls, tags)
		if area_tags.is_empty():
			return
		for poly: Array in f["geom"]:
			var rings: Array = []
			for ring in poly:
				rings.append(_moved(ring, k, offset))
			for piece in _clip_area(rings, rect):
				_area(out, area_tags, piece["outer"], piece["holes"])
	elif kind == MvtReader.LINE:
		var line_tags := _line_tags(layer, cls, tags)
		if line_tags.is_empty():
			return
		var tile := Rect2(rect[0], rect[2] - rect[0])
		for line: PackedVector2Array in f["geom"]:
			var moved := _moved(line, k, offset)
			# Clipper drops an open path that lies wholly inside the clip
			# polygon, so only lines reaching into the buffer are clipped.
			if tile.encloses(_box(moved)):
				_way(out, line_tags, moved)
				continue
			for piece in Geometry2D.clip_polyline_with_polygon(moved, rect):
				if piece.size() >= 2:
					_way(out, line_tags, piece)

static func _grown(rect: PackedVector2Array) -> PackedVector2Array:
	var g := Vector2(SEAM, SEAM)
	return PackedVector2Array([rect[0] - g, Vector2(rect[1].x + SEAM, rect[1].y - SEAM),
		rect[2] + g, Vector2(rect[3].x - SEAM, rect[3].y + SEAM)])

## OSM tags for an area feature, {} to skip it.
static func _area_tags(layer: String, cls: String, tags: Dictionary) -> Dictionary:
	match layer:
		"building":
			if tags.get("hide_3d", false) in [true, 1, "true"]:
				return {}  # Its building:part pieces are drawn instead.
			var out := {"building": "yes"}
			var h := float(tags.get("render_height", 0.0))
			var mh := float(tags.get("render_min_height", 0.0))
			if h > 0.0 and not (is_equal_approx(h, DEFAULT_RENDER_HEIGHT) and mh <= 0.0):
				out["height"] = "%.1f" % h
			if mh > 0.0:
				out["min_height"] = "%.1f" % mh
			if str(tags.get("colour", "")) != "":
				out["building:colour"] = str(tags["colour"])
			return out
		"transportation":
			if cls == "pedestrian" or (cls == "path" and str(tags.get("subclass", "")) == "pedestrian"):
				return {"highway": "pedestrian", "area": "yes"}
		"landcover":
			var sub := str(tags.get("subclass", ""))
			match cls:
				"wood":
					return {"natural": "wood"}
				"grass":
					if sub in ["park", "garden"]:
						return {"leisure": sub}
					return {"landuse": "meadow" if sub == "meadow" else "grass"}
				"wetland":
					return {"natural": "wetland"}
				"sand":
					return {"natural": "beach" if sub == "beach" else "sand"}
				"rock":
					return {"natural": "bare_rock"}
				"ice":
					return {"natural": "glacier"}
				"farmland":
					return {"landuse": sub if sub in ["orchard", "vineyard"] else "farmland"}
		"landuse":
			if cls in LANDUSE:
				return {"landuse": cls}
			if cls == "pitch":
				return {"leisure": "pitch"}
	return {}

## OSM tags for a line feature, {} to skip it.
static func _line_tags(layer: String, cls: String, tags: Dictionary) -> Dictionary:
	var out := {}
	var sub := str(tags.get("subclass", ""))
	if layer == "waterway":
		if cls in ["river", "canal", "stream", "drain", "ditch"]:
			out["waterway"] = cls
		return out
	if layer != "transportation":
		return out
	if cls in ["rail", "transit"]:
		var rail := sub if sub != "" else cls
		if not rail in OsmTags.RAIL_CLASSES:
			return {}
		out["railway"] = rail
	elif cls == "path":
		if not sub in PATHS:
			return {}
		out["highway"] = sub
	elif ROADS.has(cls):
		out["highway"] = ROADS[cls] + ("_link" if cls in RAMPS and int(tags.get("ramp", 0)) == 1 else "")
	else:
		return {}
	match str(tags.get("brunnel", "")):
		"bridge":
			out["bridge"] = "yes"
			out["layer"] = str(maxi(int(tags.get("layer", 1)), 1))
		"tunnel":
			out["tunnel"] = "yes"
	if str(tags.get("surface", "")) != "":
		out["surface"] = str(tags["surface"])
	return out

## An area's rings cut back to its tile: [{outer, holes}] with each hole
## kept in the piece that holds it.
static func _clip_area(rings: Array, rect: PackedVector2Array) -> Array:
	var pieces: Array = []
	if rings.is_empty():
		return pieces
	for outer in Geometry2D.intersect_polygons(rings[0], rect):
		if not Geometry2D.is_polygon_clockwise(outer):
			pieces.append({"outer": outer, "holes": []})
	for i in range(1, rings.size()):
		for hole in Geometry2D.intersect_polygons(rings[i], rect):
			for piece: Dictionary in pieces:
				if Geometry2D.is_point_in_polygon(hole[0], piece["outer"]):
					(piece["holes"] as Array).append(hole)
					break
	return pieces

## Simple polygons joined where they overlap; holes the joins enclose
## (a ring of water round an island) come back as polygons of their own
## and are dropped, as the islands' own holes carry them.
static func _union(polys: Array) -> Array:
	var outs: Array = []
	var boxes: Array = []
	for p: PackedVector2Array in polys:
		var cur := p
		var box := _box(cur)
		var j := 0
		while j < outs.size():
			if box.grow(SEAM).intersects(boxes[j]):
				var merged := Geometry2D.merge_polygons(cur, outs[j])
				var outers: Array = []
				for m in merged:
					if not Geometry2D.is_polygon_clockwise(m):
						outers.append(m)
				if outers.size() == 1:
					cur = outers[0]
					box = _box(cur)
					outs.remove_at(j)
					boxes.remove_at(j)
					j = 0
					continue
			j += 1
		outs.append(cur)
		boxes.append(box)
	return outs

static func _box(p: PackedVector2Array) -> Rect2:
	var r := Rect2(p[0], Vector2.ZERO)
	for v in p:
		r = r.expand(v)
	return r

static func _latlon(origin: Vector2i, p: Vector2) -> Dictionary:
	var n := float(1 << ZOOM)
	var gx := float(origin.x) + p.x / EXTENT
	var gy := float(origin.y) + p.y / EXTENT
	return {"lat": rad_to_deg(atan(sinh(PI * (1.0 - 2.0 * gy / n)))), "lon": gx / n * 360.0 - 180.0}

static func _geometry(out: Dictionary, points: PackedVector2Array, close: bool) -> Array:
	var geom: Array = []
	var origin: Vector2i = out["origin"]
	for p in points:
		geom.append(_latlon(origin, p))
	if close and points.size() > 0 and points[0] != points[points.size() - 1]:
		geom.append(_latlon(origin, points[0]))
	return geom

static func _way(out: Dictionary, tags: Dictionary, points: PackedVector2Array, close: bool = false) -> void:
	var id: int = out["next_id"]
	out["next_id"] = id + 1
	(out["elements"] as Array).append({"type": "way", "id": id, "tags": tags,
		"geometry": _geometry(out, points, close)})

## A closed way, or a multipolygon relation when the area has holes.
static func _area(out: Dictionary, tags: Dictionary, outer: PackedVector2Array, holes: Array) -> void:
	if outer.size() < 3:
		return
	if holes.is_empty():
		_way(out, tags, outer, true)
		return
	var members: Array = [{"type": "way", "ref": 0, "role": "outer", "geometry": _geometry(out, outer, true)}]
	for h: PackedVector2Array in holes:
		if h.size() >= 3:
			members.append({"type": "way", "ref": 0, "role": "inner", "geometry": _geometry(out, h, true)})
	var rel_tags := tags.duplicate()
	rel_tags["type"] = "multipolygon"
	var id: int = out["next_id"]
	out["next_id"] = id + 1
	(out["elements"] as Array).append({"type": "relation", "id": id, "tags": rel_tags, "members": members})

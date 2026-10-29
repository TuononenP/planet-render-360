class_name BuildingHeights
extends RefCounted

## Height and roof-shape inference for BuildingBuilder: regional
## defaults, neighbour estimates and tagged-height resolution.
## Pure functions over building dicts and a height-context dict.
static func _legacy_region(data: LocationData) -> String:
	if data != null and ArchitectureStyle.region_for(
			data.latitude, data.longitude) == "haussmann":
		return "haussmann"
	return "urban"

## Settlement density by buildings within 400 m of the viewpoint:
## ≥120 dense, ≥25 mid, else rural (what kind_for and the storey ranges
## key off when the map does not say).
static func _density(data: LocationData) -> String:
	var r := 400.0 * WorldScale.metres_to_units()
	var n := 0
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var bd := b as Dictionary
		if Vector2(float(bd.get("x", 1e9)), float(bd.get("z", 1e9))).length() <= r:
			n += 1
	if n >= 120:
		return "dense"
	if n >= 25:
		return "mid"
	return "rural"

## Footprint area in m² (ring area when present, else the AABB keys).
static func _area_m2(b: Dictionary) -> float:
	var m2u := WorldScale.metres_to_units()
	var fp: Variant = b.get("footprint", null)
	if fp is PackedVector2Array and (fp as PackedVector2Array).size() >= 3:
		return absf(RingGeometry.signed_area(fp as PackedVector2Array)) / (m2u * m2u)
	return float(b.get("size_x", 0.0)) * float(b.get("size_z", 0.0)) / (m2u * m2u)

## One building's ArchitectureStyle look, seeded by its position.
static func _look_for(b: Dictionary, ctx: Dictionary) -> Dictionary:
	var seed_v := TerrainBuilder._hash(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
	return ArchitectureStyle.resolve(b, str(ctx["region"]), str(ctx["density"]),
		seed_v, _area_m2(b))

## Per-build context: the style region and settlement density, plus the
## tagged heights (tag/levels resolved, in a 150 m spatial hash keyed by
## building kind) that feed the neighbour estimate — a house is judged
## against nearby houses, never against a tagged tower.
static func _height_context(data: LocationData) -> Dictionary:
	var region := ArchitectureStyle.region_for(data.latitude, data.longitude)
	var density := _density(data)
	var m2u := WorldScale.metres_to_units()
	var cell := 150.0 * m2u
	var cells := {}
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var bd := b as Dictionary
		var src := str(bd.get("height_source", ""))
		if src != "tag_height" and not (src == "levels" and int(bd.get("levels", 0)) > 0):
			continue
		var kind := ArchitectureStyle.kind_for(bd, density, _area_m2(bd))
		var h := float(bd.get("height", 0.0))
		if src == "levels":
			h = float(int(bd.get("levels", 0))) \
				* float(ArchitectureStyle.profile(region, kind)["fh"])
		if h <= 0.0:
			continue
		var p := Vector3(float(bd.get("x", 0.0)), float(bd.get("z", 0.0)), h)
		var key := Vector3i(int(floor(p.x / cell)), int(floor(p.y / cell)),
			ArchitectureStyle.KINDS.find(kind))
		if not cells.has(key):
			cells[key] = []
		(cells[key] as Array).append(p)
	return {"region": region, "density": density,
		"fidelity": MaterialLibrary.fidelity_for_preset(data.quality_preset),
		"cells": cells, "cell": cell, "radius_u": 150.0 * m2u}

## T4.2 height priority (contract §2.4): `height` tag → `building:levels`
## × the kind's regional floor height → same-kind local estimate →
## the kind's regional default (a seeded storey count, never one global
## figure). `m` is the mass (part or parent), `b` the parent; parts
## without own tags inherit parent_res. Dicts without height_source
## predate v2 (fixtures) and keep their carried height verbatim. Returns
## {total_m, source}; total includes the roof (OSM `height` semantics),
## the caller splits wall/roof from the shape.
static func _resolve_total(m: Dictionary, b: Dictionary, ctx: Dictionary,
		parent_res: Dictionary, look: Dictionary) -> Dictionary:
	var src := str(m.get("height_source", b.get("height_source", "")))
	var levels := int(m.get("levels", b.get("levels", 0)))
	# A part echoes its parent's source when it carries no tags of its
	# own ("levels" with levels 0 included), so it inherits the
	# resolved parent mass instead of re-inferring at its centroid.
	if not parent_res.is_empty() \
			and src != "tag_height" and not (src == "levels" and levels > 0):
		return {"total_m": float(parent_res["total_m"]),
			"source": str(parent_res["source"])}
	if src == "tag_height":
		return {"total_m": float(m.get("height", b.get("height", 0.0))),
			"source": "tag_height"}
	if src == "levels" and levels > 0:
		return {"total_m": float(levels) * float(look["floor_h"]),
			"source": "levels"}
	if src == "":
		var h := float(m.get("height", b.get("height", 0.0)))
		if h > 0.0:
			return {"total_m": h, "source": "tag_height"}
		if levels > 0:
			return {"total_m": float(levels) * float(look["floor_h"]),
				"source": "levels"}
	return _inferred_total(float(m.get("x", b.get("x", 0.0))),
		float(m.get("z", b.get("z", 0.0))), ctx, look)

## Step 3 of the priority: the data-derived local estimate. The plan
## names a satellite/DEM-derived estimate; what is honest today is the
## same-kind neighbour median (tagged heights within 150 m, ≥3 samples,
## ±15% seeded so a street is not a row of clones), because the T2.1 DEM
## is bare-earth (~6 m/px, buildings unresolved) and the Esri mosaic's
## capture sun geometry is unknown, so shadow extrusion would be
## guesswork. With 1–2 tagged neighbours the kind's default is clamped
## within 1.95× of their median (neighbour-guard-safe by construction);
## with none the kind's regional default applies.
static func _inferred_total(x: float, z: float, ctx: Dictionary,
		look: Dictionary) -> Dictionary:
	var near := _tagged_within(ctx, x, z, str(look["kind"]))
	var reg := float(look["default_h"])
	if near.size() >= 3:
		var jitter := 0.85 + 0.3 * ArchitectureStyle._h(x * 0.37 + z * 0.91, 8)
		return {"total_m": _median(near) * jitter, "source": "estimate"}
	if near.size() >= 1:
		var med := _median(near)
		return {"total_m": clampf(reg, med / 1.95, med * 1.95),
			"source": "default"}
	return {"total_m": reg, "source": "default"}

static func _tagged_within(ctx: Dictionary, x: float, z: float, kind: String) -> Array:
	var out: Array = []
	var cell := float(ctx["cell"])
	var r := float(ctx["radius_u"])
	var cx := int(floor(x / cell))
	var cz := int(floor(z / cell))
	var k := ArchitectureStyle.KINDS.find(kind)
	var cells := ctx["cells"] as Dictionary
	for ix in range(cx - 1, cx + 2):
		for iz in range(cz - 1, cz + 2):
			var bucket: Variant = cells.get(Vector3i(ix, iz, k), [])
			if not (bucket is Array):
				continue
			for p in (bucket as Array):
				var pv: Vector3 = p
				if Vector2(pv.x - x, pv.y - z).length() <= r:
					out.append(pv.z)
	return out

static func _median(a: Array) -> float:
	if a.is_empty():
		return 0.0
	a.sort()
	var n := a.size()
	if n % 2 == 1:
		return float(a[n / 2])
	return (float(a[n / 2 - 1]) + float(a[n / 2])) * 0.5

## Canonical roof shape from the raw `roof:shape` tag. Pitched-family
## aliases map to their nearest modelled form (skillion/gambrel read
## as gabled, cone as pyramidal, round/onion as dome); anything else
## unknown reads as flat. Untagged ("") takes the regional default —
## except legacy dicts without height_source, which keep the flat cap
## their wall heights were pinned against.
static func _effective_shape(raw: String, default_roof: String, legacy: bool) -> String:
	match raw.strip_edges().to_lower():
		"flat":
			return "flat"
		"gabled", "gambrel", "skillion", "saltbox", "shed":
			return "gabled"
		"hipped":
			return "hipped"
		"mansard":
			return "mansard"
		"pyramidal", "pyramid", "cone":
			return "pyramidal"
		"dome", "round", "onion":
			return "dome"
		"":
			return "flat" if legacy else default_roof
		_:
			return "flat"

## Roof rise in metres: the `roof:height` tag when present, else a
## shape default scaled by the footprint's short span and the style's
## regional pitch (steep alpine/German roofs, low Nordic/Australian ones;
## flat reads 0 — the cap is the roof). The caller additionally caps the
## rise below the total height so the wall keeps ≥0.5 m.
static func _roof_height_m(shape: String, span_m: float, tag_m: float,
		pitch: float = 1.0) -> float:
	if tag_m > 0.0:
		return tag_m
	# Clamps scale with the pitch so a steep alpine roof is not flattened
	# back to the default cap (identical to the old clamps at pitch 1).
	var lo := minf(pitch, 1.0)
	var hi := maxf(pitch, 1.0)
	match shape:
		"gabled":
			return clampf(span_m * 0.28 * pitch, 1.2 * lo, 4.5 * hi)
		"hipped":
			return clampf(span_m * 0.25 * pitch, 1.2 * lo, 4.0 * hi)
		"mansard":
			return clampf(span_m * 0.24 * pitch, 1.5 * lo, 3.2 * hi)
		"pyramidal":
			return clampf(span_m * 0.32 * pitch, 1.0 * lo, 5.0 * hi)
		"dome":
			return clampf(span_m * 0.30 * pitch, 1.0 * lo, 6.0 * hi)
	return 0.0

static func _ring_span_m(ring: PackedVector2Array) -> float:
	var bb := RingGeometry.aabb(ring)
	return minf(bb.size.x, bb.size.y) / WorldScale.metres_to_units()

## Pitched roof over a cleaned ring, rising rh from the eave level top
## (RoofGeometry builds the mesh; rings whose centroid falls outside keep
## the flat seal cap only).

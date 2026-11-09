class_name BridgeSpec
extends RefCounted

## One row of the capital bridge tables (scripts/data/bridges/bridge_specs_*.gd)
## and the single place that turns it into a registry entry, a model height
## and a validation report. A row is a Dictionary:
##   id        unique registry type ("br_paris_pont_neuf")
##   cc        ISO country code of the capital the bridge belongs to
##   name, wiki (wiki_title, default name), aliases (extra lower-case names)
##   lat, lon  deck centre; bearing = true deck bearing in degrees (0..360)
##   st        structure, one of STRUCTURES
##   spans     span lengths in metres between supports, in deck order
##   width     deck width in metres; clear = deck height above the water
##   tower     tower / pylon top above the water (cable bridges, bascules)
##   rise      arch crown above the deck (through, tied) or truss depth above it
##   material  "stone", "steel", "concrete" or "iron"
##   base      "water" (river), "sea", "ground" or "absolute"
##   tier      1 icon, 2 major, 3 minor (drawing order under the budget)
##   view      radius within which the bridge is built, metres (default 2500)
##   towers    (cable bridges) indices into the supports (0 = first end) that
##             carry a tower, else every interior support; pylon "single" is
##             one mast on the centre line instead of two legs; lean = metres
##             the single pylon's top is displaced along +X from its foot
##   moving    (swing, lift) index of the moving span
##   arch_spans  (arch, truss) the spans that carry the arch / truss, others
##             are plain girders; lower = metres a second deck hangs under the road
##   pier_depth, mid_depth, legs  (haunched) girder depth over the piers and at
##             mid-span, and the horizontal run of inclined rigid-frame legs
##   Structures: susp, stayed, extradosed (low pylon, deep girder), arch_deck,
##   arch_through, arch_tied, truss, girder, haunched (variable-depth box),
##   masonry, bascule, swing, lift, pontoon (floating), lateral (lateral-
##   suspension footbridge: `tower` is the pier-arm top)
##   src       where the figures come from; conf 1..3 (3 = cross-checked,
##             1 = estimated and not built, see MIN_BUILT_CONF)
## The deck is built along +X, centred on the origin, y = 0 at the water.

const STRUCTURES: Array[String] = [
	"susp", "stayed", "arch_deck", "arch_through", "arch_tied", "truss",
	"girder", "masonry", "bascule", "extradosed", "haunched", "swing", "lift",
	"pontoon", "lateral",
]
const BASES: Array[String] = ["water", "sea", "ground", "absolute"]
const MATERIALS: Array[String] = ["stone", "steel", "concrete", "iron"]
## Railing / parapet height over the deck, metres.
const PARAPET_M := 1.2
const DEFAULT_VIEW_M := 2500.0
## Rows below this confidence stay in the tables but are not built: a model of
## guessed dimensions would be less true than the mapped deck it replaces.
const MIN_BUILT_CONF := 2
## Structures whose top is a tower or pylon (`tower`), not the deck.
const TOWERED: Array[String] = ["susp", "stayed", "extradosed", "lateral", "lift"]
## Structures whose top is the arch or truss over the deck (`rise`).
const OVER_DECK: Array[String] = ["arch_through", "arch_tied", "truss"]

static func length_m(row: Dictionary) -> float:
	var total := 0.0
	for s in row.get("spans", []):
		total += float(s)
	return total

## The longest span, metres.
static func widest_span(row: Dictionary) -> float:
	var widest := 0.0
	for s in row.get("spans", []):
		widest = maxf(widest, float(s))
	return widest

## Height of the finished model's highest point over the water.
static func model_top(row: Dictionary) -> float:
	var st := str(row.get("st", ""))
	var clear := float(row.get("clear", 0.0))
	if st in TOWERED or (st == "bascule" and row.has("tower")):
		return float(row.get("tower", clear + PARAPET_M))
	if st in OVER_DECK or (st == "swing" and float(row.get("rise", 0.0)) > 0.0):
		return clear + float(row.get("rise", 0.0))
	return clear + PARAPET_M

## The registry entry of a row, in the format of LocationData.landmarks().
## Bridges are `secondary`: found by name or as extras beside a view, never
## the primary landmark of a city centre (see LocationData.landmark_entry).
static func to_entry(row: Dictionary) -> Dictionary:
	var name := str(row["name"])
	var aliases: Array = [name.to_lower()]
	for a in row.get("aliases", []):
		aliases.append(str(a))
	var view := float(row.get("view", DEFAULT_VIEW_M))
	return {
		"type": str(row["id"]), "name": name, "lat": float(row["lat"]), "lon": float(row["lon"]),
		"radius_m": view, "wiki_title": str(row.get("wiki", name)),
		"height_m": snappedf(model_top(row), 0.1),
		"clear_m": maxf(12.0, float(row.get("width", 10.0)) * 1.2),
		"yaw_deg": fposmod(float(row["bearing"]) - 90.0, 360.0),
		"span_m": snappedf(length_m(row), 0.1), "base": str(row.get("base", "water")),
		"kind": "Bridge", "secondary": true, "tier": int(row.get("tier", 2)),
		"aliases": aliases,
	}

## Problems with a row, empty when it is sound. `catalog_cc` is the set of
## country codes the capital catalog knows (empty skips that check).
static func validate(row: Dictionary, catalog_cc: Dictionary = {}) -> PackedStringArray:
	var out := PackedStringArray()
	var id := str(row.get("id", "?"))
	for key in ["id", "cc", "name", "lat", "lon", "bearing", "st", "spans", "width", "clear", "material", "src", "conf"]:
		if not row.has(key):
			out.append("%s lacks %s" % [id, key])
	if not out.is_empty():
		return out
	if not id.begins_with("br_"):
		out.append("%s should start with br_" % id)
	if not str(row["st"]) in STRUCTURES:
		out.append("%s has unknown structure %s" % [id, row["st"]])
	if not str(row["material"]) in MATERIALS:
		out.append("%s has unknown material %s" % [id, row["material"]])
	if not str(row.get("base", "water")) in BASES:
		out.append("%s has unknown base %s" % [id, row.get("base")])
	if absf(float(row["lat"])) > 90.0 or absf(float(row["lon"])) > 180.0:
		out.append("%s has out-of-range coordinates" % id)
	var bearing := float(row["bearing"])
	if bearing < 0.0 or bearing >= 360.0:
		out.append("%s bearing %.1f is outside 0..360" % [id, bearing])
	var spans: Array = row["spans"]
	if spans.is_empty():
		out.append("%s has no spans" % id)
	for s in spans:
		if float(s) < 3.0 or float(s) > 2200.0:
			out.append("%s span %.1f m is implausible" % [id, float(s)])
	var length := length_m(row)
	if length < 8.0 or length > 6000.0:
		out.append("%s is %.0f m long" % [id, length])
	if float(row["width"]) < 1.5 or float(row["width"]) > 80.0:
		out.append("%s width %.1f m is implausible" % [id, float(row["width"])])
	if float(row["clear"]) < 0.5 or float(row["clear"]) > 120.0:
		out.append("%s clearance %.1f m is implausible" % [id, float(row["clear"])])
	if int(row["conf"]) < 1 or int(row["conf"]) > 3:
		out.append("%s conf should be 1..3" % id)
	if str(row["src"]).is_empty():
		out.append("%s has no source" % id)
	var st := str(row["st"])
	if st in TOWERED:
		# A lateral footbridge's pier arms and an extradosed pylon rise only
		# a little over the deck; a lift tower must clear the lifted span.
		var min_over := {"lateral": 1.0, "extradosed": 1.5, "lift": 5.0}.get(st, 3.0) as float
		if not row.has("tower"):
			out.append("%s needs a tower height" % id)
		elif float(row["tower"]) <= float(row["clear"]) + min_over:
			out.append("%s tower is not above the deck" % id)
		if spans.size() < 2 and st != "lift":
			out.append("%s needs at least two spans around a tower" % id)
	if st in ["swing", "lift"]:
		if not row.has("moving") or int(row["moving"]) < 0 or int(row["moving"]) >= spans.size():
			out.append("%s needs moving = index of the moving span" % id)
	if st == "pontoon" and float(row["clear"]) > 6.0:
		out.append("%s: a pontoon deck stands at most 6 m over the water" % id)
	for i in row.get("arch_spans", []):
		if int(i) < 0 or int(i) >= spans.size():
			out.append("%s arch span %d is not a span" % [id, int(i)])
	if row.has("lower") and (float(row["lower"]) < 3.0 or float(row["lower"]) > 25.0):
		out.append("%s lower deck should be 3..25 m under the road" % id)
	for i in row.get("towers", []):
		if int(i) < 1 or int(i) >= spans.size():
			out.append("%s tower support %d is not an interior support" % [id, int(i)])
	if st in OVER_DECK and float(row.get("rise", 0.0)) < 2.0:
		out.append("%s needs a rise over the deck" % id)
	if st == "arch_deck" and float(row.get("rise", 0.0)) < 1.0:
		out.append("%s needs an arch rise" % id)
	if not catalog_cc.is_empty() and not catalog_cc.has(str(row["cc"])):
		out.append("%s has unknown country %s" % [id, row["cc"]])
	return out

class_name DataNotes
extends RefCounted

## Plain-language account of live data that did not arrive, shown to the
## user (loading line, DataNotice card, "Partial data" badge). Wording is
## the design system's DataNotice contract: layers in everyday words,
## what the view does instead, and never a provider, API or error code
## (those stay in the log).

## Layer key -> row shown to the user, in display order.
const LAYERS := {
	"elevation": {"layer": "Elevation", "effect": "terrain is simulated", "glyph": "▲"},
	"imagery": {"layer": "Imagery", "effect": "ground colours are estimated", "glyph": "▦"},
	"map": {"layer": "Map details", "effect": "buildings, roads and water are approximate", "glyph": "⌂"},
}

## Rows for the layers that degraded, in LAYERS order; unknown keys drop.
## Each row records whether every layer the pipeline tried degraded
## (imagery is not tried on the Fast preset, so it cannot be missing).
static func describe(keys: Array, imagery_attempted: bool = true) -> Array:
	var offline := true
	for key in LAYERS:
		if not keys.has(key) and (imagery_attempted or key != "imagery"):
			offline = false
	var out: Array = []
	for key in LAYERS:
		if keys.has(key):
			var row := (LAYERS[key] as Dictionary).duplicate()
			row["offline"] = offline
			out.append(row)
	return out

## Nothing live came back at all (offline): an error, not a caution.
static func is_error(notes: Array) -> bool:
	return not notes.is_empty() and bool((notes[0] as Dictionary).get("offline", false))

static func title(notes: Array) -> String:
	return "No live data came back" if is_error(notes) else "Some data is unavailable"

static func message(notes: Array) -> String:
	if is_error(notes):
		return "Check your connection. This view is built from estimates."
	return "This view is partly estimated. Everything else is live."

## One line for the loading screen while a layer is not responding.
static func loading_line(keys: Array) -> String:
	var names: Array[String] = []
	for row in describe(keys):
		names.append(str(row["layer"]).to_lower())
	if names.is_empty():
		return ""
	return "Not responding: %s. Using estimates." % ", ".join(names)

## True unless the map answered, validly, with no buildings (open sea,
## wilderness): that is an empty place, not an outage.
static func osm_outage(reason: String) -> bool:
	return not reason.contains("returned no buildings; OSM API returned no buildings")

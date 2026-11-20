extends SceneTree

## Stockholm bridges (plan S-4): godot --headless --script tests/stockholm_bridges_test.gd
## Offline. Every br_stockholm_* row of BridgeSpecs is built (conf >= 2), is
## sound, builds a non-empty model, and its spans add up to the length OSM maps
## for it (OSM_M: polygon or deck way, overpass.openstreetmap.fr, S-4) within
## the row's tolerance. Djurgardsbron has its four god columns and Skeppsholmsbron
## its two gilded crowns at the midpoint.

## id -> [OSM length m, tolerance, other rows whose spans add to this length].
const OSM_M := {
	"br_stockholm_centralbron": [184.4, 0.05, []],
	# Main 181 m arch; OSM water 198 m shore to shore (way 5178978).
	"br_stockholm_tranebergsbron": [198.0, 0.10, []],
	"br_stockholm_skeppsholmsbron": [172.3, 0.05, []],
	"br_stockholm_danviksbron": [91.7, 0.05, []],
	"br_stockholm_djurgardsbron": [58.5, 0.05, []],
	"br_stockholm_vasabron": [209.2, 0.05, []],
	"br_stockholm_essingebron": [211.0, 0.05, []],
	# OSM maps the whole 400 m crossing as bridge only; the water part is 259 m.
	"br_stockholm_alviksbron": [400.0, 0.05, []],
	# The mapped rail way (811.3 m) runs 28 m of embankment past each end of
	# the 753 m bridge: arches plus steel span against it, 8 %.
	"br_stockholm_arstabron_ost": [811.3, 0.08, ["br_stockholm_arstabron_ost_stal"]],
	"br_stockholm_arstabron_vast": [812.9, 0.05, []],
	"br_stockholm_skanstullsbron": [559.4, 0.05, []],
	"br_stockholm_johanneshovsbron": [462.4, 0.05, []],
	"br_stockholm_sankt_eriksbron": [151.3, 0.05, []],
	"br_stockholm_lidingobron": [1003.1, 0.05, []],
	"br_stockholm_riksbron": [52.0, 0.05, []],
	"br_stockholm_stromsbron": [137.6, 0.05, []],
	"br_stockholm_norrbro": [54.9, 0.05, []],
}
## Rows that are part of a group measured under another row.
const GROUPED := ["br_stockholm_arstabron_ost_stal"]

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)

func _run() -> void:
	var seen := {}
	for row in BridgeSpecs.all():
		var id := str(row["id"])
		if not id.begins_with("br_stockholm_"):
			continue
		seen[id] = true
		for problem in BridgeSpec.validate(row):
			failures.append(problem)
		_check(int(row["conf"]) >= 2, "%s should be conf >= 2 so BridgeParam builds it, got %d" % [id, int(row["conf"])])
		_check(not BridgeSpecs.row_for(id).is_empty(), "%s is not built" % id)
		_check(str(row["src"]).contains("OSM") or str(row["src"]).contains("Wikipedia"),
			"%s should cite its sources" % id)
		_check_spans(row)
		_check_model(id)
	for id: String in OSM_M:
		_check(seen.has(id), "%s is in the OSM table but not a row" % id)
	for id: String in seen:
		_check(OSM_M.has(id) or id in GROUPED, "%s has no OSM length in the table" % id)
	_check(seen.size() >= 18, "expected at least 18 Stockholm bridge rows, got %d" % seen.size())
	_check_djurgardsbron()
	_check_skeppsholmsbron()
	if failures.is_empty():
		print("STOCKHOLM BRIDGES OK: %d rows" % seen.size())
		quit(0)
	else:
		for f in failures:
			printerr("STOCKHOLM BRIDGES FAIL: ", f)
		quit(1)

func _check_spans(row: Dictionary) -> void:
	var id := str(row["id"])
	if not OSM_M.has(id):
		return
	var entry: Array = OSM_M[id]
	var total := BridgeSpec.length_m(row)
	for other: String in entry[2]:
		total += BridgeSpec.length_m(BridgeSpecs.row_for(other))
	var osm := float(entry[0])
	_check(absf(total - osm) <= osm * float(entry[1]),
		"%s spans add to %.1f m, OSM maps %.1f m (%.1f%%, allowed %.0f%%)" % [id, total, osm,
			absf(total - osm) / osm * 100.0, float(entry[1]) * 100.0])

func _check_model(id: String) -> void:
	var root := LandmarkBuilder.build(id)
	var parts := LandmarkBuilder.parts(root)
	var tris := 0
	for m in parts:
		tris += m.mesh.surface_get_array_len(0) / 3
	_check(not parts.is_empty() and tris > 0, "%s builds an empty model" % id)
	_check(not LocationData.entry_for_type(id).is_empty(), "%s is not registered" % id)
	root.free()

## Vertices of the part named `key`, in model metres (the Model node's scale
## is metres_to_units(), so the mesh is already in metres).
func _vertices(root: Node3D, key: String) -> PackedVector3Array:
	var out := PackedVector3Array()
	for m in LandmarkBuilder.parts(root):
		if m.name == key:
			out.append_array(m.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	return out

func _check_djurgardsbron() -> void:
	var id := "br_stockholm_djurgardsbron"
	var row := BridgeSpecs.row_for(id)
	var corners := StoBridgeDjurgard.column_positions(row)
	_check(corners.size() == 4, "Djurgardsbron should have four columns, got %d" % corners.size())
	var root := LandmarkBuilder.build(id)
	var gods := _vertices(root, "Bronze")
	var granite := _vertices(root, "Granite")
	var clear := float(row["clear"])
	for p in corners:
		var god := false
		var shaft := false
		for v in gods:
			if absf(v.x - p.x) < 1.5 and absf(v.z - p.y) < 1.5 and v.y > clear + 6.0:
				god = true
				break
		for v in granite:
			if absf(v.x - p.x) < 1.2 and absf(v.z - p.y) < 1.2 and v.y > clear + 3.0 and v.y < clear + 6.0:
				shaft = true
				break
		_check(god, "Djurgardsbron column at %s lacks its god above the deck" % p)
		_check(shaft, "Djurgardsbron column at %s lacks its granite shaft" % p)
	var top := -INF
	for v in gods:
		top = maxf(top, v.y)
	_check(absf(top - BridgeSpec.model_top(row)) < 0.8,
		"Djurgardsbron gods top out at %.1f m, row says %.1f m" % [top, BridgeSpec.model_top(row)])
	root.free()

func _check_skeppsholmsbron() -> void:
	var id := "br_stockholm_skeppsholmsbron"
	var row := BridgeSpecs.row_for(id)
	var root := LandmarkBuilder.build(id)
	var gold := _vertices(root, "Gold")
	var clear := float(row["clear"])
	var half_w := float(row["width"]) * 0.5
	for side in [-1.0, 1.0]:
		var found := false
		for v in gold:
			if absf(v.x) < 0.6 and absf(v.z - side * (half_w - 0.1)) < 0.6 and v.y > clear + BridgeSpec.PARAPET_M + 0.5:
				found = true
				break
		_check(found, "Skeppsholmsbron has no gilded crown at the midpoint on side %.0f" % side)
	for v in gold:
		if absf(v.x) > 0.8:
			failures.append("Skeppsholmsbron gold outside the midpoint: x = %.1f" % v.x)
			break
	root.free()

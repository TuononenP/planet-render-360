class_name LargeShips
extends RefCounted

## Commits the large ships MarinaBuilder plans alongside quays: cruise
## liners, cruise ferries and cargo ships. These are harbour dressing,
## not claims about real vessels. Each entry is
##   [centre Vector3, yaw, length, beam, height, seed, kind, berth]
## with kind "liner", "ferry" or "cargo:<variant>" and an optional berth
## dictionary (QuayMoorings / CargoBerths) for ShipMooring's lines,
## fenders and gangway. Ships within NEAR_M of the eye get the detailed
## model, the rest the far one (the eye does not move far in a view).
const NEAR_M := 650.0
## Cargo hulls: navy, oxide red, blue, green, graphite.
const CARGO_HULLS := ["#1f2a36", "#7a2620", "#2b5d8a", "#2a4a35", "#3a3d40"]

static func prefix(kind: String) -> String:
	if kind == "ferry":
		return "CruiseFerry_"
	if kind.begins_with("cargo"):
		return "Cargo_"
	return "Liner_"

static func commit(holder: Node3D, ships: Array, eye: Vector2, m2u: float, maps: bool = true) -> int:
	for l in ships:
		var kind := str(l[6]) if l.size() > 6 else "liner"
		var at: Vector3 = l[0]
		var detail := Vector2(at.x, at.z).distance_to(eye) <= NEAR_M * m2u
		var berth: Dictionary = l[7] if l.size() > 7 and l[7] is Dictionary else {}
		var lm := geometry(kind, float(l[2]), float(l[3]), float(l[4]), float(l[5]), detail, maps, berth)
		var parts := lm.commit(holder, prefix(kind))
		VesselPrototypes.snow_parts(parts)
		for part in parts:
			part.position = at + Vector3(0, float(berth.get("lift", 0.0)) * m2u, 0)
			part.rotation.y = float(l[1])
			part.scale = Vector3.ONE * m2u
			part.set_meta("procedural_liner", true)
			part.set_meta("vessel_model", kind)
	return ships.size()

## The ship of `kind` at true size (+X bow, waterline y = 0).
static func geometry(kind: String, length: float, beam: float, h: float, seed_value: float,
		detail: bool, maps: bool, berth: Dictionary = {}) -> LandmarkMesh:
	var hex := CruiseLinerModel.hull_hex(seed_value * 4.0)
	var model := "liner"
	var variant := ""
	if kind == "ferry":
		hex = "#f0eee8"
		model = "cruise_ferry"
	elif kind.begins_with("cargo"):
		hex = CARGO_HULLS[int(seed_value * 50.0) % CARGO_HULLS.size()]
		model = "cargo"
		variant = kind.trim_prefix("cargo:")
	var lm := VesselPrototypes.geometry(model, length, beam, h,
		VesselMaterials.paint(hex, maps, 0.42, 0.05), detail, maps, seed_value, variant)
	if detail and not berth.is_empty():
		var ultra := MaterialLibrary.hi_res
		var spec := CruiseLinerModel.spec(length, beam, true, ultra)
		if model == "cruise_ferry":
			spec = CruiseFerryModel.spec(length, beam, true, ultra)
		elif model == "cargo":
			spec = CargoShipModel.spec(length, beam, variant, true, ultra)
		ShipMooring.add(lm, spec, berth, model != "cargo", maps)
	return lm

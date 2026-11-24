class_name LandmarkLnHungerfordBridge
extends RefCounted

## Hungerford Rail Bridge (John Hawkshaw, 1864) flanked by the twin Golden Jubilee
## Cable-Stayed Footbridges (Lifschutz Davidson Sandilands & WSP, 2002; OSM ways
## 4254120, 4254123, 256367743). Origin shifted 30 m NW of the river midpoint so
## the 376 m span suppresses OSM rail ways cleanly from Charing Cross Station
## (-188 m) across Victoria Embankment (-115 m) to the South Bank rail viaduct
## (+188 m), while the 316 m twin Golden Jubilee footbridges span -128..+188 m.
## Built along +X (`base: sea`).

const RAIL_X0 := -190.0
const RAIL_X1 := 194.0
const FOOT_X0 := -128.0
const FOOT_X1 := 188.0
const PIER_X0 := -88.0
const PIER_X1 := 162.0
const DECK_Y := 10.2
const RAIL_HALF_W := 11.5
const FOOT_Z := 16.0
const PYLON_TOP := 32.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Truss", LandmarkMaterials.paint("#4B5158", 0.55, 0.55))
	lm.use("Steel", LandmarkMaterials.paint("#E6EAEF", 0.38, 0.6))
	lm.use("Cable", LandmarkMaterials.paint("#C8D0D8", 0.42, 0.72))
	lm.use("Brick", LandmarkLnKit.red_brick("#8C4838", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B5AE", 3.5))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3D4044", 4.0))
	lm.use("Lamp", LandmarkMaterials.lit("#F4F8FF", 1.4))
	_rail_truss_bridge(lm)
	_golden_jubilee_footbridges(lm)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-45.0, 12.0, 26.0), Vector3(-45.0, 24.0, 16.0), 55.0, 0.85, 50.0],
		[Vector3(35.0, 12.0, 26.0), Vector3(35.0, 24.0, 16.0), 55.0, 0.9, 50.0],
		[Vector3(115.0, 12.0, 26.0), Vector3(115.0, 24.0, 16.0), 55.0, 0.85, 50.0],
	])

static func _rail_truss_bridge(lm: LandmarkMesh) -> void:
	var rail_len := RAIL_X1 - RAIL_X0
	var rail_mid := (RAIL_X0 + RAIL_X1) * 0.5
	# Railway deck slab from Charing Cross Station (-190 m) into South Bank viaduct (+194 m)
	lm.box("Deck", Vector3(rail_mid, DECK_Y, 0.0), Vector3(rail_len, 0.9, RAIL_HALF_W * 2.0))
	# Three longitudinal steel Warren/lattice truss lines (sides + centre)
	var bays := 36
	var dx := rail_len / float(bays)
	var tr_h := 4.4
	for tz in [-RAIL_HALF_W, 0.0, RAIL_HALF_W]:
		var z := float(tz)
		lm.box("Truss", Vector3(rail_mid, DECK_Y + tr_h, z), Vector3(rail_len, 0.45, 0.45))
		lm.box("Truss", Vector3(rail_mid, DECK_Y - 0.3, z), Vector3(rail_len, 0.5, 0.5))
		for i in bays:
			var x0 := RAIL_X0 + float(i) * dx
			var x1 := x0 + dx
			lm.beam("Truss", Vector3(x0, DECK_Y, z), Vector3(x1, DECK_Y + tr_h, z), 0.26, 0.26)
			lm.beam("Truss", Vector3(x1, DECK_Y, z), Vector3(x0, DECK_Y + tr_h, z), 0.26, 0.26)
			lm.box("Truss", Vector3(x0, DECK_Y + tr_h * 0.5, z), Vector3(0.28, tr_h, 0.28))
	# South Bank brick bank abutment cleanly beneath the rail deck (clear of Queen's Walk)
	var ab_h := DECK_Y + 0.65
	lm.box("Brick", Vector3(192.0, -1.5 + ab_h * 0.5, 0.0),
		Vector3(6.0, ab_h, RAIL_HALF_W * 2.0 + 3.0))
	lm.box("Concrete", Vector3(192.0, DECK_Y - 0.65, 0.0),
		Vector3(6.6, 0.4, RAIL_HALF_W * 2.0 + 3.6))
	# North approach support piers between Victoria Embankment (-115 m) and Charing Cross (-185 m)
	for pz in [-RAIL_HALF_W - 0.8, 0.0, RAIL_HALF_W + 0.8]:
		lm.frustum("Brick", Vector3(-150.0, -1.5, float(pz)), 2.2, 2.0, DECK_Y + 1.0, 12)
	# Hawkshaw's iconic paired brick cylindrical piers (6 river piers, clear of Victoria Embankment)
	for i in 6:
		var px := lerpf(PIER_X0, PIER_X1, float(i) / 5.0)
		for pz in [-RAIL_HALF_W - 1.3, RAIL_HALF_W + 1.3]:
			lm.frustum("Brick", Vector3(px, -1.5, float(pz)), 2.5, 2.3, DECK_Y + 1.0, 12)
			lm.box("Concrete", Vector3(px, DECK_Y - 0.65, float(pz)), Vector3(5.4, 0.7, 5.4))
		lm.box("Brick", Vector3(px, (DECK_Y - 0.8) * 0.5, 0.0), Vector3(3.2, DECK_Y - 0.8, RAIL_HALF_W * 2.0))

static func _golden_jubilee_footbridges(lm: LandmarkMesh) -> void:
	var foot_len := FOOT_X1 - FOOT_X0
	var foot_mid := (FOOT_X0 + FOOT_X1) * 0.5
	for side in [-1.0, 1.0]:
		var sz := float(side)
		var dz := sz * FOOT_Z
		# Sleek white concrete-and-steel footbridge deck + lit handrail strip
		lm.box("Concrete", Vector3(foot_mid, DECK_Y - 0.4, dz), Vector3(foot_len, 0.65, 4.4))
		lm.box("Steel", Vector3(foot_mid, DECK_Y + 0.55, dz + sz * 2.1), Vector3(foot_len, 0.14, 0.14))
		lm.box("Steel", Vector3(foot_mid, DECK_Y + 0.55, dz - sz * 2.1), Vector3(foot_len, 0.14, 0.14))
		lm.box("Lamp", Vector3(foot_mid, DECK_Y + 0.15, dz + sz * 2.05), Vector3(foot_len - 4.0, 0.16, 0.12))
		# Solid concrete bank landing stair towers at both ends (Victoria Embankment & Queen's Walk)
		for ex in [FOOT_X0 + 2.0, FOOT_X1 - 2.0]:
			var tower_h := DECK_Y + 0.8
			lm.box("Concrete", Vector3(float(ex), -1.5 + tower_h * 0.5, dz), Vector3(4.2, tower_h, 4.6))
		# 6 outward-leaning white steel pylons & fan stay cables aligned with the brick piers
		for i in 6:
			var px := lerpf(PIER_X0, PIER_X1, float(i) / 5.0)
			var base := Vector3(px, -1.0, dz + sz * 1.4)
			var top := Vector3(px, PYLON_TOP, dz + sz * 8.2)
			lm.frustum("Concrete", Vector3(px, -1.5, dz + sz * 1.4), 1.8, 1.6, DECK_Y + 1.2, 10)
			lm.beam("Steel", base, top, 0.95, 0.95)
			# Backstay anchored directly onto Hawkshaw's brick pier collar
			lm.beam("Cable", top, Vector3(px, DECK_Y - 0.3, sz * (RAIL_HALF_W + 1.5)), 0.16, 0.16)
			# Fan of 4 forestays each side along deck
			for k in range(1, 5):
				var off := float(k) * 7.5
				for dir in [-1.0, 1.0]:
					var tx := clampf(px + float(dir) * off, FOOT_X0 + 2.0, FOOT_X1 - 2.0)
					var anchor := top.lerp(base, float(k - 1) * 0.08)
					lm.beam("Cable", anchor, Vector3(tx, DECK_Y - 0.2, dz + sz * 2.0), 0.12, 0.12)

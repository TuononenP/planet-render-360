extends RefCounted

## kamppi_chapel. Registry entry and model in one file.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

## Kamppi Chapel of Silence (K2S Architects, 2012), built on its mapped
## 19.8 x 13.1 m ellipse (OSM way 185401488, tagged height 12.13 m; LoD2
## 11.9 m): a windowless spruce-slat vessel flaring to its lip, flat grey roof,
## glazed door at the east end. Numbers measured; plank colour estimated from
## the owner pages (no Commons photo fetched yet: see README).
const H := 12.1

const ENTRY := {"type": "kamppi_chapel", "name": "Kamppi Chapel", "lat": 60.16945, "lon": 24.93592,
	"radius_m": 1500.0, "wiki_title": "Kamppi Chapel", "height_m": 12.1, "clear_m": 18.0,
	"yaw_deg": -5.6, "kind": "Chapel", "aliases": ["kamppi chapel", "kampin kappeli", "kampens kapell"]}

## Windowless timber vessel on the mapped 19.8 by 13.1 m ellipse (OSM way
## 185401488): spruce planks run round it, the wall flares smoothly to a
## lip at 11.5 m, the flat roof is grey and the entrance is a glazed door.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#92908A", 3.0))
	lm.use("Glass", LandmarkMaterials.glass())
	lm.use("Wood", LandmarkMaterials.paint("#B3692C", 0.5, 0.05))
	lm.use("Seam", LandmarkMaterials.paint("#8E5224", 0.55, 0.05))
	lm.use("Roof", LandmarkMaterials.paint("#6A6D6F", 0.7))
	lm.use("Door", LandmarkMaterials.paint("#2A2D30", 0.5))
	var sx := 9.9
	var sz := 6.55
	var profile := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		profile.append(Vector2(_kamppi_radius(t), H * t))
	lm.lathe("Wood", Vector3.ZERO, profile, 96, sx, sz, 0.0, true, false)
	# Fine horizontal plank seams follow the same curved vessel profile.
	for i in int(H / 0.2):
		var y := 0.15 + float(i) * 0.20
		lm.lathe("Seam", Vector3(0, y, 0), PackedVector2Array([
			Vector2(_kamppi_radius(y / H) + 0.002, 0), Vector2(_kamppi_radius(y / H) + 0.002, 0.016)]),
			96, sx, sz, 0.0, false, false)
	# Flat grey roof closes the vessel behind the wood rim.
	lm.lathe("Roof", Vector3(0, H - 0.06, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(0.0, 0)]),
		96, sx - 0.05, sz - 0.05, 0.0, false)
	# Glazed entrance in the east end, on a low stone threshold.
	var wall_x := _kamppi_radius(0.1) * sx
	U.blk(lm, "Door", wall_x - 0.15, 0.0, 0.0, 0.2, 2.7, 3.2)
	U.blk(lm, "Glass", wall_x - 0.03, 0.15, 0.0, 0.1, 2.4, 2.8)
	U.blk(lm, "Stone", wall_x + 0.7, 0.0, 0.0, 1.6, 0.12, 4.2)
	lm.commit(model)

## Wall radius (fraction of the roof rim) at fraction t of the height: a
## narrow foot that swells smoothly to the flared lip.
static func _kamppi_radius(t: float) -> float:
	return 0.80 + 0.20 * pow(clampf(t, 0.0, 1.0), 1.6)

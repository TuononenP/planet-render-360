extends RefCounted

## Topelius Memorial — "Taru ja totuus" / Fact and Fable (Gunnar Finne, 1932),
## Esplanadi park.
##
## Stepped granite terrace, tall polished grey-red granite column pedestal
## bearing a sculpted bronze portrait medallion of Zacharias Topelius, crowned
## by the twin nude allegorical bronze maidens holding the gilt flame of Truth
## and the crowned bird of Fable to exact 4.5 m.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const ASSET_DIR := "res://assets/landmarks/helsinki_3d/"

const ENTRY := {"type": "topelius_statue", "name": "Topelius Monument (Taru ja totuus)",
	"lat": 60.1674774, "lon": 24.9448067, "radius_m": 1500.0,
	"wiki_title": "Zachris Topelius", "height_m": 4.5, "clear_m": 5.5,
	"yaw_deg": 0.0, "kind": "Monument", "secondary": true,
	"aliases": ["topelius statue", "topelius monument", "taru ja totuus", "fact and fable"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8A847E", 2.0))
	lm.use("Pedestal", LandmarkMaterials.pbr("stone", "#98726B", 1.6))
	lm.use("Bronze", LandmarkMaterials.paint("#30443A", 0.38, 0.68))
	lm.use("Gold", LandmarkMaterials.gold())

	lm.frustum("Granite", Vector3.ZERO, 2.9, 2.9, 0.18, 20)
	lm.frustum("Granite", Vector3(0.0, 0.18, 0.0), 2.3, 2.3, 0.18, 20)
	U.blk(lm, "Pedestal", 0.0, 0.36, 0.0, 1.65, 0.32, 1.65)
	U.blk(lm, "Pedestal", 0.0, 0.68, 0.0, 1.32, 1.24, 1.32)
	U.blk(lm, "Pedestal", 0.0, 1.92, 0.0, 1.48, 0.16, 1.48)

	# Bronze portrait relief medallion of Zacharias Topelius on front of pedestal
	SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "topelius_medallion.glb",
		Vector3(0.0, 0.92, 0.67), Vector3.ONE, 0.0)
	lm.box("Gold", Vector3(0.0, 0.80, 0.68), Vector3(0.92, 0.07, 0.03), Basis(), 0.0)

	# Twin nude allegorical bronze maidens + crowned bird (2.08..4.50 m exact)
	SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "topelius_maidens.glb",
		Vector3(0.0, 2.08, 0.0), Vector3.ONE, 0.0)
	# Sculpted gilt Flame of Truth held in Totuus's hand
	lm.lathe("Gold", Vector3(-0.34, 3.48, 0.28), PackedVector2Array([
		Vector2(0.02, 0.0), Vector2(0.09, 0.10), Vector2(0.06, 0.22), Vector2(0.0, 0.34),
	]), 10)
	lm.commit(model)

	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-3.0, 0.4, 3.0), Vector3(0.0, 3.0, 0.0), 44.0, 0.85, 12.0, warm],
		[Vector3(3.0, 0.4, -3.0), Vector3(0.0, 3.0, 0.0), 44.0, 0.80, 12.0, warm],
	])

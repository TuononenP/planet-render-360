class_name LandmarkMiWelcomeCenter
extends RefCounted

## Art Deco Welcome Center / Ocean Rescue Beach Patrol HQ — 1001 Ocean Dr (MI-4A).
## Site: OSM way 380875536, 25.780279, -80.130344, yaw_deg 11.7.
## Local +X = east toward Lummus Park / the beach, +Z = north along Ocean Drive.
## Architect Robert Taylor (1934) Nautical Moderne "ship" pavilion (Commons views):
##   - Footprint 35.8 m (X) x 30.0 m (Z), white stucco with navy & aqua bands.
##   - Ground deck block x -9..3 (z -12..12, 3.6 m) with side wings; semicircular
##     bridge deck (R 7.0 m) bowing east from x = 3 with pipe railings.
##   - Navy-glazed bridge house (y 3.6..6.8) with rounded roof slab and porthole
##     windows; signal mast with yard arm whose tip is the model top, 11.5 m.
##   - Royal palms along the Lummus Park side.

const HEIGHT_M := 11.5
const BOW_X := 3.0
const BOW_R := 7.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F8F7F2", 3.0))
	lm.use("Navy", LandmarkMaterials.paint("#1C2F5A", 0.5, 0.05))
	lm.use("Aqua", LandmarkMaterials.paint("#58C4C8", 0.55, 0.05))
	lm.use("Glass", LandmarkMaterials.glass("#22323C"))
	lm.use("Rail", LandmarkMaterials.paint("#F2F2EE", 0.5, 0.2))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#CFC9BB", 3.0))
	lm.use("Trunk", LandmarkMaterials.pbr("concrete", "#9A9588", 2.0))
	lm.use("Frond", LandmarkMaterials.paint("#2F6B35", 0.8, 0.0))

	lm.box("Deck", Vector3(2.0, -0.15, 0.0), Vector3(34.0, 0.3, 30.0))
	_hull(lm)
	_bridge_house(lm)
	_mast(lm)
	for z: float in [-12.0, -6.0, 6.0, 12.0]:
		LandmarkMiKit.royal_palm(lm, "Trunk", "Frond", Vector3(15.0, 0.0, z), 9.0, z)
	lm.commit(model)

	var warm := Color(1.0, 0.92, 0.74)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(16.0, 1.5, -10.0), Vector3(BOW_X + 3.0, 4.5, 0.0), 40.0, 1.1, 30.0, warm],
		[Vector3(16.0, 1.5, 10.0), Vector3(BOW_X + 3.0, 4.5, 0.0), 40.0, 1.1, 30.0, warm],
	])

static func _arc(cx: float, r: float, segs: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segs + 1:
		var a := -PI * 0.5 + PI * float(i) / float(segs)
		pts.append(Vector2(cx + cos(a) * r, sin(a) * r))
	return pts

static func _hull(lm: LandmarkMesh) -> void:
	# Main deck block with side wings, window band and aqua belt.
	lm.box("White", Vector3(-3.0, 1.65, 0.0), Vector3(12.0, 3.9, 24.0))
	for sz: float in [-1.0, 1.0]:
		lm.box("White", Vector3(-1.0, 1.4, sz * 12.5), Vector3(16.0, 3.4, 5.0))
		lm.box("Aqua", Vector3(7.1, 3.15, sz * 12.5), Vector3(0.12, 0.25, 5.0))
	lm.box("Navy", Vector3(3.05, 1.9, 0.0), Vector3(0.2, 1.3, 14.0))
	lm.box("Aqua", Vector3(3.05, 3.2, 0.0), Vector3(0.22, 0.3, 14.0))
	# Semicircular bridge deck bowing east with a pipe railing.
	var arc := _arc(BOW_X, BOW_R, 14)
	lm.poly_prism("White", arc, -0.3, 3.6)
	lm.poly_prism("Navy", _arc(BOW_X, BOW_R + 0.25, 14), 3.4, 3.7)
	for i in arc.size():
		var p := arc[i]
		var o := Vector2(p.x - BOW_X, p.y).normalized() * 0.25
		lm.beam("Rail", Vector3(p.x + o.x, 3.7, p.y + o.y), Vector3(p.x + o.x, 4.7, p.y + o.y), 0.07, 0.07)
		if i < arc.size() - 1:
			var q := arc[i + 1]
			var o2 := Vector2(q.x - BOW_X, q.y).normalized() * 0.25
			lm.beam("Rail", Vector3(p.x + o.x, 4.7, p.y + o.y), Vector3(q.x + o2.x, 4.7, q.y + o2.y), 0.07, 0.07)
			lm.beam("Rail", Vector3(p.x + o.x, 4.2, p.y + o.y), Vector3(q.x + o2.x, 4.2, q.y + o2.y), 0.05, 0.05)
	LandmarkMiKit.porthole_row(lm, "Navy", "Glass", Vector2(BOW_X + 0.1, -5.5), Vector2(BOW_X + 0.1, 5.5),
		0.9, 5, 0.3, Vector2(1, 0))
	LandmarkMiKit.porthole_row(lm, "Navy", "Glass", Vector2(-9.0, -11.0), Vector2(-9.0, 11.0), 2.4, 7, 0.32,
		Vector2(-1, 0))

static func _bridge_house(lm: LandmarkMesh) -> void:
	# Ship-bridge pavilion: white house, navy glazing ribbon, rounded roof slab.
	lm.box("White", Vector3(-2.2, 5.2, 0.0), Vector3(8.4, 3.2, 9.0), Basis(), 0.04)
	lm.box("Glass", Vector3(2.05, 5.3, 0.0), Vector3(0.12, 1.5, 8.0))
	for sz: float in [-1.0, 1.0]:
		lm.box("Glass", Vector3(-2.2, 5.3, sz * 4.55), Vector3(6.4, 1.5, 0.12))
	var roof := _arc(-2.2, 4.5, 10)
	lm.poly_prism("Navy", roof, 6.75, 7.1)
	lm.box("Navy", Vector3(-4.2, 6.92, 0.0), Vector3(4.0, 0.35, 9.0))
	lm.box("Aqua", Vector3(2.1, 6.4, 0.0), Vector3(0.12, 0.2, 8.4))
	LandmarkMiKit.porthole_row(lm, "Aqua", "Glass", Vector2(-6.4, -3.5), Vector2(-6.4, 3.5), 5.2, 3, 0.3,
		Vector2(-1, 0))

static func _mast(lm: LandmarkMesh) -> void:
	var m := Vector3(-3.0, 7.1, 0.0)
	lm.frustum("White", m, 0.28, 0.22, 0.6, 8)
	lm.beam("Rail", m + Vector3(0, 0.5, 0), Vector3(m.x, HEIGHT_M, 0.0), 0.2, 0.2)
	lm.beam("Rail", Vector3(m.x, 9.6, -1.8), Vector3(m.x, 9.6, 1.8), 0.12, 0.12)
	lm.beam("Aqua", Vector3(m.x, 8.3, -1.0), Vector3(m.x, 8.3, 1.0), 0.1, 0.1)

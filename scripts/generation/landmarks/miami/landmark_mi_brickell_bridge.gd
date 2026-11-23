class_name LandmarkMiBrickellBridge
extends RefCounted

## Brickell Avenue Bridge (FDOT SR 905 / US 1, 1995, over the mouth of the
## Miami River): builds the 140.1 m twin-leaf bascule deck and piers via
## BridgeParam, then adds the architectural and sculptural landmarks documented
## in visual-plan/refs/landmarks/brickell_avenue_bridge/:
## - Two stepped Art Deco / neoclassical limestone bridge-tender control houses
##   flanking the central bascule span on the west side, with cantilevered
##   glazed control cabs, louvered friezes, and patinated copper hipped roofs.
## - Stepped limestone river-pier bastions with Manuel Carbonell's patinated
##   bronze historical bas-relief panels (#5C4938) and classical limestone urns,
##   plus ornamental sidewalk balustrades and warm globe standards.
## - Manuel Carbonell's Pillar of History (Tequesta Family) monument at the
##   south-east pier corner (-X = south, +Z = east for bearing 1.4 deg): a
##   sculpted bas-relief column rising 12.5 m above the pedestal pad to a flared
##   Doric capital, crowned by the 3.8 m bronze/gilt Tequesta Family group
##   reaching orn = 16.4 m above the deck (~24.0 m over the water), dressed with
##   warm night FLOOD_META uplights.

const ORN_TOP_M := 16.4
const COLUMN_TOP_M := 12.6
const SCULPT_H_M := 3.8
const HOUSE_ROOF_M := 7.8

static func build(model: Node3D, row: Dictionary) -> void:
	BridgeParam.build(model, row)
	var lm := LandmarkMesh.new()
	lm.use("Limestone", LandmarkMaterials.pbr("limestone", "#E8DFCF", 3.0))
	lm.use("RoofCopper", LandmarkMaterials.pbr("copper", "#4D7B68", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#22323A"))
	lm.use("BronzeRelief", LandmarkMaterials.paint("#5C4938", 0.46, 0.55))
	lm.use("BronzeGilt", LandmarkMaterials.paint("#8C6D3B", 0.36, 0.76))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A8", 0.9))

	var c := float(row["clear"])
	var width := float(row["width"])
	var hw := width * 0.5
	var h := BridgeParam.half_length(row)
	var xs := BridgeParam.supports(row)
	var x_south := xs[1] if xs.size() >= 3 else -28.05
	var x_north := xs[xs.size() - 2] if xs.size() >= 4 else 28.05

	# Two stepped Art Deco / neoclassical limestone bridge-tender houses on the
	# west (-Z) river-pier corners flanking the 56.1 m bascule span.
	for xp in [x_south, x_north]:
		_tender_house(lm, xp, -hw - 1.15, c)
		_pier_relief_panel(lm, xp, -hw - 3.35, c, Vector3.FORWARD)

	# East (+Z) river-pier bastions with bronze bas-relief plaques; north-east
	# carries a classical bowl finial while south-east carries the Pillar of History.
	_east_pier_bastion(lm, x_north, hw + 0.85, c, true)
	_east_pier_bastion(lm, x_south, hw + 0.85, c, false)
	_pier_relief_panel(lm, x_north, hw + 2.45, c, Vector3.BACK)
	_pier_relief_panel(lm, x_south, hw + 2.45, c, Vector3.BACK)

	# Ornamental sidewalk balustrades and warm globe standards along both edges.
	_sidewalk_balustrades(lm, h, c, hw, x_south, x_north)

	# Pillar of History (Tequesta Family) at the south-east corner (-X, +Z).
	var mon_pos := Vector3(x_south - 0.6, c, hw + 0.65)
	_pillar_of_history(lm, mon_pos)

	BridgeCamber.apply(lm, h, c, float(row.get("camber", 0.0)), float(row.get("tilt", 0.0)))
	lm.commit(model)
	_set_flood_lights(model, c, hw, x_south, x_north, mon_pos)

## Stepped limestone bridge-tender control house rising from y = 0 through deck
## `c` up to a cantilevered glazed operator's cab and patinated copper hipped cap.
static func _tender_house(lm: LandmarkMesh, cx: float, cz: float, c: float) -> void:
	# Tapered waterline plinth and pier shaft (always >= 0.0 for fitted low-bank checks).
	var plinth_h := minf(1.3, c * 0.45)
	LandmarkBrKit.tapered_box(lm, "Limestone", Vector3(cx, 0.0, cz), 2.95, 2.45, 2.65, 2.15, plinth_h)
	if c > plinth_h + 0.05:
		lm.box("Limestone", Vector3(cx, (plinth_h + c) * 0.5, cz),
			Vector3(5.2, c - plinth_h, 4.2), Basis(), 0.03)
	# Lower shaft above deck with recessed casement windows and Deco belt course.
	var shaft_h := 3.55
	lm.box("Limestone", Vector3(cx, c + shaft_h * 0.5, cz), Vector3(4.9, shaft_h, 3.95), Basis(), 0.03)
	LandmarkMiKit.deco_eyebrow(lm, "Limestone", Vector2(cx - 2.55, cz - 2.0),
		Vector2(cx + 2.55, cz - 2.0), c + 2.25, 0.22, 0.14, Vector2(0.0, -1.0))
	for sx in [-1.0, 1.0]:
		lm.box("Glass", Vector3(cx + sx * 1.15, c + 1.45, cz - 1.99), Vector3(0.75, 1.05, 0.08), Basis(), 0.0)
	# Stepped corbelled brackets supporting the cantilevered control cab.
	lm.box("Limestone", Vector3(cx, c + shaft_h + 0.22, cz - 0.2), Vector3(5.5, 0.44, 4.65), Basis(), 0.02)
	lm.box("Limestone", Vector3(cx, c + shaft_h + 0.56, cz - 0.35), Vector3(6.1, 0.28, 5.25), Basis(), 0.02)
	for sx in [-1.85, 0.0, 1.85]:
		lm.beam("Limestone", Vector3(cx + sx, c + shaft_h - 0.45, cz - 1.85),
			Vector3(cx + sx, c + shaft_h + 0.55, cz - 2.85), 0.34, 0.28)
	# Glazed operator's cab with limestone corner piers, mullions, and louvered attic.
	var cab_y0 := c + shaft_h + 0.70
	var cab_h := 1.95
	var cab_z := cz - 0.35
	lm.box("Glass", Vector3(cx, cab_y0 + cab_h * 0.5, cab_z), Vector3(5.76, cab_h, 4.92), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Limestone", Vector3(cx + sx * 2.74, cab_y0 + cab_h * 0.5, cab_z + sz * 2.32),
				Vector3(0.52, cab_h, 0.52), Basis(), 0.0)
	# Window mullions around all four faces of the control room.
	for k in [-1.35, 0.0, 1.35]:
		for sz in [-1.0, 1.0]:
			lm.box("Limestone", Vector3(cx + k, cab_y0 + cab_h * 0.5, cab_z + sz * 2.48),
				Vector3(0.18, cab_h, 0.12), Basis(), 0.0)
		for sx in [-1.0, 1.0]:
			lm.box("Limestone", Vector3(cx + sx * 2.90, cab_y0 + cab_h * 0.5, cab_z + k * 0.82),
				Vector3(0.12, cab_h, 0.18), Basis(), 0.0)
	lm.box("Limestone", Vector3(cx, cab_y0 + 0.26, cab_z), Vector3(6.02, 0.52, 5.18), Basis(), 0.02)
	# Louvered attic frieze and wide Classical / Deco eaves cornice.
	var att_y0 := cab_y0 + cab_h
	lm.box("Limestone", Vector3(cx, att_y0 + 0.34, cab_z), Vector3(5.96, 0.68, 5.12), Basis(), 0.02)
	lm.box("Limestone", Vector3(cx, att_y0 + 0.76, cab_z), Vector3(6.65, 0.18, 5.80), Basis(), 0.0)
	# Patinated copper-green hipped roof cap (ridge along X).
	var eave_y := att_y0 + 0.85
	var cap_rise := HOUSE_ROOF_M - (eave_y - c)
	lm.gable("RoofCopper", Vector3(cx, eave_y, cab_z), 5.0, 6.2, maxf(cap_rise, 0.85),
		Basis(Vector3.FORWARD, Vector3.UP, Vector3.RIGHT), 0.35, "Limestone")

## Stepped limestone pier bastion on the east (+Z) river piers; `with_bowl` adds
## the shallow classical limestone urn seen on the non-monument pier corners.
static func _east_pier_bastion(lm: LandmarkMesh, cx: float, cz: float, c: float, with_bowl: bool) -> void:
	var plinth_h := minf(1.3, c * 0.45)
	LandmarkBrKit.tapered_box(lm, "Limestone", Vector3(cx, 0.0, cz), 2.55, 1.85, 2.25, 1.58, plinth_h)
	if c > plinth_h + 0.05:
		lm.box("Limestone", Vector3(cx, (plinth_h + c) * 0.5, cz),
			Vector3(4.4, c - plinth_h, 3.1), Basis(), 0.03)
	lm.box("Limestone", Vector3(cx, c + 1.15, cz), Vector3(3.6, 2.3, 2.7), Basis(), 0.03)
	lm.box("Limestone", Vector3(cx, c + 2.40, cz), Vector3(3.9, 0.22, 3.0), Basis(), 0.0)
	if with_bowl:
		lm.lathe("Limestone", Vector3(cx, c + 2.51, cz), PackedVector2Array([
			Vector2(0.42, 0.0), Vector2(0.32, 0.22), Vector2(0.95, 0.52),
			Vector2(1.04, 0.68), Vector2(0.0, 0.72)]), 12, 1.0, 1.0, 0.0, false)

## Patinated bronze bas-relief panel (#5C4938) set in a moulded limestone frame
## on the outer river pier face, clamped safely above y = 0.35 m.
static func _pier_relief_panel(lm: LandmarkMesh, cx: float, face_z: float, c: float, out_n: Vector3) -> void:
	var y_top := maxf(c - 0.45, 1.55)
	var y_bot := maxf(y_top - minf(2.4, c * 0.55), 0.35)
	if y_top <= y_bot + 0.3:
		return
	var cy := (y_bot + y_top) * 0.5
	var ph := y_top - y_bot
	var pw := 1.45
	lm.box("Limestone", Vector3(cx, cy, face_z), Vector3(pw + 0.32, ph + 0.32, 0.16), Basis(), 0.0)
	lm.box("BronzeRelief", Vector3(cx, cy, face_z + out_n.z * 0.09), Vector3(pw, ph, 0.10), Basis(), 0.0)
	# Sculpted relief figures suggested by layered vertical bronze bosses.
	for k in [-0.36, 0.0, 0.36]:
		lm.box("BronzeGilt", Vector3(cx + k, cy - ph * 0.06, face_z + out_n.z * 0.15),
			Vector3(0.24, ph * 0.62, 0.07), Basis(), 0.0)

## Ornamental limestone plinth curbs, piers, and warm globe lamps along both sidewalks.
static func _sidewalk_balustrades(lm: LandmarkMesh, h: float, c: float, hw: float,
		x_south: float, x_north: float) -> void:
	var len_x := 2.0 * h - 1.2
	for s: float in [-1.0, 1.0]:
		var z := s * (hw - 0.26)
		lm.box("Limestone", Vector3(0.0, c + 0.14, z), Vector3(len_x, 0.28, 0.38), Basis(), 0.0)
		lm.box("Limestone", Vector3(0.0, c + 1.16, z), Vector3(len_x, 0.12, 0.34), Basis(), 0.0)
		var posts := [-h + 1.2, (x_south - h) * 0.5, x_south + 3.8, 0.0, x_north - 3.8, (x_north + h) * 0.5, h - 1.2]
		for i in posts.size():
			var px := float(posts[i])
			lm.box("Limestone", Vector3(px, c + 0.72, z), Vector3(0.62, 1.44, 0.56), Basis(), 0.0)
			lm.box("Limestone", Vector3(px, c + 1.50, z), Vector3(0.76, 0.14, 0.70), Basis(), 0.0)
			if i % 2 == 0:
				lm.frustum("BronzeRelief", Vector3(px, c + 1.57, z), 0.18, 0.10, 0.28, 8)
				lm.lathe("Lamp", Vector3(px, c + 1.83, z), PackedVector2Array([
					Vector2(0.0, 0.0), Vector2(0.24, 0.10), Vector2(0.29, 0.28),
					Vector2(0.24, 0.46), Vector2(0.0, 0.56)]), 8, 1.0, 1.0, 0.0, false)

## Manuel Carbonell's Pillar of History (12.5 m bas-relief column on a 0.1 m pad
## to COLUMN_TOP_M = 12.6 m) crowned by the 3.8 m Tequesta Family sculpture
## reaching ORN_TOP_M = 16.4 m above the deck.
static func _pillar_of_history(lm: LandmarkMesh, base: Vector3) -> void:
	# Stepped limestone and bronze base plinth on the SE bastion deck.
	lm.box("Limestone", base + Vector3(0, 0.35, 0), Vector3(2.85, 0.70, 2.85), Basis(), 0.02)
	lm.box("BronzeRelief", base + Vector3(0, 0.85, 0), Vector3(2.35, 0.30, 2.35), Basis(), 0.02)
	# 12.5 m sculpted bas-relief column (y = 0.10 .. 12.60 m above deck) with
	# undulating relief bands evoking the 159 carved Tequesta figures + Doric capital.
	var col_prof := PackedVector2Array([
		Vector2(1.06, 0.95), Vector2(0.92, 1.25),
		Vector2(0.82, 1.60), Vector2(0.86, 2.90), Vector2(0.79, 4.20),
		Vector2(0.84, 5.60), Vector2(0.77, 7.00), Vector2(0.81, 8.40),
		Vector2(0.74, 9.80), Vector2(0.78, 11.10), Vector2(0.72, 11.75),
		Vector2(0.92, 11.95), Vector2(1.36, 12.28), Vector2(1.40, 12.52),
		Vector2(0.95, COLUMN_TOP_M), Vector2(0.0, COLUMN_TOP_M),
	])
	lm.lathe("BronzeRelief", base, col_prof, 14, 1.0, 1.0, 0.0, false)
	# Gilt collar rings accenting the capital and base torus.
	lm.lathe("BronzeGilt", base + Vector3(0, 11.88, 0), PackedVector2Array([
		Vector2(0.76, 0.0), Vector2(0.98, 0.12), Vector2(1.42, 0.42),
		Vector2(1.42, 0.62), Vector2(0.0, 0.66)]), 14, 1.0, 1.0, 0.0, false)

	# Crowning 3.8 m Tequesta Family sculpture (y = 12.60 .. 16.40 m above deck):
	# standing warrior father aiming/raising bow & lifting child + seated mother.
	var top_base := base + Vector3(0, COLUMN_TOP_M, 0)
	lm.lathe("BronzeGilt", top_base, PackedVector2Array([
		Vector2(0.82, 0.0), Vector2(0.74, 0.22), Vector2(0.0, 0.24)]), 10, 1.0, 1.0, 0.0, false)
	# Standing Tequesta warrior torso and head (facing west/river -Z, +X).
	lm.beam("BronzeGilt", top_base + Vector3(-0.18, 0.18, 0.14), top_base + Vector3(-0.06, 1.42, 0.04), 0.28, 0.26)
	lm.beam("BronzeGilt", top_base + Vector3(0.20, 0.18, -0.14), top_base + Vector3(0.08, 1.42, -0.02), 0.28, 0.26)
	lm.lathe("BronzeGilt", top_base + Vector3(0.0, 1.32, 0.0), PackedVector2Array([
		Vector2(0.30, 0.0), Vector2(0.38, 0.65), Vector2(0.42, 1.15),
		Vector2(0.18, 1.32), Vector2(0.21, 1.62), Vector2(0.0, 1.78)]), 10, 1.0, 1.0, 0.0, false)
	# Seated mother figure nestled beside the warrior's knee.
	lm.lathe("BronzeGilt", top_base + Vector3(0.32, 0.18, 0.28), PackedVector2Array([
		Vector2(0.36, 0.0), Vector2(0.30, 0.58), Vector2(0.24, 1.05),
		Vector2(0.14, 1.22), Vector2(0.16, 1.44), Vector2(0.0, 1.56)]), 8, 1.0, 1.0, 0.0, false)
	lm.beam("BronzeGilt", top_base + Vector3(0.30, 1.10, 0.26), top_base + Vector3(0.08, 1.62, 0.08), 0.15, 0.15)
	# Warrior's raised arms & bow + child held aloft to exact y = c + 16.40 m.
	var shoulder := top_base + Vector3(0.0, 2.42, 0.0)
	var child_hip := top_base + Vector3(-0.08, 3.05, -0.12)
	lm.beam("BronzeGilt", shoulder + Vector3(-0.22, 0.0, 0.08), child_hip, 0.17, 0.17)
	lm.beam("BronzeGilt", shoulder + Vector3(0.20, 0.0, -0.08), top_base + Vector3(0.14, 3.22, -0.44), 0.16, 0.16)
	# Sculpted bow arc facing toward the river channel.
	var bow_top := top_base + Vector3(0.24, SCULPT_H_M - 0.08, -0.62)
	var bow_mid := top_base + Vector3(0.28, 2.95, -0.78)
	var bow_bot := top_base + Vector3(0.18, 2.15, -0.52)
	lm.beam("BronzeGilt", bow_bot, bow_mid, 0.08, 0.08)
	lm.beam("BronzeGilt", bow_mid, bow_top, 0.08, 0.08)
	# Child figure held overhead, reaching exact SCULPT_H_M = 3.8 m (c + 16.4 m).
	lm.lathe("BronzeGilt", child_hip, PackedVector2Array([
		Vector2(0.18, 0.0), Vector2(0.21, 0.36), Vector2(0.12, 0.50),
		Vector2(0.14, 0.66), Vector2(0.0, SCULPT_H_M - 3.05)]), 8, 1.0, 1.0, 0.0, false)
	lm.beam("BronzeGilt", child_hip + Vector3(0.0, 0.38, 0.0),
		top_base + Vector3(-0.04, SCULPT_H_M, -0.04), 0.10, 0.10)

## Warm night floodlights washing the Pillar of History & Tequesta Family statue
## and the two limestone bridge-tender control houses.
static func _set_flood_lights(model: Node3D, c: float, hw: float, x_south: float,
		x_north: float, mon: Vector3) -> void:
	var warm := Color(1.0, 0.86, 0.64)
	var spots: Array = [
		[mon + Vector3(-4.2, 0.8, -3.6), mon + Vector3(0.0, 11.5, 0.0), 42.0, 1.15, 28.0, warm],
		[mon + Vector3(4.2, 0.8, -3.2), mon + Vector3(0.0, 13.8, 0.0), 38.0, 1.15, 28.0, warm],
		[mon + Vector3(0.0, 0.8, 3.8), mon + Vector3(0.0, 12.8, 0.0), 40.0, 1.0, 26.0, warm],
		[Vector3(x_south - 6.0, c + 0.8, -hw + 2.5), Vector3(x_south, c + 4.8, -hw - 1.2), 48.0, 0.85, 22.0, warm],
		[Vector3(x_north + 6.0, c + 0.8, -hw + 2.5), Vector3(x_north, c + 4.8, -hw - 1.2), 48.0, 0.85, 22.0, warm],
		[Vector3(0.0, 1.2, -hw - 8.0), Vector3(0.0, c + 1.0, -hw), 58.0, 0.75, 36.0, warm],
	]
	model.set_meta(LandmarkLights.FLOOD_META, spots)

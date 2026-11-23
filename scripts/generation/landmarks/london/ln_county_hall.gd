class_name LandmarkLnCountyHall
extends RefCounted

## County Hall, South Bank (Ralph Knott, 1922; OSM relation 1789966, 65 m from preset eye).
## Edwardian Baroque Portland-stone river front with rusticated Cornish-granite plinth,
## central recessed curved crescent with giant Ionic colonnade, steeply pitched red-tile
## mansard roof with dormer rows, tall Portland-stone chimney stacks, and central fleche.
## +Z faces the Thames (west-northwest via registry yaw), height 45 m to fleche finial.

const W := 156.0
const D := 56.0
const PLINTH_H := 6.5
const EAVES_H := 26.5
const ROOF_TOP := 36.0
const TOP_H := 45.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkLnKit.granite("#8B8780", 3.2))
	lm.use("Stone", LandmarkLnKit.portland("#DFD8C8", 3.5))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#9A4834", 2.4))
	lm.use("Slate", LandmarkLnKit.welsh_slate("#4C545C", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#242D34"))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#4E7868", 2.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2B0", 1.2))
	_wings_and_plinth(lm)
	_central_crescent(lm)
	_roofs_and_fleche(lm)
	_windows_and_lamps(lm)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-48.0, 2.0, 34.0), Vector3(-48.0, 22.0, 22.0), 58.0, 0.85, 65.0],
		[Vector3(0.0, 2.0, 32.0), Vector3(0.0, 24.0, 14.0), 64.0, 1.0, 70.0],
		[Vector3(48.0, 2.0, 34.0), Vector3(48.0, 22.0, 22.0), 58.0, 0.85, 65.0],
	])

static func _wings_and_plinth(lm: LandmarkMesh) -> void:
	# Rusticated granite terrace plinth along the whole river front
	lm.box("Granite", Vector3(0.0, PLINTH_H * 0.5, 0.0), Vector3(W + 3.0, PLINTH_H, D + 3.0))
	lm.box("Stone", Vector3(0.0, PLINTH_H + 0.4, 0.0), Vector3(W + 3.8, 0.8, D + 3.8))
	# North & south flanking pavilions (projecting forward on +Z)
	for sx in [-1.0, 1.0]:
		var cx := float(sx) * 51.0
		lm.box("Stone", Vector3(cx, (PLINTH_H + EAVES_H) * 0.5, 2.0), Vector3(52.0, EAVES_H - PLINTH_H, D - 2.0))
		lm.box("Stone", Vector3(cx, EAVES_H + 0.5, 2.0), Vector3(53.4, 1.2, D - 0.6))
		# End pedimented projection
		var px := float(sx) * 66.0
		lm.box("Stone", Vector3(px, (PLINTH_H + EAVES_H) * 0.5, 3.0), Vector3(20.0, EAVES_H - PLINTH_H, D))
		LandmarkLnKit.colonnade_x(lm, "Stone", px - 7.5, px + 7.5, PLINTH_H + 1.0, D * 0.5 + 3.4, 4, 14.5, 0.68)
		LandmarkLnKit.pediment_z(lm, "Stone", px, EAVES_H + 1.1, D * 0.5 + 3.0, 19.0, 4.2, 2.2)
	# Rear spine behind central courtyard
	lm.box("Stone", Vector3(0.0, (PLINTH_H + EAVES_H) * 0.5, -14.0), Vector3(64.0, EAVES_H - PLINTH_H, 24.0))

static func _central_crescent(lm: LandmarkMesh) -> void:
	# Curved recessed river crescent with giant Ionic colonnade (14 columns along arc)
	var segs := 14
	var rad := 32.0
	var cz := 26.0
	for i in segs:
		var a0 := lerpf(-0.92, 0.92, float(i) / float(segs))
		var a1 := lerpf(-0.92, 0.92, float(i + 1) / float(segs))
		var am := (a0 + a1) * 0.5
		var p0 := Vector3(sin(a0) * rad, PLINTH_H, cz - cos(a0) * rad * 0.55)
		var p1 := Vector3(sin(a1) * rad, PLINTH_H, cz - cos(a1) * rad * 0.55)
		var pm := (p0 + p1) * 0.5
		var seg_w := p0.distance_to(p1) + 0.4
		var rot := Basis(Vector3.UP, atan2(p1.z - p0.z, p1.x - p0.x))
		lm.box("Stone", pm + Vector3(0.0, (EAVES_H - PLINTH_H) * 0.5, -3.0),
			Vector3(seg_w, EAVES_H - PLINTH_H, 6.0), rot)
		# Giant Ionic column standing proud of the recessed crescent wall
		var cp := Vector3(sin(am) * (rad - 1.2), PLINTH_H + 0.8, cz - cos(am) * rad * 0.55 + 1.8)
		lm.box("Stone", cp + Vector3(0.0, 0.5, 0.0), Vector3(1.6, 1.0, 1.6))
		lm.frustum("Stone", cp + Vector3(0.0, 1.0, 0.0), 0.62, 0.55, 14.5, 10)
		lm.box("Stone", cp + Vector3(0.0, 16.0, 0.0), Vector3(1.8, 0.9, 1.8))
		lm.box("Stone", cp + Vector3(0.0, 17.6, 0.0), Vector3(seg_w + 0.5, 2.2, 2.6), rot)

static func _roofs_and_fleche(lm: LandmarkMesh) -> void:
	# Steeply pitched red-tile mansard roofs on wings and rear range
	for sx in [-1.0, 1.0]:
		LandmarkLnKit.mansard_roof(lm, "Tile", "Stone", "Glass",
			Vector3(float(sx) * 51.0, EAVES_H + 1.0, 2.0), 51.0, D - 3.0, ROOF_TOP - EAVES_H - 1.0, 6)
		for k in 3:
			var cx := float(sx) * (36.0 + float(k) * 15.0)
			lm.box("Stone", Vector3(cx, ROOF_TOP + 2.2, 4.0), Vector3(2.8, 6.5, 2.2))
			lm.box("Stone", Vector3(cx, ROOF_TOP + 5.6, 4.0), Vector3(3.3, 0.6, 2.7))
	LandmarkLnKit.mansard_roof(lm, "Tile", "Stone", "Glass",
		Vector3(0.0, EAVES_H + 1.0, -14.0), 62.0, 22.0, ROOF_TOP - EAVES_H - 1.0, 7)
	# Central octagonal copper-clad fleche rising to 45 m
	lm.box("Stone", Vector3(0.0, ROOF_TOP + 1.2, -12.0), Vector3(7.0, 3.0, 7.0))
	lm.frustum("Stone", Vector3(0.0, ROOF_TOP + 2.7, -12.0), 2.8, 2.5, 3.2, 8)
	lm.frustum("Copper", Vector3(0.0, ROOF_TOP + 5.9, -12.0), 2.5, 0.15, TOP_H - (ROOF_TOP + 5.9), 8)

static func _windows_and_lamps(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		var x0 := float(sx) * 28.0
		var x1 := float(sx) * 74.0
		for row in 3:
			var wy := PLINTH_H + 3.2 + float(row) * 5.2
			for i in 8:
				var wx := lerpf(x0, x1, (float(i) + 0.5) / 8.0)
				lm.box("Glass", Vector3(wx, wy, D * 0.5 + 1.15), Vector3(2.1, 3.3, 0.16))
				lm.box("Glass", Vector3(wx, wy, -D * 0.5 + 2.85), Vector3(2.1, 3.3, 0.16))
	# Embankment terrace lamps
	for i in 9:
		var lx := lerpf(-70.0, 70.0, float(i) / 8.0)
		LandmarkLnKit.globe_lamp(lm, "Slate", "Lamp", Vector3(lx, PLINTH_H + 0.8, D * 0.5 + 1.2), 3.6)

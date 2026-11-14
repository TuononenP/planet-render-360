class_name LandmarkFhEspoo
extends RefCounted

## Espoo modernist landmarks, true metres. +Z is the entrance side.
## Sources and estimated dimensions: docs/espoo-landmark-sources.md.
## Keep campus wings separate and courtyards open; do not fill the site
## with one bounding box. Materials share the existing PBR weathering kit.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

static func _materials() -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B5AA", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#854B3C", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#58746B", 2.0, 0.55, 0.45))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#555853", 3.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6B5440", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#454A45", 2.0, 0.85))
	lm.use("Metal", LandmarkMaterials.paint("#3C4140"))
	lm.use("Glass", LandmarkMaterials.glass("#334A4B"))
	return lm

## Siréns' low brick-and-timber chapel, transparent altar wall facing
## the freestanding forest cross, enclosed approach court and open belfry.
static func otaniemi_chapel(model: Node3D) -> void:
	var lm := _materials()
	U.blk(lm, "Granite", 0, 0, 0, 17, 0.35, 23)
	# Side walls only: the altar glazing is a real opening between them.
	for x in [-7.7, 7.7]:
		U.blk(lm, "Brick", x, 0.35, -1, 0.6, 5.1, 20)
	U.blk(lm, "Brick", 0, 0.35, 9.5, 16, 3.1, 0.6)
	U.blk(lm, "Brick", -10.0, 0.35, 5.5, 4, 3.0, 10)
	U.wedge(lm, "Wood", "Roof", -8.2, 8.2, -11.3, 10.3, 5.45, 0.15, 0.75)
	_glass_wall(lm, Vector3(-7.4, 0.4, -11.02), Vector3(7.4, 0.4, -11.02), Vector3(0, 0, -1), 4.9, 8)
	_glass_wall(lm, Vector3(-6, 0.4, 9.82), Vector3(6, 0.4, 9.82), Vector3(0, 0, 1), 2.8, 6)
	for x in [-7.0, -3.5, 0.0, 3.5, 7.0]:
		lm.beam("Wood", Vector3(x, 5.35, -11), Vector3(x, 5.95, 10), 0.16, 0.3)
	# Narrow timber fascia boards under the eaves and the entrance canopy.
	for x in range(-16, 17):
		U.blk(lm, "Wood", float(x) * 0.48, 3.5, 9.84, 0.075, 2.25, 0.09)
	for x in [-8.25, 8.25]:
		lm.beam("Metal", Vector3(x, 5.65, -11.3), Vector3(x, 6.25, 10.3), 0.10, 0.10)
	for x in [-1.5, 1.5]:
		lm.beam("Wood", Vector3(x, 0.25, 22.3), Vector3(x, 5.4, 25.3), 0.14, 0.14)
	# Cross stands outside beyond the glass altar, not on the roof.
	U.blk(lm, "Metal", 0, 0.2, -17, 0.16, 5.0, 0.16)
	U.blk(lm, "Metal", 0, 3.75, -17, 2.6, 0.14, 0.14)
	for x in [-8.3, 8.3]:
		U.blk(lm, "Brick", x, 0, 18, 0.45, 2.15, 15)
	U.blk(lm, "Brick", -4.8, 0, 25.3, 7.5, 2.15, 0.45)
	U.blk(lm, "Brick", 5.5, 0, 25.3, 6, 2.15, 0.45)
	for x in [-1.5, 1.5]:
		for z in [22.3, 25.3]:
			U.blk(lm, "Wood", x, 0, z, 0.24, 8.0, 0.24)
	for y in [5.5, 7.7]:
		U.blk(lm, "Wood", 0, y, 23.8, 3.4, 0.22, 3.5)
	for x in [-0.65, 0.65]:
		lm.frustum("Metal", Vector3(x, 5.8, 23.8), 0.4, 0.2, 0.65, 12)
	lm.commit(model, "Otaniemi_")

## Ruusuvuori's concrete sanctuary cube and low courtyard parish wing.
## The bells hang in a separate low portal, with no invented steeple.
static func tapiola_church(model: Node3D) -> void:
	var lm := _materials()
	U.blk(lm, "Concrete", 0, 0, 0, 25, 16.5, 25)
	# Vertical board impressions/panel joints on the bare sanctuary walls.
	for s in [-1.0, 1.0]:
		for k in 24:
			var x := -12.0 + float(k)
			U.blk(lm, "Granite", x, 0.5, s * 12.51, 0.018, 15.4, 0.015)
		for k in 12:
			var z := -11.0 + float(k) * 2.0
			U.blk(lm, "Glass", s * 12.52, 14.7, z, 0.02, 1.0, 1.65)
	U.blk(lm, "Metal", 0, 16.5, 0, 25.5, 0.2, 25.5)
	for row in [[-22, 16, 18, 9], [0, 25, 62, 9], [-30, 3, 8, 34]]:
		var x: float = row[0]
		var z: float = row[1]
		var w: float = row[2]
		var d: float = row[3]
		U.blk(lm, "Concrete", x, 0, z, w, 4.0, d)
		U.blk(lm, "Metal", x, 4.0, z, w + 0.3, 0.18, d + 0.3)
		U.box_windows(lm, "Glass", x, z, w, d, 0.8, 1, 3.0, maxi(2, int(w / 2.5)), maxi(2, int(d / 2.5)), 1.8, 2.6)
	_glass_wall(lm, Vector3(-10, 0.2, 12.55), Vector3(-2, 0.2, 12.55), Vector3(0, 0, 1), 3.4, 4)
	# Exposed concrete entrance gate and three suspended bells.
	for x in [-9.5, -3.5]:
		U.blk(lm, "Concrete", x, 0, 38, 0.65, 5.7, 0.65)
	U.blk(lm, "Concrete", -6.5, 5.7, 38, 6.65, 0.6, 0.8)
	for x in [-8.4, -6.5, -4.6]:
		lm.frustum("Metal", Vector3(x, 3.7, 38), 0.45, 0.24, 0.75, 16)
		U.blk(lm, "Metal", x, 4.45, 38, 0.05, 1.25, 0.05)
	lm.commit(model, "TapiolaChurch_")

## Aarne Ervi's 49 m office tower: 13 storeys, enamel panel grid,
## continuous window bands and recessed panorama restaurant crown.
static func keskustorni(model: Node3D) -> void:
	var lm := _materials()
	lm.use("Enamel", LandmarkMaterials.paint("#BED1CA", 0.42, 0.2))
	U.blk(lm, "Granite", 0, 0, 0, 28.5, 0.5, 18.5)
	U.blk(lm, "Enamel", 0, 0.5, 0, 28, 44.5, 18)
	for s in [-1.0, 1.0]:
		for floor in 12:
			var y := 2.8 + float(floor) * 3.45
			_glass_wall(lm, Vector3(-13.6, y, s * 9.02), Vector3(13.6, y, s * 9.02), Vector3(0, 0, s), 1.8, 14)
			_glass_wall(lm, Vector3(s * 14.02, y, -7.18), Vector3(s * 14.02, y, 7.18), Vector3(s, 0, 0), 1.8, 7)
		for k in 15:
			U.blk(lm, "Metal", -14 + float(k) * 2, 0.5, s * 9.07, 0.045, 44.5, 0.045)
		for k in 10:
			U.blk(lm, "Metal", s * 14.07, 0.5, -9 + float(k) * 2, 0.045, 44.5, 0.045)
	U.blk(lm, "Metal", 0, 45.0, 0, 28.8, 0.55, 18.8)
	U.blk(lm, "Glass", 0, 45.55, 0, 22.5, 2.65, 11.2)
	for x in [-11, -5.5, 0.0, 5.5, 11.0]:
		for z in [-5.7, 5.7]:
			U.blk(lm, "Enamel", x, 45.55, z, 0.12, 2.65, 0.12)
	U.blk(lm, "Enamel", 0, 48.2, 0, 24.0, 0.8, 12.6)
	# Ground-floor lobby and modest projecting entrance canopy.
	U.blk(lm, "Glass", 0, 0.5, 9.03, 12, 2.0, 0.06)
	U.blk(lm, "Enamel", 0, 2.6, 10.5, 12.5, 0.2, 3)
	lm.commit(model, "Keskustorni_")

## Printing house: eight 27 m square roof modules, supported by 3 m
## concrete ventilation pylons and radial steel roof stays (city source).
static func weegee(model: Node3D) -> void:
	var lm := _materials()
	U.blk(lm, "Concrete", 0, 0, 0, 108, 4.1, 54)
	U.blk(lm, "Glass", 0, 4.1, 0, 108, 5.4, 54)
	U.blk(lm, "Concrete", 0, 9.5, 0, 108.6, 0.5, 54.6)
	for s in [-1.0, 1.0]:
		for k in 49:
			U.blk(lm, "Metal", -54 + float(k) * 2.25, 4.1, s * 27.03, 0.075, 5.4, 0.08)
		for k in 25:
			U.blk(lm, "Metal", s * 54.03, 4.1, -27 + float(k) * 2.25, 0.08, 5.4, 0.075)
		U.blk(lm, "Concrete", 0, 6.55, s * 27.1, 108, 0.22, 0.2)
	for ix in 4:
		for iz in 2:
			var c := Vector3(-40.5 + float(ix) * 27, 0, -13.5 + float(iz) * 27)
			lm.frustum("Concrete", c, 1.5, 1.5, 14, 24)
			lm.frustum("Metal", c + Vector3.UP * 14, 1.33, 1.33, 0.08, 24)
			for dx in [-1.0, 1.0]:
				for dz in [-1.0, 1.0]:
					lm.beam("Metal", c + Vector3.UP * 13.2, c + Vector3(dx * 12.9, 10.1, dz * 12.9), 0.10, 0.10)
				lm.beam("Metal", c + Vector3.UP * 13.2, c + Vector3(dx * 12.9, 10.1, 0), 0.10, 0.10)
	# Recessed entry at the foot of the northern glass facade.
	U.blk(lm, "Metal", 18, 0.15, 27.08, 8, 3.5, 0.12)
	U.blk(lm, "Glass", 18, 0.2, 27.16, 6.8, 3.2, 0.08)
	U.blk(lm, "Concrete", 18, 3.7, 28.6, 9, 0.2, 3)
	lm.commit(model, "WeeGee_")

## Flat modern glazing with mullions, no classical window mouldings.
static func _glass_wall(lm: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3,
		h: float, panes: int) -> void:
	lm.quad("Glass", a, b, b + Vector3.UP * h, a + Vector3.UP * h, out)
	for i in panes + 1:
		lm.beam("Metal", a.lerp(b, float(i) / float(panes)),
			a.lerp(b, float(i) / float(panes)) + Vector3.UP * h, 0.055, 0.07)
	lm.beam("Metal", a, b, 0.06, 0.08)
	lm.beam("Metal", a + Vector3.UP * h, b + Vector3.UP * h, 0.06, 0.08)

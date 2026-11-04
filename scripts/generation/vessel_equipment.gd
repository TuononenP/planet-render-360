class_name VesselEquipment
extends RefCounted

## Ultra fittings use the existing marine palette and batches. No nodes
## or new material surfaces are needed for individual pieces of equipment.

static func ring(lm: LandmarkMesh, key: String, at: Vector3, normal: Vector3, radius: float, thickness: float) -> void:
	var u := normal.cross(Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT).normalized()
	var v := normal.cross(u)
	var path: Array = []
	for i in 17:
		var a := TAU * float(i % 16) / 16.0
		path.append(at + (u * cos(a) + v * sin(a)) * radius)
	HullLoft.tube(lm, key, path, thickness, 6)

static func helm(lm: LandmarkMesh, at: Vector3, scale: float) -> void:
	var r := scale * 0.17
	var centre := at + Vector3(-scale * 0.12, scale * 0.05, 0)
	ring(lm, "Steel", centre, Vector3.LEFT, r, scale * 0.012)
	for i in 3:
		var a := TAU * float(i) / 3.0
		HullLoft.tube(lm, "Steel", [centre, centre + Vector3(0, cos(a), sin(a)) * r], scale * 0.009, 6)
	lm.disc("Dark", centre - Vector3(scale * 0.01, 0, 0), Vector3.LEFT, r * 0.25, 12)
	lm.box("Dark", at + Vector3(scale * 0.02, scale * 0.28, 0), Vector3(scale * 0.06, scale * 0.22, scale * 0.39), Basis(), scale * 0.015)
	lm.box("Glass", at + Vector3(-scale * 0.015, scale * 0.29, 0), Vector3(scale * 0.012, scale * 0.16, scale * 0.29), Basis(), 0.0)
	for side in [-1.0, 1.0]:
		lm.disc("White", at + Vector3(-scale * 0.025, scale * 0.12, float(side) * scale * 0.23), Vector3.LEFT, scale * 0.045, 12)
	HullLoft.tube(lm, "Steel", [at + Vector3(0, -scale * 0.1, scale * 0.32),
		at + Vector3(-scale * 0.07, scale * 0.1, scale * 0.32)], scale * 0.018, 8)

static func ladder(lm: LandmarkMesh, base: Vector3, height: float, width: float) -> void:
	for side in [-1.0, 1.0]:
		HullLoft.tube(lm, "Steel", [base + Vector3(0, 0, float(side) * width * 0.5),
			base + Vector3(0, height, float(side) * width * 0.5)], 0.022, 8)
	var count := maxi(2, int(height / 0.28))
	for i in count:
		var y := height * (float(i) + 0.5) / float(count)
		HullLoft.tube(lm, "Steel", [base + Vector3(0, y, -width * 0.5), base + Vector3(0, y, width * 0.5)], 0.018, 6)

static func line(lm: LandmarkMesh, a: Vector3, b: Vector3, sag: float, radius: float = 0.012) -> void:
	var path: Array = []
	for i in 9:
		var t := float(i) / 8.0
		path.append(a.lerp(b, t) - Vector3.UP * sin(PI * t) * sag)
	HullLoft.tube(lm, "Dark", path, radius, 5)

static func winch(lm: LandmarkMesh, at: Vector3, radius: float) -> void:
	lm.lathe("Steel", at, PackedVector2Array([Vector2(radius, 0), Vector2(radius * 0.65, radius * 0.3),
		Vector2(radius * 0.65, radius * 1.2), Vector2(radius, radius * 1.4), Vector2(radius, radius * 1.55)]), 12)
	ring(lm, "Dark", at + Vector3(0, radius * 0.6, 0), Vector3.UP, radius * 0.7, radius * 0.08)

static func vent(lm: LandmarkMesh, at: Vector3, radius: float) -> void:
	lm.lathe("White", at, PackedVector2Array([Vector2(radius * 0.45, 0), Vector2(radius * 0.45, radius),
		Vector2(radius, radius * 1.1), Vector2(radius, radius * 1.35), Vector2(radius * 0.65, radius * 1.55)]), 12)

static func porthole(lm: LandmarkMesh, at: Vector3, normal: Vector3, radius: float) -> void:
	lm.disc("Glass", at, normal, radius, 20)
	ring(lm, "Steel", at + normal * 0.008, normal, radius, radius * 0.09)

static func life_ring(lm: LandmarkMesh, at: Vector3, normal: Vector3, radius: float) -> void:
	ring(lm, "White", at, normal, radius, radius * 0.22)
	var u := normal.cross(Vector3.UP).normalized()
	for side in [-1.0, 1.0]:
		HullLoft.tube(lm, "Dark", [at + u * radius * float(side) - Vector3.UP * radius * 0.3,
			at + u * radius * float(side) + Vector3.UP * radius * 0.3], radius * 0.08, 5)

## A framed aft-facing access door, with upper glazing and a grab handle.
static func door(lm: LandmarkMesh, at: Vector3, height: float, width: float) -> void:
	lm.box("White", at + Vector3(-0.025, height * 0.5, 0), Vector3(0.05, height, width), Basis(), 0.02)
	lm.box("Dark", at + Vector3(-0.055, height * 0.5, 0), Vector3(0.018, height * 0.92, width * 0.83), Basis(), 0.0)
	lm.box("Glass", at + Vector3(-0.07, height * 0.73, 0), Vector3(0.012, height * 0.3, width * 0.65), Basis(), 0.0)
	HullLoft.tube(lm, "Steel", [at + Vector3(-0.1, height * 0.42, width * 0.3),
		at + Vector3(-0.1, height * 0.56, width * 0.3)], 0.015, 8)

static func chair(lm: LandmarkMesh, at: Vector3) -> void:
	VesselForms.slab(lm, "White", at + Vector3(0, 0.45, 0), Vector3(0.48, 0.08, 0.48), 0.08)
	VesselForms.slab(lm, "White", at + Vector3(-0.2, 0.72, 0), Vector3(0.06, 0.5, 0.48), 0.025)
	for side in [-1.0, 1.0]:
		HullLoft.tube(lm, "Steel", [at + Vector3(-0.2, 0.05, float(side) * 0.19),
			at + Vector3(0.18, 0.43, float(side) * 0.19)], 0.012, 6)
		HullLoft.tube(lm, "Steel", [at + Vector3(0.2, 0.05, float(side) * 0.19),
			at + Vector3(-0.18, 0.43, float(side) * 0.19)], 0.012, 6)

static func deck(lm: LandmarkMesh, spec: Dictionary) -> void:
	var length: float = spec["length"]
	var beam: float = spec["beam"]
	var size := clampf(beam * 0.035, 0.08, 0.22)
	for side in [-1.0, 1.0]:
		var x := length * 0.28
		winch(lm, Vector3(x, HullLoft.sheer(spec, x) + 0.02, float(side) * beam * 0.25), size)
		vent(lm, Vector3(length * 0.19, HullLoft.sheer(spec, length * 0.19), float(side) * beam * 0.31), size * 0.7)
		var aft := Vector3(-length * 0.4, HullLoft.sheer(spec, -length * 0.4) + 0.04, float(side) * beam * 0.38)
		var mid := Vector3(-length * 0.18, HullLoft.sheer(spec, -length * 0.18) + 0.04, float(side) * beam * 0.43)
		line(lm, aft, mid, size * 0.7, size * 0.06)
		life_ring(lm, Vector3(-length * 0.35, HullLoft.sheer(spec, -length * 0.35) + size * 2.5,
			float(side) * beam * 0.43), Vector3(0, 0, float(side)), size * 1.4)

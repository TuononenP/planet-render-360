class_name FtKupittaanPuistoPavilions
extends RefCounted

## Kupittaa Park Pools & Pavilions (Kupittaan maauimala + historic Pyhän
## Henrikin lähde octagonal spring pavilion) in Kupittaanpuisto.
## Origin at 60.444650 N, 22.287600 E, yaw_deg -34.0.
##
## Architectural & facade spec:
## - Main 50 m turquoise outdoor swimming pool + children's pool set in a
##   pale concrete/stone sun-deck terrace (foundation dropped to -1.6 m).
## - White modernist changing-room & café pavilion along the north edge
##   with deep overhanging canopy and warm glazed foyer.
## - Twin turquoise/yellow water-slide tower rising to 10.0 m.
## - Historic octagonal Pyhän Henrikin lähde (St. Henry's Spring) neoclassical
##   pavilion with 8 white columns and conical green-copper roof.

const FOUND := -1.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#DDD8CE", 3.0))
	lm.use("Water", LandmarkMaterials.lit("#44B8CC", 0.55))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#F2EFE8", 2.5))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#A87B50", 2.0))
	lm.use("Copper", LandmarkFrKit.copper("#487464"))
	lm.use("Slide", LandmarkMaterials.paint("#2E8CA8", 0.35, 0.25))
	lm.use("Steel", LandmarkMaterials.paint("#C8CDD0", 0.4, 0.7))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE2A4", 0.9))

	# Sun-deck terrace slab (56 x 40 m).
	LandmarkFrKit.rect(lm, "Deck", -28.0, 28.0, -20.0, 20.0, FOUND, 0.45)
	# Main 25x14 m turquoise outdoor pool + children's splash pool.
	LandmarkFrKit.rect(lm, "Water", -16.0, 10.0, -4.0, 12.0, 0.44, 0.56)
	LandmarkFrKit.rect(lm, "Water", 12.5, 22.5, 2.0, 12.0, 0.44, 0.56)
	# Pool lane dividers.
	for i in 4:
		var z := lerpf(-1.0, 9.0, float(i) / 3.0)
		lm.box("Wall", Vector3(-3.0, 0.60, z), Vector3(25.2, 0.08, 0.14), Basis(), 0.0)

	# Modernist changing-room & café pavilion (-Z edge, 36 x 9 m, h = 4.8 m).
	LandmarkFrKit.rect(lm, "Wall", -18.0, 18.0, -18.5, -9.5, 0.45, 4.4)
	LandmarkFrKit.rect(lm, "Wood", -19.2, 19.2, -19.2, -7.8, 4.35, 4.85)
	for i in 8:
		var x := lerpf(-15.0, 15.0, float(i) / 7.0)
		lm.box("WarmGlow", Vector3(x, 2.4, -9.46), Vector3(2.8, 2.6, 0.08), Basis(), 0.0)
		lm.frustum("Steel", Vector3(x, 0.45, -8.2), 0.12, 0.12, 3.95, 8)

	# Water-slide tower (+X/+Z corner, peaking at 10.0 m).
	var sx := 23.0
	var sz := -7.5
	for cx: float in [-1.4, 1.4]:
		for cz: float in [-1.4, 1.4]:
			lm.frustum("Steel", Vector3(sx + cx, 0.45, sz + cz), 0.14, 0.14, 9.55, 8)
	LandmarkFrKit.rect(lm, "Deck", sx - 1.8, sx + 1.8, sz - 1.8, sz + 1.8, 7.6, 7.95)
	lm.frustum("Copper", Vector3(sx, 8.6, sz), 2.4, 0.15, 1.4, 4)
	# Curved slide chute descending into the children's pool.
	for s in 8:
		var t0 := float(s) / 8.0
		var t1 := float(s + 1) / 8.0
		var a0 := t0 * PI * 1.1
		var a1 := t1 * PI * 1.1
		var p0 := Vector3(sx - 2.0 - sin(a0) * 3.8, lerpf(7.6, 1.2, t0), sz + 2.5 + (1.0 - cos(a0)) * 4.2)
		var p1 := Vector3(sx - 2.0 - sin(a1) * 3.8, lerpf(7.6, 1.2, t1), sz + 2.5 + (1.0 - cos(a1)) * 4.2)
		var mid := (p0 + p1) * 0.5
		var dir := (p1 - p0).normalized()
		var b := Basis.looking_at(dir, Vector3.UP)
		lm.box("Slide", mid, Vector3(1.15, 0.55, p0.distance_to(p1) + 0.15), b, 0.0)

	# Historic octagonal St. Henry's Spring (Pyhän Henrikin lähde) pavilion (-X = -22, +Z = 14).
	var px := -22.0
	var pz := 13.5
	lm.frustum("Deck", Vector3(px, FOUND, pz), 4.4, 4.2, 0.9 - FOUND, 8)
	for i in 8:
		var a := TAU * float(i) / 8.0
		lm.frustum("Wall", Vector3(px + cos(a) * 3.2, 0.9, pz + sin(a) * 3.2), 0.20, 0.18, 3.6, 10)
	lm.frustum("Wall", Vector3(px, 4.5, pz), 3.7, 3.8, 0.55, 8)
	lm.frustum("Copper", Vector3(px, 5.05, pz), 4.1, 0.15, 2.35, 8)
	lm.commit(model)

	var warm := Color(1.0, 0.90, 0.74)
	var aqua := Color(0.55, 0.90, 1.0)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.0, -4.0), Vector3(0.0, 3.5, -10.0), 28.0, 0.85, 65.0, warm],
		[Vector3(-3.0, 2.0, 4.0), Vector3(-3.0, 0.4, 4.0), 24.0, 0.75, 80.0, aqua],
		[Vector3(-22.0, 1.0, 19.0), Vector3(-22.0, 4.2, 13.5), 18.0, 0.85, 55.0, warm],
	])

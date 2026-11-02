class_name LandmarkFhHelsinkiModern
extends RefCounted

## Four modern buildings in true metres: Kiasma (Steven Holl, curved
## aluminium-and-glass volumes), the Oodi library (ALA, timber belly under
## a steel arch), Dipoli (Reima and Raili Pietilä, copper lobes on boulders)
## and the Heureka science centre. Footprints are the OpenStreetMap
## outlines in the model frame the registry yaw turns onto the map.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

# --- Kiasma ---------------------------------------------------------------

## Holl's museum of contemporary art (1998), origin at the OSM footprint
## centre, front +Z (the registry yaw turns it onto Mannerheimintie): two
## long bars meeting at an angle, wrapped in aluminium and green-tinted
## glass bands, the northern bar topped by a roof that falls to the south.
static func kiasma(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Alu", LandmarkMaterials.pbr("concrete", "#B9BEC1", 3.0, 0.35, 0.6))
	lm.use("Glass", LandmarkMaterials.glass("#2F4F4A"))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#8E9396", 3.0, 0.45, 0.5))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	var foot := PackedVector2Array([Vector2(55.1, 18.5), Vector2(52.0, 29.3), Vector2(-21.6, 7.5),
		Vector2(-49.5, 19.8), Vector2(-63.3, -5.3), Vector2(-26.4, -11.8), Vector2(4.1, -12.8),
		Vector2(56.4, 2.2), Vector2(52.8, 15.9), Vector2(55.6, 16.7)])
	lm.poly_prism("Alu", foot, 0.0, 19.0)
	# Glazed bands round every long facade, four storeys.
	for i in foot.size():
		var a := foot[i]
		var b := foot[(i + 1) % foot.size()]
		if a.distance_to(b) > 9.0:
			FhU.wall_run(lm, "Glass", a.lerp(b, 0.06), a.lerp(b, 0.94), Vector2(0, 3), 1.6, 4, 4.4,
				int(a.distance_to(b) * 0.88 / 4.2), 3.3, 2.6)
	# Roof of the northern bar rising to the back, and the southern bar's cap.
	FhU.wedge(lm, "Roof", "Roof", -50.0, 50.0, -12.0, 3.0, 19.0, 7.0, 2.0)
	lm.poly_prism("Roof", PackedVector2Array([Vector2(51.0, 27.6), Vector2(-19.5, 9.8), Vector2(-19.5, 3.5),
		Vector2(51.0, 3.5)]), 19.0, 22.5)
	FhU.blk(lm, "Plinth", 52.0, 0.0, 10.0, 6.0, 1.2, 36.0)
	lm.commit(model)

# --- Oodi ---------------------------------------------------------------

## Helsinki Central Library Oodi (ALA, 2018), origin at the OSM footprint
## centre, x along the 149 m long axis (north to south), front +Z on the
## Kansalaistori side: the open glazed ground floor, the spruce-clad
## "bridge" volume with its overhanging canopy and the great steel arch on
## the end facade.
static func oodi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#2E3F44"))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#C5A06A", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#8A8D8E", 3.0, 0.5, 0.4))
	lm.use("Steel", LandmarkMaterials.paint("#E4E6E6", 0.45, 0.4))
	lm.use("Floor", LandmarkMaterials.pbr("concrete", "#9C9A94", 3.0))
	var foot := PackedVector2Array([Vector2(90.1, -8.2), Vector2(103.6, 12.5), Vector2(51.9, 25.6),
		Vector2(44.6, 26.3), Vector2(-45.2, 12.2), Vector2(-45.2, -19.5), Vector2(83.2, -19.2)])
	# Ground floor set back from the long sides, so the timber "bridge" overhangs it.
	var cen := Vector2(28.0, 3.0)
	var low := PackedVector2Array()
	for p in foot:
		low.append(cen + Vector2((p.x - cen.x) * 0.97, (p.y - cen.y) * 0.84))
	lm.poly_prism("Glass", low, 0.0, 5.2)
	for k in 12:
		var t := float(k) / 11.0
		lm.box("Steel", Vector3(lerpf(-43.0, 43.0, t), 2.9, lerpf(12.4, 25.6, t) - 0.6), Vector3(0.6, 5.8, 0.6))
	lm.poly_prism("Floor", foot, 5.0, 5.8)
	lm.poly_prism("Wood", foot, 5.8, 17.4)
	lm.poly_prism("Roof", foot, 17.4, 18.2)
	# Window bands round the timber volume.
	for i in foot.size():
		var a := foot[i]
		var b := foot[(i + 1) % foot.size()]
		if a.distance_to(b) > 12.0:
			FhU.wall_run(lm, "Glass", a.lerp(b, 0.05), a.lerp(b, 0.95), Vector2(20, 0), 8.0, 2, 4.6,
				int(a.distance_to(b) * 0.9 / 5.0), 3.4, 2.4)
	# The steel arch across the north end, spanning the full 32 m width.
	var zc := -3.65
	var prev := Vector3(-45.6, 0.0, zc - 15.85)
	for k in range(1, 17):
		var u := -1.0 + 2.0 * float(k) / 16.0
		var p := Vector3(-45.6, 19.5 * (1.0 - u * u), zc + u * 15.85)
		lm.beam("Steel", prev, p, 1.3, 1.4, Vector3.RIGHT)
		prev = p
	for k in 7:
		var u := -0.75 + 0.25 * float(k)
		lm.beam("Steel", Vector3(-45.6, 0.0, zc + u * 15.85),
				Vector3(-45.6, 19.5 * (1.0 - u * u), zc + u * 15.85), 0.35, 0.5, Vector3.RIGHT)
	lm.commit(model)

# --- Dipoli ----------------------------------------------------------------

## Reima and Raili Pietilä's Dipoli (1966), origin at the OSM footprint
## centre (registry yaw 17): boulder-and-concrete walls under copper-clad
## roof lobes that climb from the ground to 10 m, with copper roof
## lanterns up to 11 m.
static func dipoli(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("cliff", "#8A8478", 4.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#8E6B47", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#7A8A70", 2.5, 0.5, 0.45))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A3A19B", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	var foot := PackedVector2Array([Vector2(15.0, -22.0), Vector2(30.1, -39.9), Vector2(32.9, -30.1),
		Vector2(41.4, -20.6), Vector2(36.7, -13.2), Vector2(38.9, -9.1), Vector2(44.9, -11.7),
		Vector2(39.8, -3.5), Vector2(41.6, 9.9), Vector2(34.4, 10.5), Vector2(26.6, 18.4),
		Vector2(20.4, 35.3), Vector2(21.4, 44.7), Vector2(12.7, 43.0), Vector2(4.3, 49.5),
		Vector2(-3.4, 26.6), Vector2(-17.9, 27.8), Vector2(-23.9, 31.5), Vector2(-25.3, 41.0),
		Vector2(-32.6, 43.2), Vector2(-46.6, 34.9), Vector2(-47.7, 9.9), Vector2(-36.7, 15.6),
		Vector2(-40.4, 9.0), Vector2(-36.1, 5.7), Vector2(-31.9, -15.7), Vector2(-45.9, -15.7),
		Vector2(-47.2, -29.2), Vector2(-32.8, -26.5), Vector2(-39.4, -39.6), Vector2(-18.8, -36.8),
		Vector2(-13.8, -36.8), Vector2(7.1, -39.8), Vector2(7.1, -22.0)])
	lm.poly_prism("Stone", foot, 0.0, 3.2)
	var inner := PackedVector2Array()
	for p in foot:
		inner.append(p * 0.9 + Vector2(-1.0, 1.0))
	lm.poly_prism("Wood", inner, 3.2, 5.2, false)
	lm.poly_prism("Copper", inner, 5.2, 5.7)
	# Copper-clad lobes [x, z, rx, rz, height above the 5.4 m wall top].
	for l in [[0.0, 12.0, 32.0, 21.0, 4.6], [-32.0, -4.0, 15.0, 12.0, 2.7], [14.0, -18.0, 15.0, 10.0, 2.2],
			[28.0, -26.0, 10.0, 8.0, 1.8], [-20.0, -29.0, 12.0, 8.0, 2.1], [31.0, 12.0, 10.0, 10.0, 2.5],
			[-30.0, 30.0, 13.0, 9.0, 2.4], [9.0, 38.0, 10.0, 8.0, 2.0]]:
		lm.lathe("Copper", Vector3(float(l[0]), 5.4, float(l[1])), FhU.dome_prof(1.0, float(l[4]), 8), 18,
			float(l[2]), float(l[3]))
	# Copper roof lanterns and chimneys.
	for q in [Vector2(-5, 10), Vector2(12, 18), Vector2(-20, 3), Vector2(30, 10), Vector2(-28, -6), Vector2(5, 34)]:
		lm.box("Copper", Vector3(q.x, 10.3, q.y), Vector3(2.2, 1.4, 2.2))
	for q in [Vector2(-5, 10), Vector2(12, 18)]:
		lm.box("Concrete", Vector3(q.x, 9.7, q.y), Vector3(1.4, 0.4, 1.4))
	# Irregular window slits in the wood band.
	for i in foot.size():
		var a := foot[i]
		var b := foot[(i + 1) % foot.size()]
		if a.distance_to(b) > 10.0:
			FhU.wall_run(lm, "Glass", a.lerp(b, 0.15), a.lerp(b, 0.85), Vector2(0, 5), 1.1, 1, 3.0,
				int(a.distance_to(b) * 0.7 / 6.0), 2.2, 2.4)
	lm.commit(model)

# --- Heureka ---------------------------------------------------------------

## Heikkinen-Komonen's science centre in Tikkurila (1989), origin at the
## OSM footprint centre (registry yaw 15): the white exhibition bars round
## the 33 m concrete rotunda with its glazed roof, the mirror-clad dome of
## the 2016 extension and the coloured cubes on the facade.
static func heureka(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E8E6E0", 3.0))
	lm.use("Drum", LandmarkMaterials.pbr("concrete", "#C9C7C0", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2F4A55"))
	lm.use("Mirror", LandmarkMaterials.pbr("concrete", "#B8C0C6", 3.0, 0.15, 0.9))
	lm.use("Red", LandmarkMaterials.paint("#C23A32", 0.5, 0.2))
	lm.use("Yellow", LandmarkMaterials.paint("#E4B83A", 0.5, 0.2))
	lm.use("Blue", LandmarkMaterials.paint("#2E5FA8", 0.5, 0.2))
	# Exhibition bars: east bar, south wing, west bar and the lobby.
	FhU.blk(lm, "Wall", 27.0, 0.0, -4.0, 34.0, 12.0, 80.0)
	FhU.blk(lm, "Wall", -4.5, 0.0, -4.5, 29.0, 7.0, 79.0)
	FhU.blk(lm, "Wall", 8.0, 0.0, 50.0, 72.0, 10.0, 30.0)
	FhU.blk(lm, "Wall", -32.0, 0.0, -4.0, 26.0, 8.0, 76.0)
	FhU.blk(lm, "Wall", -22.0, 0.0, -48.0, 28.0, 7.0, 12.0)
	# The rotunda: 33 m concrete drum, ring of glazing and a glass roof cone.
	var rc := Vector3(8.65, 0.0, -16.4)
	lm.frustum("Drum", rc, 16.5, 16.5, 20.0, 28)
	lm.frustum("Glass", rc + Vector3(0, 20.0, 0), 16.2, 16.2, 0.8, 28)
	lm.lathe("Glass", rc + Vector3(0, 20.8, 0), PackedVector2Array([Vector2(16.0, 0), Vector2(10.0, 0.7),
		Vector2(0.0, 1.2)]), 28)
	for k in 14:
		var a := TAU * float(k) / 14.0
		FhU.opening(lm, "Glass", rc + Vector3(cos(a) * 16.55, 12.0, sin(a) * 16.55), Vector3(cos(a), 0, sin(a)),
				4.0, 5.0, false)
	# Mirror-clad dome of the extension.
	var mc := Vector3(-30.2, 0.0, -4.3)
	lm.frustum("Mirror", mc, 8.5, 8.5, 6.5, 24)
	lm.lathe("Mirror", mc + Vector3(0, 6.5, 0), FhU.dome_prof(8.5, 8.5, 10), 24)
	# Windows and the coloured cubes hanging on the east and south faces.
	FhU.window_grid(lm, "Glass", Vector3(44.1, 0, -40.0), Vector3(44.1, 0, 32.0), Vector3(1, 0, 0), 2.5, 2, 4.0,
			12, 3.0, 2.4)
	FhU.window_grid(lm, "Glass", Vector3(-26.0, 0, 65.1), Vector3(40.0, 0, 65.1), Vector3(0, 0, 1), 2.5, 2, 3.8,
			12, 3.0, 2.2)
	lm.box("Red", Vector3(44.9, 8.5, -14.0), Vector3(3.0, 3.0, 3.0))
	lm.box("Yellow", Vector3(44.9, 6.0, 10.0), Vector3(3.0, 3.0, 3.0))
	lm.box("Blue", Vector3(44.9, 9.0, 28.0), Vector3(3.0, 3.0, 3.0))
	lm.box("Red", Vector3(30.0, 7.5, 65.9), Vector3(3.0, 3.0, 3.0))
	lm.box("Yellow", Vector3(10.0, 6.5, 65.9), Vector3(3.0, 3.0, 3.0))
	lm.commit(model)

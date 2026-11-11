class_name LandmarkTsShibuyaTowers
extends RefCounted

## Shibuya's station towers in true metres on LandmarkMesh, each built in
## the frame of its OSM footprint (registry yaw_deg) about the footprint's
## area centroid, y = 0 at the street. Plans are the OSM outlines,
## simplified; setbacks and crowns follow photographs (sources in
## docs/tokyo-seoul-landmark-sources.md). Glass curtain walls carry floor
## bands and mullions so the floors read at distance.

## Shibuya Scramble Square (2019, Nikken Sekkei, SANAA, Kengo Kuma and
## Jun Aoki): 229.7 m over Shibuya Station. A podium filling the 60 x 69 m
## OSM footprint to 48 m, the tower stepping in at 150 m and 200 m, the
## lighter-glazed Sky Gallery floors under the roof, and the open rooftop
## deck (Shibuya Sky) ringed by its full-height glass edge, with the
## rooftop frame round the central deck.
static func scramble_square(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", glass("#6F8FA6"))
	lm.use("Frame", LandmarkMaterials.paint("#D3D7DA", 0.4, 0.6))
	lm.use("Stone", LandmarkMaterials.pbr("concrete", "#9E9C97", 3.0))
	lm.use("Gallery", glass("#A9C6D6"))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#7C7F82", 4.0))
	lm.use("Lit", LandmarkMaterials.lit("#FFF4DC", 0.5))
	# Podium on the station, its plinth and the ledge at 48 m.
	lm.poly_prism("Stone", rect(-30.4, -34.8, 30.9, 35.3), 0.0, 1.2)
	curtain(lm, "Glass", "Frame", rect(-30.0, -34.4, 30.5, 34.9), 1.2, 48.0, 5.2, 4.5)
	lm.poly_prism("Frame", rect(-30.6, -35.0, 31.1, 35.5), 47.4, 48.4)
	# Tower shaft, two setbacks, Sky Gallery band.
	curtain(lm, "Glass", "Frame", rect(-26.0, -30.5, 26.5, 31.0), 48.4, 150.0, 4.6, 4.5)
	lm.poly_prism("Frame", rect(-26.4, -30.9, 26.9, 31.4), 149.4, 150.4)
	curtain(lm, "Glass", "Frame", rect(-24.5, -28.0, 25.0, 28.5), 150.4, 200.0, 4.6, 4.5)
	lm.poly_prism("Frame", rect(-24.9, -28.4, 25.4, 28.9), 199.4, 200.4)
	curtain(lm, "Glass", "Frame", rect(-23.0, -25.5, 23.5, 26.0), 200.4, 214.0, 4.6, 4.5)
	curtain(lm, "Gallery", "Frame", rect(-23.0, -25.5, 23.5, 26.0), 214.0, 226.4, 6.2, 2.0)
	# Shibuya Sky: the roof deck, the glass edge on slim posts, a lit
	# strip at its foot, and the rooftop frame round the central deck.
	var deck := rect(-23.6, -26.1, 24.1, 26.6)
	lm.poly_prism("Deck", deck, 226.4, 227.9)
	var edge := rect(-23.2, -25.7, 23.7, 26.2)
	for i in 4:
		var a := edge[i]
		var b := edge[(i + 1) % 4]
		var n := Vector2(b.y - a.y, a.x - b.x).normalized()
		lm.quad("Gallery", Vector3(a.x, 227.9, a.y), Vector3(b.x, 227.9, b.y), Vector3(b.x, 229.7, b.y),
			Vector3(a.x, 229.7, a.y), Vector3(n.x, 0, n.y))
		var posts := int(a.distance_to(b) / 2.0)
		for k in posts + 1:
			var p := a.lerp(b, float(k) / float(posts))
			lm.box("Frame", Vector3(p.x, 228.75, p.y), Vector3(0.12, 1.7, 0.12), Basis(), 0.0)
		lm.box("Lit", Vector3((a.x + b.x) * 0.5, 228.0, (a.y + b.y) * 0.5) - Vector3(n.x, 0, n.y) * 0.3,
			Vector3(a.distance_to(b), 0.12, 0.2), _edge_basis(a, b), 0.0)
	var ring := rect(-15.0, -17.0, 15.5, 17.5)
	for i in 4:
		var a := ring[i]
		var b := ring[(i + 1) % 4]
		lm.box("Frame", Vector3((a.x + b.x) * 0.5, 229.3, (a.y + b.y) * 0.5), Vector3(a.distance_to(b) + 0.6, 0.6, 0.6),
			_edge_basis(a, b), 0.0)
		var posts := int(a.distance_to(b) / 6.0)
		for k in posts:
			var p := a.lerp(b, float(k) / float(posts))
			lm.box("Frame", Vector3(p.x, 228.6, p.y), Vector3(0.5, 1.4, 0.5), Basis(), 0.0)
	lm.poly_prism("Deck", rect(-9.0, -9.0, 9.5, 9.5), 227.9, 228.1)
	lm.commit(model)

## Shibuya Hikarie (2012, Nikken Sekkei / Tokyu Architects): 182.5 m. The
## OSM footprint's three parts: the deck arm east to Miyamasuzaka, the
## nine-storey east block, and the tower plot, where the shopping and
## theatre floors rise as five stacked, outward-stepping layers to the
## dark sky-lobby band, and the office tower above carries the white
## vertical stripes up to its screened crown.
static func hikarie(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", glass("#71889A"))
	lm.use("Frame", LandmarkMaterials.paint("#E4E6E6", 0.45, 0.4))
	lm.use("Band", LandmarkMaterials.paint("#8E969B", 0.5, 0.5))
	lm.use("Stone", LandmarkMaterials.pbr("concrete", "#B9B5AC", 3.0))
	lm.use("Lobby", LandmarkMaterials.glass("#1E2A33"))
	# Deck arm and the east block (OSM building:part, 9 storeys).
	lm.poly_prism("Stone", rect(66.0, -21.0, 118.0, -9.0), 0.0, 9.0)
	lm.box("Lobby", Vector3(92.0, 5.0, -8.95), Vector3(50.0, 4.0, 0.1), Basis(), 0.0)
	var east := PackedVector2Array([Vector2(16.6, 31.3), Vector2(22.3, 31.4), Vector2(24.6, 29.0),
		Vector2(22.3, 5.0), Vector2(65.5, -11.0), Vector2(66.2, -22.5), Vector2(16.9, -24.7)])
	curtain(lm, "Glass", "Band", east, 0.0, 40.0, 4.4, 4.0)
	# Five stacked layers, each a little wider than the one below.
	var flare := [0.0, 1.0, 2.0, 3.0, 2.0]
	for k in 5:
		var f: float = flare[k]
		var y0 := 14.4 * k
		var plan := rect(-64.0 - f, -24.0 - f, 16.6 + f, 30.0 + f)
		curtain(lm, "Glass", "Band", plan, y0, y0 + 13.6, 4.5, 4.5)
		lm.poly_prism("Band", rect(-64.6 - f, -24.6 - f, 17.2 + f, 30.6 + f), y0 + 13.6, y0 + 14.4)
	# Sky lobby, office tower and crown screen.
	lm.poly_prism("Lobby", rect(-60.0, -21.0, 12.0, 27.0), 72.0, 77.0)
	curtain(lm, "Glass", "Frame", rect(-58.0, -19.0, 10.0, 25.0), 77.0, 179.5, 4.2, 3.6)
	var crown := rect(-58.0, -19.0, 10.0, 25.0)
	for i in 4:
		var a := crown[i]
		var b := crown[(i + 1) % 4]
		lm.box("Frame", Vector3((a.x + b.x) * 0.5, 181.0, (a.y + b.y) * 0.5), Vector3(a.distance_to(b) + 0.4, 3.0, 0.4),
			_edge_basis(a, b))
	lm.commit(model)

## Shibuya Stream (2018, Tokyu Sekkei / CAt): 180 m (OSM 179.95) on the
## Shibuya River. The podium fills the OSM footprint, the slab tower over
## its west end wears a white grid, and an open screen crowns it.
static func stream(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", glass("#7A8C99"))
	lm.use("Frame", LandmarkMaterials.paint("#EDEDEA", 0.5, 0.2))
	lm.use("Stone", LandmarkMaterials.pbr("concrete", "#A9A69F", 3.0))
	var podium := PackedVector2Array([Vector2(-46.4, 25.5), Vector2(-46.3, -20.0), Vector2(56.4, -19.8),
		Vector2(50.2, 9.8), Vector2(10.7, 20.0)])
	lm.poly_prism("Stone", podium, 0.0, 1.0)
	curtain(lm, "Glass", "Frame", podium, 1.0, 22.0, 5.0, 3.0)
	var tower := rect(-40.0, -18.0, 30.0, 6.0)
	curtain(lm, "Glass", "Frame", tower, 22.0, 176.0, 4.4, 3.0)
	for i in 4:
		var a := tower[i]
		var b := tower[(i + 1) % 4]
		lm.box("Frame", Vector3((a.x + b.x) * 0.5, 178.0, (a.y + b.y) * 0.5), Vector3(a.distance_to(b) + 0.4, 4.0, 0.4),
			_edge_basis(a, b))
	lm.commit(model)

## Curtain-wall glass: the calibrated PBR the city towers use, light
## enough to read as glazing against the sky (LandmarkMaterials.glass is
## the near-black of small windows).
static func glass(hex: String) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("concrete", hex, 4.0, 0.22, 0.4)

## Axis rectangle x0..x1 by z0..z1, counter-clockwise from (x0, z0).
static func rect(x0: float, z0: float, x1: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)])

## Curtain wall over `poly` from y0 to y1: the glazed prism (top capped),
## a spandrel band every `floor_h` metres and mullions every `mullion_m`
## along each edge, both on the `frame` key.
static func curtain(lm: LandmarkMesh, glass: String, frame: String, poly: PackedVector2Array, y0: float, y1: float,
		floor_h: float, mullion_m: float) -> void:
	lm.poly_prism(glass, poly, y0, y1)
	var floors := int((y1 - y0) / floor_h)
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var length := a.distance_to(b)
		if length < 0.5:
			continue
		var basis := _edge_basis(a, b)
		var mid := (a + b) * 0.5
		for k in range(1, floors + 1):
			var y := y0 + floor_h * k
			if y > y1 - 0.4:
				break
			lm.box(frame, Vector3(mid.x, y, mid.y), Vector3(length + 0.3, 0.55, 0.35), basis, 0.0)
		var cuts := int(length / mullion_m)
		for m in range(1, cuts):
			var p := a.lerp(b, float(m) / float(cuts))
			lm.beam(frame, Vector3(p.x, y0, p.y), Vector3(p.x, y1, p.y), 0.18, 0.35, Vector3(b.x - a.x, 0, b.y - a.y))

## Basis whose X runs along the plan edge a -> b.
static func _edge_basis(a: Vector2, b: Vector2) -> Basis:
	var d := Vector3(b.x - a.x, 0, b.y - a.y).normalized()
	return Basis(d, Vector3.UP, d.cross(Vector3.UP).normalized())

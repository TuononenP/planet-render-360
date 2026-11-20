class_name FtSibeliusMuseum
extends RefCounted

## Sibelius Museum (Sibelius-museo, 1968, Woldemar Baeckman):
## Celebrated brutalist board-formed concrete architectural jewel on
## Piispankatu 17 (+X ENE, +Z SSE toward Piispankatu, -Z NNW toward Aurajoki,
## turned by yaw_deg = -28.0°, height_m = 8.5):
##   - Low horizontal board-formed concrete gallery perimeter (48 x 44 m,
##     H 5.6 m) with crisp cantilevered roof fascia, deep concrete shadow
##     reveals, and recessed entrance colonnade facing Piispankatu (+Z).
##   - Glazed interior courtyard atrium with exposed concrete mullions and
##     warm illuminated exhibition galleries visible through the glass.
##   - Signature sweeping hyperbolic-paraboloid (hypar) concrete shell roof
##     rising over the central Sibelius Hall concert auditorium (to 8.6 m),
##     flanked by clerestory glazing bands.
## Surfaces: 6 merged PBR parts (Concrete, ConcreteDark, Stone, Frame,
## Glass, Lamp).

const FOUND := -1.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C9C5BC", 2.8, 0.82))
	lm.use("ConcreteDark", LandmarkMaterials.pbr("concrete", "#8E8B84", 2.5, 0.85))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#787672", 2.4))
	lm.use("Frame", LandmarkMaterials.paint("#2A2E33", 0.45, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#253642"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFEAC0", 1.35))

	# Stone plinth & low horizontal board-formed concrete museum block (48 x 42 m, H 5.5 m).
	LandmarkFrKit.rect(lm, "Stone", -24.4, 24.4, -21.4, 21.4, FOUND, 0.45)
	# Perimeter gallery walls wrapping central atrium & concert hall.
	LandmarkFrKit.rect(lm, "Concrete", -24.0, 24.0, -21.0, 21.0, 4.35, 5.55)
	LandmarkFrKit.rect(lm, "ConcreteDark", -23.6, 23.6, -20.6, 20.6, 5.55, 5.80)
	# Solid horizontal board-formed concrete flanks on -X, +X, and -Z river wing.
	LandmarkFrKit.rect(lm, "Concrete", -24.0, -14.5, -21.0, 21.0, 0.45, 4.4)
	LandmarkFrKit.rect(lm, "Concrete", 14.5, 24.0, -21.0, 21.0, 0.45, 4.4)
	LandmarkFrKit.rect(lm, "Concrete", -14.5, 14.5, -21.0, -13.5, 0.45, 4.4)
	# Vertical board-form relief ribs along the brutalist concrete walls.
	for k in 17:
		var rx := lerpf(-23.0, 23.0, float(k) / 16.0)
		lm.box("ConcreteDark", Vector3(rx, 4.95, 21.06), Vector3(0.14, 1.15, 0.14))
		lm.box("ConcreteDark", Vector3(rx, 2.95, -21.06), Vector3(0.14, 5.0, 0.14))
	for k in 15:
		var rz := lerpf(-20.0, 20.0, float(k) / 14.0)
		lm.box("ConcreteDark", Vector3(-24.06, 2.95, rz), Vector3(0.14, 5.0, 0.14))
		lm.box("ConcreteDark", Vector3(24.06, 2.95, rz), Vector3(0.14, 5.0, 0.14))
	# Recessed glazed entrance facade & colonnade on Piispankatu (+Z = +18..+21).
	LandmarkFrKit.rect(lm, "Glass", -14.5, 14.5, 17.6, 17.8, 0.45, 4.35)
	LandmarkFrKit.rect(lm, "Lamp", -13.6, 13.6, 16.4, 16.8, 0.85, 4.05)
	for k in 13:
		var mx := lerpf(-14.2, 14.2, float(k) / 12.0)
		lm.box("Frame", Vector3(mx, 2.4, 17.82), Vector3(0.14, 3.9, 0.22))
	for px: float in [-11.5, -5.8, 0.0, 5.8, 11.5]:
		lm.box("Concrete", Vector3(px, 2.4, 20.4), Vector3(0.42, 4.0, 0.42))
	# Sweeping hyperbolic-paraboloid (hypar) concrete shell roof over Sibelius Hall (to 8.6 m).
	var nx := 12
	var nz := 12
	var hx := 12.5
	var hz := 11.5
	var z_off := -1.5
	var rows: Array = []
	for j in nz + 1:
		var v := lerpf(-1.0, 1.0, float(j) / float(nz))
		var row := PackedVector3Array()
		for i in nx + 1:
			var u := lerpf(-1.0, 1.0, float(i) / float(nx))
			# Authentic saddle / hyperbolic-paraboloid double-curved shell surface.
			var y := 7.1 + 1.45 * (u * u - v * v * 0.65) + 0.55 * (1.0 - v * v)
			row.append(Vector3(u * hx, y, z_off + v * hz))
		rows.append(row)
	lm.grid("Concrete", rows, Vector3.UP)
	# Clerestory glazing ribbon & concrete edge beams beneath the hypar shell perimeter.
	LandmarkFrKit.rect(lm, "Glass", -11.8, 11.8, z_off - 10.8, z_off + 10.8, 5.55, 7.15)
	LandmarkFrKit.rect(lm, "Lamp", -10.8, 10.8, z_off - 9.8, z_off + 9.8, 5.75, 6.95)
	for k in 9:
		var cx := lerpf(-11.6, 11.6, float(k) / 8.0)
		lm.box("Frame", Vector3(cx, 6.35, z_off + 10.85), Vector3(0.14, 1.6, 0.16))
		lm.box("Frame", Vector3(cx, 6.35, z_off - 10.85), Vector3(0.14, 1.6, 0.16))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.2, 26.5), Vector3(0.0, 3.8, 18.0), 66.0, 0.85, 34.0, Color(1.0, 0.90, 0.74)],
		[Vector3(0.0, 6.0, -18.0), Vector3(0.0, 7.8, -1.5), 62.0, 0.75, 32.0, Color(0.95, 0.94, 0.90)],
	])

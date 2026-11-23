class_name LandmarkMiBacardi
extends RefCounted

## Bacardi Building & Jewel Box (National YoungArts Campus) — Midtown/Edgewater MI-2A.7
## Site: 2100 Biscayne Blvd, OSM way 454144052 (25.797335, -80.189586, yaw_deg -0.9).
## Architects: Enrique Gutiérrez (1963 Tower) & Ignacio Carrera-Justiz (1973 Jewel Box Annex).
## Measured envelope & materials (Commons front/quarter/side, height_m = 38.0):
##   - Raised travertine sculpture plaza (y = 0..1.4 m) edged by a cobalt-blue glazed tile wall.
##   - 1963 8-storey Bacardi Tower (y = 0..38.0 m, 44 x 16 m slab elevated on 4 monumental white
##     structural piers & roof trusses): North/South dark-tinted curtain walls with crisp white
##     sun-fins & top perforated mechanical bay, and iconic East/West end walls patterned with
##     procedural cobalt-blue (#1D4E8F), turquoise (#2C82B5) & white azulejo geometric panels.
##   - 1973 cantilevered square "Jewel Box" annex (18 x 18 m, y = 5.5..16.5 m) perched on a warm
##     terracotta-ochre central pedestal core at Vector3(28, 0, 10), wrapped in multifaceted
##     stained-glass jewel panels (lit/glass in amber, ruby, sapphire, and teal).

const HEIGHT_M := 38.0
const TOWER_C := Vector3(-10.0, 0.0, -7.0)
const JEWEL_C := Vector3(28.0, 0.0, 10.0)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F5F5F2", 3.5))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#DFD8CA", 3.2))
	lm.use("Glass", LandmarkMaterials.glass("#1A2936"))
	lm.use("Steel", LandmarkMaterials.paint("#2E3338", 0.38, 0.62))
	lm.use("CobaltTile", LandmarkMaterials.pbr("slate", "#1D4E8F", 1.8, 0.18, 0.08))
	lm.use("TurquoiseTile", LandmarkMaterials.pbr("slate", "#2C82B5", 1.8, 0.20, 0.06))
	lm.use("PedestalOchre", LandmarkMaterials.pbr("render", "#C25E1A", 2.8))
	lm.use("AmberLamp", LandmarkMaterials.lit("#E89B25", 0.65))
	lm.use("RubyLamp", LandmarkMaterials.lit("#B8292F", 0.60))
	lm.use("SapphireLamp", LandmarkMaterials.lit("#1E5AA8", 0.60))
	lm.use("TealLamp", LandmarkMaterials.lit("#228B94", 0.60))

	_build_travertine_plaza(lm)
	_build_bacardi_tower(lm)
	_build_jewel_box(lm)
	lm.commit(model)

	var crisp := Color(0.92, 0.96, 1.0)
	var warm := Color(1.0, 0.86, 0.62)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(24.0, 1.8, -7.0), Vector3(12.0, 22.0, -7.0), 48.0, 1.25, 42.0, crisp],
		[Vector3(-44.0, 1.8, -7.0), Vector3(-32.0, 22.0, -7.0), 48.0, 1.25, 42.0, crisp],
		[Vector3(-10.0, 1.8, 16.0), Vector3(-10.0, 22.0, -1.0), 54.0, 1.05, 48.0, crisp],
		[Vector3(-10.0, 1.8, -26.0), Vector3(-10.0, 22.0, -13.0), 54.0, 1.05, 48.0, crisp],
		[Vector3(28.0, 1.8, 25.0), Vector3(28.0, 11.0, 14.0), 52.0, 0.95, 30.0, warm],
	])

static func _build_travertine_plaza(lm: LandmarkMesh) -> void:
	# Raised travertine plaza with cobalt-blue glazed tile street retaining wall (front.jpg & quarter.jpg)
	lm.box("CobaltTile", Vector3(6.0, 0.525, 2.0), Vector3(88.0, 1.75, 50.0))
	lm.box("Travertine", Vector3(6.0, 1.28, 2.0), Vector3(87.2, 0.28, 49.2))

	# Wide travertine entrance stairs on the East Biscayne Blvd (+X) and South (+Z) street edges
	for s in 5:
		var sy := 0.28 * float(s + 1)
		lm.box("Travertine", Vector3(50.8 - float(s) * 0.45, sy * 0.5, -6.0),
			Vector3(1.2, sy, 14.0), Basis(), 0.0)
		lm.box("Travertine", Vector3(10.0, sy * 0.5, 27.6 - float(s) * 0.45),
			Vector3(16.0, sy, 1.2), Basis(), 0.0)

	# Perimeter dark-steel plaza guardrails
	lm.beam("Steel", Vector3(-37.0, 2.35, 26.2), Vector3(49.0, 2.35, 26.2), 0.07, 0.07)
	lm.beam("Steel", Vector3(49.2, 2.35, -22.0), Vector3(49.2, 2.35, 26.2), 0.07, 0.07)

static func _build_bacardi_tower(lm: LandmarkMesh) -> void:
	var w := 44.0
	var d := 16.0
	var hx := w * 0.5
	var hz := d * 0.5
	var y_plaza := 1.4
	var y_soffit := 6.4
	var y_glass_top := 33.4
	var y_crown := HEIGHT_M

	# Recessed ground-level glazed elevator & lobby core under the elevated slab + external sculptural stair
	lm.box("White", TOWER_C + Vector3(0.0, (y_plaza + y_soffit) * 0.5, 0.0), Vector3(24.0, y_soffit - y_plaza, 9.6))
	lm.box("Glass", TOWER_C + Vector3(0.0, 3.8, hz - 3.1), Vector3(16.0, 4.2, 0.30), Basis(), 0.0)
	for st in 8:
		var t := float(st) / 8.0
		lm.box("White", TOWER_C + Vector3(15.5 + t * 4.5, y_plaza + 0.3 + t * 4.7, 2.5),
			Vector3(0.9, 0.22, 2.2), Basis(), 0.0)

	# 4 monumental white structural columns (2 pairs spanning N-S) rising from plaza to y = 38.0 m (quarter.jpg)
	for px in [-9.2, 9.2]:
		for sz in [-1.0, 1.0]:
			lm.box("White", TOWER_C + Vector3(px, (y_plaza + y_crown) * 0.5, sz * (hz + 0.38)),
				Vector3(1.35, y_crown - y_plaza, 1.15))
		# Roof transfer girder tying each pair of mega-columns across the top at y = 37.2..38.0 m
		lm.box("White", TOWER_C + Vector3(px, y_crown - 0.45, 0.0), Vector3(1.35, 0.90, d + 1.5))

	# Main suspended 44 x 16 m office slab (y = 6.4..33.6 m) + white floor soffit & top parapet frame (38.0 m)
	lm.box("White", TOWER_C + Vector3(0.0, y_soffit + 0.35, 0.0), Vector3(w, 0.70, d))
	lm.box("Glass", TOWER_C + Vector3(0.0, (y_soffit + 0.7 + y_glass_top) * 0.5, 0.0),
		Vector3(w - 0.8, y_glass_top - (y_soffit + 0.7), d - 0.3))
	# Top open-air roof truss & perforated dark-steel mechanical screen storey (y = 33.4..38.0 m, quarter.jpg)
	lm.box("Steel", TOWER_C + Vector3(0.0, 35.4, 0.0), Vector3(w - 2.4, 3.8, d - 1.8))
	lm.box("White", TOWER_C + Vector3(0.0, y_crown - 0.35, 0.0), Vector3(w, 0.70, d))
	for sx in [-1.0, 1.0]:
		lm.box("White", TOWER_C + Vector3(sx * (hx - 0.35), (y_soffit + y_crown) * 0.5, 0.0),
			Vector3(0.70, y_crown - y_soffit, d))

	# North (-Z) & South (+Z) glazed curtain walls: crisp white vertical sun-fins & horizontal spandrel bars
	var mullions := 12
	for sz in [-1.0, 1.0]:
		var fz: float = TOWER_C.z + sz * (hz + 0.05)
		for m in mullions + 1:
			var mx := TOWER_C.x - (hx - 1.2) + (w - 2.4) * (float(m) / float(mullions))
			lm.box("White", Vector3(mx, (y_soffit + y_crown) * 0.5, fz),
				Vector3(0.18, y_crown - y_soffit, 0.42), Basis(), 0.0)
		for fl in 7:
			var fy := y_soffit + 0.7 + float(fl + 1) * 3.8
			lm.box("White", Vector3(TOWER_C.x, fy, fz), Vector3(w - 0.8, 0.18, 0.28), Basis(), 0.0)

	# Iconic East (+X) & West (-X) end walls: procedural cobalt, turquoise & white azulejo geometric mosaic
	for sx in [-1.0, 1.0]:
		var fx: float = TOWER_C.x + sx * (hx + 0.04)
		# Crisp white end-wall architectural slab canvas
		lm.box("White", Vector3(fx - sx * 0.16, (y_soffit + y_crown) * 0.5, TOWER_C.z),
			Vector3(0.36, y_crown - y_soffit, d - 0.1))
		# Procedural geometric azulejo panel grid (5 columns x 9 rows of architectural chevrons/diamonds)
		var cols := 5
		var rows := 9
		var cell_z := (d - 2.2) / float(cols)
		var cell_y := (y_crown - y_soffit - 2.4) / float(rows)
		for r in rows:
			var cy := y_soffit + 1.2 + (float(r) + 0.5) * cell_y
			for c in cols:
				var cz := TOWER_C.z - (d - 2.2) * 0.5 + (float(c) + 0.5) * cell_z
				var pat := (r * 3 + c * 2 + (1 if sx > 0.0 else 0)) % 5
				if pat == 0 or pat == 2:
					lm.box("CobaltTile", Vector3(fx + sx * 0.05, cy, cz),
						Vector3(0.10, cell_y * 0.82, cell_z * 0.82), Basis(), 0.0)
					if pat == 2:
						lm.box("White", Vector3(fx + sx * 0.09, cy, cz),
							Vector3(0.08, cell_y * 0.36, cell_z * 0.36), Basis(), 0.0)
				elif pat == 1 or pat == 3:
					lm.box("TurquoiseTile", Vector3(fx + sx * 0.05, cy, cz),
						Vector3(0.10, cell_y * 0.72, cell_z * 0.72), Basis(), 0.0)
					lm.box("CobaltTile", Vector3(fx + sx * 0.08, cy + cell_y * 0.16, cz - cell_z * 0.14),
						Vector3(0.08, cell_y * 0.34, cell_z * 0.34), Basis(), 0.0)

static func _build_jewel_box(lm: LandmarkMesh) -> void:
	# 1973 Ignacio Carrera-Justiz cantilevered square "Jewel Box" annex at Vector3(28, 0, 10)
	# Central warm terracotta-ochre concrete pedestal core (y = 1.4..5.5 m, front.jpg & side.jpg)
	lm.box("PedestalOchre", JEWEL_C + Vector3(0.0, 3.45, 0.0), Vector3(9.2, 4.1, 9.2))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("White", JEWEL_C + Vector3(sx * 4.55, 3.45, sz * 4.55), Vector3(0.28, 4.1, 0.28), Basis(), 0.0)

	# Cantilevered 18 x 18 m square Jewel Box volume (y = 5.5..16.5 m) with crisp white soffit & roof cap
	var jb_w := 18.0
	var jb_hw := jb_w * 0.5
	var y0 := 5.5
	var y1 := 16.5
	lm.box("White", JEWEL_C + Vector3(0.0, y0 + 0.28, 0.0), Vector3(jb_w, 0.56, jb_w))
	lm.box("Glass", JEWEL_C + Vector3(0.0, (y0 + 0.56 + y1 - 0.44) * 0.5, 0.0),
		Vector3(jb_w - 0.5, (y1 - y0) - 1.0, jb_w - 0.5))
	lm.box("White", JEWEL_C + Vector3(0.0, y1 - 0.22, 0.0), Vector3(jb_w, 0.44, jb_w))

	# Multifaceted thick dalle-de-verre stained-glass jewel panels & dark bronze/steel structural grid
	var jewel_keys := ["AmberLamp", "SapphireLamp", "RubyLamp", "TealLamp"]
	var cols := 6
	var rows := 3
	var cw := (jb_w - 0.8) / float(cols)
	var rh := (y1 - y0 - 1.0) / float(rows)
	for side in 4:
		var ang := float(side) * PI * 0.5
		var n3 := Vector3(sin(ang), 0.0, cos(ang))
		var t3 := Vector3(cos(ang), 0.0, -sin(ang))
		var basis := Basis(t3, Vector3.UP, n3)
		var face_c := JEWEL_C + n3 * (jb_hw - 0.12)
		# Structural dark-steel frame mullions (6 x 3 bays, matching front.jpg & side.jpg)
		for c in cols + 1:
			var ox := -(jb_w - 0.8) * 0.5 + float(c) * cw
			lm.box("Steel", face_c + t3 * ox + Vector3(0.0, (y0 + y1) * 0.5, 0.0),
				Vector3(0.18, y1 - y0, 0.30), basis, 0.0)
		for r in rows + 1:
			var oy := y0 + 0.5 + float(r) * rh
			lm.box("Steel", face_c + Vector3(0.0, oy, 0.0),
				Vector3(jb_w, 0.18, 0.30), basis, 0.0)
		# Faceted stained-glass mosaic sub-panels within each bay
		for r in rows:
			var py := y0 + 0.5 + (float(r) + 0.5) * rh
			for c in cols:
				var px := -(jb_w - 0.8) * 0.5 + (float(c) + 0.5) * cw
				var k_main: String = jewel_keys[(c + r * 2 + side) % 4]
				var k_acc: String = jewel_keys[(c * 3 + r + side + 1) % 4]
				lm.box(k_main, face_c + t3 * px + Vector3(0.0, py, 0.0),
					Vector3(cw * 0.86, rh * 0.84, 0.14), basis, 0.0)
				lm.box(k_acc, face_c + t3 * (px + cw * 0.12) + Vector3(0.0, py, 0.0) + n3 * 0.04,
					Vector3(cw * 0.44, rh * 0.42, 0.12), basis, 0.0)

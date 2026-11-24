extends RefCounted

## Statue of Alexander II (Walter Runeberg & Johannes Takanen, 1894),
## centrepiece of Senate Square before Helsinki Cathedral.
##
## Raised grey-granite platform with front steps, granite posts & cast-iron
## perimeter railing, clipped dark-green conifers, two 5-lantern front bronze
## candelabra & two 3-lantern rear candelabra, stepped moulded red-granite
## pedestal with gilt bronze 1863 inscription & Imperial crest, surrounded at
## its foot by the four bronze allegorical groups (Lex with Finnish heraldic
## Lion, Pax, Lux, Labor) and crowned by Tsar Alexander II in Russian Imperial
## Guard officer uniform at exact 10.7 m.

const ASSET_DIR := "res://assets/landmarks/helsinki_3d/"

const ENTRY := {"type": "alexander_ii_monument", "name": "Statue of Alexander II",
	"lat": 60.169495, "lon": 24.952240, "radius_m": 2500.0,
	"wiki_title": "Statue of Alexander II, Helsinki", "height_m": 10.7, "clear_m": 10.0,
	"yaw_deg": 0.0, "kind": "Monument",
	"aliases": ["statue of alexander ii", "alexander ii monument", "aleksanteri ii:n patsas",
		"alexandersstatyn"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#88837C", 2.2))
	lm.use("RedGranite", LandmarkMaterials.pbr("stone", "#8B4840", 1.8))
	lm.use("Bronze", LandmarkMaterials.paint("#2D4238", 0.36, 0.70))
	lm.use("Iron", LandmarkMaterials.paint("#222628", 0.48, 0.56))
	lm.use("Conifer", LandmarkMaterials.paint("#29422C", 0.82, 0.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkMaterials.lit("#FFE6B4", 1.15))

	var hw := 8.5
	var hd := 7.5
	var top := 0.90
	# Raised Senate Square granite platform & front steps
	lm.box("Granite", Vector3(0.0, top * 0.5, 0.0), Vector3(hw * 2.0, top, hd * 2.0))
	for k in 3:
		var sh := top * float(3 - k) / 4.0
		lm.box("Granite", Vector3(0.0, sh * 0.5, hd + 0.25 + 0.45 * float(k)),
			Vector3(8.8, sh, 0.48), Basis(), 0.0)

	# Perimeter granite posts & cast-iron railings (open across front steps)
	var corners := [
		Vector3(-hw + 0.3, top, hd - 0.3), Vector3(-hw + 0.3, top, -hd + 0.3),
		Vector3(hw - 0.3, top, -hd + 0.3), Vector3(hw - 0.3, top, hd - 0.3),
	]
	for i in 3:
		_fence(lm, corners[i], corners[i + 1])
	for sx in [-1.0, 1.0]:
		_fence(lm, Vector3(sx * (hw - 0.3), top, hd - 0.3), Vector3(sx * 4.5, top, hd - 0.3))

	# Six clipped conical yew/spruce conifers on platform
	for p in [Vector3(-5.5, top, 4.8), Vector3(-3.6, top, 5.6), Vector3(3.6, top, 5.6),
			Vector3(5.5, top, 4.8), Vector3(-5.5, top, -4.8), Vector3(5.5, top, -4.8)]:
		lm.frustum("Conifer", p, 0.48, 0.06, 1.65, 10)

	# Four ornate bronze & granite candelabra (5-lantern front, 3-lantern rear)
	for sx in [-1.0, 1.0]:
		_candelabrum(lm, Vector3(sx * (hw - 1.4), top, hd - 1.4), 7.8, 5)
		_candelabrum(lm, Vector3(sx * (hw - 1.4), top, -hd + 1.4), 5.6, 3)

	# Stepped moulded red-granite pedestal (y = 0.90..7.20 m)
	var y := top
	for t in [[6.2, 0.45, 6.2], [5.0, 0.55, 5.0], [3.5, 0.85, 2.9], [2.45, 3.65, 1.95],
			[2.85, 0.40, 2.35], [2.15, 0.40, 1.75]]:
		lm.box("RedGranite", Vector3(0.0, y + float(t[1]) * 0.5, 0.0),
			Vector3(float(t[0]), float(t[1]), float(t[2])))
		y += float(t[1])
	# Gilt bronze Grand Duchy shield & "1863" year inscription on pedestal front
	lm.box("Gold", Vector3(0.0, 4.85, 1.00), Vector3(0.75, 0.88, 0.06), Basis(), 0.0)
	lm.box("Gold", Vector3(0.0, 4.15, 1.00), Vector3(0.85, 0.14, 0.04), Basis(), 0.0)

	# High-resolution bronze Tsar Alexander II atop pedestal (7.20 + 3.50 = 10.70 m exact!)
	SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "alexander_ii_emperor.glb",
		Vector3(0.0, y, 0.0), Vector3.ONE, 0.0)
	# Four bronze allegorical groups (Lex + Lion in front, Pax in rear, Lux & Labor on flanks)
	var foot := top + 1.00
	SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "alexander_ii_lex.glb",
		Vector3(0.0, foot, 0.0), Vector3.ONE, 0.0)
	SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "alexander_ii_groups.glb",
		Vector3(0.0, foot, 0.0), Vector3.ONE, 0.0)

	lm.commit(model)
	var warm := Color(1.0, 0.89, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-6.5, 1.2, 6.5), Vector3(0.0, 7.5, 0.0), 44.0, 0.95, 22.0, warm],
		[Vector3(6.5, 1.2, 6.5), Vector3(0.0, 7.5, 0.0), 44.0, 0.95, 22.0, warm],
		[Vector3(0.0, 1.2, -6.5), Vector3(0.0, 7.5, 0.0), 46.0, 0.85, 22.0, warm],
	])

static func _fence(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var run := b - a
	var run_len := run.length()
	var r := Basis(Vector3.UP, atan2(run.x, run.z))
	var bays := maxi(int(round(run_len / 2.5)), 1)
	for i in bays + 1:
		lm.box("Granite", a + run * float(i) / float(bays) + Vector3(0, 0.5, 0), Vector3(0.48, 1.0, 0.48), r)
	for ry in [0.16, 0.84]:
		lm.box("Iron", (a + b) * 0.5 + Vector3(0, ry, 0), Vector3(0.05, 0.06, run_len), r, 0.0)
	var n := int(run_len / 0.26)
	for k in n:
		lm.box("Iron", a + run * (float(k) + 0.5) / float(n) + Vector3(0, 0.5, 0), Vector3(0.03, 0.68, 0.03), r, 0.0)

static func _candelabrum(lm: LandmarkMesh, base: Vector3, h: float, n: int) -> void:
	var shaft := h - 1.8
	lm.box("Granite", base + Vector3(0, 0.6, 0), Vector3(1.05, 1.2, 1.05))
	lm.frustum("Granite", base + Vector3(0, 1.2, 0), 0.40, 0.28, shaft - 1.2, 12)
	lm.box("Granite", base + Vector3(0, shaft + 0.15, 0), Vector3(0.78, 0.3, 0.78))
	var stem := base + Vector3(0, shaft + 0.3, 0)
	lm.frustum("Iron", stem, 0.08, 0.06, 1.2, 8)
	_lantern(lm, stem + Vector3(0, 1.2, 0))
	for i in n - 1:
		var a := TAU * (float(i) + 0.5) / float(n - 1)
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Iron", stem + d * 0.35 + Vector3(0, 0.55, 0), Vector3(0.7, 0.05, 0.05), Basis(Vector3.UP, -a), 0.0)
		_lantern(lm, stem + d * 0.7 + Vector3(0, 0.35, 0))

static func _lantern(lm: LandmarkMesh, base: Vector3) -> void:
	lm.frustum("Lamp", base, 0.14, 0.22, 0.36, 8)
	lm.frustum("Iron", base + Vector3(0, 0.36, 0), 0.24, 0.04, 0.18, 8)

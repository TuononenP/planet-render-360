class_name LandmarkArchetypes
extends RefCounted

## On-the-fly models for any OSM-tagged notable feature (church,
## cathedral, castle, lighthouse, stadium, mosque, temple, windmill,
## tower) in true metres at the feature's real height and footprint,
## with the same calibrated photographic PBR sets as buildings (T4.3)
## and the regional religious look (ArchitectureStyle.religious_look:
## wall set + stone/roof colour + tower style spire | bell | onion |
## minaret | pagoda | shikhara). Merged per material (LandmarkMesh).

## `size` = footprint in metres (x, z); the model's long side runs
## along local Z and the node turns when the footprint is wider in X.
static func build(model: Node3D, archetype: String, h: float, size: Vector2,
		region: String = "") -> void:
	var look := _look(region)
	var lm := LandmarkMesh.new()
	lm.use("Walls", LandmarkMaterials.pbr(str(look["set"]), str(look["wall"]), 3.0))
	lm.use("Roof", LandmarkMaterials.pbr(str(look["roof_set"]), str(look["roof"]), 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#D8CFBE", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#22292D"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var w := minf(size.x, size.y)
	var l := maxf(size.x, size.y)
	match archetype:
		"church": _church(lm, h, w, l, false, str(look["tower"]))
		"cathedral": _church(lm, h, w, l, true, str(look["tower"]))
		"castle": _castle(lm, h, w, l)
		"lighthouse": _lighthouse(lm, h)
		"stadium": _stadium(lm, h, w, l)
		"mosque": _mosque(lm, h, w, l)
		"temple": _temple(lm, h, w, l, str(look["tower"]))
		"windmill": _windmill(lm, h)
		"column": LandmarkMonuments.column(lm, h)
		"obelisk": LandmarkMonuments.obelisk(lm, h)
		_: _tower(lm, h, w)
	lm.commit(model)
	if size.x > size.y:
		model.rotation.y = PI * 0.5

## Regional wall set/colours (sRGB hex) and tower style; neutral
## limestone + slate spire when no region is known.
static func _look(region: String) -> Dictionary:
	var out := {"set": "limestone", "wall": "#BFB4A2", "roof_set": "slate",
		"roof": "#4A535C", "tower": "spire"}
	if region == "":
		return out
	var look := ArchitectureStyle.religious_look(region)
	var p := ArchitectureStyle.profile(region, "religious")
	var walls: Array = p.get("w", [])
	if not walls.is_empty() and MaterialLibrary.PBR_SETS.has(str((walls[0] as Array)[0])):
		out["set"] = str((walls[0] as Array)[0])
		if out["set"] == "stone":
			out["set"] = "limestone"  # dressed ashlar; the sandstone set is too saturated to tint
	var roofs: Array = p.get("rf", [])
	if not roofs.is_empty() and MaterialLibrary.PBR_SETS.has(str((roofs[0] as Array)[0])):
		out["roof_set"] = str((roofs[0] as Array)[0])
	var stone: Color = look.get("stone", Color(0, 0, 0, 0))
	var roof: Color = look.get("roof", Color(0, 0, 0, 0))
	if stone.a > 0.0:
		out["wall"] = "#" + stone.linear_to_srgb().to_html(false)
	if roof.a > 0.0:
		out["roof"] = "#" + roof.linear_to_srgb().to_html(false)
	out["tower"] = str(look.get("tower", "spire"))
	return out

# --- Churches ---

## Basilica: nave + aisles, buttresses and tall windows, apse, and one
## (church) or two (cathedral) west towers topped in the regional style.
static func _church(lm: LandmarkMesh, h: float, w: float, l: float, twin: bool, style: String) -> void:
	var eave := clampf(h * 0.28, 8.0, 30.0)
	var nw := w * 0.62
	var body := l * 0.78
	var zc := l * 0.11
	lm.box("Walls", Vector3(0, eave * 0.5, zc), Vector3(nw, eave, body))
	lm.gable("Roof", Vector3(0, eave, zc), nw, body, nw * 0.55, Basis(), 0.6, "Walls")
	lm.box("Walls", Vector3(0, eave * 0.3, zc), Vector3(w, eave * 0.6, body * 0.96))
	for sx in [-1.0, 1.0]:
		lm.quad("Roof", Vector3(sx * w * 0.5, eave * 0.6, zc - body * 0.48),
			Vector3(sx * w * 0.5, eave * 0.6, zc + body * 0.48),
			Vector3(sx * nw * 0.5, eave * 0.9, zc + body * 0.48),
			Vector3(sx * nw * 0.5, eave * 0.9, zc - body * 0.48), Vector3(sx, 2.0, 0).normalized())
		var bays := maxi(3, int(body / 7.0))
		for k in bays:
			var z := zc - body * 0.45 + body * 0.9 * (float(k) + 0.5) / float(bays)
			lm.box("Windows", Vector3(sx * (nw * 0.5 + 0.05), eave * 0.78, z), Vector3(0.1, eave * 0.32, 2.0))
			lm.box("Windows", Vector3(sx * (w * 0.5 + 0.05), eave * 0.3, z), Vector3(0.1, eave * 0.3, 1.8))
			lm.box("Walls", Vector3(sx * (w * 0.5 + 0.5), eave * 0.3, z + body * 0.45 / float(bays)),
				Vector3(1.2, eave * 0.6, 1.2))
	lm.lathe("Walls", Vector3(0, 0, zc + body * 0.5), PackedVector2Array([Vector2(nw * 0.5, 0),
		Vector2(nw * 0.5, eave)]), 10, 1.0, 1.0, 0.0, false)
	lm.lathe("Roof", Vector3(0, eave, zc + body * 0.5), PackedVector2Array([Vector2(nw * 0.52, 0),
		Vector2(0.3, nw * 0.5)]), 10, 1.0, 1.0, 0.0, false)
	if style == "onion":
		_onion(lm, Vector3(0, eave + nw * 0.55, zc), nw * 0.22, h * 0.25)
	var tw := clampf(w * (0.3 if twin else 0.36), 6.0, 18.0)
	var tz := -l * 0.5 + tw * 0.5
	var xs: Array = [-(w * 0.5 - tw * 0.5), w * 0.5 - tw * 0.5] if twin else [0.0]
	for x in xs:
		_church_tower(lm, Vector3(float(x), 0, tz), tw, h, style)
	if twin:
		lm.box("Walls", Vector3(0, eave * 0.6, tz), Vector3(w - tw * 2.0, eave * 1.2, tw))
		lm.disc("Windows", Vector3(0, eave * 0.8, tz - tw * 0.5 - 0.05), Vector3.FORWARD, minf(w * 0.12, eave * 0.25))
	lm.box("Windows", Vector3(0, minf(eave * 0.25, 5.0), -l * 0.5 - 0.05), Vector3(minf(4.0, w * 0.2), minf(eave * 0.5, 10.0), 0.1))

## West tower: shaft with belfry openings and a regional top.
static func _church_tower(lm: LandmarkMesh, base: Vector3, tw: float, h: float, style: String) -> void:
	var frac := {"spire": 0.58, "bell": 0.82, "onion": 0.70, "minaret": 0.75,
		"pagoda": 0.82, "shikhara": 0.6}.get(style, 0.6) as float
	var th := h * frac
	lm.box("Walls", base + Vector3(0, th * 0.5, 0), Vector3(tw, th, tw))
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Windows", base + r * Vector3(0, th - tw * 0.55, tw * 0.5 + 0.03),
			Vector3(tw * 0.32, tw * 0.6, 0.1), r)
		lm.box("Trim", base + r * Vector3(0, th - 0.4, tw * 0.5 + 0.15), Vector3(tw + 0.3, 0.8, 0.3), r)
	var top := base + Vector3(0, th, 0)
	var rest := h - th
	match style:
		"onion":
			lm.frustum("Walls", top, tw * 0.36, tw * 0.36, rest * 0.25, 12)
			_onion(lm, top + Vector3(0, rest * 0.25, 0), tw * 0.42, rest * 0.75)
		"bell", "pagoda":
			lm.lathe("Roof", top, PackedVector2Array([Vector2(tw * 0.72, 0), Vector2(tw * 0.5, rest * 0.35),
				Vector2(tw * 0.2, rest * 0.8), Vector2(0.0, rest)]), 4, 1.0, 1.0, PI * 0.25, false)
		_:
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					lm.spire("Roof", top + Vector3(sx * tw * 0.42, 0, sz * tw * 0.42), tw * 0.08, rest * 0.18)
			lm.lathe("Roof", top, PackedVector2Array([Vector2(tw * 0.5, 0), Vector2(tw * 0.42, rest * 0.12),
				Vector2(0.15, rest * 0.96)]), 8, 1.0, 1.0, PI / 8.0, false)
			lm.box("Gilt", top + Vector3(0, rest * 0.98, 0), Vector3(0.18, rest * 0.06 + 0.5, 0.18))

## Russian onion dome with drum neck and gilded cross.
static func _onion(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	lm.lathe("Gilt", base, PackedVector2Array([Vector2(r * 0.7, 0), Vector2(r * 1.0, h * 0.18),
		Vector2(r * 1.05, h * 0.32), Vector2(r * 0.8, h * 0.5), Vector2(r * 0.3, h * 0.68),
		Vector2(r * 0.08, h * 0.8), Vector2(0.0, h * 0.84)]), 16)
	lm.box("Gilt", base + Vector3(0, h * 0.92, 0), Vector3(0.15, h * 0.16, 0.15))
	lm.box("Gilt", base + Vector3(0, h * 0.95, 0), Vector3(h * 0.07, 0.15, 0.15))

# --- Secular landmarks ---

## Curtain wall with crenellations, round corner towers with conical
## roofs, gatehouse and the keep.
static func _castle(lm: LandmarkMesh, h: float, w: float, l: float) -> void:
	var wall_h := clampf(h * 0.35, 8.0, 20.0)
	var corners := [Vector3(-w * 0.5, 0, -l * 0.5), Vector3(w * 0.5, 0, -l * 0.5),
		Vector3(w * 0.5, 0, l * 0.5), Vector3(-w * 0.5, 0, l * 0.5)]
	for k in 4:
		var a: Vector3 = corners[k]
		var b: Vector3 = corners[(k + 1) % 4]
		var mid := (a + b) * 0.5
		var along := (b - a)
		var basis := Basis(Vector3.UP, atan2(along.x, along.z) + PI * 0.5)
		lm.box("Walls", mid + Vector3(0, wall_h * 0.5, 0), Vector3(along.length(), wall_h, 3.0), basis)
		var n := int(along.length() / 3.0)
		for m in n:
			if m % 2 == 0:
				lm.box("Walls", a.lerp(b, (float(m) + 0.5) / float(n)) + Vector3(0, wall_h + 0.7, 0),
					Vector3(1.4, 1.4, 3.0), basis)
	var tr := clampf(w * 0.09, 3.0, 9.0)
	for c in corners:
		lm.frustum("Walls", c, tr * 1.1, tr, wall_h * 1.45, 16)
		lm.lathe("Roof", c + Vector3(0, wall_h * 1.45, 0), PackedVector2Array([Vector2(tr * 1.15, 0),
			Vector2(0.0, tr * 2.4)]), 16)
	for sx in [-1.0, 1.0]:
		lm.frustum("Walls", Vector3(sx * 5.0, 0, -l * 0.5), 3.2, 3.0, wall_h * 1.3, 12)
	lm.box("Windows", Vector3(0, 3.0, -l * 0.5 - 1.55), Vector3(4.0, 6.0, 0.1))
	var kw := clampf(w * 0.34, 8.0, 30.0)
	lm.box("Walls", Vector3(0, h * 0.425, l * 0.1), Vector3(kw, h * 0.85, kw))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * kw * 0.5, h * 0.85, l * 0.1 + sz * kw * 0.5)
			lm.frustum("Walls", p - Vector3(0, 4.0, 0), 1.6, 1.6, 6.0, 10)
			lm.lathe("Roof", p + Vector3(0, 2.0, 0), PackedVector2Array([Vector2(1.8, 0),
				Vector2(0.0, h * 0.15)]), 10)
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		for k in 2:
			lm.box("Windows", Vector3(0, 0, l * 0.1) + r * Vector3(0, h * (0.4 + 0.22 * float(k)), kw * 0.5 + 0.04),
				Vector3(1.4, 2.6, 0.1), r)

## Banded lighthouse: tapered tower, gallery with railing, glazed
## lantern with the lit lamp, domed cap, and the keeper's house.
static func _lighthouse(lm: LandmarkMesh, h: float) -> void:
	lm.use("Red", LandmarkMaterials.pbr("render", "#B03A2A", 3.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#EEEAE0", 3.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD98A", 1.6))
	var r0 := clampf(h * 0.09, 3.0, 10.0)
	var r1 := r0 * 0.62
	var top := h * 0.82
	var bands := 4
	for k in bands:
		var y0 := top * float(k) / float(bands)
		var y1 := top * float(k + 1) / float(bands)
		lm.frustum("Red" if k % 2 == 0 else "White", Vector3(0, y0, 0),
			lerpf(r0, r1, y0 / top), lerpf(r0, r1, y1 / top), y1 - y0, 20)
	lm.frustum("White", Vector3(0, top, 0), r1 * 1.4, r1 * 1.4, 0.6, 20)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.box("Red", Vector3(cos(a) * r1 * 1.35, top + 1.1, sin(a) * r1 * 1.35), Vector3(0.12, 1.0, 0.12))
	lm.frustum("Red", Vector3(0, top + 1.6, 0), r1 * 1.38, r1 * 1.38, 0.15, 20)
	lm.frustum("Windows", Vector3(0, top + 0.6, 0), r1 * 0.85, r1 * 0.85, h * 0.1, 12)
	lm.frustum("Lamp", Vector3(0, top + 1.6, 0), r1 * 0.4, r1 * 0.4, h * 0.05, 10)
	lm.lathe("Red", Vector3(0, top + 0.6 + h * 0.1, 0), PackedVector2Array([Vector2(r1 * 0.95, 0),
		Vector2(r1 * 0.6, h * 0.05), Vector2(0.0, h * 0.08)]), 16)
	lm.box("White", Vector3(r0 + 5.0, 2.5, 0), Vector3(8.0, 5.0, 6.0))
	lm.gable("Red", Vector3(r0 + 5.0, 5.0, 0), 6.0, 8.0, 2.4, Basis(Vector3.UP, PI * 0.5), 0.3, "White")

## Elliptical bowl: ribbed facade, cantilevered membrane roof ring,
## raked seating facing the grass pitch.
static func _stadium(lm: LandmarkMesh, h: float, w: float, l: float) -> void:
	lm.use("Concrete", LandmarkMaterials.pbr("render", "#C9C5BC", 4.0))
	lm.use("Canopy", LandmarkMaterials.pbr("membrane", "#E6E4DE", 6.0, 0.5))
	lm.use("Seats", LandmarkMaterials.pbr("concrete", "#7C8A96", 2.0))
	lm.use("Pitch", LandmarkMaterials.pbr("grass", "#4F7A35", 6.0))
	var hh := clampf(h, 12.0, 60.0)
	var a := w * 0.5
	var b := l * 0.5
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(1.0, 0), Vector2(1.0, hh * 0.45)]),
		48, a, b, 0.0, true, false)
	lm.lathe("Windows", Vector3.ZERO, PackedVector2Array([Vector2(0.995, hh * 0.45),
		Vector2(0.99, hh * 0.78)]), 48, a, b, 0.0, true, false)
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(1.0, hh * 0.78),
		Vector2(1.0, hh * 0.84)]), 48, a, b, 0.0, true, false)
	for k in 32:
		var t := TAU * float(k) / 32.0
		var p := Vector3(cos(t) * a * 1.01, 0, sin(t) * b * 1.01)
		lm.beam("Concrete", p, p * 1.0 + Vector3(0, hh, 0), 1.0, 1.4)
	lm.lathe("Canopy", Vector3.ZERO, PackedVector2Array([Vector2(1.03, hh), Vector2(0.72, hh * 0.9)]),
		48, a, b, 0.0, true, false)
	lm.lathe("Canopy", Vector3.ZERO, PackedVector2Array([Vector2(0.72, hh * 0.9), Vector2(1.03, hh)]),
		48, a, b, 0.0, true, false)
	lm.lathe("Seats", Vector3.ZERO, PackedVector2Array([Vector2(0.98, hh * 0.78), Vector2(0.66, 1.0)]),
		48, a, b, 0.0, true, false)
	var pitch := PackedVector2Array()
	for k in 32:
		var t := TAU * float(k) / 32.0
		pitch.append(Vector2(cos(t) * a * 0.66, sin(t) * b * 0.66))
	lm.poly_prism("Pitch", pitch, 0.0, 0.5)

## Prayer hall, main dome on a windowed drum, semi-domes, and slender
## minarets with balconies and pointed caps.
static func _mosque(lm: LandmarkMesh, h: float, w: float, l: float) -> void:
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#5E6E78", 2.0, 0.45, 0.4))
	var hall := clampf(h * 0.25, 8.0, 25.0)
	lm.box("Walls", Vector3(0, hall * 0.5, l * 0.1), Vector3(w * 0.8, hall, l * 0.7))
	var dr := minf(w * 0.3, l * 0.28)
	var c := Vector3(0, hall, l * 0.1)
	lm.frustum("Walls", c, dr * 1.02, dr, dr * 0.35, 24)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.box("Windows", c + Vector3(cos(a) * dr * 1.0, dr * 0.18, sin(a) * dr * 1.0),
			Vector3(0.9, dr * 0.2, 0.1), Basis(Vector3.UP, -a + PI * 0.5))
	lm.lathe("Dome", c + Vector3(0, dr * 0.35, 0), _dome(dr, dr * 0.95), 24)
	lm.box("Gilt", c + Vector3(0, dr * 1.4, 0), Vector3(0.3, dr * 0.2, 0.3))
	for sz in [-1.0, 1.0]:
		lm.lathe("Dome", c + Vector3(0, 0, sz * dr * 1.05), _dome(dr * 0.55, dr * 0.5), 16)
	var mh := maxf(h, hall * 2.5)
	var n := 4 if w * l > 2500.0 else 2
	for k in n:
		var x := (-1.0 if k % 2 == 0 else 1.0) * w * 0.48
		var z := (-l * 0.4) if k < 2 else (l * 0.45)
		var p := Vector3(x, 0, z)
		lm.frustum("Walls", p, 2.4, 1.9, mh * 0.82, 12)
		for g in [0.55, 0.78]:
			lm.frustum("Trim", p + Vector3(0, mh * float(g), 0), 2.9, 2.9, 0.8, 12)
		lm.lathe("Dome", p + Vector3(0, mh * 0.82, 0), PackedVector2Array([Vector2(2.1, 0),
			Vector2(0.0, mh * 0.18)]), 12)

## Temple by region: pagoda (East Asia), shikhara (South Asia), else a
## classical peristyle temple with pediments.
static func _temple(lm: LandmarkMesh, h: float, w: float, l: float, style: String) -> void:
	match style:
		"pagoda": _pagoda(lm, h, w)
		"shikhara": _shikhara(lm, h, w, l)
		_: _classical(lm, h, w, l)

static func _pagoda(lm: LandmarkMesh, h: float, w: float) -> void:
	var tiers := clampi(int(h / 9.0), 3, 7)
	var base := clampf(w * 0.7, 8.0, 30.0)
	var tier_h := h * 0.8 / float(tiers)
	for k in tiers:
		var s := base * (1.0 - 0.1 * float(k))
		var y := tier_h * float(k)
		lm.box("Walls", Vector3(0, y + tier_h * 0.35, 0), Vector3(s * 0.7, tier_h * 0.7, s * 0.7))
		lm.lathe("Roof", Vector3(0, y + tier_h * 0.7, 0), PackedVector2Array([Vector2(s * 0.85, tier_h * 0.08),
			Vector2(s * 0.62, 0.0), Vector2(s * 0.42, tier_h * 0.3)]), 4, 1.0, 1.0, PI * 0.25, false, false)
	var top := tier_h * float(tiers)
	lm.frustum("Gilt", Vector3(0, top, 0), 0.5, 0.3, h - top, 8)
	for k in 6:
		lm.frustum("Gilt", Vector3(0, top + (h - top) * (0.2 + 0.1 * float(k)), 0), 1.0, 1.0, 0.3, 10)

static func _shikhara(lm: LandmarkMesh, h: float, w: float, l: float) -> void:
	var r := clampf(w * 0.35, 5.0, 20.0)
	lm.box("Walls", Vector3(0, 1.5, 0), Vector3(w, 3.0, l))
	lm.box("Walls", Vector3(0, 3.0 + h * 0.12, l * 0.25), Vector3(w * 0.7, h * 0.24, l * 0.4))
	lm.spire("Roof", Vector3(0, 3.0 + h * 0.24, l * 0.25), w * 0.37, h * 0.12)
	lm.lathe("Walls", Vector3(0, 3.0, -l * 0.15), PackedVector2Array([Vector2(r, 0), Vector2(r, h * 0.2),
		Vector2(r * 0.95, h * 0.45), Vector2(r * 0.7, h * 0.7), Vector2(r * 0.35, h * 0.84)]), 16, 1.0, 1.0, 0.0, false)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Trim", Vector3(0, 3.0, -l * 0.15) + d * r * 1.02, Vector3(0, 3.0 + h * 0.83, -l * 0.15) + d * r * 0.36, 0.7, 0.5)
	var top := Vector3(0, 3.0 + h * 0.84, -l * 0.15)
	lm.frustum("Trim", top, r * 0.42, r * 0.42, h * 0.04, 24)
	lm.lathe("Gilt", top + Vector3(0, h * 0.04, 0), PackedVector2Array([Vector2(r * 0.15, 0),
		Vector2(r * 0.12, h * 0.06), Vector2(0.0, maxf(h * 0.12 - 3.0, 2.0))]), 10)

static func _classical(lm: LandmarkMesh, h: float, w: float, l: float) -> void:
	var col_h := clampf(h * 0.6, 6.0, 20.0)
	for k in 3:
		lm.box("Trim", Vector3(0, 0.5 + float(k), 0), Vector3(w - float(k) * 2.0, 1.0, l - float(k) * 2.0))
	var y0 := 3.0
	lm.box("Walls", Vector3(0, y0 + col_h * 0.5, 0), Vector3(w * 0.65, col_h, l * 0.75))
	var nx := clampi(int(w / 4.0), 4, 8)
	var nz := clampi(int(l / 4.0), 6, 14)
	for i in nx:
		for sz in [-1.0, 1.0]:
			var x := -w * 0.42 + w * 0.84 * float(i) / float(nx - 1)
			lm.frustum("Trim", Vector3(x, y0, sz * l * 0.42), 0.8, 0.68, col_h, 12)
	for j in nz:
		for sx in [-1.0, 1.0]:
			var z := -l * 0.42 + l * 0.84 * float(j) / float(nz - 1)
			lm.frustum("Trim", Vector3(sx * w * 0.42, y0, z), 0.8, 0.68, col_h, 12)
	lm.box("Trim", Vector3(0, y0 + col_h + 0.8, 0), Vector3(w * 0.92, 1.6, l * 0.92))
	lm.gable("Roof", Vector3(0, y0 + col_h + 1.6, 0), w * 0.92, l * 0.92, w * 0.16, Basis(), 0.4, "Trim")

## Tower mill: tapered octagonal body, reefing stage, boat cap and four
## lattice sails on the windshaft.
static func _windmill(lm: LandmarkMesh, h: float) -> void:
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6E5642", 2.0))
	lm.use("Sails", LandmarkMaterials.pbr("wood", "#D8D0BE", 2.0))
	var r0 := clampf(h * 0.18, 3.0, 7.0)
	var body := h * 0.72
	lm.frustum("Walls", Vector3.ZERO, r0, r0 * 0.62, body, 8, PI / 8.0)
	lm.frustum("Wood", Vector3(0, body * 0.32, 0), r0 * 1.35, r0 * 1.35, 0.5, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		lm.box("Windows", Vector3(cos(a) * r0 * 0.75, body * 0.55, sin(a) * r0 * 0.75), Vector3(0.9, 1.4, 0.1),
			Basis(Vector3.UP, -a + PI * 0.5))
	lm.lathe("Wood", Vector3(0, body, 0), PackedVector2Array([Vector2(r0 * 0.7, 0), Vector2(r0 * 0.6, r0 * 0.5),
		Vector2(0.0, r0 * 0.9)]), 12, 1.0, 1.3)
	var hub := Vector3(0, body + r0 * 0.3, -r0 * 0.9)
	lm.beam("Wood", Vector3(0, body + r0 * 0.3, 0), hub, 0.6, 0.6)
	var arm := h * 0.42
	for k in 4:
		var a := 0.35 + PI * 0.5 * float(k)
		var d := Vector3(sin(a), cos(a), 0)
		var side := Vector3(cos(a), -sin(a), 0)
		lm.beam("Sails", hub, hub + d * arm, 0.5, 0.4)
		var s0 := hub + d * arm * 0.22
		var s1 := hub + d * arm
		lm.beam("Sails", s0 + side * arm * 0.2, s1 + side * arm * 0.2, 0.25, 0.2)
		for m in 7:
			var p := s0.lerp(s1, float(m) / 6.0)
			lm.beam("Sails", p, p + side * arm * 0.2, 0.18, 0.15)

## Tall (≥100 m): telecom tower — concrete shaft, glazed pod, mast.
## Lower: masonry tower with belfry windows and a pyramid roof.
static func _tower(lm: LandmarkMesh, h: float, w: float) -> void:
	if h >= 100.0:
		lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#CFCBC2", 4.0))
		lm.use("Mast", LandmarkMaterials.paint("#C8CACC", 0.4, 0.6))
		var r := clampf(h * 0.05, 4.0, 12.0)
		var pod := h * 0.7
		lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(r * 1.6, 0), Vector2(r, h * 0.12),
			Vector2(r * 0.7, pod)]), 20)
		lm.lathe("Concrete", Vector3(0, pod, 0), PackedVector2Array([Vector2(r * 0.7, 0),
			Vector2(r * 2.4, h * 0.03), Vector2(r * 2.5, h * 0.035)]), 24, 1.0, 1.0, 0.0, true, false)
		lm.frustum("Windows", Vector3(0, pod + h * 0.035, 0), r * 2.5, r * 2.3, h * 0.04, 24)
		lm.lathe("Concrete", Vector3(0, pod + h * 0.075, 0), PackedVector2Array([Vector2(r * 2.3, 0),
			Vector2(r * 1.4, h * 0.03), Vector2(r * 0.6, h * 0.045)]), 24)
		lm.frustum("Mast", Vector3(0, pod + h * 0.12, 0), r * 0.25, r * 0.08, h - pod - h * 0.12, 8)
		return
	var tw := clampf(w * 0.5, 6.0, 18.0)
	var th := h * 0.8
	lm.box("Walls", Vector3(0, th * 0.5, 0), Vector3(tw, th, tw))
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		for k in 3:
			lm.box("Windows", r * Vector3(0, th * (0.3 + 0.25 * float(k)), tw * 0.5 + 0.03),
				Vector3(tw * 0.18, tw * 0.35, 0.1), r)
		lm.box("Trim", r * Vector3(0, th - 0.4, tw * 0.5 + 0.15), Vector3(tw + 0.3, 0.8, 0.3), r)
	lm.spire("Roof", Vector3(0, th, 0), tw * 0.56, h - th)

static func _dome(r: float, h: float) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in 9:
		var t := PI * 0.5 * float(k) / 8.0
		pr.append(Vector2(cos(t) * r, sin(t) * h))
	pr[pr.size() - 1] = Vector2(0.0, h)
	return pr

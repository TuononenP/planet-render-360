class_name TramModel
extends RefCounted

## Procedural trams: one cached mesh per body section, livery and level
## of detail, built from its TramSpecs spec. A section is one loft
## (VehicleKit.skin) whose strips and bays pick their surface: paint by
## livery role, window and door glass, lamps and a destination panel on
## a nose. Running gear, roof equipment, the bellows half at a joint and
## an open car's benches are added to it. A section faces +X, centred on
## its own length, wheels on y = 0 (metres).
##
## Surfaces are shared materials: a paint per colour, a roof that takes
## snow (StreetSnow), and glass, lamps and the destination panel that
## light up at night with the city (CityLights), since a tram on the
## street is in service. The far mesh drops the fittings and folds every
## painted surface into one vertex-coloured surface shared by all
## liveries.

## Nose rows, as the share of the body's width left at each.
const NOSE_K := [0.97, 0.9, 0.8, 0.62, 0.35, 0.07, 0.0]
## Share of the roof's rise left at the tip of a nose: the roof domes down.
const NOSE_DOME := 0.45
const NOSE_K_FAR := [0.8, 0.45, 0.0]
const DOOR_M := 1.3
## Collector height over the rails: just under OverheadWires' contact wire.
const COLLECTOR_M := OverheadWires.CONTACT_M - 0.1

static var _meshes := {}
static var _materials := {}

## The mesh of section `id` of a `kind` train in `livery`; `tail` gives
## a nose red lamps (the trailing cab).
static func mesh(kind: String, id: String, livery: String, tail: bool = false, far: bool = false) -> ArrayMesh:
	var key := "%s|%s|%s|%d|%d" % [kind, id, livery, int(tail), int(far)]
	if _meshes.has(key):
		return _meshes[key]
	# A train (TrainSpecs) is built as a tram is, from the same vocabulary.
	var rail := TrainSpecs.KIND.has(kind)
	var k: Dictionary = TrainSpecs.KIND[kind] if rail else TramSpecs.KIND[kind]
	var sec := TrainSpecs.section(kind, id) if rail else TramSpecs.section(kind, id)
	var liv := TrainSpecs.livery(livery) if rail else TramSpecs.livery(livery)
	var lm := LandmarkMesh.new()
	for role: String in ["lower", "band", "upper", "pillar", "inner", "door", "cab"]:
		if liv.has(role):
			lm.use(_ckey(liv[role]), paint(liv[role]))
	lm.use("Roof", roof(liv["roof"]))
	for name: String in ["Glass", "Dark", "Metal", "HeadLamp", "TailLamp", "Board"]:
		lm.use(name, material(name))
	_body(lm, k, sec, liv, tail, far)
	_running_gear(lm, k, sec, liv, far)
	if not far:
		_roof_gear(lm, sec)
	var out := lm.to_array_mesh(false)
	if far:
		out = _folded(out)
	_meshes[key] = out
	return out

static func _ckey(c: Color) -> String:
	return "C" + c.to_html(false)

## Bays of the side between `x_r` and `x_f`: [type, x0, x1], rear first.
static func bays(sec: Dictionary, x_r: float, x_f: float, far: bool) -> Array:
	var out: Array = []
	if sec.has("plan"):
		var plan: Array = sec["plan"]
		var total := 0.0
		for b: Array in plan:
			total += float(b[1])
		var x := x_r
		for b: Array in plan:
			var x1 := x + float(b[1]) * (x_f - x_r) / total
			out.append([str(b[0]), x, x1])
			x = x1
		(out[out.size() - 1] as Array)[2] = x_f
		return out
	var doors: Array = (sec.get("doors", []) as Array).duplicate()
	doors.sort()
	var x := x_r
	for d: float in doors:
		_windows(out, sec, x, d - DOOR_M * 0.5, far)
		var a := d - DOOR_M * 0.5
		var b := d + DOOR_M * 0.5
		if far:
			out.append(["D", a, b])
		else:
			out.append_array([["F", a, a + 0.05], ["D", a + 0.05, d - 0.02], ["F", d - 0.02, d + 0.02],
				["D", d + 0.02, b - 0.05], ["F", b - 0.05, b]])
		x = b
	_windows(out, sec, x, x_f, far)
	return out

## A run of windows between `a` and `b`, panels at its ends and between.
static func _windows(out: Array, sec: Dictionary, a: float, b: float, far: bool) -> void:
	var margin := 0.16
	var pitch := float(sec.get("pitch", 1.4))
	var n := int((b - a - 2.0 * margin) / pitch)
	if n < 1:
		out.append(["P", a, b])
		return
	out.append(["P", a, a + margin])
	if far:
		out.append(["W", a + margin, b - margin])
	else:
		var post := 0.1
		var wide := (b - a - 2.0 * margin - post * float(n - 1)) / float(n)
		var x := a + margin
		for i in n:
			out.append(["W", x, x + wide])
			if i < n - 1:
				out.append(["P", x + wide, x + wide + post])
			x += wide + post
	out.append(["P", b - margin, b])

## Height where the profile's first `role` strip starts.
static func _role_y(prof: Array, role: String) -> float:
	for p: Array in prof:
		if str(p[2]) == role:
			return float(p[0])
	return float(prof[prof.size() - 1][0])

static func _row(prof: Array, w: float, x: float) -> PackedVector3Array:
	var row := PackedVector3Array()
	for p: Array in prof:
		row.append(Vector3(x, float(p[0]), w * float(p[1])))
	return row

## The end section drawn in to `k` of its width and bowed out along
## `dir` (+1 front, -1 rear); above the belt the bow gives way to the
## screen's rake, and the roof domes down toward the tip.
static func _nose_row(prof: Array, w: float, x: float, dir: float, nose: Dictionary, k: float,
		belt: float) -> PackedVector3Array:
	var row := PackedVector3Array()
	var bow := 1.0 - pow(k, float(nose["pow"]))
	var eaves := _role_y(prof, "roof")
	for p: Array in prof:
		var y := float(p[0])
		if y > eaves:
			y = eaves + (y - eaves) * lerpf(NOSE_DOME, 1.0, k)
		var reach := maxf(float(nose["len"]) - float(nose["rake"]) * maxf(y - belt, 0.0), 0.03)
		row.append(Vector3(x + dir * bow * reach, y, w * float(p[1]) * k))
	return row

## Lofts the section's shell: floor, sides, roof and both ends.
static func _body(lm: LandmarkMesh, k: Dictionary, sec: Dictionary, liv: Dictionary, tail: bool, far: bool) -> void:
	var w := float(k["w"]) * 0.5
	var prof: Array = sec["prof"]
	var half := float(sec["len"]) * 0.5
	var front: Dictionary = sec["front"]
	var rear: Dictionary = sec["rear"]
	var x_f := half - float(front.get("len", 0.0))
	var x_r := -half + float(rear.get("len", 0.0))
	var belt := _role_y(prof, "win")
	var ks: Array = NOSE_K_FAR if far else NOSE_K
	var rows: Array = []
	# Per gap between rows: the bay type (or nf / nr / cap) and how far
	# in from the corner a nose gap lies.
	var types := PackedStringArray()
	var depth := PackedFloat32Array()
	if rear.is_empty():
		rows.append(_nose_row(prof, w, x_r, -1.0, {"len": 0.0, "rake": 0.0, "pow": 1.0}, 0.0, belt))
		types.append("cap")
		depth.append(0.0)
	else:
		for i in range(ks.size() - 1, -1, -1):
			rows.append(_nose_row(prof, w, x_r, -1.0, rear, float(ks[i]), belt))
			types.append("nr")
			depth.append((float(ks[i]) + (float(ks[i - 1]) if i > 0 else 1.0)) * 0.5)
	var side := bays(sec, x_r, x_f, far)
	for b: Array in side:
		rows.append(_row(prof, w, float(b[1])))
		types.append(str(b[0]))
		depth.append(1.0)
	rows.append(_row(prof, w, x_f))
	if front.is_empty():
		types.append("cap")
		depth.append(0.0)
		rows.append(_nose_row(prof, w, x_f, 1.0, {"len": 0.0, "rake": 0.0, "pow": 1.0}, 0.0, belt))
	else:
		var last := 1.0
		for kv: float in ks:
			types.append("nf")
			depth.append((last + kv) * 0.5)
			rows.append(_nose_row(prof, w, x_f, 1.0, front, kv, belt))
			last = kv
	var board_c := -1
	for c in prof.size():
		if str(prof[c][2]) == "upper":
			board_c = c
			break
	var keys := func(r: int, c: int) -> String:
		var t := types[r]
		var nose := front if t == "nf" else rear
		var lamp := "TailLamp" if tail or t == "nr" else "HeadLamp"
		return _key(str(prof[c][2]), t, depth[r], nose, liv, lamp, c == board_c)
	VehicleKit.skin(lm, rows, keys, [], true)
	if bool(sec.get("open", false)) and not far:
		# An open car shows its inside: the same shell, facing in.
		var inner := _ckey(liv["inner"])
		var keys_in := func(r: int, c: int) -> String:
			var key: String = keys.call(r, c)
			return key if key in ["", "Glass"] else inner
		VehicleKit.skin(lm, rows, keys_in, [], true, true)
		_interior(lm, w, prof, side, liv)
	for end: Array in [[front, half, 1.0, "HeadLamp"], [rear, -half, -1.0, "TailLamp"]]:
		var nose: Dictionary = end[0]
		var dir := float(end[2])
		if nose.is_empty():
			# Half of the bellows to the next section.
			var top := float(prof[prof.size() - 1][0])
			var low := float(prof[0][0]) + 0.08
			var across := w * 1.84
			if k.has("gangway"):
				# A train's gangway: narrower than the car, from the floor up.
				var gangway: Vector2 = k["gangway"]
				across = gangway.x
				top = low + gangway.y + 0.2
			lm.box("Dark", Vector3(float(end[1]) + dir * float(k["gap"]) * 0.27, (top + low) * 0.5 - 0.1, 0.0),
				Vector3(float(k["gap"]) * 0.56, top - low - 0.2, across), Basis(), 0.0)
		elif str(nose.get("lamps", "")) == "single":
			var at := Vector3(float(end[1]), belt - 0.42, 0.0)
			var lens := "TailLamp" if tail else str(end[3])
			lm.disc("Metal", at + Vector3(dir * 0.006, 0, 0), Vector3(dir, 0, 0), 0.15, 8 if far else 16)
			lm.disc(lens, at + Vector3(dir * 0.014, 0, 0), Vector3(dir, 0, 0), 0.11, 8 if far else 16)

## Surface key of a shell quad: its strip's `role`, its bay type `t`,
## and on a nose how far in from the corner it lies (`k`: 1 at the
## corner, 0 on the centreline). "" leaves it open.
static func _key(role: String, t: String, k: float, nose: Dictionary, liv: Dictionary, lamp: String,
		board_strip: bool) -> String:
	if t == "cap":
		return "Dark"
	var on_nose := t == "nf" or t == "nr"
	# A train's painted door leaf (glazed at window height only) and the
	# one colour of its cab end.
	if t == "D" and liv.has("door") and role in ["lower", "lamp", "band", "upper"]:
		return _ckey(liv["door"])
	if on_nose and liv.has("cab") and role in ["lower", "band", "upper"]:
		if not (role == "upper" and board_strip and bool(nose.get("board", false)) and k < 0.62):
			return _ckey(liv["cab"])
	match role:
		"under", "skirt":
			return "Dark"
		"roof":
			return "Roof"
		"lower", "lamp", "band":
			if on_nose:
				if role == "lamp" and str(nose.get("lamps", "")) in ["pair", "tail"] and k > 0.6 and k < 0.8:
					return "TailLamp" if str(nose["lamps"]) == "tail" else lamp
				return _ckey(liv.get("cab", liv["lower" if role == "lamp" else role]))
			match t:
				"D":
					return "Glass"
				"F":
					return "Dark"
				"S", "O":
					return ""
			return _ckey(liv["lower" if role == "lamp" else role])
		"win":
			if on_nose:
				if (bool(nose.get("post", false)) and k > 0.86) or (bool(nose.get("mullion", false)) and k < 0.07):
					return _ckey(liv["pillar"])
				return "" if bool(nose.get("open", false)) else "Glass"
			match t:
				"W", "D":
					return "Glass"
				"F":
					return "Dark"
				"S", "O":
					return ""
			return _ckey(liv["pillar"])
		"stand", "cler":
			if not on_nose and t in ["W", "D"]:
				return "Glass"
			return "Roof" if role == "cler" and on_nose else _ckey(liv["upper"])
		"upper":
			if on_nose and board_strip and bool(nose.get("board", false)) and k < 0.62:
				return "Board"
	return _ckey(liv["upper"])

## What stands inside an open car: a bulkhead with its door where the
## saloon meets a platform or the open section, and along the open bays
## outward benches back to back, the grip lever between them and a
## running board outside.
static func _interior(lm: LandmarkMesh, w: float, prof: Array, side: Array, liv: Dictionary) -> void:
	var floor_y := float(prof[0][0])
	var top := _role_y(prof, "upper")
	var wood := _ckey(liv["inner"])
	for i in range(1, side.size() - 1):
		var b: Array = side[i]
		var before := str(side[i - 1][0])
		var after := str(side[i + 1][0])
		if str(b[0]) == "P" and ((before in ["S", "O"] and after == "W") or (before == "W" and after in ["S", "O"])):
			var x := (float(b[1]) + float(b[2])) * 0.5
			lm.box(_ckey(liv["upper"]), Vector3(x, (floor_y + top) * 0.5, 0.0), Vector3(0.05, top - floor_y, w * 1.78),
				Basis(), 0.0)
			lm.box("Dark", Vector3(x, floor_y + 0.95, 0.0), Vector3(0.07, 1.9, 0.7), Basis(), 0.0)
	var x0 := INF
	var x1 := -INF
	for b: Array in side:
		if str(b[0]) == "O":
			x0 = minf(x0, float(b[1]))
			x1 = maxf(x1, float(b[2]))
		elif str(b[0]) == "S":
			# A step under the platform's opening.
			for s: float in [1.0, -1.0]:
				lm.box("Dark", Vector3((float(b[1]) + float(b[2])) * 0.5, floor_y - 0.3, s * (w - 0.06)),
					Vector3(float(b[2]) - float(b[1]) - 0.1, 0.04, 0.3), Basis(), 0.0)
	if x1 < x0:
		return
	var xm := (x0 + x1) * 0.5
	var run := x1 - x0 - 0.1
	for s: float in [1.0, -1.0]:
		lm.box(wood, Vector3(xm, floor_y + 0.45, s * w * 0.66), Vector3(run, 0.06, w * 0.56), Basis(), 0.0)
		lm.box(wood, Vector3(xm, floor_y + 0.7, s * w * 0.36), Vector3(run, 0.56, 0.06), Basis(), 0.0)
		lm.box(_ckey(liv["lower"]), Vector3(xm, floor_y + 0.21, s * w * 0.6), Vector3(run, 0.42, 0.05), Basis(), 0.0)
		lm.box(wood, Vector3(xm, floor_y - 0.3, s * (w + 0.13)), Vector3(run + 0.3, 0.05, 0.3), Basis(), 0.0)
	lm.beam("Metal", Vector3(xm + 0.1, floor_y, 0.0), Vector3(xm - 0.2, floor_y + 1.3, 0.0), 0.05)
	lm.beam("Metal", Vector3(xm + 0.5, floor_y, 0.0), Vector3(xm + 0.35, floor_y + 1.1, 0.0), 0.04)

## Bogies (or a two-axle car's one truck) under the section.
static func _running_gear(lm: LandmarkMesh, k: Dictionary, sec: Dictionary, liv: Dictionary, far: bool) -> void:
	var gauge := float(liv["gauge"])
	var r := float(k["wheel_r"])
	var w := float(k["w"]) * 0.5
	if sec.has("truck"):
		var truck: Array = sec["truck"]
		var a := float(truck[0])
		var b := float(truck[1])
		_frame(lm, (a + b) * 0.5, b - a + 2.0 * r + 0.5, gauge, r, far)
		for ax: float in [a, b]:
			_axle(lm, ax, gauge, r, far)
		if not far:
			# Lifeguards under both platforms, a bumper beam at each end.
			var half := float(sec["len"]) * 0.5
			var floor_h := float(sec["prof"][0][0])
			for s: float in [1.0, -1.0]:
				lm.box("Dark", Vector3(s * (half - 0.75), 0.24, 0.0), Vector3(0.5, 0.05, gauge + 0.7), Basis(), 0.0)
				lm.box("Dark", Vector3(s * (half - 0.04), floor_h - 0.03, 0.0), Vector3(0.12, 0.14, 1.7), Basis(), 0.0)
		return
	var axle := float(sec.get("axle", 0.9))
	var floor_y := float(sec["prof"][0][0])
	# A train's underfloor equipment cases, between the bogies.
	for b: Array in sec.get("under", []):
		lm.box("Dark", Vector3(float(b[0]), (floor_y + 0.3) * 0.5 + 0.02, 0.0),
			Vector3(float(b[1]), floor_y - 0.3, w * 1.72), Basis(), 0.0)
	for x: float in sec.get("bogies", []):
		_frame(lm, x, 2.0 * (axle + r) + 0.1, gauge, r, far)
		for ax: float in [x - axle, x + axle]:
			_axle(lm, ax, gauge, r, far)
		if not far and floor_y < 0.6 and absf(x) < float(sec["len"]) * 0.5:
			# Skirt panels over a low-floor car's bogie.
			for s: float in [1.0, -1.0]:
				lm.box("Dark", Vector3(x, floor_y - 0.05, s * (w * 0.9)), Vector3(2.0 * (axle + r) + 0.3, 0.14, 0.04),
					Basis(), 0.0)

## A truck's side frames and cross members as one dark block; from afar
## it also stands in for the wheels, down to the rail.
static func _frame(lm: LandmarkMesh, x: float, length: float, gauge: float, r: float, far: bool) -> void:
	if far:
		lm.box("Dark", Vector3(x, r * 0.7, 0.0), Vector3(length, r * 1.4, gauge + 0.2), Basis(), 0.0)
	else:
		lm.box("Dark", Vector3(x, r, 0.0), Vector3(length, 0.2, gauge + 0.42), Basis(), 0.0)

## A wheelset at `x`: two steel wheels on the rails, `gauge` apart.
static func _axle(lm: LandmarkMesh, x: float, gauge: float, r: float, far: bool) -> void:
	if far:
		return
	var hw := 0.05
	for s: float in [1.0, -1.0]:
		var c := Vector3(x, r, s * (gauge * 0.5 + hw))
		VehicleKit.revolve(lm, "Metal", c, PackedVector2Array([Vector2(r, -hw), Vector2(r, hw)]), 18, s, false)
		lm.disc("Metal", c + Vector3(0, 0, s * hw), Vector3(0, 0, s), r, 18)
		lm.disc("Dark", c - Vector3(0, 0, s * hw), Vector3(0, 0, -s), r, 18)
	lm.beam("Dark", Vector3(x, r, -gauge * 0.5), Vector3(x, r, gauge * 0.5), 0.1)

## Equipment boxes, and the pantograph or trolley pole reaching the wire.
static func _roof_gear(lm: LandmarkMesh, sec: Dictionary) -> void:
	var prof: Array = sec["prof"]
	var top := float(prof[prof.size() - 1][0])
	for b: Array in sec.get("boxes", []):
		lm.box("Metal", Vector3(float(b[0]), top + 0.1, 0.0), Vector3(float(b[1]), 0.34, 1.5), Basis(), 0.05)
	if sec.has("panto"):
		var x := float(sec["panto"])
		lm.box("Metal", Vector3(x, top + 0.03, 0.0), Vector3(1.6, 0.1, 1.0), Basis(), 0.0)
		var foot := Vector3(x - 0.7, top + 0.1, 0.0)
		var knee := Vector3(x + 0.6, lerpf(top, COLLECTOR_M, 0.48), 0.0)
		var head := Vector3(x - 0.2, COLLECTOR_M - 0.04, 0.0)
		lm.beam("Dark", foot, knee, 0.07)
		lm.beam("Dark", knee, head, 0.05)
		lm.beam("Dark", foot + Vector3(1.0, 0, 0), foot.lerp(knee, 0.55), 0.035)
		for dx: float in [-0.14, 0.14]:
			lm.box("Dark", head + Vector3(dx, 0.02, 0.0), Vector3(0.05, 0.04, 1.5), Basis(), 0.0)
	if sec.has("pole"):
		var x := float(sec["pole"])
		lm.box("Metal", Vector3(x, top + 0.06, 0.0), Vector3(0.6, 0.14, 0.4), Basis(), 0.0)
		lm.beam("Dark", Vector3(x, top + 0.12, 0.0), Vector3(x - 4.4, COLLECTOR_M, 0.0), 0.045)

## The far mesh with every painted surface folded into one
## vertex-coloured surface: three draws a section, whatever the livery.
static func _folded(src: ArrayMesh) -> ArrayMesh:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var col := PackedColorArray()
	var out := ArrayMesh.new()
	for si in src.get_surface_count():
		var name := src.surface_get_name(si)
		var arr := src.surface_get_arrays(si)
		if name in ["Roof", "Glass"]:
			var keep := []
			keep.resize(Mesh.ARRAY_MAX)
			keep[Mesh.ARRAY_VERTEX] = arr[Mesh.ARRAY_VERTEX]
			keep[Mesh.ARRAY_NORMAL] = arr[Mesh.ARRAY_NORMAL]
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, keep)
			out.surface_set_name(out.get_surface_count() - 1, name)
			out.surface_set_material(out.get_surface_count() - 1, src.surface_get_material(si))
			continue
		var tint := (src.surface_get_material(si) as StandardMaterial3D).albedo_color
		var sv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		v.append_array(sv)
		n.append_array(arr[Mesh.ARRAY_NORMAL] as PackedVector3Array)
		for i in sv.size():
			col.append(tint)
	if not v.is_empty():
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = v
		arrays[Mesh.ARRAY_NORMAL] = n
		arrays[Mesh.ARRAY_COLOR] = col
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.surface_set_name(out.get_surface_count() - 1, "Paint")
		out.surface_set_material(out.get_surface_count() - 1, material("FarPaint"))
	return out

## The shared paint of one livery colour.
static func paint(c: Color) -> StandardMaterial3D:
	var id := _ckey(c)
	if _materials.has(id):
		return _materials[id]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.36 if c.v > 0.1 else 0.6
	m.metallic_specular = 0.5
	_materials[id] = m
	return m

## The roof in `c`: it takes the season's snow, like the street's roofs.
static func roof(c: Color) -> ShaderMaterial:
	var id := "Roof" + c.to_html(false)
	if _materials.has(id):
		return _materials[id]
	var src := StandardMaterial3D.new()
	src.albedo_color = c
	src.roughness = 0.6
	var m := StreetSnow.material(src)
	m.set_shader_parameter("use_vertex", false)
	_materials[id] = m
	return m

## The shared material of a fixed surface key.
static func material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	match key:
		"Glass":
			# Dark, mirror-smooth glass by day (as CarModel's); the saloon
			# lights show through it at night.
			m.albedo_color = Color(0.03, 0.04, 0.05)
			m.roughness = 0.04
			m.metallic_specular = 0.6
			m.emission_enabled = true
			m.emission = Color(1.0, 0.86, 0.62)
			CityLights.mark_glow(m, 0.14)
		"Dark":
			m.albedo_color = TramSpecs.DARK
			m.roughness = 0.6
		"Metal":
			m.albedo_color = Color(0.4, 0.41, 0.42)
			m.metallic = 0.6
			m.roughness = 0.45
		"HeadLamp":
			m.albedo_color = Color(0.85, 0.87, 0.88)
			m.roughness = 0.15
			m.emission_enabled = true
			m.emission = Color(1.0, 0.95, 0.82)
			CityLights.mark_glow(m, 3.0)
		"TailLamp":
			m.albedo_color = Color(0.45, 0.02, 0.02)
			m.roughness = 0.15
			m.emission_enabled = true
			m.emission = Color(1.0, 0.06, 0.04)
			CityLights.mark_glow(m, 1.6)
		"Board":
			# The destination panel: a plain light panel, no text.
			m.albedo_color = Color(0.06, 0.05, 0.03)
			m.roughness = 0.2
			m.emission_enabled = true
			m.emission = Color(1.0, 0.62, 0.16)
			CityLights.mark_glow(m, 1.0)
		"FarPaint":
			m.vertex_color_use_as_albedo = true
			m.vertex_color_is_srgb = true
			m.roughness = 0.45
	_materials[key] = m
	return m

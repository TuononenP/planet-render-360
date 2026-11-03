class_name KerbBuilder
extends RefCounted

## Raised kerbs (desktop Ultra, Phase 7 of the Ultra pass): a stone kerb
## along both edges of urban streets near the eye, where lower tiers
## keep RoadSurface's painted kerb band. Profile across the edge, from
## the carriageway out: a HEIGHT_M vertical face, a TOP_M flat top, then
## a RAMP_M slope down to the ground behind (the pavement line, which
## the ground mesh does not raise). It sits over the painted band
## (INSET_M inside the ribbon edge) and stops CUT_M short of every
## junction node, so it never crosses a side street. Draped on the road's
## surface height. Granite grey in Europe and most places, poured
## concrete in North America (also RoadSurface's band colour).

const RADIUS_M := 400.0
const HEIGHT_M := 0.13
const TOP_M := 0.25
const RAMP_M := 0.5
const INSET_M := 0.25
const CUT_M := 9.0
const STEP_M := 2.0
## Above the draped ground, like the road ribbon (RoadBuilder lift).
const LIFT_M := 0.04
const GRANITE := Color(0.30, 0.30, 0.29)
const CONCRETE := Color(0.46, 0.45, 0.42)

static func stone_for(data: LocationData) -> Color:
	var region := ArchitectureStyle.country_region_for(data.latitude, data.longitude, data.country)
	return CONCRETE if StreetFurniture.furniture_family(region, data.country) == "na" else GRANITE

## Adds the kerb mesh to `root` on desktop Ultra. Returns metres of kerb.
static func build(root: Node3D, data: LocationData, ground: GroundTruth) -> float:
	if not RenderQuality.ultra_desktop(data.quality_preset):
		return 0.0
	var m := WorldScale.metres_to_units()
	var junc := RoadSurface.junctions(data)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var total := 0.0
	var r2 := pow(RADIUS_M * m, 2.0)
	for line in data.roads:
		if not (line is Dictionary):
			continue
		var rd: Dictionary = line
		if bool(rd.get("tunnel", false)) or bool(rd.get("bridge", false)) or bool(rd.get("area", false)):
			continue
		if str(rd.get("class", "")) not in StreetProps.LIT:
			continue
		var pts: PackedVector2Array = rd.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var mid := pts[pts.size() / 2]
		if mid.length_squared() > r2 or ground.land_class_at(mid.x, mid.y) != "urban":
			continue
		var half := float(rd.get("width_m", 6.0)) * 0.5 * m - INSET_M * m
		for run in _runs(_dense(pts, STEP_M * m), junc, m, r2):
			for side in [-1.0, 1.0]:
				total += _strip(st, run, half * side, side, ground, m)
	if total <= 0.0:
		return 0.0
	st.generate_normals()
	st.generate_tangents()
	var mi := MeshInstance3D.new()
	mi.name = "Kerbs"
	mi.mesh = st.commit()
	var stone := stone_for(data)
	var set_name := "concrete" if stone == CONCRETE else "stone"
	var row: Dictionary = MaterialLibrary.PBR_SETS[set_name]
	mi.material_override = StreetSnow.material(MaterialLibrary.pbr_material(set_name,
		MaterialLibrary._calib_tint(row["mean"], stone), 1.0) as StandardMaterial3D)
	root.add_child(mi)
	return total / m

## The line resampled every `step` (internal units).
static func _dense(pts: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array([pts[0]])
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var n := maxi(1, int(ceil(a.distance_to(b) / step)))
		for k in range(1, n + 1):
			out.append(a.lerp(b, float(k) / float(n)))
	return out

## Pieces of the line farther than CUT_M from any junction and inside
## the radius.
static func _runs(line: PackedVector2Array, junc: Dictionary, m: float, r2: float) -> Array:
	var out: Array = []
	var cur := PackedVector2Array()
	for p in line:
		var keep := p.length_squared() <= r2 \
			and RoadSurface.junction_frac(junc, p) * RoadSurface.JUNCTION_M > CUT_M * m
		if keep:
			cur.append(p)
		elif cur.size() >= 2:
			out.append(cur)
			cur = PackedVector2Array()
		else:
			cur = PackedVector2Array()
	if cur.size() >= 2:
		out.append(cur)
	return out

## One kerb strip `off` across from the line (toward `side`), as quads
## between consecutive samples: face, top, ramp. Returns its length.
static func _strip(st: SurfaceTool, run: PackedVector2Array, off: float, side: float,
		ground: GroundTruth, m: float) -> float:
	var length := 0.0
	var prev: Array = []
	var along := 0.0
	var prev_along := 0.0
	for i in run.size():
		var p := run[i]
		var d := (run[mini(i + 1, run.size() - 1)] - run[maxi(i - 1, 0)]).normalized()
		var n := Vector2(-d.y, d.x)
		if i > 0:
			prev_along = along
			along += run[i].distance_to(run[i - 1])
		var y := ground.height_at_world(p.x, p.y) + LIFT_M * m
		var edge := p + n * off
		var top_out := edge + n * side * TOP_M * m
		var ramp_out := top_out + n * side * RAMP_M * m
		var y_out := ground.height_at_world(ramp_out.x, ramp_out.y)
		# Cross-section: kerb foot, kerb lip, back of the top, ramp foot.
		var cs := [Vector3(edge.x, y - 0.02 * m, edge.y), Vector3(edge.x, y + HEIGHT_M * m, edge.y),
			Vector3(top_out.x, y + HEIGHT_M * m, top_out.y), Vector3(ramp_out.x, y_out, ramp_out.y)]
		if not prev.is_empty():
			for k in 3:
				_quad(st, prev[k], prev[k + 1], cs[k + 1], cs[k], prev_along / m, along / m, k, side)
			length += run[i].distance_to(run[i - 1])
		prev = cs
	return length

## One quad, wound to face out of the kerb on either side of the road.
static func _quad(st: SurfaceTool, a0: Vector3, a1: Vector3, b1: Vector3, b0: Vector3,
		u0: float, u1: float, k: int, side: float) -> void:
	var v0 := float(k) * 0.3
	var v1 := v0 + 0.3
	var uv := [Vector2(u0, v0), Vector2(u0, v1), Vector2(u1, v1), Vector2(u1, v0)]
	var q := [a0, a1, b1, b0]
	var order := [0, 1, 2, 0, 2, 3] if side < 0.0 else [0, 2, 1, 0, 3, 2]
	for j in order:
		st.set_uv(uv[j])
		st.add_vertex(q[j])

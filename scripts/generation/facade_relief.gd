class_name FacadeRelief
extends RefCounted

## Real 3D facade relief on near buildings. The composed facade textures
## paint every window, balcony and moulding, but painted relief has no
## silhouette, casts no shadow and vanishes when a street is seen edge-on
## — the reason a block read as a flat box. On every exposed wall stretch
## (PartyWalls: not a shared wall) this builds what projects from a real
## facade, on the facade's own storey rows and window bays so stone and
## iron line up with the painted windows:
## - string courses at the floor lines (Paris always, else `string_course`);
## - continuous balconies: slab + wrought-iron railing (Paris on its
##   painted balcony rows; elsewhere the look's `balcony_rows`);
## - balconettes: an iron rail across a tall window (Paris rows that paint
##   them; elsewhere a `balconette` share of French windows);
## - deep projecting balconies per bay (modernist blocks, `deep_balcony`);
## - stone sills under punched windows, quoins at corners (`quoins`);
## - bay windows (`oriel`): canted glazed bays up the street front.
## StreetFront adds the ground floor and street furniture of the facade.
## Driven by the look's `relief` dict (ArchitectureStyle); seeded per
## building; distance-gated like BuildingTrim (every tier, AC-12).

## Relief only within this distance of the viewpoint (m).
const RADIUS_M := 300.0
## Shortest exposed stretch that gets relief (m).
const MIN_SPAN_M := 1.5
## Patterns whose windows are punched openings (sills, balconettes).
const PUNCHED: Array[String] = ["punched", "ornate", "brownstone", "shophouse",
	"haussmann", "balcony"]

## `d`: {ring, cover, base, g_top, top, v_rep, storeys, look, facade, seed,
## party, b, ground_y, roof_h, shape, gable_front} (internal units).
static func add(root: Node3D, d: Dictionary) -> void:
	var facade: Material = d["facade"]
	var uvp := FacadeMaterials.facade_uv(facade)
	if uvp.x <= 0.0:
		return
	var look: Dictionary = d["look"]
	var relief: Dictionary = look.get("relief", {})
	var kit := ReliefKit.new()
	var rows := storey_rows(d, uvp)
	var stone := ReliefKit.stone(str(look.get("wall_set", "limestone")),
		look.get("wall_colour", Color(0, 0, 0, 0)))
	var party: PartyWalls = d.get("party")
	var spans := exposed_spans(d["ring"], d["cover"])
	for sp in spans:
		sp["street"] = party != null and party.faces_street(sp["a"], sp["b"], sp["n"])
		sp["bays"] = 0 if float(sp["len_m"]) < uvp.x * 0.5 else maxi(1, roundi(float(sp["len_m"]) / uvp.x))
		_storeys(kit, sp, rows, look, relief, stone, float(d["seed"]), uvp.z == 0.0)
		if sp["street"] and ArchitectureStyle._h(float(d["seed"]) + float(sp["edge"]) * 0.53, 64) \
				< float(relief.get("oriel", 0.0)):
			_oriels(kit, sp, rows, stone, str(look.get("ground", "")) == "")
	StreetFront.add(kit, spans, rows, d, stone)
	kit.flush(root, "Relief")

## Exposed stretches of the ring's edges: [{a, b, n, dir, len_m, first,
## last}] (first/last: the stretch starts/ends at a ring corner).
static func exposed_spans(ring: PackedVector2Array, cover: Array) -> Array:
	var m := WorldScale.metres_to_units()
	var out: Array = []
	for i in ring.size():
		var ea := ring[i]
		var eb := ring[(i + 1) % ring.size()]
		if ea.distance_to(eb) < MIN_SPAN_M * m:
			continue
		var n := PartyWalls.outward(ring, i)
		var pieces: Array = cover[i] if i < cover.size() else [[0.0, 1.0, PartyWalls.OPEN]]
		for pc in pieces:
			if not is_inf(float(pc[2])):
				continue
			var a := ea.lerp(eb, float(pc[0]))
			var b := ea.lerp(eb, float(pc[1]))
			var len := a.distance_to(b)
			if len < MIN_SPAN_M * m:
				continue
			out.append({"a": a, "b": b, "n": n, "dir": (b - a) / len, "len_m": len / m,
				"first": float(pc[0]) < 0.001, "last": float(pc[1]) > 0.999, "edge": i})
	return out

## Storey rows bottom-up, in world Y: {y0, y1, storey, ground, win0, win1,
## win_w (share of a bay), balcony, balconette, slab, rail_h}. The Paris
## facade follows StoreyComposer.paris_rows over the whole wall; tiled
## patterns stack one storey per tile above the ground band.
static func storey_rows(d: Dictionary, uvp: Vector3) -> Array:
	var look: Dictionary = d["look"]
	var relief: Dictionary = look.get("relief", {})
	var base := float(d["base"])
	var top := float(d["top"])
	var out: Array = []
	if uvp.z == 0.0:
		var rows := clampi(int(d["storeys"]), 1, 8)
		var layout := StoreyComposer.paris_rows(rows, int(look.get("variant", 0)))
		var k := (top - base) / float(StoreyComposer.S)
		var bay_px := float(StoreyComposer.S) / float(StoreyComposer.PARIS_BAYS)
		for r in range(rows - 1, -1, -1):
			var row: Dictionary = layout[r]
			var win_h := float(row["win_h"])
			out.append({"y0": top - (float(row["y"]) + float(row["h"])) * k,
				"y1": top - float(row["y"]) * k, "storey": rows - 1 - r,
				"ground": row["ground"] or rows == 1,
				"win0": top - (float(row["win_y"]) + win_h) * k,
				"win1": top - float(row["win_y"]) * k,
				"win_w": minf(win_h * 0.56, bay_px * 0.5) / bay_px,
				"balcony": row["balcony"], "balconette": row["balconette"],
				"slab": top - float(row["slab_y"]) * k, "rail_h": float(row["rail_h"]) * k})
		return out
	var g_top := float(d["g_top"])
	var banded := g_top > base + 0.01
	var y0 := g_top if banded else base
	var n := maxi(1, int(float(d["v_rep"])) - (1 if banded else 0))
	if banded:
		out.append({"y0": base, "y1": g_top, "storey": 0, "ground": true,
			"win0": base, "win1": g_top, "win_w": 0.7, "balcony": false,
			"balconette": false, "slab": g_top, "rail_h": 0.0})
	var box := FacadeComposer._window_box(str(look.get("window", "casement")))
	var cell := float(FacadeComposer.CELL)
	var rh := (top - y0) / float(n)
	var rows_b: Array = relief.get("balcony_rows", [])
	for j in n:
		var yt := y0 + rh * float(j + 1)
		var storey := j + (1 if banded else 0)
		var w1 := yt - float(box.z) / cell * rh
		var w0 := w1 - float(box.y) / cell * rh
		out.append({"y0": yt - rh, "y1": yt, "storey": storey,
			"ground": storey == 0, "win0": w0, "win1": w1,
			"win_w": float(box.x) / cell, "balcony": storey > 0 and rows_b.has(storey),
			"balconette": false, "slab": w0 + 0.05 * WorldScale.metres_to_units(),
			"rail_h": 1.0 * WorldScale.metres_to_units()})
	return out

## Upper-storey relief on one exposed stretch.
static func _storeys(kit: ReliefKit, sp: Dictionary, rows: Array, look: Dictionary,
		relief: Dictionary, stone: Material, seed_v: float, paris: bool) -> void:
	var m := WorldScale.metres_to_units()
	var a: Vector2 = sp["a"]
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var len := float(sp["len_m"]) * m
	var bays := int(sp["bays"])
	var step := len / float(maxi(bays, 1))
	var mid := a + dir * len * 0.5
	var pattern := str(look.get("pattern", ""))
	var punched := pattern in PUNCHED
	var french := paris or str(look.get("window", "")) == "french"
	var courses := paris or bool(relief.get("string_course", false))
	var deep := ArchitectureStyle._h(seed_v, 61) < float(relief.get("deep_balcony", 0.0))
	var solid := str(look.get("wall_set", "")) == "concrete" or pattern in ["panel", "strip"]
	for row in rows:
		if row["ground"]:
			continue
		var y0 := float(row["y0"])
		if courses:
			kit.box(stone, Vector3(mid.x, y0 + 0.09 * m, mid.y) + az * 0.06 * m, ax, az,
				Vector3(len, 0.18 * m, 0.12 * m))
		if row["balcony"]:
			_balcony(kit, a, dir, n, len, float(row["slab"]), float(row["rail_h"]),
				0.55 * m if paris else 0.8 * m, stone)
		for j in bays:
			var c := a + dir * step * (float(j) + 0.5)
			var ww := step * float(row["win_w"])
			var w0 := float(row["win0"])
			var hv := ArchitectureStyle._h(seed_v + float(j) * 0.37, 70 + int(row["storey"]))
			if deep and not row["balcony"]:
				_deep_balcony(kit, c, ax, az, step * 0.86, y0, stone, solid)
				continue
			if punched and not row["balcony"] and pattern != "balcony":
				kit.box(stone, Vector3(c.x, w0 - 0.04 * m, c.y) + az * 0.07 * m, ax, az,
					Vector3(ww + 0.2 * m, 0.08 * m, 0.14 * m))
			var rail_here: bool = row["balconette"] if paris \
				else (french and hv < float(relief.get("balconette", 0.0)))
			if rail_here and not row["balcony"]:
				var h := minf(0.9 * m, (float(row["win1"]) - w0) * 0.32)
				var off := az * 0.16 * m
				var p0 := Vector3(c.x, w0, c.y) - ax * (ww * 0.5 + 0.06 * m) + off
				var p1 := Vector3(c.x, w0, c.y) + ax * (ww * 0.5 + 0.06 * m) + off
				kit.rail(p0, p1, h, az)
				kit.box(stone, Vector3(c.x, w0 - 0.03 * m, c.y) + az * 0.09 * m, ax, az,
					Vector3(ww + 0.18 * m, 0.06 * m, 0.18 * m))
	if bool(relief.get("quoins", false)):
		_quoins(kit, sp, rows, stone)

## Continuous balcony along the stretch: a stone slab whose top is at
## `slab`, `depth` out, with an iron railing on its front and ends.
static func _balcony(kit: ReliefKit, a: Vector2, dir: Vector2, n: Vector2,
		len: float, slab: float, rail_h: float, depth: float, stone: Material) -> void:
	var m := WorldScale.metres_to_units()
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var mid := a + dir * len * 0.5
	var t := 0.16 * m
	kit.box(stone, Vector3(mid.x, slab - t * 0.5, mid.y) + az * depth * 0.5, ax, az,
		Vector3(len, t, depth))
	var h := clampf(rail_h, 0.8 * m, 1.1 * m)
	var f0 := Vector3(a.x, slab, a.y) + az * (depth - 0.03 * m) + ax * 0.05 * m
	var f1 := f0 + ax * (len - 0.1 * m)
	kit.rail(f0, f1, h, az)
	kit.rail(Vector3(a.x, slab, a.y) + ax * 0.05 * m, f0, h, -ax)
	kit.rail(f1, Vector3(a.x, slab, a.y) + ax * (len - 0.05 * m), h, ax)

## A projecting balcony in one bay at floor level y: slab plus a solid
## concrete parapet (modern blocks) or an iron railing.
static func _deep_balcony(kit: ReliefKit, c: Vector2, ax: Vector3, az: Vector3,
		w: float, y: float, stone: Material, solid: bool) -> void:
	var m := WorldScale.metres_to_units()
	var depth := 1.15 * m
	var t := 0.18 * m
	var base := Vector3(c.x, y, c.y)
	kit.box(stone, base + Vector3.UP * t * 0.5 + az * depth * 0.5, ax, az, Vector3(w, t, depth))
	if solid:
		kit.box(stone, base + Vector3.UP * (t + 0.5 * m) + az * (depth - 0.05 * m), ax, az,
			Vector3(w, 1.0 * m, 0.1 * m))
		for s in [-1.0, 1.0]:
			kit.box(stone, base + Vector3.UP * (t + 0.5 * m) + az * depth * 0.5 + ax * s * (w * 0.5 - 0.05 * m),
				ax, az, Vector3(0.1 * m, 1.0 * m, depth))
	else:
		var f0 := base + Vector3.UP * t + az * (depth - 0.03 * m) - ax * w * 0.5
		var f1 := f0 + ax * w
		kit.rail(f0, f1, 1.0 * m, az)
		kit.rail(f0 - az * (depth - 0.06 * m), f0, 1.0 * m, -ax)
		kit.rail(f1, f1 - az * (depth - 0.06 * m), 1.0 * m, ax)

## Quoins: alternating long and short stones up both corners of a stretch
## that ends at a ring corner.
static func _quoins(kit: ReliefKit, sp: Dictionary, rows: Array, stone: Material) -> void:
	if rows.is_empty():
		return
	var m := WorldScale.metres_to_units()
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var y_lo := float(rows[0]["y1"]) if rows[0]["ground"] else float(rows[0]["y0"])
	var y_hi := float(rows[-1]["y1"])
	var courses := int((y_hi - y_lo) / (0.6 * m))
	for end in [[sp["first"], sp["a"], 1.0], [sp["last"], sp["b"], -1.0]]:
		if not end[0]:
			continue
		var p: Vector2 = end[1]
		for k in courses:
			var w := (0.9 if k % 2 == 0 else 0.55) * m
			var c := Vector3(p.x, y_lo + (float(k) + 0.5) * 0.6 * m, p.y) \
				+ ax * float(end[2]) * w * 0.5 + az * 0.03 * m
			kit.box(stone, c, ax, az, Vector3(w, 0.52 * m, 0.06 * m))

## Bay windows on every other bay of a street stretch: a canted stone bay
## 0.6 m deep up the storeys (from the ground on a house without a shop
## front), glazed on its front and both canted sides per storey.
static func _oriels(kit: ReliefKit, sp: Dictionary, rows: Array, stone: Material,
		from_ground: bool) -> void:
	var bays := int(sp["bays"])
	if bays < 1 or rows.size() < 2:
		return
	var m := WorldScale.metres_to_units()
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0.0, dir.y)
	var az := Vector3(n.x, 0.0, n.y)
	var step := float(sp["len_m"]) * m / float(bays)
	var glass := ReliefKit.glass()
	var depth := 0.6 * m
	var lo := 0 if from_ground else 1
	for j in range(0 if bays < 3 else 1, bays, 2):
		var c2: Vector2 = (sp["a"] as Vector2) + dir * step * (float(j) + 0.5)
		var w := step * 0.78
		var front := w - 2.0 * depth * 0.7
		for r in range(lo, rows.size()):
			var row: Dictionary = rows[r]
			var y0 := float(row["y0"]) + (0.1 * m if r == lo else 0.0)
			var y1 := float(row["y1"])
			var c := Vector3(c2.x, 0.0, c2.y)
			# Front face and the two canted cheeks (45°), sill to lintel.
			var fl := c - ax * front * 0.5 + az * depth
			var fr := c + ax * front * 0.5 + az * depth
			var bl := c - ax * w * 0.5
			var br := c + ax * w * 0.5
			for face in [[fl, fr], [bl, fl], [fr, br]]:
				var p0: Vector3 = face[0]
				var p1: Vector3 = face[1]
				var fn := (p1 - p0).cross(Vector3.UP).normalized()
				if fn.dot(az) < 0.0:
					fn = -fn
				var up0 := Vector3.UP * y0
				var up1 := Vector3.UP * y1
				kit.quad(stone, p0 + up0, p1 + up0, p1 + up1, p0 + up1, fn)
				var g0 := Vector3.UP * lerpf(y0, y1, 0.22)
				var g1 := Vector3.UP * lerpf(y0, y1, 0.88)
				var inset := (p1 - p0) * 0.12
				kit.quad(glass, p0 + inset + g0 + fn * 0.01 * m, p1 - inset + g0 + fn * 0.01 * m,
					p1 - inset + g1 + fn * 0.01 * m, p0 + inset + g1 + fn * 0.01 * m, fn)
		if lo > 0:
			# Corbelled base under a bay that starts above the street.
			kit.box(stone, Vector3(c2.x, float(rows[lo]["y0"]) - 0.1 * m, c2.y) + az * depth * 0.5,
				ax, az, Vector3(w, 0.4 * m, depth))
		# Lead-capped top over the bay.
		var top := float(rows[-1]["y1"])
		kit.box(stone, Vector3(c2.x, top + 0.06 * m, c2.y) + az * depth * 0.5, ax, az,
			Vector3(w, 0.12 * m, depth + 0.08 * m))

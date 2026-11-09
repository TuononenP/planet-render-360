class_name FinlandRelief
extends RefCounted

## Small facade pieces for northern masonry: rusticated granite bases
## and corner turrets. Shares the building's ReliefKit and detail radius.
static func plinth(kit: ReliefKit, sp: Dictionary, rows: Array, seed_v: float) -> void:
	if rows.is_empty():
		return
	var m := WorldScale.metres_to_units()
	var dir: Vector2 = sp["dir"]
	var n: Vector2 = sp["n"]
	var ax := Vector3(dir.x, 0, dir.y)
	var az := Vector3(n.x, 0, n.y)
	var h := minf(float(rows[0]["y1"]) - float(rows[0]["y0"]), 1.2 * m)
	var stone := ReliefKit.stone("stone", Color.html("#958c86" if ArchitectureStyle._h(seed_v, 93) < 0.5 else "#928f89").srgb_to_linear())
	var len := float(sp["len_m"]) * m
	var count := maxi(1, ceili(len / (0.95 * m)))
	for row in 3:
		var rh := h / 3.0
		for j in count:
			var width := len / float(count)
			var c2: Vector2 = sp["a"] + dir * width * (float(j) + 0.5)
			kit.box(stone, Vector3(c2.x, float(rows[0]["y0"]) + rh * (float(row) + 0.5), c2.y)
				+ az * (0.06 + ArchitectureStyle._h(seed_v + j, 94 + row) * 0.04) * m,
				ax, az, Vector3(width - 0.025 * m, rh - 0.02 * m, 0.18 * m))

## Last construction year a Jugend / national-romantic corner turret fits.
const TURRET_LAST_YEAR := 1930

## True when a corner turret suits mass `d`: not a lifted part (its top is
## another part's floor, not a roofline) and not a building mapped as built
## after the style ended (Aalto's 1961 Enso-Gutzeit block is a flat marble
## cube). An undated building keeps the regional odds.
static func turret_fits(d: Dictionary) -> bool:
	if bool(d.get("raised", false)):
		return false
	var year := int((d.get("b", {}) as Dictionary).get("start_year", 0))
	return year <= 0 or year < TURRET_LAST_YEAR

static func turret(kit: ReliefKit, sp: Dictionary, d: Dictionary, stone: Material) -> void:
	if not bool(sp["first"]) or float(sp["len_m"]) < 8.0:
		return
	var m := WorldScale.metres_to_units()
	var p: Vector2 = sp["a"]
	var c := Vector3(p.x, float(d["top"]) - 1.5 * m, p.y)
	var r := 1.35 * m
	var roof := ReliefKit.flat("#39413e", 0.6, 0.3)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var b := TAU * float(k + 1) / 12.0
		var n := Vector3(cos((a + b) * 0.5), 0, sin((a + b) * 0.5))
		var p0 := c + Vector3(cos(a), 0, sin(a)) * r
		var p1 := c + Vector3(cos(b), 0, sin(b)) * r
		kit.quad(stone, p0, p1, p1 + Vector3.UP * 3.5 * m, p0 + Vector3.UP * 3.5 * m, n)
		var base0 := p0 + Vector3.UP * 3.5 * m
		var base1 := p1 + Vector3.UP * 3.5 * m
		var tip := c + Vector3.UP * 8.0 * m
		kit.tri(roof, base0, base1, tip, (n + Vector3.UP * 0.3).normalized())

## A short masonry corner drum capped with a patinated copper dome.
static func corner_dome(kit: ReliefKit, sp: Dictionary, d: Dictionary, stone: Material) -> void:
	if not bool(sp["first"]) or float(sp["len_m"]) < 8.0:
		return
	var m := WorldScale.metres_to_units()
	var centre: Vector2 = sp["a"]
	var base := float(d["top"]) - 1.0 * m
	var radius := 1.35 * m
	var ring := PackedVector2Array()
	for i in 12:
		var angle := TAU * float(i) / 12.0
		ring.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var normal := ((a + b) * 0.5 - centre).normalized()
		kit.quad(stone, Vector3(a.x, base, a.y), Vector3(b.x, base, b.y),
			Vector3(b.x, base + 3.0 * m, b.y), Vector3(a.x, base + 3.0 * m, a.y),
			Vector3(normal.x, 0, normal.y))
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	if RoofDomes.faces(ring, centre, base + 3.0 * m, 1.8 * m, "dome", vertices, normals, uvs):
		var copper := ReliefKit.flat("#719384", 0.65, 0.3)
		for i in range(0, vertices.size(), 3):
			kit.tri(copper, vertices[i], vertices[i + 1], vertices[i + 2],
				(normals[i] + normals[i + 1] + normals[i + 2]).normalized())

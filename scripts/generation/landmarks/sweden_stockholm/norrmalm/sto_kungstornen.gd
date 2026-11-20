extends RefCounted

## Kungstornen, the two King's Towers on Kungsgatan (Sven Wallander and
## Arvid Bjerke, 1924-25), with the granite bridge between them. Origin at
## the centre of the northern tower (OSM way 121566299, 18.4 x 16.4 m, 60 m);
## the southern tower (way 121265089, 17.2 x 16.6 m, 61 m) stands at
## SOUTH_C, 44 m south and 2 m east in this frame, the bridge across
## Kungsgatan between them. Long axis +X: the registry yaw (-7.1) turns it
## onto the mapped bearing 82.9, so local +Z is south-south-east. The
## registry clears the southern footprint with `clear_offsets_m` at SOUTH_C.
##
## From the photos (front, quarter, side in visual-plan/refs/landmarks/
## kungstornen/; the crowns are flat with dark roofs, not copper pyramids):
## - Chicago-style stone-faced steel frames: a two-storey base of heavy
##   rusticated pink-grey granite with arched openings, then a shaft of dark
##   grey-brown render with three columns of tall mullioned windows to a
##   face, twelve storeys of them, between flat pilaster strips; the corner
##   piers are wider and coursed in horizontal bands.
## - A stepped stone platform with a balustrade carries the crown: a
##   recessed arcade of round-headed openings, each with a gilded shell
##   head, a frieze with round lights, and a projecting terracotta-toned
##   dentilled cornice. Gilded balls with white flagpoles stand on the far
##   corners; green-patina figures stand on the front corners.
## - The roofs are flat and dark. The northern tower tops out at 58.6 m
##   (poles to 60 m), the southern at 59.6 m (poles to 61 m).
## - Between the tower bases a flat-topped red-grey granite arch bridge
##   (deck 15 m, soffit springing at 7.5 m and rising to 12 m) carries
##   Malmskillnadsgatan over Kungsgatan, with solid parapets.
## Window bays, the crown arch counts and the bridge profile are scaled
## from the photos; the shells glow at night and the crowns are floodlit.

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_pal_kit.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const SOUTH_C := Vector2(2.0, 44.0)
const BASE := 8.5
const PIER := 2.4
const STOREY := 3.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#6B6358", 3.0))
	lm.use("Pier", LandmarkMaterials.pbr("limestone", "#7A7064", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#74645C", 2.6))
	lm.use("Crown", LandmarkMaterials.pbr("render", "#B5785C", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3340"))
	lm.use("Frame", LandmarkMaterials.paint("#2F2E2D", 0.5, 0.3))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#3E3F41", 3.0, 0.7))
	lm.use("Lamp", LandmarkMaterials.lit("#FFC970", 0.5))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Pole", LandmarkMaterials.paint("#ECECE8", 0.5, 0.3))
	lm.use("Copper", LandmarkMaterials.pbr("sheet_metal", "#6F9C88", 2.0, 0.55, 0.35))
	_tower(lm, Vector2.ZERO, 18.4, 16.4, 58.6, 60.0)
	_tower(lm, SOUTH_C, 17.2, 16.6, 59.6, 61.0)
	_bridge(lm, -5.8, 7.8, 8.5, SOUTH_C.y - 8.6)
	lm.commit(model)
	var warm := Color(1.0, 0.86, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.5, -26.0), Vector3(0.0, 50.0, -8.0), 32.0, 0.9, 80.0, warm],
		[Vector3(2.0, 1.5, 70.0), Vector3(2.0, 50.0, 52.0), 32.0, 0.9, 80.0, warm]])

# --- Towers --------------------------------------------------------------

## One tower centred on `c`, w (X) x d (Z): base, shaft, platform, crown.
## `ct` is the crown cornice top, `pole_top` the flagpole tips.
static func _tower(lm: LandmarkMesh, c: Vector2, w: float, d: float, ct: float, pole_top: float) -> void:
	var hx := w * 0.5
	var hz := d * 0.5
	var plat := ct - 7.2
	_base(lm, c, hx, hz)
	K.rb(lm, "Wall", c.x - hx, c.x + hx, BASE, plat, c.y - hz, c.y + hz, 0.0)
	# The four faces: [out, face-line centre, length, left corner offset].
	for f in _faces(c, hx, hz):
		var out: Vector3 = f[0]
		var mid: Vector3 = f[1]
		var len: float = f[2]
		var right := K.right(out)
		var left := mid - right * len * 0.5
		var zone := len - 2.0 * PIER
		LandmarkDetail.pierced_face(lm, "Wall", "Glass", left + right * PIER + Vector3(0, BASE, 0), right, out,
			zone, plat - BASE, 3, int((plat - BASE - 0.9) / STOREY), Vector2(1.7, 2.5), 0.9, STOREY, 0.3)
		# Flat pilaster strips between the window columns.
		for k in [1, 2]:
			var p := left + right * (PIER + zone * float(k) / 3.0) + Vector3(0, BASE, 0)
			lm.box("Pier", p + Vector3(0, (plat - BASE) * 0.5, 0) + out * 0.2, Vector3(0.8, plat - BASE, 0.45),
				Basis(right, Vector3.UP, out), 0.0)
		LandmarkDetail.cornice(lm, "Pier", mid + Vector3(0, plat, 0) + out * 0.15 - right * (len * 0.5 + 0.2),
			mid + Vector3(0, plat, 0) + out * 0.15 + right * (len * 0.5 + 0.2), out, 0.9, false)
	for s in [-1.0, 1.0]:
		for t in [-1.0, 1.0]:
			_corner_pier(lm, c, hx, hz, float(s), float(t), plat, ct)
	_crown(lm, c, hx, hz, plat, ct)
	_roof_and_poles(lm, c, hx, hz, ct, pole_top)

static func _faces(c: Vector2, hx: float, hz: float) -> Array:
	return [[Vector3(0, 0, 1), Vector3(c.x, 0, c.y + hz), 2.0 * hx],
		[Vector3(0, 0, -1), Vector3(c.x, 0, c.y - hz), 2.0 * hx],
		[Vector3(1, 0, 0), Vector3(c.x + hx, 0, c.y), 2.0 * hz],
		[Vector3(-1, 0, 0), Vector3(c.x - hx, 0, c.y), 2.0 * hz]]

## Two storeys of rusticated granite with arched openings and a cornice.
static func _base(lm: LandmarkMesh, c: Vector2, hx: float, hz: float) -> void:
	K.rb(lm, "Granite", c.x - hx - 0.3, c.x + hx + 0.3, 0.0, BASE, c.y - hz - 0.3, c.y + hz + 0.3)
	for f in _faces(c, hx, hz):
		var out: Vector3 = f[0]
		var mid: Vector3 = f[1]
		var len: float = f[2]
		var right := K.right(out)
		var face := mid + out * 0.3
		K.courses(lm, "Granite", face, out, len + 0.6, 0.0, BASE, 1.4, 0.14, 0.08)
		var n := 3
		var offs: Array = []
		for i in n:
			offs.append((float(i) - 1.0) * len / 3.6)
		K.holes(lm, "Frame", face + out * 0.1, out, offs, 0.6, 2.2, 5.4, true)
		K.holes(lm, "Glass", face + out * 0.1, out, offs, 6.3, 1.4, 1.6, false)
		LandmarkDetail.cornice(lm, "Pier", mid + out * 0.3 + Vector3(0, BASE, 0) - right * (len * 0.5 + 0.3),
			mid + out * 0.3 + Vector3(0, BASE, 0) + right * (len * 0.5 + 0.3), out, 0.8, false)

## A wide corner pier up the shaft and on to the crown, coursed in bands.
static func _corner_pier(lm: LandmarkMesh, c: Vector2, hx: float, hz: float, sx: float, sz: float,
		plat: float, ct: float) -> void:
	var x0 := minf(sx * (hx - PIER), sx * (hx + 0.45))
	var x1 := maxf(sx * (hx - PIER), sx * (hx + 0.45))
	var z0 := minf(sz * (hz - PIER), sz * (hz + 0.45))
	var z1 := maxf(sz * (hz - PIER), sz * (hz + 0.45))
	K.rb(lm, "Pier", c.x + x0, c.x + x1, BASE + 0.8, ct - 1.1, c.y + z0, c.y + z1, 0.0)
	var cx := c.x + sx * (hx - PIER * 0.5 + 0.225)
	var cz := c.y + sz * (hz - PIER * 0.5 + 0.225)
	K.courses(lm, "Pier", Vector3(cx, 0, c.y + sz * (hz + 0.45)), Vector3(0, 0, sz), PIER + 0.45, BASE + 0.8, plat, 1.7, 0.12, 0.07)
	K.courses(lm, "Pier", Vector3(c.x + sx * (hx + 0.45), 0, cz), Vector3(sx, 0, 0), PIER + 0.45, BASE + 0.8, plat, 1.7, 0.12, 0.07)

## Balustrade, recessed arcade with gilded shells, frieze with round lights
## and the projecting terracotta cornice.
static func _crown(lm: LandmarkMesh, c: Vector2, hx: float, hz: float, plat: float, ct: float) -> void:
	var ya := plat + 0.9
	var inset := 0.9
	K.rb(lm, "Pier", c.x - hx + inset, c.x + hx - inset, ya, ct - 1.1, c.y - hz + inset, c.y + hz - inset, 0.0)
	for f in _faces(c, hx, hz):
		var out: Vector3 = f[0]
		var mid: Vector3 = f[1]
		var len: float = f[2]
		var right := K.right(out)
		var zone := len - 2.0 * PIER
		var wall := mid - out * inset
		# Balustrade between the corner blocks: rails and posts.
		var rail := mid + out * 0.55 + Vector3(0, ya, 0)
		var basis := Basis(right, Vector3.UP, out)
		lm.box("Pier", rail + Vector3(0, 0.12, 0), Vector3(zone, 0.2, 0.3), basis, 0.0)
		lm.box("Pier", rail + Vector3(0, 0.82, 0), Vector3(zone, 0.18, 0.34), basis, 0.0)
		var posts := int(zone / 1.0)
		for i in posts + 1:
			lm.box("Pier", rail + right * (zone * (float(i) / float(posts) - 0.5)) + Vector3(0, 0.45, 0),
				Vector3(0.18, 0.7, 0.18), basis, 0.0)
		# Arcade: round-headed openings with gilded shell heads.
		var n := maxi(int(roundf(zone / 1.7)), 3)
		for i in n:
			var off := zone * ((float(i) + 0.5) / float(n) - 0.5)
			var p := wall + right * off + out * 0.04
			FhU.opening(lm, "Frame", p + Vector3(0, ya + 0.3, 0), out, 1.15, 2.9, true)
			_shell(lm, p + Vector3(0, ya + 0.3 + 2.9 - 0.58, 0) + out * 0.03, out, right, 0.58)
			lm.disc("Frame", wall + right * (zone * ((float(i) + 0.5) / float(n) - 0.5)) + Vector3(0, ct - 1.8, 0) + out * 0.04,
				out, 0.3, 8)
		# The projecting terracotta cornice with dentils.
		LandmarkDetail.cornice(lm, "Crown", mid + Vector3(0, ct - 1.1, 0) + out * 0.1 - right * (len * 0.5 + 0.1),
			mid + Vector3(0, ct - 1.1, 0) + out * 0.1 + right * (len * 0.5 + 0.1), out, 1.1, true)

## Half-disc shell head: a fan over the top half of a circle, ribbed.
static func _shell(lm: LandmarkMesh, c: Vector3, out: Vector3, right: Vector3, r: float) -> void:
	var prev := c + right * r
	for k in range(1, 9):
		var a := PI * float(k) / 8.0
		var p := c + right * (r * cos(a)) + Vector3.UP * (r * sin(a))
		lm.tri("Lamp", c, prev, p, out, out, out, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
		prev = p
	for k in range(1, 7):
		var a := PI * float(k) / 7.0
		var p := c + right * (r * cos(a) * 0.96) + Vector3.UP * (r * sin(a) * 0.96)
		lm.beam("Gilt", c + out * 0.02, p + out * 0.02, 0.05, 0.05)

## Flat dark roof, gilded corner balls with flagpoles, patina figures.
static func _roof_and_poles(lm: LandmarkMesh, c: Vector2, hx: float, hz: float, ct: float, pole_top: float) -> void:
	K.rb(lm, "Roof", c.x - hx - 0.9, c.x + hx + 0.9, ct, ct + 0.12, c.y - hz - 0.9, c.y + hz + 0.9, 0.0)
	for s in [-1.0, 1.0]:
		var base := Vector3(c.x + float(s) * (hx - 0.6), ct + 0.12, c.y - (hz - 0.6) * float(s))
		lm.lathe("Gilt", base + Vector3(0, 0.1, 0), LandmarkFhUtil.ball(0.42), 8)
		lm.beam("Pole", base + Vector3(0, 0.8, 0), Vector3(base.x, pole_top, base.z), 0.1, 0.1)
		K.figure(lm, "Copper", Vector3(c.x + float(s) * (hx - 0.6), ct + 0.12, c.y + (hz - 0.6) * float(s)), 1.6)

# --- Bridge ----------------------------------------------------------------

## The granite arch bridge over Kungsgatan between the tower bases: x0..x1
## wide, from the north tower's face z0 to the south tower's face z1.
static func _bridge(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float) -> void:
	var spring := 7.5
	var rise := 4.5
	var deck := 15.0
	var span := z1 - z0
	var zm := (z0 + z1) * 0.5
	var rad := (span * span * 0.25 + rise * rise) / (2.0 * rise)
	var segs := 16
	var pts: Array[Vector2] = []
	for i in segs + 1:
		var z := z0 + span * float(i) / float(segs)
		var dz := z - zm
		pts.append(Vector2(z, spring + rise - (rad - sqrt(rad * rad - dz * dz))))
	# Soffit.
	for i in segs:
		var a := pts[i]
		var b := pts[i + 1]
		var n := Vector3(0, -(b.x - a.x), b.y - a.y).normalized()
		lm.quad("Granite", Vector3(x0, a.y, a.x), Vector3(x1, a.y, a.x), Vector3(x1, b.y, b.x), Vector3(x0, b.y, b.x), n)
	# Spandrel faces: the region between the soffit and the deck.
	var poly := PackedVector2Array()
	for p in pts:
		poly.append(p)
	poly.append(Vector2(z1, deck))
	poly.append(Vector2(z0, deck))
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		for end in [x0, x1]:
			var nx := Vector3(1, 0, 0) if end == x1 else Vector3(-1, 0, 0)
			var v: Array[Vector3] = []
			for k in 3:
				var q := poly[idx[t + k]]
				v.append(Vector3(end, q.y, q.x))
			lm.tri("Granite", v[0], v[1], v[2], nx, nx, nx, Vector2(v[0].z, -v[0].y), Vector2(v[1].z, -v[1].y),
				Vector2(v[2].z, -v[2].y))
	# Deck, carriageway and parapets.
	K.rb(lm, "Granite", x0, x1, deck - 0.4, deck, z0, z1, 0.0)
	K.rb(lm, "Roof", x0 + 0.7, x1 - 0.7, deck, deck + 0.06, z0, z1, 0.0)
	K.rb(lm, "Granite", x0, x0 + 0.7, deck, deck + 1.1, z0, z1, 0.0)
	K.rb(lm, "Granite", x1 - 0.7, x1, deck, deck + 1.1, z0, z1, 0.0)
	# A string course along the soffit edge, on both faces.
	for end in [x0 - 0.12, x1 + 0.12]:
		K.rb(lm, "Pier", minf(end, end + 0.12), maxf(end, end + 0.12), deck - 0.9, deck - 0.4, z0, z1, 0.0)

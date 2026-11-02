class_name LandmarkLpRegistan
extends RefCounted

## The Registan of Samarkand in true metres, and the Timurid / Shaybanid
## madrasa front shared with Bukhara's Mir-i-Arab: glazed tile over baked
## brick, a pishtaq between two storeys of recessed arched loggias, corner
## minarets or guldasta turrets.

## Compass frame with the square open to the south: Ulugh Beg Madrasa
## (west, 1417-1420, 56 x 81 m, its 35 m portal between 33 m corner
## minarets), Sher-Dor (east, 1619-1636, the tiger-and-sun mosaics in the
## portal spandrels, two ribbed turquoise domes on tall drums, 38 m
## portal) and Tilya-Kori (north, 1646-1660, the long two-storey front
## with guldasta turrets, the blue mosque dome behind its west wing).
static func registan(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#C9A872", 3.5))
	lm.use("Tile", LandmarkMaterials.pbr("render", "#2A63B0", 2.0, 0.34))
	lm.use("Turq", LandmarkMaterials.pbr("render", "#30AEB6", 2.0, 0.3))
	lm.use("Cream", LandmarkMaterials.pbr("render", "#E6D9B6", 2.0, 0.5))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#CFBE98", 6.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#17120E", 3.0, 0.92))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#D08A2E", 2.0, 0.4))
	lm.box("Court", Vector3(0, 0.1, 29.0), Vector3(112, 0.2, 74), Basis(), 0.0)
	# Ulugh Beg (west, faces east) and Sher-Dor (east, faces west).
	madrasa(lm, Vector3(-50, 0.2, 33.5), PI * 0.5, 56.0, 70.0, 12.0, 22.0, 34.8, 6.2, 14.0, 11.0, 33.0)
	madrasa(lm, Vector3(50, 0.2, 33.5), -PI * 0.5, 58.0, 56.0, 12.5, 24.0, 37.3, 6.6, 16.0, 12.0, 30.0)
	_tigers(lm, Vector3(50 - 1.5, 0.2, 33.5), -PI * 0.5, 6.6 + 1.2, 16.0 + 12.0)
	for s in [-1.0, 1.0]:
		var dp := Vector3(50.0 + 14.0, 0, 33.5 + float(s) * 19.5)
		_domed_drum(lm, dp + Vector3(0, 12.5, 0), 5.6, 8.4)
		LandmarkLpParts.ribbed_dome(lm, "Turq", dp + Vector3(0, 20.9, 0),
			LandmarkLpParts.bulb_profile(6.3, 9.6, 1.12, 12, 1.15), 16, 0.045)
	# Tilya-Kori (north, faces south) and its mosque dome behind the west wing.
	madrasa(lm, Vector3(0, 0.2, -4.5), 0.0, 84.0, 60.0, 13.0, 22.0, 27.0, 5.6, 13.0, 9.0, 0.0)
	var dc := Vector3(-24.0, 0, -30.0)
	_domed_drum(lm, dc + Vector3(0, 13.0, 0), 9.4, 6.0)
	LandmarkLpParts.ribbed_dome(lm, "Tile", dc + Vector3(0, 19.0, 0),
		LandmarkLpParts.bulb_profile(10.0, 11.0, 1.08, 12, 1.2), 24, 0.02)
	lm.commit(model)

## Tall glazed drum: cobalt wall with `n` arched windows, a turquoise
## inscription band below its top and a cornice ring.
static func _domed_drum(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	lm.frustum("Tile", base, r, r, h, 32)
	lm.frustum("Brick", base, r + 0.2, r + 0.2, 0.6, 32)
	lm.frustum("Cream", base + Vector3(0, h - 1.8, 0), r + 0.06, r + 0.06, 1.2, 32)
	lm.frustum("Turq", base + Vector3(0, h - 0.5, 0), r + 0.1, r + 0.25, 0.5, 32)
	var n := 16
	for k in n:
		var a := TAU * (float(k) + 0.5) / float(n)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkLpParts.arch_panel(lm, "Dark", base + d * (r + 0.02) + Vector3(0, h * 0.25, 0), PI * 0.5 - a,
			r * 0.07, h * 0.3, r * 0.1)

## Sher-Dor's spandrel mosaics: a striding tiger (with the sun rising on its
## back) chasing a white doe on each side of the portal arch, in ochre
## relief on the cobalt tile, `crown` m above the foot.
static func _tigers(lm: LandmarkMesh, front: Vector3, yaw: float, a: float, crown: float) -> void:
	var r := LandmarkLpParts.across(yaw)
	var f := LandmarkLpParts.outward(yaw)
	var b := Basis(Vector3.UP, yaw)
	for s in [-1.0, 1.0]:
		var sd := float(s)
		var c := front + f * 0.06 + r * (sd * (a + 2.2)) + Vector3(0, crown - 4.5, 0)
		var walk := -r * sd
		lm.box("Ochre", c, Vector3(2.6, 0.9, 0.1), b, 0.0)
		lm.box("Ochre", c + walk * 1.5 + Vector3(0, 0.25, 0), Vector3(0.7, 0.7, 0.1), b, 0.0)
		for x in [-1.0, -0.7, 0.7, 1.0]:
			lm.box("Ochre", c + walk * float(x) - Vector3(0, 0.9, 0), Vector3(0.22, 0.9, 0.1), b, 0.0)
		lm.beam("Ochre", c - walk * 1.3, c - walk * 1.9 + Vector3(0, 0.8, 0), 0.16, 0.1, f)
		lm.disc("Cream", c + f * 0.08 + Vector3(0, 1.4, 0), f, 0.9, 16)
		lm.disc("Ochre", c + f * 0.1 + Vector3(0, 1.4, 0), f, 0.5, 12)
		var dc := c + walk * 3.1 + Vector3(0, 0.4, 0)
		lm.box("Cream", dc, Vector3(1.6, 0.6, 0.1), b, 0.0)
		lm.box("Cream", dc + walk * 0.95 + Vector3(0, 0.45, 0), Vector3(0.4, 0.6, 0.1), b, 0.0)
		for x in [-0.6, 0.6]:
			lm.box("Cream", dc + walk * float(x) - Vector3(0, 0.6, 0), Vector3(0.14, 0.7, 0.1), b, 0.0)

## One madrasa: a body of `width` x `depth` behind the front plane point `p`
## (facing `yaw`): the wings' two storeys of recessed arched loggias in
## tile, a turquoise parapet band, the pishtaq (pw x ph) with its frame
## bands, a cream inscription band, the stepped muqarnas hood in the niche
## (half-width a, spring, rise) and corner minarets mh tall (the rear
## pair two thirds) or, when mh is 0, low guldasta turrets at the corners.
static func madrasa(lm: LandmarkMesh, p: Vector3, yaw: float, width: float, depth: float, wall_h: float,
		pw: float, ph: float, a: float, spring: float, rise: float, mh: float) -> void:
	var r := LandmarkLpParts.across(yaw)
	var f := LandmarkLpParts.outward(yaw)
	var basis := Basis(Vector3.UP, yaw)
	lm.box("Brick", p - f * depth * 0.5 + Vector3(0, wall_h * 0.5, 0), Vector3(width, wall_h, depth), basis)
	lm.box("Turq", p + Vector3(0, wall_h + 0.3, 0) - f * 0.2, Vector3(width + 0.4, 0.6, 1.0), basis)
	# Wings: two storeys of loggias as recessed niches in a tiled skin.
	var wing := width * 0.5 - pw * 0.5 - 1.0
	var n := maxi(int(wing / 5.4), 1)
	var hl := wall_h * 0.52
	for s in [-1.0, 1.0]:
		var wc := p + r * (float(s) * (pw * 0.5 + 0.5 + wing * 0.5))
		var lower := LandmarkLpDetail.bays(n, wing, 1.7, 2.9, 2.2)
		var upper := LandmarkLpDetail.bays(n, wing, 1.5, 2.1, 1.9)
		LandmarkLpDetail.arcade_skin(lm, "Tile", "Dark", wc + f * 0.6, yaw, wing, hl, lower, 0.6, 6)
		LandmarkLpDetail.arcade_skin(lm, "Tile", "Dark", wc + f * 0.6 + Vector3(0, hl, 0), yaw, wing,
			wall_h - hl, upper, 0.6, 6)
		lm.box("Cream", wc + f * 0.65 + Vector3(0, hl, 0), Vector3(wing, 0.25, 0.1), basis, 0.0)
		for ar in lower:
			var u: float = ar[0]
			LandmarkLpDetail.alfiz(lm, "Turq", wc + f * 0.6 + r * u, yaw, 1.7, 2.9 + 2.2 + 0.4, 0.22, 0.06)
			LandmarkLpDetail.alfiz(lm, "Turq", wc + f * 0.6 + r * u + Vector3(0, hl, 0), yaw, 1.5, 2.1 + 1.9 + 0.35,
				0.2, 0.06)
	# Pishtaq: the portal slab, frame bands, inscription, hood, spandrels.
	var front := p + f * 1.5
	LandmarkLpParts.iwan(lm, "Tile", "Dark", front, yaw, pw, ph, a, spring, rise, 5.5)
	LandmarkLpDetail.alfiz(lm, "Turq", front + Vector3(0, 0.0, 0), yaw, pw * 0.5 - 1.2, ph - 1.4, 0.7, 0.18)
	LandmarkLpDetail.alfiz(lm, "Cream", front, yaw, a + 1.0, spring + rise + 1.2, 0.5, 0.12)
	lm.box("Cream", front + f * 0.1 + Vector3(0, ph - 2.6, 0), Vector3(pw - 3.4, 1.2, 0.2), basis, 0.0)
	LandmarkLpDetail.arch_band(lm, "Turq", front, yaw, a, spring, rise, 0.45, 0.1, 8)
	LandmarkLpDetail.muqarnas_hood(lm, "Cream", front, yaw, a, spring, rise, 4, 0.9)
	# Tiled screen at the back of the niche: the door and the window over it.
	var fill := PackedVector2Array([Vector2(-a, 0.0)])
	for q in LandmarkLpParts.arch_outline(a, rise):
		fill.append(q + Vector2(0.0, spring))
	fill.append(Vector2(a, 0.0))
	LandmarkLpParts.slab(lm, "Tile", fill, front - f * 4.4, yaw, 0.2)
	LandmarkLpParts.arch_panel(lm, "Dark", front - f * 4.38, yaw, a * 0.4, spring * 0.45, a * 0.4)
	LandmarkLpParts.arch_panel(lm, "Dark", front - f * 4.38 + Vector3(0, spring * 0.7, 0), yaw, a * 0.3,
		spring * 0.3, a * 0.3)
	lm.box("Turq", front - f * 2.75 + Vector3(0, ph + 0.25, 0), Vector3(pw + 0.4, 0.5, 5.9), basis)
	# Corners: minarets, or low guldasta turrets with ribbed caps.
	for s in [-1.0, 1.0]:
		var side := r * (float(s) * (width * 0.5 - 2.4))
		if mh > 0.0:
			LandmarkLpDetail.tile_minaret(lm, "Brick", "Tile", p + side - f * 2.4, 2.1, mh)
			LandmarkLpDetail.tile_minaret(lm, "Brick", "Tile", p + side - f * (depth - 2.4), 2.1, mh * 0.66)
		else:
			for back in [2.4, depth - 2.4]:
				var g: Vector3 = p + side - f * float(back)
				lm.frustum("Brick", g, 2.2, 2.0, wall_h + 3.0, 16)
				for y in [wall_h * 0.4, wall_h * 0.8]:
					lm.frustum("Tile", g + Vector3(0, float(y), 0), 2.12, 2.1, 1.0, 16)
				lm.frustum("Turq", g + Vector3(0, wall_h + 3.0, 0), 2.3, 2.3, 0.4, 16)
				LandmarkLpParts.ribbed_dome(lm, "Turq", g + Vector3(0, wall_h + 3.4, 0),
					LandmarkLpParts.bulb_profile(1.9, 2.6, 1.1, 8, 1.2), 8, 0.06)

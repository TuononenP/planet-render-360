class_name LandmarkSaoTowers
extends RefCounted

## Oceania's two observation towers in true metres: Auckland's Sky Tower
## and Sydney Tower (Centrepoint).

# --- Sky Tower, Auckland ---

const SKY_H := 328.0
const SKY_POD_Y := 172.0
const SKY_DECK_Y := 216.0
const SKY_MAST_Y := 237.0

## Pod outline above SKY_POD_Y as (radius, height): flaring concrete
## underside, two glazed tiers (main observation at 186 m and the
## revolving Orbit restaurant at 190 m), the SkyWalk ledge and the cap.
static var SKY_POD_LOWER := PackedVector2Array([Vector2(5.4, 0.0), Vector2(9.0, 2.0),
	Vector2(15.0, 5.0), Vector2(19.5, 8.0)])
static var SKY_POD_GLASS := PackedVector2Array([Vector2(19.5, 8.0), Vector2(20.6, 13.5),
	Vector2(19.6, 14.0), Vector2(20.6, 19.6)])
static var SKY_POD_CAP := PackedVector2Array([Vector2(20.0, 20.4), Vector2(16.0, 23.0),
	Vector2(9.0, 26.0), Vector2(5.2, 28.0)])

## Gordon Moller's tower (1997): a 12 m concrete shaft standing on eight
## legs over the SkyCity podium, the main pod (levels 48-53, 180-200 m)
## with its SkyWalk ledge at 192 m, the Sky Deck ring at 220 m, the
## concrete cap to 237 m and the steel antenna mast to 328 m.
static func sky_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BDB8B0", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Frame", LandmarkMaterials.paint("#CFCFCB", 0.5, 0.3))
	lm.use("Mast", LandmarkMaterials.paint("#ECEBE6", 0.5, 0.3))
	lm.use("Podium", LandmarkMaterials.pbr("render", "#8A8E92", 4.0))
	_sky_podium(lm)
	_sky_shaft(lm)
	_sky_pod(lm)
	_sky_deck(lm)
	_sky_mast(lm)
	lm.commit(model)

## SkyCity podium: storey bands, a glazed street front and the plaza
## around the tower foot.
static func _sky_podium(lm: LandmarkMesh) -> void:
	lm.box("Podium", Vector3(0, 9.0, 30.0), Vector3(86.0, 18.0, 36.0))
	lm.box("Podium", Vector3(-30.0, 9.0, -6.0), Vector3(26.0, 18.0, 36.0))
	for k in 4:
		var y := 2.5 + 4.2 * float(k)
		lm.box("Glass", Vector3(0, y, 48.1), Vector3(84.0, 2.4, 0.2), Basis(), 0.0)
		lm.box("Glass", Vector3(-43.1, y, 12.0), Vector3(0.2, 2.4, 70.0), Basis(), 0.0)
		lm.box("Podium", Vector3(0, y + 1.6, 48.3), Vector3(86.0, 0.5, 0.5), Basis(), 0.0)
	lm.frustum("Podium", Vector3.ZERO, 14.0, 14.0, 0.4, 32)

## The shaft on its eight splayed legs, the glass lift faces on the
## north side and joint rings every 12 m.
static func _sky_shaft(lm: LandmarkMesh) -> void:
	lm.frustum("Concrete", Vector3(0, 0, 0), 6.0, 5.5, SKY_POD_Y, 32)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Concrete", d * 11.0 + Vector3(0, 0.4, 0), d * 5.6 + Vector3(0, 34.0, 0), 2.6, 1.8, d.cross(Vector3.UP))
		lm.box("Concrete", d * 11.0 + Vector3(0, 0.6, 0), Vector3(3.4, 1.2, 3.4), Basis.looking_at(d))
	var y := 12.0
	while y < SKY_POD_Y:
		var r := lerpf(6.0, 5.5, y / SKY_POD_Y)
		lm.lathe("Concrete", Vector3(0, y, 0), PackedVector2Array([Vector2(r, 0.0), Vector2(r + 0.15, 0.1),
			Vector2(r + 0.15, 0.4), Vector2(r, 0.5)]), 32, 1.0, 1.0, 0.0, true, false)
		y += 12.0
	# Lift glazing: three vertical strips on the north (-Z) face.
	for k in 3:
		var a := -PI * 0.5 + (float(k) - 1.0) * 0.32
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Glass", d * 5.9 + Vector3(0, 20.0, 0), d * 5.45 + Vector3(0, SKY_POD_Y, 0), 1.4, 0.2, d.cross(Vector3.UP))
		for s in [-1.0, 1.0]:
			var off: Vector3 = d.cross(Vector3.UP) * 0.8 * float(s)
			lm.beam("Frame", d * 6.0 + off + Vector3(0, 20.0, 0), d * 5.55 + off + Vector3(0, SKY_POD_Y, 0), 0.25, 0.25)

## The main pod: lower shell, two glazed tiers with mullions and floor
## bands, the SkyWalk ledge with its overhead rail, and the roof cap.
static func _sky_pod(lm: LandmarkMesh) -> void:
	var pod := Vector3(0, SKY_POD_Y, 0)
	lm.lathe("Concrete", pod, SKY_POD_LOWER, 48)
	lm.lathe("Glass", pod, SKY_POD_GLASS, 48)
	lm.lathe("Frame", pod, SKY_POD_CAP, 48)
	for y in [8.0, 13.7, 19.8]:
		lm.frustum("Frame", pod + Vector3(0, float(y) - 0.3, 0), 20.8, 20.8, 0.6, 48)
	for i in 48:
		var a := TAU * float(i) / 48.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Frame", pod + d * 19.6 + Vector3(0, 8.0, 0), pod + d * 20.7 + Vector3(0, 13.5, 0), 0.2, 0.2)
		lm.beam("Frame", pod + d * 19.7 + Vector3(0, 14.0, 0), pod + d * 20.7 + Vector3(0, 19.6, 0), 0.2, 0.2)
	# SkyWalk: a 1.2 m ledge without rails round the pod at 192 m.
	var walk := pod + Vector3(0, 20.0, 0)
	lm.lathe("Frame", walk, PackedVector2Array([Vector2(20.6, 0.0), Vector2(21.8, 0.0), Vector2(21.8, 0.4),
		Vector2(20.6, 0.4)]), 48)
	lm.frustum("Frame", walk + Vector3(0, 3.0, 0), 21.4, 21.4, 0.15, 48)
	for i in 16:
		var a := TAU * float(i) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Frame", walk + d * 17.0 + Vector3(0, 2.6, 0), walk + d * 21.4 + Vector3(0, 3.1, 0), 0.2, 0.2)
	lm.frustum("Concrete", Vector3(0, SKY_POD_Y + 28.0, 0), 5.2, 4.4, SKY_DECK_Y - SKY_POD_Y - 28.0, 24)

## The Sky Deck ring at 220 m: underside, glazed band with mullions,
## roof and the concrete cap tapering to the mast foot at 237 m.
static func _sky_deck(lm: LandmarkMesh) -> void:
	var deck := Vector3(0, SKY_DECK_Y, 0)
	lm.lathe("Frame", deck, PackedVector2Array([Vector2(4.4, 0.0), Vector2(8.5, 1.4), Vector2(9.6, 2.4)]), 32)
	lm.frustum("Glass", deck + Vector3(0, 2.4, 0), 9.6, 9.8, 4.0, 32)
	for i in 24:
		var a := TAU * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Frame", deck + d * 9.7 + Vector3(0, 2.4, 0), deck + d * 9.9 + Vector3(0, 6.4, 0), 0.18, 0.18)
	lm.lathe("Frame", deck + Vector3(0, 6.4, 0), PackedVector2Array([Vector2(10.0, 0.0), Vector2(9.2, 0.8),
		Vector2(4.2, 2.6)]), 32)
	lm.frustum("Concrete", deck + Vector3(0, 9.0, 0), 4.2, 3.0, SKY_MAST_Y - SKY_DECK_Y - 9.0, 20)

## The 91 m mast: a tapering steel tube with three antenna platforms,
## dishes, and the slim whip to the tip.
static func _sky_mast(lm: LandmarkMesh) -> void:
	lm.frustum("Mast", Vector3(0, SKY_MAST_Y, 0), 2.6, 1.2, 60.0, 16)
	for y in [246.0, 262.0, 280.0]:
		var r := lerpf(2.6, 1.2, (float(y) - SKY_MAST_Y) / 60.0)
		lm.frustum("Mast", Vector3(0, float(y), 0), r + 1.6, r + 1.6, 0.5, 16)
		for i in 6:
			var a := TAU * float(i) / 6.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.beam("Mast", d * (r + 1.4) + Vector3(0, float(y) + 0.5, 0), d * (r + 1.4) + Vector3(0, float(y) + 5.0, 0), 0.3, 0.3)
			if i % 2 == 0:
				lm.lathe("Mast", d * (r + 0.6) + Vector3(0, float(y) + 2.5, 0), PackedVector2Array([Vector2(0.0, 0.0),
					Vector2(0.9, 0.0), Vector2(0.0, 0.6)]), 10)
	lm.frustum("Mast", Vector3(0, SKY_MAST_Y + 60.0, 0), 1.2, 0.25, SKY_H - SKY_MAST_Y - 60.0, 10)

# --- Sydney Tower ---

const SYD_H := 309.0
const SYD_TURRET_Y := 228.0
const SYD_SKYWALK_Y := 268.0
const SYD_SHAFT_R := 3.35
const SYD_PODIUM_H := 40.0
const SYD_CABLES := 56

## Turret outline above SYD_TURRET_Y as (radius, height): the conical
## underside, the four public levels (restaurants, functions and the
## observation deck at 250 m), the narrower drum of the window
## cleaner, water tank and telecom levels, and the SkyWalk roof.
static var SYD_TURRET_LOWER := PackedVector2Array([Vector2(SYD_SHAFT_R, 0.0), Vector2(8.0, 3.0),
	Vector2(13.0, 6.0), Vector2(15.5, 8.0)])
static var SYD_TURRET_GLASS := PackedVector2Array([Vector2(15.5, 8.0), Vector2(15.5, 15.6),
	Vector2(15.2, 16.0), Vector2(15.5, 16.4), Vector2(15.5, 23.6)])
static var SYD_TURRET_UPPER := PackedVector2Array([Vector2(15.5, 24.2), Vector2(13.0, 26.0),
	Vector2(12.0, 28.0), Vector2(11.5, 37.0), Vector2(10.0, 38.6), Vector2(4.0, 40.0)])

## Donald Crone's tower (1981): a 6.7 m shaft of 46 welded steel barrel
## units over the Centrepoint podium, braced by 56 cables in a
## hyperboloid net; the gold turret 31 m across with four public levels
## (observation deck 250 m), the drum above with the 162,000 l water
## tank, the SkyWalk at 268 m and the spire to 309 m.
static func sydney_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Shaft", LandmarkMaterials.pbr("concrete", "#D5CDB8", 4.0))
	lm.use("Gold", LandmarkMaterials.pbr("concrete", "#D9B452", 3.0, 0.4, 0.5))
	lm.use("Glass", LandmarkMaterials.glass("#4B4A3C"))
	lm.use("Mast", LandmarkMaterials.paint("#B9BDC0", 0.45, 0.5))
	lm.use("Podium", LandmarkMaterials.pbr("render", "#B9B5AA", 4.0))
	_syd_podium(lm)
	lm.frustum("Shaft", Vector3(0, SYD_PODIUM_H, 0), SYD_SHAFT_R, SYD_SHAFT_R, SYD_TURRET_Y - SYD_PODIUM_H + 1.0, 24)
	# Weld rings between the barrel units (46 over the full shaft).
	var unit := SYD_TURRET_Y / 46.0
	for k in range(1, 46):
		var y := unit * float(k)
		if y < SYD_PODIUM_H + 1.0:
			continue
		lm.frustum("Shaft", Vector3(0, y - 0.2, 0), SYD_SHAFT_R + 0.12, SYD_SHAFT_R + 0.12, 0.4, 24)
	_syd_cables(lm)
	_syd_turret(lm)
	_syd_spire(lm)
	lm.commit(model)

## Centrepoint podium: shop and office storeys with glazed bands, the
## anchor ring for the cables on its roof.
static func _syd_podium(lm: LandmarkMesh) -> void:
	lm.box("Podium", Vector3(0, SYD_PODIUM_H * 0.5, 0), Vector3(72.0, SYD_PODIUM_H, 52.0))
	for k in 9:
		var y := 3.0 + 4.2 * float(k)
		lm.box("Glass", Vector3(0, y, 26.1), Vector3(68.0, 2.0, 0.2), Basis(), 0.0)
		lm.box("Glass", Vector3(0, y, -26.1), Vector3(68.0, 2.0, 0.2), Basis(), 0.0)
		lm.box("Glass", Vector3(36.1, y, 0), Vector3(0.2, 2.0, 48.0), Basis(), 0.0)
	lm.frustum("Podium", Vector3(0, SYD_PODIUM_H, 0), 12.0, 11.0, 1.6, 32)
	lm.frustum("Mast", Vector3(0, SYD_PODIUM_H, 0), SYD_SHAFT_R + 1.2, SYD_SHAFT_R + 0.8, 3.0, 24)

## The 56 stay cables: half twisting one way and half the other from
## the podium ring to the turret foot, so they cross in a net.
static func _syd_cables(lm: LandmarkMesh) -> void:
	var y0 := SYD_PODIUM_H + 1.6
	var y1 := SYD_TURRET_Y + 2.0
	for k in SYD_CABLES:
		var a := TAU * float(k) / float(SYD_CABLES)
		var twist := 0.55 if k % 2 == 0 else -0.55
		var prev := Vector3(cos(a) * 10.5, y0, sin(a) * 10.5)
		for s in range(1, 5):
			var t := float(s) / 4.0
			var b := a + twist * t
			var r := lerpf(10.5, 7.0, t)
			var p := Vector3(cos(b) * r, lerpf(y0, y1, t), sin(b) * r)
			lm.beam("Mast", prev, p, 0.22, 0.22)
			prev = p

## The turret: conical gold underside, the glazed public levels with
## gold mullions and floor bands, the cleaner rail, the upper drum with
## gold fins, and the SkyWalk deck with its glass-floored ledge.
static func _syd_turret(lm: LandmarkMesh) -> void:
	var t := Vector3(0, SYD_TURRET_Y, 0)
	lm.lathe("Gold", t, SYD_TURRET_LOWER, 48)
	lm.lathe("Glass", t, SYD_TURRET_GLASS, 48)
	lm.lathe("Gold", t, SYD_TURRET_UPPER, 48)
	for y in [8.0, 12.0, 16.0, 20.0, 24.0]:
		lm.frustum("Gold", t + Vector3(0, float(y) - 0.3, 0), 15.8, 15.8, 0.6, 48)
	for i in 60:
		var a := TAU * float(i) / 60.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Gold", t + d * 15.6 + Vector3(0, 8.0, 0), t + d * 15.6 + Vector3(0, 23.7, 0), 0.22, 0.25)
	for i in 32:
		var a := TAU * float(i) / 32.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Gold", t + d * 11.9 + Vector3(0, 28.0, 0), t + d * 11.6 + Vector3(0, 37.0, 0), 0.5, 0.6)
	# Water-tank band and the window-cleaner track.
	lm.frustum("Glass", t + Vector3(0, 30.0, 0), 11.85, 11.75, 1.8, 48)
	lm.frustum("Mast", t + Vector3(0, 24.4, 0), 16.0, 16.0, 0.5, 48)
	# SkyWalk at 268 m: deck ring with posts and a handrail.
	var sw := Vector3(0, SYD_SKYWALK_Y, 0)
	lm.frustum("Gold", sw - Vector3(0, 0.4, 0), 12.6, 12.6, 0.4, 48)
	lm.frustum("Mast", sw + Vector3(0, 1.1, 0), 12.4, 12.4, 0.08, 48)
	for i in 32:
		var a := TAU * float(i) / 32.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Mast", sw + d * 12.4, sw + d * 12.4 + Vector3(0, 1.15, 0), 0.08, 0.08)

## The spire from the turret roof to 309 m: tapering tube, platforms
## and the navigation beacon at the tip.
static func _syd_spire(lm: LandmarkMesh) -> void:
	var y0 := SYD_TURRET_Y + 40.0
	lm.frustum("Mast", Vector3(0, y0, 0), 1.9, 1.0, 22.0, 12)
	lm.frustum("Mast", Vector3(0, y0 + 22.0, 0), 1.0, 0.2, SYD_H - y0 - 22.6, 10)
	for y in [y0 + 6.0, y0 + 14.0, y0 + 21.0]:
		var r := lerpf(1.9, 1.0, (float(y) - y0) / 22.0)
		lm.frustum("Mast", Vector3(0, float(y), 0), r + 0.9, r + 0.9, 0.35, 12)
		for i in 4:
			var a := TAU * float(i) / 4.0 + 0.4
			var d := Vector3(cos(a), 0, sin(a))
			lm.beam("Mast", d * (r + 0.7) + Vector3(0, float(y), 0), d * (r + 0.7) + Vector3(0, float(y) + 3.0, 0), 0.25, 0.25)
	lm.lathe("Gold", Vector3(0, SYD_H - 0.6, 0), PackedVector2Array([Vector2(0.25, 0.0), Vector2(0.3, 0.3),
		Vector2(0.0, 0.6)]), 8)

class_name LandmarkSaoTowers
extends RefCounted

## Oceania's two observation towers in true metres: Auckland's Sky Tower
## and Sydney Tower (Centrepoint).

# --- Sky Tower, Auckland ---

const SKY_H := 328.0
const SKY_POD_Y := 172.0

## Pod outline above SKY_POD_Y as (radius, height): flaring concrete
## underside, glazed observation band, closing cap.
static var SKY_POD_LOWER := PackedVector2Array([Vector2(5.2, 0.0), Vector2(9.0, 2.0),
	Vector2(15.0, 4.5), Vector2(19.5, 7.0)])
static var SKY_POD_GLASS := PackedVector2Array([Vector2(19.5, 7.0), Vector2(21.0, 9.0),
	Vector2(21.0, 13.0), Vector2(19.5, 15.5)])
static var SKY_POD_CAP := PackedVector2Array([Vector2(19.5, 15.5), Vector2(15.0, 18.0),
	Vector2(8.0, 20.5), Vector2(5.0, 22.0)])

## The 328 m concrete shaft (12 m across at the foot) rising from the
## SkyCity podium, the 40 m observation pod at 172-194 m, the Sky Deck
## ring at 216 m and the white steel mast to the tip.
static func sky_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BDB8B0", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Frame", LandmarkMaterials.paint("#CFCFCB", 0.5, 0.3))
	lm.use("Mast", LandmarkMaterials.paint("#ECEBE6", 0.5, 0.3))
	lm.use("Podium", LandmarkMaterials.pbr("render", "#8A8E92", 4.0))
	lm.box("Podium", Vector3(0, 9.0, 12.0), Vector3(86.0, 18.0, 60.0))
	lm.box("Glass", Vector3(0, 6.0, 42.1), Vector3(70.0, 4.0, 0.2))
	lm.frustum("Concrete", Vector3(0, 0, 0), 6.6, 5.2, SKY_POD_Y, 24)
	var pod := Vector3(0, SKY_POD_Y, 0)
	lm.lathe("Concrete", pod, SKY_POD_LOWER, 32)
	lm.lathe("Glass", pod, SKY_POD_GLASS, 32)
	lm.lathe("Frame", pod, SKY_POD_CAP, 32)
	lm.frustum("Concrete", Vector3(0, SKY_POD_Y + 22.0, 0), 5.0, 3.6, 22.0, 20)
	# Sky Deck: a small glazed ring with a flat roof around the shaft.
	var deck := Vector3(0, 216.0, 0)
	lm.lathe("Frame", deck, PackedVector2Array([Vector2(3.8, 0.0), Vector2(8.5, 1.4),
		Vector2(9.5, 2.4)]), 20)
	lm.frustum("Glass", deck + Vector3(0, 2.4, 0), 9.5, 9.5, 3.0, 20)
	lm.lathe("Frame", deck + Vector3(0, 5.4, 0), PackedVector2Array([Vector2(9.7, 0.0),
		Vector2(9.0, 0.8), Vector2(3.4, 2.4)]), 20)
	lm.frustum("Mast", Vector3(0, 224.0, 0), 3.0, 1.4, 56.0, 12)
	lm.frustum("Mast", Vector3(0, 280.0, 0), 1.4, 0.25, SKY_H - 280.0, 8)
	lm.commit(model)

# --- Sydney Tower ---

const SYD_H := 309.0
const SYD_TURRET_Y := 220.0

## Turret outline above SYD_TURRET_Y as (radius, height).
static var SYD_TURRET_LOWER := PackedVector2Array([Vector2(4.4, 0.0), Vector2(10.0, 2.5),
	Vector2(15.5, 5.5), Vector2(17.5, 8.0)])
static var SYD_TURRET_GLASS := PackedVector2Array([Vector2(17.5, 8.0), Vector2(18.2, 10.0),
	Vector2(18.2, 17.0), Vector2(17.5, 19.0)])
static var SYD_TURRET_UPPER := PackedVector2Array([Vector2(17.5, 19.0), Vector2(16.0, 21.0),
	Vector2(11.0, 24.0), Vector2(5.0, 26.5), Vector2(2.4, 28.0)])

## The slender concrete shaft over the Centrepoint podium carrying the
## three-storey gold turret at 220-248 m, eight stay cables up the
## shaft and the steel mast to 309 m.
static func sydney_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Shaft", LandmarkMaterials.pbr("concrete", "#D5CDB8", 4.0))
	lm.use("Gold", LandmarkMaterials.pbr("concrete", "#D9B452", 3.0, 0.4, 0.5))
	lm.use("Glass", LandmarkMaterials.glass("#4B4A3C"))
	lm.use("Mast", LandmarkMaterials.paint("#B9BDC0", 0.45, 0.5))
	lm.use("Podium", LandmarkMaterials.pbr("render", "#B9B5AA", 4.0))
	lm.box("Podium", Vector3(0, 20.0, 0), Vector3(72.0, 40.0, 52.0))
	lm.box("Glass", Vector3(0, 12.0, 26.1), Vector3(60.0, 6.0, 0.2))
	lm.frustum("Shaft", Vector3(0, 0, 0), 5.8, 4.4, SYD_TURRET_Y, 20)
	var turret := Vector3(0, SYD_TURRET_Y, 0)
	lm.lathe("Gold", turret, SYD_TURRET_LOWER, 32)
	lm.lathe("Glass", turret, SYD_TURRET_GLASS, 32)
	lm.lathe("Gold", turret, SYD_TURRET_UPPER, 32)
	lm.frustum("Mast", Vector3(0, SYD_TURRET_Y + 28.0, 0), 1.9, 1.0, 40.0, 10)
	lm.frustum("Mast", Vector3(0, SYD_TURRET_Y + 68.0, 0), 1.0, 0.2, SYD_H - SYD_TURRET_Y - 68.0, 8)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Mast", d * 6.2 + Vector3(0, 40.0, 0), d * 8.8 + Vector3(0, 222.0, 0), 0.5, 0.5)
	lm.commit(model)

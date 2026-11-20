class_name FtCityTheatre
extends RefCounted

## Turku City Theatre (Turun kaupunginteatteri, 1962 Luukkonen & Stenros +
## 2017 LPR-arkkitehdit Sopukka & backstage copper expansion) in true metres
## (+X ENE upstream along Itäinen Rantakatu, -Z NNW facing Aurajoki, +Z SSE
## toward Volter Kilven katu / Samppalinna, turned by yaw_deg = -31.2°):
##   - Elevated granite/concrete riverside terrace podium (-36..36, -23.5..-17.5)
##     with wide approach stairs down to Itäinen Rantakatu and dark-metal rails.
##   - 1962 white modernist riverside foyer (68 x 30 m, H 10.8 m) with
##     cantilevered white concrete terrace canopy (overhang 4.6 m), deep
##     rhythmic dark-anodized vertical mullions, recessed lobby glazing, and
##     warm illuminated timber-and-glass interior mezzanine visible at night.
##   - Dark-brick / textured dark concrete auditorium flanks behind foyer.
##   - Tall white modernist stage fly-tower (28 x 20 m, rising to 22.3 m)
##     with vertical precast rib articulation and rooftop plant housing.
##   - 2017 burnished & patinated copper-clad Sopukka studio and backstage
##     expansion wrapping the +X (upstream) and +Z (hillside) flanks (H 14.6 m)
##     with standing-seam vertical ribs and recessed rehearsal glazing.
## Surfaces: 10 merged PBR parts (White, Concrete, DarkBrick, Copper, Patina,
## Stone, Roof, Frame, Glass, Lamp).

const FOUND := -1.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_terrace_and_foyer(lm)
	_build_auditorium_and_flytower(lm)
	_build_copper_expansion(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("White", LandmarkMaterials.pbr("render", "#EFECE4", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C4C0B8", 2.8))
	lm.use("DarkBrick", LandmarkMaterials.pbr("brick", "#4C4743", 2.4))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#8A563B", 2.2, 0.42, 0.62))
	lm.use("Patina", LandmarkFrKit.copper("#556E62"))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#787672", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#4E5358", 2.5))
	lm.use("Frame", LandmarkMaterials.paint("#2B2F34", 0.45, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#263742"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BC", 1.4))

static func _build_terrace_and_foyer(lm: LandmarkMesh) -> void:
	# Elevated riverside terrace podium & granite approach steps (-Z faces Aurajoki).
	LandmarkFrKit.rect(lm, "Stone", -36.5, 36.5, -23.2, 14.0, FOUND, 1.35)
	for step in 5:
		var t := float(step) / 4.0
		var sz0 := lerpf(-23.2, -25.4, t)
		var sy := lerpf(1.25, 0.15, t)
		LandmarkFrKit.rect(lm, "Stone", -26.0, 26.0, sz0 - 0.55, sz0, FOUND, sy)
	# Terrace parapet rails on the flanking ends outside the grand stairs.
	for sx: float in [-1.0, 1.0]:
		var x0 := -36.0 if sx < 0.0 else 26.2
		var x1 := -26.2 if sx < 0.0 else 36.0
		lm.beam("Frame", Vector3(x0, 2.35, -23.0), Vector3(x1, 2.35, -23.0), 0.06, 0.06)
		for k in 6:
			var px := lerpf(x0, x1, float(k) / 5.0)
			lm.beam("Frame", Vector3(px, 1.35, -23.0), Vector3(px, 2.35, -23.0), 0.05, 0.05)
	# Main 1962 white modernist riverside foyer volume (68 x 24 m, H 10.8 m).
	LandmarkFrKit.rect(lm, "White", -34.0, 34.0, -17.6, 8.0, 8.8, 10.8)
	LandmarkFrKit.rect(lm, "Roof", -33.6, 33.6, -17.2, 7.6, 10.8, 11.15)
	# Solid side return piers framing the panoramic riverfront glass wall.
	for sx: float in [-1.0, 1.0]:
		var x0 := -34.0 if sx < 0.0 else 30.8
		var x1 := -30.8 if sx < 0.0 else 34.0
		LandmarkFrKit.rect(lm, "White", x0, x1, -17.8, 8.0, 1.35, 8.85)
	# Cantilevered white concrete riverfront canopy (-22.2 .. -17.4) with warm soffit strip.
	LandmarkFrKit.rect(lm, "White", -35.6, 35.6, -22.2, -17.4, 8.85, 10.85)
	LandmarkFrKit.rect(lm, "Concrete", -35.2, 35.2, -21.9, -17.6, 8.65, 8.85)
	LandmarkFrKit.rect(lm, "Lamp", -32.0, 32.0, -20.3, -19.5, 8.56, 8.66)
	# Slender recessed concrete colonnade piers supporting the terrace canopy.
	for k in 9:
		var px := lerpf(-31.0, 31.0, float(k) / 8.0)
		lm.box("White", Vector3(px, 5.05, -21.1), Vector3(0.46, 7.4, 0.46))
	# Panoramic riverfront foyer glazing (-Z) with deep vertical mullions & warm illuminated lobby.
	LandmarkFrKit.rect(lm, "Glass", -30.8, 30.8, -17.75, -17.55, 1.45, 8.75)
	# Inset illuminated foyer mezzanine slab & warm acoustic glow backing.
	LandmarkFrKit.rect(lm, "Concrete", -29.6, 29.6, -16.8, -12.5, 4.85, 5.25)
	LandmarkFrKit.rect(lm, "Lamp", -29.8, 29.8, -15.6, -15.2, 1.65, 8.35)
	# Deep rhythmic vertical mullions (25 bays) and horizontal mezzanine transom.
	for k in 25:
		var mx := lerpf(-30.6, 30.6, float(k) / 24.0)
		var w := 0.34 if k % 4 == 0 else 0.16
		var d := 0.52 if k % 4 == 0 else 0.32
		lm.box("Frame", Vector3(mx, 5.1, -17.82), Vector3(w, 7.45, d))
	lm.box("Frame", Vector3(0.0, 5.05, -17.82), Vector3(61.6, 0.24, 0.38))
	# Glazed upper side gallery windows on west flank (-X).
	LandmarkFrKit.rect(lm, "Glass", -34.12, -33.92, -14.0, 4.0, 4.6, 8.1)
	for k in 7:
		var mz := lerpf(-13.8, 3.8, float(k) / 6.0)
		lm.box("Frame", Vector3(-34.16, 6.35, mz), Vector3(0.26, 3.6, 0.16))

static func _build_auditorium_and_flytower(lm: LandmarkMesh) -> void:
	# Textured dark-brick auditorium mass rising behind the white foyer (z = -6..18, H 13.8 m).
	LandmarkFrKit.rect(lm, "DarkBrick", -28.0, 22.0, -6.0, 18.0, 1.35, 13.6)
	LandmarkFrKit.rect(lm, "White", -28.2, 22.2, -6.2, 18.2, 13.2, 13.95)
	LandmarkFrKit.rect(lm, "Roof", -27.8, 21.8, -5.8, 17.8, 13.95, 14.25)
	# Tall white modernist stage fly-tower rising to 22.3 m (registry height_m = 22.0).
	LandmarkFrKit.rect(lm, "White", -14.2, 14.2, -1.5, 18.2, 13.8, 21.9)
	LandmarkFrKit.rect(lm, "Concrete", -14.4, 14.4, -1.7, 18.4, 21.45, 22.0)
	LandmarkFrKit.rect(lm, "Roof", -13.9, 13.9, -1.2, 17.9, 21.9, 22.3)
	# Vertical precast concrete shadow ribs on the fly-tower faces.
	for k in 11:
		var rx := lerpf(-13.2, 13.2, float(k) / 10.0)
		lm.box("Concrete", Vector3(rx, 17.6, -1.58), Vector3(0.22, 7.6, 0.22))
		lm.box("Concrete", Vector3(rx, 17.6, 18.28), Vector3(0.22, 7.6, 0.22))
	for k in 8:
		var rz := lerpf(-0.6, 17.4, float(k) / 7.0)
		lm.box("Concrete", Vector3(-14.28, 17.6, rz), Vector3(0.22, 7.6, 0.22))
		lm.box("Concrete", Vector3(14.28, 17.6, rz), Vector3(0.22, 7.6, 0.22))
	# Rooftop mechanical louver penthouse set back on the fly-tower.
	LandmarkFrKit.rect(lm, "Concrete", -6.5, 6.5, 4.0, 12.5, 21.9, 22.28)

static func _build_copper_expansion(lm: LandmarkMesh) -> void:
	# 2017 burnished & patinated copper-clad Sopukka studio wing (+X upstream, x = 14..39, z = -4..24).
	LandmarkFrKit.rect(lm, "Stone", 14.0, 39.4, -4.4, 24.4, FOUND, 1.35)
	LandmarkFrKit.rect(lm, "Copper", 14.2, 39.0, -4.0, 24.0, 1.35, 14.4)
	LandmarkFrKit.rect(lm, "Roof", 14.5, 38.7, -3.7, 23.7, 14.4, 14.7)
	# Rear hillside backstage copper wing along Volter Kilven katu (+Z, x = -25..14.5, z = 17.5..27.5).
	LandmarkFrKit.rect(lm, "Stone", -25.4, 14.5, 17.5, 27.8, FOUND, 1.35)
	LandmarkFrKit.rect(lm, "Copper", -25.0, 14.5, 17.8, 27.5, 1.35, 13.1)
	LandmarkFrKit.rect(lm, "Roof", -24.7, 14.2, 18.1, 27.2, 13.1, 13.4)
	# Standing-seam patinated copper vertical fins along the Sopukka east (+X) & river (-Z) walls.
	for k in 14:
		var sz := lerpf(-3.2, 23.2, float(k) / 13.0)
		lm.box("Patina", Vector3(39.08, 7.85, sz), Vector3(0.22, 12.9, 0.18))
	for k in 16:
		var sx := lerpf(-24.0, 37.5, float(k) / 15.0)
		var sy := 7.2 if sx < 14.2 else 7.85
		var sh := 11.6 if sx < 14.2 else 12.9
		var sz_f := 27.58 if sx < 14.2 else 24.08
		lm.box("Patina", Vector3(sx, sy, sz_f), Vector3(0.18, sh, 0.22))
	# Sopukka glazed studio corner entrance (+X, -Z) & upper rehearsal strip windows.
	LandmarkFrKit.rect(lm, "Glass", 34.0, 39.1, -4.12, -3.92, 1.5, 5.4)
	LandmarkFrKit.rect(lm, "Glass", 38.92, 39.12, -3.8, 5.5, 1.5, 5.4)
	LandmarkFrKit.rect(lm, "Lamp", 34.8, 38.2, -3.1, 4.5, 1.7, 5.1)
	LandmarkFrKit.rect(lm, "Glass", 38.92, 39.12, 7.5, 21.5, 8.8, 11.4)
	LandmarkFrKit.rect(lm, "Glass", -21.0, 11.0, 27.42, 27.62, 8.2, 10.6)
	for k in 8:
		var gx := lerpf(-20.0, 10.0, float(k) / 7.0)
		lm.box("Frame", Vector3(gx, 9.4, 27.62), Vector3(0.16, 2.5, 0.22))

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-18.0, 2.0, -28.0), Vector3(-14.0, 7.5, -17.5), 58.0, 0.85, 42.0, Color(1.0, 0.90, 0.74)],
		[Vector3(18.0, 2.0, -28.0), Vector3(14.0, 7.5, -17.5), 58.0, 0.85, 42.0, Color(1.0, 0.90, 0.74)],
		[Vector3(0.0, 11.2, -12.0), Vector3(0.0, 18.0, -1.5), 52.0, 0.75, 36.0, Color(0.95, 0.94, 0.90)],
		[Vector3(44.0, 2.0, 6.0), Vector3(39.0, 8.5, 10.0), 54.0, 0.70, 34.0, Color(1.0, 0.82, 0.58)],
	])

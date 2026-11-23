class_name LandmarkLnTrafalgarSquare
extends RefCounted

## Trafalgar Square ensemble (`LN-3.5`, OSM ways 150920358, 30734422):
## - Nelson's Column (William Railton, 1843): 51.6 m fluted Dartmoor granite Corinthian
##   column on stepped bronze-relief plinth, four Landseer bronze lions on radiating
##   pedestals, bronze Corinthian capital, and 5.5 m Craigleith-stone statue of Nelson.
## - Twin granite fountain basins (Lutyens, 1939) north of the column.
## - National Gallery (William Wilkins, 1838) along the north terrace: 138 m Portland-stone
##   facade, central octastyle Corinthian portico & pediment, central lead dome, and
##   flanking pepper-pot domes.

const COL_TOP := 51.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkLnKit.granite("#8F8A82", 3.0))
	lm.use("Stone", LandmarkLnKit.portland("#E0D9C8", 3.4))
	lm.use("Bronze", LandmarkMaterials.paint("#2E332E", 0.45, 0.65))
	lm.use("Lead", LandmarkMaterials.paint("#565E66", 0.52, 0.35))
	lm.use("Water", LandmarkMaterials.pool_water("#386E78"))
	lm.use("Glass", LandmarkMaterials.glass("#242D34"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2B0", 1.2))
	_nelsons_column(lm)
	_fountains(lm)
	_national_gallery(lm)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 14.0), Vector3(0.0, 38.0, 0.0), 42.0, 1.0, 65.0],
		[Vector3(0.0, 2.0, -56.0), Vector3(0.0, 18.0, -76.0), 68.0, 0.9, 65.0],
	])

static func _nelsons_column(lm: LandmarkMesh) -> void:
	# Stepped granite base & bronze battle-relief pedestal (0..10.5 m)
	lm.box("Granite", Vector3(0.0, 0.9, 0.0), Vector3(16.0, 1.8, 16.0))
	lm.box("Granite", Vector3(0.0, 2.4, 0.0), Vector3(11.0, 1.4, 11.0))
	lm.box("Granite", Vector3(0.0, 6.6, 0.0), Vector3(6.4, 7.2, 6.4))
	# Four bronze battle relief plaques
	for rot_i in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(rot_i))
		var out := rot * Vector3(0.0, 0.0, 1.0)
		lm.box("Bronze", Vector3(0.0, 6.6, 0.0) + out * 3.25, Vector3(4.2, 4.2, 0.16), rot)
	# Four Landseer bronze lions on diagonal granite pedestals
	for i in 4:
		var a := PI * 0.25 + PI * 0.5 * float(i)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var rot := Basis(Vector3.UP, -a)
		lm.box("Granite", dir * 8.2 + Vector3(0.0, 1.4, 0.0), Vector3(5.6, 2.8, 2.4), rot)
		lm.box("Bronze", dir * 8.4 + Vector3(0.0, 3.6, 0.0), Vector3(4.6, 1.8, 1.6), rot)
		lm.box("Bronze", dir * 9.8 + Vector3(0.0, 4.6, 0.0), Vector3(1.5, 1.6, 1.4), rot)
	# Fluted granite column shaft (10.5..42.5 m)
	lm.frustum("Granite", Vector3(0.0, 10.2, 0.0), 2.1, 1.75, 32.3, 16)
	# Bronze Corinthian capital (42.5..46.0 m)
	lm.frustum("Bronze", Vector3(0.0, 42.5, 0.0), 1.8, 2.9, 3.2, 12)
	lm.box("Bronze", Vector3(0.0, 45.8, 0.0), Vector3(5.4, 0.8, 5.4))
	# Admiral Nelson statue (46.2..51.6 m)
	lm.frustum("Stone", Vector3(0.0, 46.2, 0.0), 0.9, 0.72, 4.4, 10)
	lm.frustum("Stone", Vector3(0.0, 50.6, 0.0), 0.55, 0.25, 1.0, 8)

static func _fountains(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		var fx := float(sx) * 26.0
		var fz := -36.0
		lm.frustum("Granite", Vector3(fx, 0.0, fz), 11.5, 11.5, 1.1, 16)
		lm.disc("Water", Vector3(fx, 0.95, fz), Vector3.UP, 10.6, 16)
		lm.frustum("Bronze", Vector3(fx, 1.0, fz), 2.2, 1.4, 3.2, 12)
		lm.frustum("Bronze", Vector3(fx, 4.2, fz), 3.6, 0.8, 1.4, 12)

static func _national_gallery(lm: LandmarkMesh) -> void:
	# North terrace overlooking Trafalgar Square (z = -84 m)
	var gz := -86.0
	var gw := 134.0
	var gd := 28.0
	# Terrace retaining wall & steps
	lm.box("Granite", Vector3(0.0, 1.8, gz + 20.0), Vector3(gw + 6.0, 3.6, 14.0))
	# Main Portland-stone gallery body
	lm.box("Stone", Vector3(0.0, 10.5, gz), Vector3(gw, 17.4, gd))
	lm.box("Stone", Vector3(0.0, 19.6, gz), Vector3(gw + 1.6, 1.2, gd + 1.4))
	# Central octastyle Corinthian portico & triangular pediment
	LandmarkLnKit.colonnade_x(lm, "Stone", -13.0, 13.0, 3.6, gz + gd * 0.5 + 3.5, 8, 14.2, 0.65)
	LandmarkLnKit.pediment_z(lm, "Stone", 0.0, 19.4, gz + gd * 0.5 + 3.5, 28.5, 4.8, 2.4)
	# Central lead dome & cupola (height ~35 m)
	lm.frustum("Stone", Vector3(0.0, 20.2, gz + 2.0), 8.2, 8.0, 5.5, 16)
	var prof := PackedVector2Array()
	for i in 7:
		var a := float(i) / 6.0 * PI * 0.5
		prof.append(Vector2(cos(a) * 8.0, sin(a) * 6.8))
	lm.lathe("Lead", Vector3(0.0, 25.7, gz + 2.0), prof, 16)
	lm.frustum("Stone", Vector3(0.0, 32.3, gz + 2.0), 1.8, 1.6, 2.6, 10)
	lm.frustum("Lead", Vector3(0.0, 34.9, gz + 2.0), 1.6, 0.2, 1.6, 10)
	# Flanking pepper-pot domes & end pavilions
	for sx in [-1.0, 1.0]:
		var px := float(sx) * 34.0
		lm.frustum("Stone", Vector3(px, 20.2, gz + 4.0), 3.2, 3.0, 3.6, 12)
		lm.frustum("Lead", Vector3(px, 23.8, gz + 4.0), 3.0, 0.3, 3.8, 12)
		var ex := float(sx) * 56.0
		lm.box("Stone", Vector3(ex, 11.2, gz + 1.2), Vector3(20.0, 18.8, gd + 2.4))
		LandmarkLnKit.colonnade_x(lm, "Stone", ex - 7.0, ex + 7.0, 3.6, gz + gd * 0.5 + 2.8, 4, 14.2, 0.58)
	# Classical blind niches & windows
	for i in 18:
		var wx := lerpf(-gw * 0.46, gw * 0.46, float(i) / 17.0)
		if absf(wx) > 15.0:
			lm.box("Glass", Vector3(wx, 12.2, gz + gd * 0.5 + 0.1), Vector3(2.2, 4.2, 0.14))

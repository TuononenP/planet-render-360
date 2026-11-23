class_name LandmarkLnBanksideCity
extends RefCounted

## Bankside & City of London historic icons (`LN-4.1`–`LN-4.5`):
## - `tate_modern`: Bankside Power Station (Giles Gilbert Scott, 1963) + Blavatnik Building.
## - `shakespeares_globe`: 20-sided white lime-plaster & oak timber-framed thatched theatre.
## - `bank_junction`: Royal Exchange Corinthian portico & Bank of England.
## - `monument_london`: Wren's 61.5 m fluted Doric column & gilded flaming urn.
## - `lloyds_building`: Richard Rogers's stainless-steel inside-out service towers & barrel vault.

static func tate_modern(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#7E5B48", 3.2))
	lm.use("DarkBrick", LandmarkMaterials.pbr("brick", "#604436", 3.2))
	lm.use("Glass", LandmarkMaterials.glass("#2A3A46"))
	lm.use("Lightbeam", LandmarkMaterials.lit("#FFF4DC", 1.1))
	lm.use("Steel", LandmarkMaterials.paint("#3E4348", 0.45, 0.55))
	# Monumental Bankside Power Station turbine hall (155 m x 56 m x 35 m)
	lm.box("Brick", Vector3(0.0, 17.5, 0.0), Vector3(155.0, 35.0, 56.0))
	# Iconic tall cathedral-like slotted vertical glass windows along the river front (+Z)
	for i in 12:
		var wx := lerpf(-66.0, 66.0, float(i) / 11.0)
		if absf(wx) > 10.0:
			lm.box("Glass", Vector3(wx, 18.0, 28.15), Vector3(2.8, 25.0, 0.25))
			lm.box("DarkBrick", Vector3(wx + 4.8, 18.0, 28.25), Vector3(1.6, 33.0, 0.5))
	# Herzog & de Meuron's horizontal glass "Lightbeam" roof extension (35..41 m)
	lm.box("Lightbeam", Vector3(0.0, 38.0, 0.0), Vector3(148.0, 5.6, 20.0))
	lm.box("Steel", Vector3(0.0, 41.0, 0.0), Vector3(150.0, 0.6, 21.0))
	# 99 m fluted brick central chimney with illuminated Swiss-light glass crown
	lm.box("Brick", Vector3(0.0, 47.0, 24.0), Vector3(14.0, 94.0, 11.0))
	for sx in [-4.5, 0.0, 4.5]:
		lm.box("DarkBrick", Vector3(float(sx), 47.0, 29.6), Vector3(1.4, 92.0, 0.5))
	lm.box("Lightbeam", Vector3(0.0, 96.5, 24.0), Vector3(12.8, 5.0, 9.8))
	# Blavatnik Building (Switch House) twisted brick-lattice pyramid behind (-Z, 64 m)
	lm.box("DarkBrick", Vector3(12.0, 18.0, -44.0), Vector3(44.0, 36.0, 34.0))
	lm.frustum("DarkBrick", Vector3(12.0, 36.0, -44.0), 22.0, 13.0, 28.0, 4)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 3.0, 42.0), Vector3(0.0, 52.0, 24.0), 58.0, 0.9, 85.0],
	])

static func shakespeares_globe(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#EFECE4", 2.8))
	lm.use("Oak", LandmarkMaterials.paint("#3B2C20", 0.72, 0.05))
	lm.use("Thatch", LandmarkMaterials.pbr("render", "#7A6A4E", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#222B30"))
	# 20-sided open-air white lime-plaster & oak-timber ring (30 m diameter, 15 m tall)
	var segs := 20
	var r_out := 15.0
	var r_in := 11.2
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var am := (a0 + a1) * 0.5
		var p := Vector3(cos(am) * ((r_out + r_in) * 0.5), 5.6, sin(am) * ((r_out + r_in) * 0.5))
		var rot := Basis(Vector3.UP, -am)
		lm.box("Plaster", p, Vector3(r_out - r_in, 11.2, 4.9), rot)
		# Dark oak vertical & horizontal timber framing on outer face
		var op := Vector3(cos(a0) * (r_out + 0.08), 5.6, sin(a0) * (r_out + 0.08))
		lm.box("Oak", op, Vector3(0.28, 11.2, 0.28), rot)
		for hy in [3.6, 7.2, 10.8]:
			var hp := Vector3(cos(am) * (r_out + 0.08), float(hy), sin(am) * (r_out + 0.08))
			lm.box("Oak", hp, Vector3(0.24, 0.28, 4.8), rot)
		# Pitched thatched roof ring around open courtyard (11.2..15.0 m)
		var rp := Vector3(cos(am) * ((r_out + r_in) * 0.5), 12.6, sin(am) * ((r_out + r_in) * 0.5))
		lm.box("Thatch", rp, Vector3(5.4, 2.8, 5.2), rot)
	# Tiring house gable & turret (top = 15.0 m)
	lm.box("Plaster", Vector3(0.0, 12.4, -12.8), Vector3(11.0, 4.2, 5.0))
	lm.box("Thatch", Vector3(0.0, 14.6, -12.8), Vector3(11.6, 0.8, 5.4))
	lm.commit(model)

static func bank_junction(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkLnKit.portland("#E0D9C8", 3.4))
	lm.use("Slate", LandmarkLnKit.welsh_slate("#495159", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#222B32"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Royal Exchange (William Tite, 1844): Portland-stone trapezoidal block + octastyle Corinthian portico
	lm.box("Stone", Vector3(0.0, 10.5, 0.0), Vector3(46.0, 21.0, 74.0))
	lm.box("Stone", Vector3(0.0, 21.6, 0.0), Vector3(47.4, 1.2, 75.4))
	lm.gable("Slate", Vector3(0.0, 22.2, -4.0), 44.0, 62.0, 3.2, Basis(), 0.0, "Slate")
	for i in 10:
		var wz := lerpf(-30.0, 30.0, float(i) / 9.0)
		for sx in [-1.0, 1.0]:
			lm.box("Glass", Vector3(float(sx) * 23.1, 13.0, wz), Vector3(0.14, 4.4, 2.4))
	LandmarkLnKit.colonnade_x(lm, "Stone", -14.0, 14.0, 1.5, 41.5, 8, 16.5, 0.72)
	LandmarkLnKit.pediment_z(lm, "Stone", 0.0, 19.6, 41.5, 31.0, 5.4, 2.6)
	# Rear Baroque bell tower & golden grasshopper weathervane (top = 30.0 m)
	lm.box("Stone", Vector3(0.0, 23.5, -28.0), Vector3(9.0, 5.0, 9.0))
	lm.frustum("Stone", Vector3(0.0, 26.0, -28.0), 3.2, 0.4, 3.2, 8)
	lm.box("Gilt", Vector3(0.0, 29.6, -28.0), Vector3(1.6, 0.8, 0.35))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 52.0), Vector3(0.0, 18.0, 38.0), 62.0, 0.95, 55.0],
	])

static func monument_london(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkLnKit.portland("#E2DAC8", 2.8))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Iron", LandmarkMaterials.paint("#24282C", 0.5, 0.5))
	# Stepped plinth & carved square pedestal (0..12.2 m)
	lm.box("Stone", Vector3(0.0, 1.0, 0.0), Vector3(9.6, 2.0, 9.6))
	lm.box("Stone", Vector3(0.0, 6.8, 0.0), Vector3(6.4, 10.4, 6.4))
	lm.box("Stone", Vector3(0.0, 12.2, 0.0), Vector3(7.2, 0.8, 7.2))
	# Fluted Portland-stone Doric column shaft (12.6..49.5 m)
	lm.frustum("Stone", Vector3(0.0, 12.6, 0.0), 2.35, 1.95, 36.9, 16)
	# Abacus viewing gallery & iron cage (49.5..53.2 m)
	lm.box("Stone", Vector3(0.0, 50.2, 0.0), Vector3(6.2, 1.4, 6.2))
	lm.frustum("Iron", Vector3(0.0, 50.9, 0.0), 2.6, 2.6, 2.4, 12)
	# Drum & gilded flaming urn (53.2..61.5 m)
	lm.frustum("Stone", Vector3(0.0, 53.2, 0.0), 1.8, 1.4, 4.2, 12)
	lm.frustum("Gilt", Vector3(0.0, 57.4, 0.0), 1.5, 0.12, 4.1, 12)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 14.0), Vector3(0.0, 44.0, 0.0), 42.0, 0.95, 72.0],
	])

static func lloyds_building(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#C6CCD2", 0.34, 0.8))
	lm.use("DarkSteel", LandmarkMaterials.paint("#6E767E", 0.42, 0.72))
	lm.use("Glass", LandmarkMaterials.glass("#3B5160"))
	lm.use("Lamp", LandmarkMaterials.lit("#66B2FF", 1.3))
	# Main stepped glazed office core (54 m x 44 m, stepping 44..66 m)
	lm.box("Glass", Vector3(0.0, 22.0, 0.0), Vector3(52.0, 44.0, 42.0))
	lm.box("Glass", Vector3(0.0, 54.0, -4.0), Vector3(44.0, 20.0, 32.0))
	# Glazed barrel-vaulted atrium roof (64..74 m)
	var segs := 8
	for i in segs:
		var a := lerpf(-1.2, 1.2, (float(i) + 0.5) / float(segs))
		lm.box("Glass", Vector3(sin(a) * 14.0, 64.0 + cos(a) * 9.5, -4.0), Vector3(4.2, 0.9, 34.0))
	# Six iconic external stainless-steel cylindrical service towers (up to 88.0 m)
	var towers := [
		[-30.0, -14.0, 88.0], [-30.0, 10.0, 76.0],
		[30.0, -14.0, 84.0], [30.0, 10.0, 72.0],
		[-12.0, 26.0, 68.0], [12.0, 26.0, 78.0],
	]
	for t in towers:
		var tx: float = t[0]
		var tz: float = t[1]
		var th: float = t[2]
		lm.frustum("Steel", Vector3(tx, 0.0, tz), 4.2, 4.2, th - 6.0, 12)
		lm.box("DarkSteel", Vector3(tx, th - 3.0, tz), Vector3(6.8, 6.0, 6.8))
		# Exposed vertical silver lift-duct tubes
		lm.frustum("DarkSteel", Vector3(tx + 3.2, 0.0, tz), 1.1, 1.1, th - 8.0, 8)
		lm.box("Lamp", Vector3(tx, th - 8.0, tz + 4.3), Vector3(1.2, 12.0, 0.2))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 3.0, 40.0), Vector3(0.0, 55.0, 0.0), 60.0, 0.9, 95.0],
	])

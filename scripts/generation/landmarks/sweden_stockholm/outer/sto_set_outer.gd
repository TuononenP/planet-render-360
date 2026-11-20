extends RefCounted

## Builders for data/stockholm/sto_reg_outer.gd. Returns false for a
## type it does not own.

const StoFarArena = preload("res://scripts/generation/landmarks/sweden_stockholm/outer/sto_far_arena.gd")
const StoFarNrm = preload("res://scripts/generation/landmarks/sweden_stockholm/outer/sto_far_nrm.gd")
const StoFarKth = preload("res://scripts/generation/landmarks/sweden_stockholm/outer/sto_far_kth.gd")
const StoFarSu = preload("res://scripts/generation/landmarks/sweden_stockholm/outer/sto_far_su.gd")
const StoFarNks = preload("res://scripts/generation/landmarks/sweden_stockholm/outer/sto_far_nks.gd")

static func build(_model: Node3D, type: String) -> bool:
	match type:
		"kungliga_biblioteket": StoOuterKb.build(_model)
		"adolf_fredriks_kyrka": StoOuterAdolf.build(_model)
		"stockholm_stadion": StoOuterStadion.build(_model)
		"berwaldhallen": StoOuterBerwald.build(_model)
		"skatteskrapan": StoOuterSkatteskrapan.build(_model)
		"norra_tornen": StoOuterNorraTornen.build(_model)
		"tele2_arena": StoOuterTele2Arena.build(_model)
		"viking_line_terminal": StoOuterViking.build(_model)
		"varta_terminal": StoOuterVarta.build(_model)
		"karl_xii_statue": StoOuterStatues.build_karl(_model)
		"gustav_ii_adolf_statue": StoOuterStatues.build_gustav(_model)
		"strawberry_arena": StoFarArena.build(_model)
		"naturhistoriska_riksmuseet": StoFarNrm.build(_model)
		"kth_main": StoFarKth.build(_model)
		"stockholm_university": StoFarSu.build(_model)
		"nya_karolinska": StoFarNks.build(_model)
		_:
			return false
	return true

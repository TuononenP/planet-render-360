extends RefCounted

## Builders for data/stockholm/sto_reg_inner.gd. Returns false for a
## type it does not own.

static func build(_model: Node3D, type: String) -> bool:
	match type:
		"munchenbryggeriet": StoMunchen.build(_model)
		"hogalid_church": StoHogalid.build(_model)
		"fotografiska": StoFotografiska.build(_model)
		"engelbrektskyrkan": StoEngelbrekt.build(_model)
		_:
			return false
	return true

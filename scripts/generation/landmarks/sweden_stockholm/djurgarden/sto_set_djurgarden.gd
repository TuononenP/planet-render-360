extends RefCounted

## Builders for data/stockholm/sto_reg_djurgarden.gd. Returns false for a
## type it does not own.

static func build(_model: Node3D, type: String) -> bool:
	match type:
		"skansen_bredablick": StoDjurgBredablick.build(_model)
		"skansen_hazelius_gate": StoDjurgHazeliusGate.build(_model)
		"waldemarsudde": StoDjurgWaldemarsudde.build(_model)
		"rosendal": StoDjurgRosendal.build(_model)
		"abba_museum": StoDjurgAbba.build(_model)
		"liljevalchs": StoDjurgLiljevalchs.build(_model)
		"cirkus": StoDjurgCirkus.build(_model)
		"sjohistoriska": StoSjohistoriska.build(_model)
		"tekniska_museet": StoTekniska.build(_model)
		"grona_lund_park": StoGronaPark.build(_model)
		_:
			return false
	return true

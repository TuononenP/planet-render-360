class_name ArchitectureCitiesVenice
extends RefCounted

## Venice sestieri architectural fabrics & era rule (`VN-8.1`–`VN-8.3`).
## Recalibrated lime-stucco palette with `VENICE_PAINT = 0.35` lifts Venice's
## dark luma and tames excess saturation (`fidelity-scorecard.md:521`), while
## `venice_rule` restricts `venice_modern` strictly to Tronchetto, Santa Marta,
## Piazzale Roma, Marittima and Sacca Fisola — eliminating the modern foreground
## concrete block beside Ponte dell'Accademia (`fidelity-scorecard.md:515`).

const VENICE_PAINT := 0.35

## Sun-washed Venetian lime stucco: luminous cream, pale peach-ochre, faded rose,
## warm apricot, weathered sand and muted burnt sienna.
const STUCCO_WASHED := ["#E6CBB0", "#DFB796", "#D49A7C", "#E9D9BE", "#E4C79B", "#C98468", "#DCD0BC", "#E2BFA8"]
const STUCCO_PALE := ["#EDE4D2", "#E8DCC5", "#EFE8DA", "#E3D3B8", "#E6D0B4"]
const ISTRIAN_STONE := ["#EFEBE0", "#E7E1D3", "#DDD5C4"]
const VENICE_BRICK := ["#B35A43", "#A44F3A", "#BD674E", "#984B38"]
const VENICE_ROOF := ["#9E6850", "#AE765A", "#8D5B46", "#B58468", "#965F48"]
const VENICE_SHUTTER := ["#354F38", "#3E583D", "#2E4535", "#563829"]
const BURANO_BRIGHT := ["#3A6CA8", "#E4B83A", "#C9483C", "#3E8C62", "#9A5CA2", "#E27848", "#D86A8C", "#4A9CA8"]

const BASE := {
	"venice_grand_canal": "venice",
	"venice_san_marco": "venice",
	"venice_palazzo": "venice",
	"venice_ghetto": "venice",
	"venice_arsenale": "venice",
	"venice_burano": "venice",
	"venice_lido": "venice",
}

const REGIONS := {
	# Monumental Grand Canal palazzi: 3–5 tall piano-nobile storeys, white Istrian
	# trim, Gothic/Renaissance polifore, terracotta hipped roofs & bell chimneys.
	"venice_grand_canal": {
		"apartments": {"vt": VENICE_PAINT, "w": [["render", STUCCO_WASHED], ["stone", ISTRIAN_STONE]],
			"p": [["ornate", 4], ["punched", 2]], "wn": "gothic", "bay": 2.7, "fr": "#F2EDE0",
			"sh": VENICE_SHUTTER, "sp": 0.45, "rl": 0.35, "r": [["hipped", 4], ["gabled", 1]], "pitch": 0.44,
			"rf": [["terracotta", VENICE_ROOF]], "fh": 4.1, "st": [3, 5], "fix": true, "ch": 0.7,
			"g": [["stone", 3], ["render", 2], ["shop", 1]], "ev": 0.35,
			"rv": {"balconette": 0.45, "string_course": true, "quoins": true, "chimney_cap": "bell", "altana": 0.35}},
		"commercial": {"vt": VENICE_PAINT, "w": [["stone", ISTRIAN_STONE], ["render", STUCCO_WASHED]],
			"p": "ornate", "wn": "gothic", "bay": 2.8, "fr": "#F2EDE0", "sh": VENICE_SHUTTER, "sp": 0.35,
			"r": [["hipped", 3], ["gabled", 1]], "pitch": 0.44, "rf": [["terracotta", VENICE_ROOF]],
			"fh": 4.1, "st": [3, 5], "fix": true, "ch": 0.55, "g": [["stone", 2], ["shop", 2]], "ev": 0.35,
			"rv": {"balconette": 0.4, "string_course": true, "quoins": true, "awning": 0.35, "chimney_cap": "bell",
				"awning_colours": ["#F0ECE2", "#2A4A3A", "#862C22"]}},
		"civic": {"vt": VENICE_PAINT, "w": [["stone", ISTRIAN_STONE], ["render", STUCCO_PALE]],
			"p": "ornate", "wn": "gothic", "r": [["hipped", 3], ["gabled", 1]], "pitch": 0.46,
			"rf": [["terracotta", VENICE_ROOF]], "fh": 4.4, "st": [3, 5], "fix": true,
			"rv": {"string_course": true, "quoins": true}},
	},
	# San Marco & Mercerie ceremonial Istrian-stone & pale-stucco arcaded blocks.
	"venice_san_marco": {
		"apartments": {"vt": VENICE_PAINT, "w": [["stone", ISTRIAN_STONE], ["render", STUCCO_PALE]],
			"p": [["ornate", 3], ["punched", 2]], "wn": "gothic", "bay": 2.6, "fr": "#F2EDE0",
			"sh": VENICE_SHUTTER, "sp": 0.4, "r": [["hipped", 3], ["gabled", 1]], "pitch": 0.44,
			"rf": [["terracotta", VENICE_ROOF]], "fh": 3.8, "st": [3, 5], "fix": true, "ch": 0.65,
			"g": [["shop", 3], ["stone", 2]], "ev": 0.35,
			"rv": {"balconette": 0.35, "string_course": true, "quoins": true, "awning": 0.35, "chimney_cap": "bell",
				"altana": 0.3, "awning_colours": ["#F2EEE4", "#862C22", "#2A4A3A"]}},
		"commercial": {"vt": VENICE_PAINT, "w": [["stone", ISTRIAN_STONE], ["render", STUCCO_PALE]],
			"p": "ornate", "wn": "gothic", "bay": 2.7, "fr": "#F2EDE0", "sh": VENICE_SHUTTER, "sp": 0.3,
			"r": [["hipped", 3], ["gabled", 1]], "pitch": 0.44, "rf": [["terracotta", VENICE_ROOF]],
			"fh": 3.9, "st": [3, 5], "fix": true, "g": [["shop", 4], ["stone", 1]], "ev": 0.35,
			"rv": {"string_course": true, "quoins": true, "awning": 0.5, "chimney_cap": "bell",
				"awning_colours": ["#F2EEE4", "#862C22", "#2A4A3A", "#C8A44E"]}},
	},
	# Historic sestieri residential palazzi & townhouses (Dorsoduro, San Polo, Santa Croce, Cannaregio, Castello).
	"venice_palazzo": {
		"apartments": {"vt": VENICE_PAINT, "w": [["render", STUCCO_WASHED], ["brick", VENICE_BRICK]],
			"p": [["punched", 4], ["ornate", 2]], "wn": "gothic", "bay": 2.5, "fr": "#EDE7D8",
			"sh": VENICE_SHUTTER, "sp": 0.65, "r": [["hipped", 3], ["gabled", 2]], "pitch": 0.45,
			"rf": [["terracotta", VENICE_ROOF]], "fh": 3.4, "st": [3, 4], "fix": true, "ch": 0.75,
			"g": [["render", 3], ["shop", 2]], "ev": 0.35,
			"rv": {"balconette": 0.25, "string_course": true, "awning": 0.2, "chimney_cap": "bell", "altana": 0.4}},
		"house": {"vt": VENICE_PAINT, "w": [["render", STUCCO_WASHED], ["brick", VENICE_BRICK]],
			"p": "punched", "wn": "gothic", "bay": 2.4, "fr": "#EDE7D8", "sh": VENICE_SHUTTER, "sp": 0.75,
			"r": [["gabled", 3], ["hipped", 2]], "pitch": 0.46, "rf": [["terracotta", VENICE_ROOF]],
			"fh": 3.2, "st": [2, 3], "fix": true, "ch": 0.8, "ev": 0.35,
			"rv": {"string_course": true, "chimney_cap": "bell", "altana": 0.4}},
	},
	# Venetian Ghetto tall 5–7 storey historic warm-plaster case-torri tenements.
	"venice_ghetto": {
		"apartments": {"vt": VENICE_PAINT, "w": [["render", STUCCO_PALE], ["render", STUCCO_WASHED]],
			"p": "punched", "wn": "casement", "bay": 2.3, "fr": "#EDE7D8", "sh": VENICE_SHUTTER, "sp": 0.65,
			"r": [["hipped", 2], ["gabled", 2]], "pitch": 0.42, "rf": [["terracotta", VENICE_ROOF]],
			"fh": 2.85, "st": [5, 7], "fix": true, "ch": 0.7, "g": [["shop", 2], ["render", 2]], "ev": 0.3,
			"rv": {"string_course": true, "chimney_cap": "bell", "altana": 0.25}},
	},
	# Arsenale, Giudecca industrial lofts & Murano glassworks: weathered red brick & terracotta gables.
	"venice_arsenale": {
		"apartments": {"vt": VENICE_PAINT, "w": [["brick", VENICE_BRICK], ["render", STUCCO_WASHED]],
			"p": "punched", "wn": "casement", "bay": 2.7, "fr": "#E8E2D2", "sh": VENICE_SHUTTER, "sp": 0.5,
			"r": [["gabled", 3], ["hipped", 2]], "pitch": 0.46, "rf": [["terracotta", VENICE_ROOF]],
			"fh": 3.4, "st": [2, 4], "fix": true, "ch": 0.5, "ev": 0.35, "rv": {"string_course": true}},
		"commercial": {"vt": VENICE_PAINT, "w": [["brick", VENICE_BRICK]],
			"p": "punched", "wn": "casement", "bay": 3.2, "fr": "#E8E2D2", "sp": 0.1,
			"r": [["gabled", 4], ["hipped", 1]], "pitch": 0.48, "rf": [["terracotta", VENICE_ROOF]],
			"fh": 4.2, "st": [2, 3], "fix": true, "ev": 0.35},
		"outbuilding": {"vt": VENICE_PAINT, "w": [["brick", VENICE_BRICK]],
			"p": "punched", "r": [["gabled", 3]], "pitch": 0.48, "rf": [["terracotta", VENICE_ROOF]],
			"fh": 4.0, "st": [1, 2], "fix": true},
	},
	# Burano fisherman houses: vivid jewel-box colours under pitched terracotta roofs.
	"venice_burano": {
		"house": {"vt": 0.45, "w": [["render", BURANO_BRIGHT]], "p": "punched", "wn": "casement",
			"bay": 2.3, "fr": "#F6F3EC", "sh": VENICE_SHUTTER, "sp": 0.75,
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 0.46, "rf": [["terracotta", VENICE_ROOF]],
			"fh": 3.0, "st": [2, 3], "fix": true, "ch": 0.65, "ev": 0.3},
		"apartments": {"vt": 0.45, "w": [["render", BURANO_BRIGHT]], "p": "punched", "wn": "casement",
			"bay": 2.4, "fr": "#F6F3EC", "sh": VENICE_SHUTTER, "sp": 0.7,
			"r": [["gabled", 3], ["hipped", 1]], "pitch": 0.46, "rf": [["terracotta", VENICE_ROOF]],
			"fh": 3.0, "st": [2, 3], "fix": true, "ch": 0.65, "ev": 0.3},
	},
	# Lido di Venezia: Venetian Liberty / Art Nouveau pale stucco villas.
	"venice_lido": {
		"house": {"vt": VENICE_PAINT, "w": [["render", STUCCO_PALE]], "p": "ornate", "wn": "casement",
			"bay": 2.8, "fr": "#F4F0E6", "sh": VENICE_SHUTTER, "sp": 0.7,
			"r": [["hipped", 3], ["gabled", 1]], "pitch": 0.48, "rf": [["terracotta", VENICE_ROOF]],
			"fh": 3.4, "st": [2, 3], "fix": true, "ev": 0.45, "rv": {"balconette": 0.35, "string_course": true}},
		"apartments": {"vt": VENICE_PAINT, "w": [["render", STUCCO_PALE], ["render", STUCCO_WASHED]],
			"p": [["ornate", 2], ["punched", 2]], "wn": "casement", "bay": 2.8, "fr": "#F4F0E6",
			"sh": VENICE_SHUTTER, "sp": 0.55, "r": [["hipped", 3], ["gabled", 1]], "pitch": 0.45,
			"rf": [["terracotta", VENICE_ROOF]], "fh": 3.3, "st": [3, 4], "fix": true, "ev": 0.4,
			"rv": {"balconette": 0.3, "string_course": true}},
	},
}

## Venice era & district rule called from `BuildingEra`:
## - Restricts `venice_modern` strictly to the Tronchetto / Piazzale Roma / Santa Marta /
##   Marittima / Sacca Fisola modern district circles (never historic palazzi!).
## - Routes historic sestieri by district circle (`venice_grand_canal`, `venice_san_marco`,
##   `venice_ghetto`, `venice_arsenale`, `venice_palazzo`, `venice_burano`, `venice_lido`).
static func venice_rule(_kind: String, c: Dictionary) -> String:
	var district := str(c.get("district", ""))
	if district == "venice_modern":
		return "venice_modern"
	if BASE.has(district):
		return district
	var lv := int(c.get("levels", 0))
	var area := float(c.get("area", 0.0))
	if lv >= 4 and area >= 450.0:
		return "venice_grand_canal"
	return "venice"

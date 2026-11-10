class_name FacadeCurtainKit
extends RefCounted

## Curtain-wall art for FacadeComposer: one bay of a named glazing type, on
## its CELL px grid. Drawn colours are linear, like the composer's own. Clear
## and tinted glass stays light enough to read as sky-lit by day (sRGB about
## 80-130 from a distance); only the bronze of the 1950s-70s reads dark.
##   sill      y where the spandrel starts (the rest of the storey)
##   mullions  vertical mullions per bay
##   width     mullion width in px
##   fin       a vertical fin's shadow beside each mullion

const CELL := 128
const LOOKS := {
	# Dark bronze glass and spandrels behind proud bronze mullions.
	"intl_bronze": {"low": Color(0.060, 0.054, 0.048), "top": Color(0.085, 0.076, 0.066),
		"spandrel": Color(0.052, 0.046, 0.040), "mullion": Color(0.130, 0.100, 0.075),
		"sill": 92, "mullions": 2, "width": 5, "fin": false},
	# 1950s International Style: blue-green glass on a bright aluminium grid
	# over light spandrels (Lever House, the UN Secretariat).
	"intl_aluminium": {"low": Color(0.070, 0.115, 0.110), "top": Color(0.100, 0.150, 0.145),
		"spandrel": Color(0.125, 0.155, 0.152), "mullion": Color(0.420, 0.430, 0.430),
		"sill": 90, "mullions": 2, "width": 3, "fin": false},
	# Mirror glass running through the floors on a thin aluminium grid.
	"silver_reflective": {"low": Color(0.160, 0.175, 0.190), "top": Color(0.210, 0.225, 0.240),
		"spandrel": Color(0.150, 0.165, 0.180), "mullion": Color(0.300, 0.310, 0.320),
		"sill": 100, "mullions": 1, "width": 2, "fin": false},
	# Blue-green low-e glass with slim mullions.
	"lowe_blue": {"low": Color(0.080, 0.130, 0.160), "top": Color(0.115, 0.170, 0.205),
		"spandrel": Color(0.100, 0.145, 0.170), "mullion": Color(0.240, 0.260, 0.280),
		"sill": 98, "mullions": 2, "width": 3, "fin": false},
	# Gulf gold reflective glass on a bronze grid.
	"gold_reflective": {"low": Color(0.200, 0.160, 0.095), "top": Color(0.255, 0.205, 0.125),
		"spandrel": Color(0.170, 0.135, 0.085), "mullion": Color(0.260, 0.215, 0.145),
		"sill": 100, "mullions": 1, "width": 3, "fin": false},
	# Green-tinted glass of 1980s-90s Asian office towers.
	"green_glass": {"low": Color(0.075, 0.140, 0.115), "top": Color(0.105, 0.180, 0.150),
		"spandrel": Color(0.080, 0.135, 0.112), "mullion": Color(0.200, 0.230, 0.215),
		"sill": 96, "mullions": 2, "width": 3, "fin": false},
	# Near-neutral clear glass, a short spandrel and vertical fins.
	"clear_fin": {"low": Color(0.095, 0.115, 0.122), "top": Color(0.135, 0.155, 0.162),
		"spandrel": Color(0.090, 0.102, 0.108), "mullion": Color(0.180, 0.190, 0.190),
		"sill": 108, "mullions": 2, "width": 3, "fin": true},
	# Pale silver-blue glass over light terracotta spandrels (One Vanderbilt).
	"pale_terracotta": {"low": Color(0.150, 0.180, 0.205), "top": Color(0.215, 0.245, 0.270),
		"spandrel": Color(0.400, 0.360, 0.290), "mullion": Color(0.440, 0.420, 0.380),
		"sill": 94, "mullions": 2, "width": 4, "fin": false},
}

static func has(id: String) -> bool:
	return LOOKS.has(id)

## One bay at x = ox. nor and rgh are null at detail 0.
static func draw(id: String, alb: Image, nor: Image, rgh: Image, ox: int, hv: float) -> void:
	var s: Dictionary = LOOKS[id]
	var sill := int(s["sill"])
	var low: Color = s["low"]
	var top: Color = s["top"]
	var spandrel: Color = s["spandrel"]
	var mullion: Color = s["mullion"]
	var width := int(s["width"])
	var step := CELL / int(s["mullions"])
	var v := 0.94 + hv * 0.12
	for y in sill:
		var sky := top.lerp(low, float(y) / float(sill))
		alb.fill_rect(Rect2i(ox, y, CELL, 1), Color(sky.r * v, sky.g * v, sky.b * v))
	alb.fill_rect(Rect2i(ox, sill, CELL, CELL - sill), spandrel)
	alb.fill_rect(Rect2i(ox, sill - 2, CELL, 3), mullion)
	alb.fill_rect(Rect2i(ox, CELL - 2, CELL, 2), mullion)
	for x in range(0, CELL, step):
		alb.fill_rect(Rect2i(ox + x, 0, width, CELL), mullion)
		if bool(s["fin"]):
			alb.fill_rect(Rect2i(ox + x + width, 0, 5, CELL), Color(0.018, 0.022, 0.024))
	if nor == null:
		return
	rgh.fill_rect(Rect2i(ox, 0, CELL, sill), Color(0.08, 0.08, 0.08))
	rgh.fill_rect(Rect2i(ox, sill, CELL, CELL - sill), Color(0.4, 0.4, 0.4))
	nor.fill_rect(Rect2i(ox, sill - 2, CELL, 1), Color(0.5, 0.38, 1.0))
	nor.fill_rect(Rect2i(ox, sill - 1, CELL, 2), Color(0.5, 0.62, 1.0))
	for x in range(0, CELL, step):
		nor.fill_rect(Rect2i(ox + x, 0, maxi(1, width / 2), CELL), Color(0.38, 0.5, 1.0))
		nor.fill_rect(Rect2i(ox + x + maxi(1, width / 2), 0, maxi(1, width / 2), CELL), Color(0.62, 0.5, 1.0))
		rgh.fill_rect(Rect2i(ox + x, 0, width, CELL), Color(0.4, 0.4, 0.4))

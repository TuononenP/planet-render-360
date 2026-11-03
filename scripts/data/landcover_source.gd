class_name LandcoverSource
extends RefCounted

## Addressing for the registered WorldCover v200 and Meta canopy v2 COGs.
## WorldCover uses 3-degree geographic tiles; canopy uses z10 Web Mercator
## quadkeys. Both return pixel coordinates in the full-resolution image.

const WORLDCOVER_BASE := "https://esa-worldcover.s3.eu-central-1.amazonaws.com/v200/2021/map/"
const CANOPY_BASE := "https://dataforgood-fb-data.s3.amazonaws.com/forests/v2/global/dinov3_global_chm_v2_ml3/chm/"
const WORLDCOVER_SIZE := 36000
const CANOPY_ZOOM := 10
const CANOPY_SIZE := 32768
const MERCATOR_LIMIT := 85.0511287798066

static func worldcover(lat: float, lon: float) -> Dictionary:
	if not is_finite(lat) or not is_finite(lon) or lat < -90.0 or lat >= 90.0 \
			or lon < -180.0 or lon >= 180.0:
		return {}
	var south := int(floor(lat / 3.0)) * 3
	var west := int(floor(lon / 3.0)) * 3
	var name := "%s%02d%s%03d" % ["N" if south >= 0 else "S", absi(south),
		"E" if west >= 0 else "W", absi(west)]
	var x := clampi(int(floor((lon - float(west)) / 3.0 * WORLDCOVER_SIZE)), 0, WORLDCOVER_SIZE - 1)
	var y := clampi(int(floor((float(south + 3) - lat) / 3.0 * WORLDCOVER_SIZE)), 0, WORLDCOVER_SIZE - 1)
	return {"url": WORLDCOVER_BASE + "ESA_WorldCover_10m_2021_v200_" + name + "_Map.tif",
		"tile": name, "pixel": Vector2i(x, y)}

static func canopy(lat: float, lon: float) -> Dictionary:
	if not is_finite(lat) or not is_finite(lon) or absf(lat) > MERCATOR_LIMIT \
			or lon < -180.0 or lon >= 180.0:
		return {}
	var n := 1 << CANOPY_ZOOM
	var x := (lon + 180.0) / 360.0 * n
	var r := deg_to_rad(lat)
	var y := (1.0 - log(tan(r) + 1.0 / cos(r)) / PI) * 0.5 * n
	var tx := clampi(int(floor(x)), 0, n - 1)
	var ty := clampi(int(floor(y)), 0, n - 1)
	var key := ""
	for level in range(CANOPY_ZOOM, 0, -1):
		var mask := 1 << (level - 1)
		var digit := (1 if (tx & mask) != 0 else 0) + (2 if (ty & mask) != 0 else 0)
		key += str(digit)
	return {"url": CANOPY_BASE + key + ".tif", "tile": key,
		"pixel": Vector2i(clampi(int(floor((x - tx) * CANOPY_SIZE)), 0, CANOPY_SIZE - 1),
			clampi(int(floor((y - ty) * CANOPY_SIZE)), 0, CANOPY_SIZE - 1))}

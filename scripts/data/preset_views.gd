class_name PresetViews
extends RefCounted

## Curated opening view for each quick-pick preset: where the world is
## centred, where the camera stands and which way it looks, so a preset
## opens on the scene people picture (Shibuya Crossing, not a Setagaya
## lawn). Data only: builders never branch on a preset, and any other
## coordinate keeps View360's generic camera.
##
## A view is resolved from the pin itself (for_pin), so History,
## Recents, Retry, offline saves and typed coordinates all reopen the
## same view. Camera-only: never part of the WorldCache key, because the
## same origin always resolves the same view.
##
## Row fields:
##   id, label (chip text; PlaceCard.SKY_FOR keys on it), name
##   lat, lon        world origin: the centre of the ±1200 m detailed extent
##   eye_lat/eye_lon camera ground position, inside the extent; the
##                   origin when absent. Setting it lets the extent cover
##                   what the camera faces rather than what is behind it.
##   eye_m           eye height above the ground (≥ 4 m: the DEM blurs
##                   kerbs and cliff edges into ramps)
##   asl_m           optional floor for the camera in metres ASL, for
##                   decks and clifftops the smoothed DEM sits below
##   bearing, pitch  opening look in degrees (compass bearing; +pitch up)
##   clear           optional, default true: View360 lifts the eye until
##                   nothing right in front blocks the look; false where
##                   the buildings beside the look are the framing
## Every eye below was checked in captures (visual-plan/reviews/vantage-r4-*).
## Positions were checked against OSM (Nominatim, 2026-11-01).

## A pin this close to a row's origin opens with that row's view.
const MATCH_M := 15.0

const ROWS := [
	# Palais de Chaillot esplanade, on the axis to the Eiffel Tower
	# (~600 m, bearing 135°); the tower opens just left of centre.
	{"id": "paris", "label": "Paris", "name": "Paris, France",
		"lat": 48.8622, "lon": 2.2887, "eye_m": 6.0, "bearing": 142.0, "pitch": 4.0},
	# Harder Kulm (1322 m) over Interlaken to Eiger, Mönch and Jungfrau
	# (139–155°); the extent sits between the summit and the town.
	{"id": "alps", "label": "Alps", "name": "Interlaken, Switzerland",
		"lat": 46.6900, "lon": 7.8580, "eye_lat": 46.6983, "eye_lon": 7.8549,
		"eye_m": 4.0, "asl_m": 1324.0, "bearing": 147.0, "pitch": -4.0},
	# Surprise Corner, across the Bow to the Banff Springs Hotel (210°).
	# The lookout stands on a bluff the DEM smooths away, and the river
	# woods are photo-derived (not mapped forest the look check sees):
	# eye over the treetops.
	{"id": "banff", "label": "Banff", "name": "Banff, Canada",
		"lat": 51.1720, "lon": -115.5640, "eye_lat": 51.1676, "eye_lon": -115.5596,
		"eye_m": 28.0, "bearing": 205.0, "pitch": -4.0},
	# Highway 1 pull-out at the north end of Bixby Creek Bridge (the
	# span ~130 m away at 142°), the coast running south on the right.
	{"id": "big_sur", "label": "Big Sur", "name": "Big Sur, United States",
		"lat": 36.3740, "lon": -121.9022, "eye_lat": 36.3725, "eye_lon": -121.9028,
		"eye_m": 4.0, "bearing": 150.0, "pitch": -5.0},
	# Shibuya Crossing from the station side, over the scramble to
	# QFRONT and Center Gai.
	{"id": "tokyo", "label": "Tokyo", "name": "Tokyo, Japan",
		"lat": 35.6595, "lon": 139.7005, "eye_lat": 35.6590, "eye_lon": 139.7011,
		"eye_m": 15.0, "bearing": 320.0, "pitch": -8.0},
	# Brooklyn Bridge Park Pier 1 at the railing (8 m short of the pier's
	# edge, where the reference photos were taken; further in, the park
	# trees block the view), across the East River to the Financial
	# District (~291°) and One WTC (~310°); the extent covers Lower
	# Manhattan, not Brooklyn.
	{"id": "new_york", "label": "New York", "name": "New York, United States",
		"lat": 40.7060, "lon": -74.0040, "eye_lat": 40.70265, "eye_lon": -73.99686,
		"eye_m": 6.0, "bearing": 298.0, "pitch": 3.0},
	# Monteliusvägen clifftop: City Hall (335°), Riddarholmen (27°),
	# Gamla stan (46°) across Riddarfjärden.
	{"id": "stockholm", "label": "Stockholm", "name": "Stockholm, Sweden",
		"lat": 59.3207, "lon": 18.0604, "eye_m": 6.0, "bearing": 10.0, "pitch": -3.0},
	# Place du Palais on Le Rocher, over Port Hercule to Monte-Carlo and
	# the Casino (34°).
	{"id": "monaco", "label": "Monaco", "name": "Monaco",
		"lat": 43.7310, "lon": 7.4209, "eye_m": 4.0, "asl_m": 62.0, "bearing": 25.0, "pitch": -5.0},
	# Open ground east of Dubai Mall, 850 m due east of Burj Khalifa
	# (828 m: needs the distance and an upward look) with no tower on the
	# sight line (checked on the cached OSM); the extent spans both.
	{"id": "dubai", "label": "Dubai", "name": "Dubai, United Arab Emirates",
		"lat": 25.1925, "lon": 55.2741, "eye_lat": 25.19787, "eye_lon": 55.28278,
		"eye_m": 20.0, "bearing": 265.0, "pitch": 12.0},
	# Queen's Walk by Westminster Bridge, across the Thames to the Palace
	# of Westminster and Big Ben (~251°); the London Eye just behind.
	{"id": "london", "label": "London", "name": "London, United Kingdom",
		"lat": 51.5018, "lon": -0.1196, "eye_m": 8.0, "bearing": 258.0, "pitch": 3.0},
	# Largo Gaetana Agnesi on the Colle Oppio, down onto the Colosseum
	# (~160 m, 162°).
	{"id": "rome", "label": "Rome", "name": "Rome, Italy",
		"lat": 41.8916, "lon": 12.4916, "eye_m": 4.0, "bearing": 168.0, "pitch": 0.0},
	# Ponte dell'Accademia, down the Grand Canal to the Salute (~104°).
	# The palazzi on both banks frame the canal, so the look check is
	# off (it would lift the eye over Palazzo Barbaro, 60 m to the left).
	{"id": "venice", "label": "Venice", "name": "Venice, Italy",
		"lat": 45.4318, "lon": 12.3290, "eye_m": 8.0, "bearing": 104.0, "pitch": -2.0,
		"clear": false},
	# Gwanghwamun Square, north to the palace gate (~360 m) and Bugaksan.
	{"id": "seoul", "label": "Seoul", "name": "Seoul, South Korea",
		"lat": 37.5728, "lon": 126.9769, "eye_m": 10.0, "bearing": 4.0, "pitch": 2.0},
]

## The row whose origin lies within MATCH_M of (lat, lon), {} for none.
static func for_pin(lat: float, lon: float) -> Dictionary:
	for row in ROWS:
		var d := WorldScale.xz_from_latlon(float(row["lat"]), float(row["lon"]), lat, lon)
		if d.length() <= MATCH_M:
			return row
	return {}

## Origin of the row named `place_name`, or Vector2.INF when no preset
## carries that name (lat in x, lon in y).
static func origin_for_name(place_name: String) -> Vector2:
	for row in ROWS:
		if str(row["name"]) == place_name:
			return Vector2(float(row["lat"]), float(row["lon"]))
	return Vector2.INF

## Camera ground position of `view` in metres relative to the world
## origin (c_lat, c_lon).
static func eye_xz(view: Dictionary, c_lat: float, c_lon: float) -> Vector2:
	if not view.has("eye_lat"):
		return WorldScale.xz_from_latlon(float(view["lat"]), float(view["lon"]), c_lat, c_lon)
	return WorldScale.xz_from_latlon(float(view["eye_lat"]), float(view["eye_lon"]), c_lat, c_lon)

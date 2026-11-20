class_name TurkuNotable
extends RefCounted

## Well-known central Turku street-front buildings that stay OSM extrusions
## (not hand-built Tier 1 landmarks): their real facade finish, colour, roof
## and completion year, keyed by verified OSM identity from turku_detailed
## and turku_ring1600, so district randomisation cannot turn historic Empire,
## Jugendstil, modernist, Kupittaa or TYKS blocks into wrong-era materials.
## Values fill only what the map leaves out (BuildingReferences.fill) and run
## inside OsmParser before CityOpenData / HelsinkiLod2.

const PROVENANCE := "tku_notable"
const CITYGML_SRC := "https://turku.asiointi.fi/TeklaOGCWeb/WFS.ashx"

const ROWS := {
	# Läntinen Rantakatu
	"way:90775554": {"name": "Hôtel du Nord (Läntinen Rantakatu 1)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#dfca96", "start_year": 1830, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:34203891": {"name": "Qwenselin talo (Läntinen Rantakatu 13)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ebdcb0", "start_year": 1840, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#2f3338"}},
	"way:90775557": {"name": "Maaherran talo (Läntinen Rantakatu 1)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8c494", "start_year": 1733, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:777814619": {"name": "Majland (Läntinen Rantakatu 42)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b27c5c", "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:90775528": {"name": "Läntinen Rantakatu 7", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ebdcb0", "start_year": 1758, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#2f3338"}},
	"way:90775547": {"name": "Läntinen Rantakatu 21", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ccc6b8", "start_year": 1952, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:34203889": {"name": "Läntinen Rantakatu 15", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ebdcb0", "start_year": 1809, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#2f3338"}},
	"way:90775542": {"name": "Läntinen Rantakatu 3", "source": CITYGML_SRC, "values": {"material": "stone", "colour": "#a69c90", "start_year": 1898, "roof_shape": "mansard", "roof_material": "metal", "roof_colour": "#5a3c34"}},
	"way:674183209": {"name": "Läntinen Rantakatu 27", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#dfca96", "start_year": 1778, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	# Itäinen Rantakatu
	"way:88509262": {"name": "Rettigin palatsi (Itäinen Rantakatu 4)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8c6a4", "start_year": 1928, "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:583733866": {"name": "Samppalinna (Itäinen Rantakatu 10)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#dfca96", "start_year": 1865, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:49336044": {"name": "Itäinen Rantakatu 46", "source": CITYGML_SRC, "values": {"material": "glass", "colour": "#c0ccd4", "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:49336037": {"name": "Itäinen Rantakatu 40a", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1957, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:642149875": {"name": "Itäinen Rantakatu 15", "source": CITYGML_SRC, "values": {"material": "glass", "colour": "#c0ccd4", "start_year": 2020, "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:642149877": {"name": "Itäinen Rantakatu 19", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#eae6dc", "start_year": 1999, "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:642149880": {"name": "Itäinen Rantakatu 23", "source": CITYGML_SRC, "values": {"material": "glass", "colour": "#c0ccd4", "start_year": 2015, "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:642149872": {"name": "Itäinen Rantakatu 13", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#dcd8ce", "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:642149874": {"name": "Itäinen Rantakatu 11", "source": CITYGML_SRC, "values": {"material": "glass", "colour": "#c0ccd4", "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:642149881": {"name": "Itäinen Rantakatu 25", "source": CITYGML_SRC, "values": {"material": "glass", "colour": "#c0ccd4", "roof_material": "metal", "roof_colour": "#3f444a"}},
	# Aurakatu
	"way:315581388": {"name": "Kultatalo (Aurakatu 12a)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e2ded4", "start_year": 1959, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:90775544": {"name": "Verdandin talo (Aurakatu 1)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#8c4230", "start_year": 1898, "roof_material": "metal", "roof_colour": "#466e5e"}},
	"way:100310231": {"name": "Vimma (Aurakatu 16)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#c8b8a4", "start_year": 1902, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#383c42"}},
	"way:22495091": {"name": "Turun kaupungintalo (Aurakatu 2)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#dfca96", "start_year": 1811, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:315830460": {"name": "Åbo Svenska Församling (Aurakatu 18)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b27c5c", "start_year": 2005, "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:733557435": {"name": "Teräksenkulma (Aurakatu 12b)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1955, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:220497445": {"name": "Suomalainen Pohja (Aurakatu 24)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ccc6b8", "start_year": 1980, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:89811393": {"name": "Aurakatu 13", "source": CITYGML_SRC, "values": {"material": "stone", "colour": "#a69c90", "start_year": 1910, "roof_material": "metal", "roof_colour": "#5a3c34"}},
	"way:90081644": {"name": "Aurakatu 15", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d6be9c", "start_year": 1906, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#46423e"}},
	"way:733547251": {"name": "Aurakatu 10", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8c494", "start_year": 1865, "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:315581385": {"name": "Aurakatu 12b", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1955, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:315830459": {"name": "Aurakatu 22", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8c6a4", "start_year": 1920, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	# Linnankatu
	"way:88417164": {"name": "Radisson Blu Marina Palace (Linnankatu 32)", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1973, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:687986055": {"name": "Regina (Linnankatu 9b)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#9c503c", "start_year": 1927, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:109814378": {"name": "Turun Kivipaino (Linnankatu 31)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8c8a8", "start_year": 1910, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#383c42"}},
	"way:1137763732": {"name": "Phoenix (Linnankatu 24)", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#d2d0c8", "start_year": 2023, "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:28174284": {"name": "Linnankatu 8", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1962, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:109814429": {"name": "Linnankatu 36", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#9c503c", "start_year": 1930, "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:1083509497": {"name": "Linnankatu 5", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1957, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:109814349": {"name": "Linnankatu 39", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e6cf8c", "start_year": 1827, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#2f3338"}},
	"way:88417181": {"name": "Linnankatu 33", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#9c503c", "start_year": 1928, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:90088622": {"name": "Linnankatu 21", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1967, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:44173779": {"name": "Linnankatu 2", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#d2d0c8", "start_year": 2006, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:109814396": {"name": "Linnankatu 45", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1957, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#45494e"}},
	# Eerikinkatu
	"way:673942356": {"name": "Julininkulma (Eerikinkatu 4)", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#d2d0c8", "start_year": 1988, "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:315890062": {"name": "Ilmarinhovi (Eerikinkatu 9b)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8d4c8", "start_year": 1961, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:465777801": {"name": "Sokos Wiklund (Eerikinkatu 11)", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1974, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:315581686": {"name": "St. Erik (Eerikinkatu 17)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d6be9c", "start_year": 1912, "roof_material": "metal", "roof_colour": "#466e5e"}},
	"way:90088668": {"name": "Original Sokos Hotel Seurahuone (Eerikinkatu 23)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e8e2d4", "start_year": 1928, "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:1043097294": {"name": "Åbo Svenska Teater (Eerikinkatu 13)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ebdcb0", "start_year": 1837, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#2f3338"}},
	"way:24244537": {"name": "VPK:n talo (Eerikinkatu 24)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8c8a8", "start_year": 1892, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#383c42"}},
	"way:60956283": {"name": "Kelan toimitalo (Eerikinkatu 26)", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1971, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:48260669": {"name": "Nuortentalo (Eerikinkatu 1)", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1961, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:49029963": {"name": "Eerikinkatu 35", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#a65c44", "start_year": 1916, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#466e5e"}},
	"way:524925068": {"name": "Eerikinkatu 15", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b27c5c", "start_year": 1986, "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:673942357": {"name": "Eerikinkatu 2", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e2ded4", "start_year": 1963, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#45494e"}},
	# Yliopistonkatu
	"way:674080358": {"name": "Vaisteen talo (Yliopistonkatu 16)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#9c503c", "start_year": 1926, "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:673836967": {"name": "Aimo Park (Yliopistonkatu 29b)", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#d2d0c8", "start_year": 2000, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:28190211": {"name": "Betel-kirkko (Yliopistonkatu 29a)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8c8a8", "start_year": 1905, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#383c42"}},
	"way:672718790": {"name": "Aleksandra (Yliopistonkatu 19)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#dcd8ce", "start_year": 1988, "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:673942344": {"name": "Centro Hotel (Yliopistonkatu 12a)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1974, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:672852921": {"name": "Ihotalo (Yliopistonkatu 13b)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1970, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:733547250": {"name": "Yliopistonkatu 20", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#d2d0c8", "start_year": 1986, "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:48637943": {"name": "Yliopistonkatu 27a", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ebe7dc", "start_year": 1938, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#484440"}},
	"way:136526658": {"name": "Yliopistonkatu 11a", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e8e2d4", "start_year": 1928, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:100310223": {"name": "Yliopistonkatu 29b", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e2ded4", "start_year": 1975, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:673942341": {"name": "Yliopistonkatu 10", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#a86448", "start_year": 1928, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#484440"}},
	"way:110126418": {"name": "Yliopistonkatu 24", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ebe7dc", "start_year": 1928, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#484440"}},
	# Humalistonkatu
	"way:28174291": {"name": "Lounais-Suomen maalaistentalo (Humalistonkatu 7b)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#9c503c", "start_year": 1928, "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:110126447": {"name": "Postitalo (Humalistonkatu 1)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#a86448", "start_year": 1932, "roof_material": "metal", "roof_colour": "#484440"}},
	"way:672626251": {"name": "Pulssi (Humalistonkatu 11)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1983, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:673836988": {"name": "Humalistonkatu 1", "source": CITYGML_SRC, "values": {"material": "glass", "colour": "#c0ccd4", "start_year": 2012, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:9033969": {"name": "Humalistonkatu 16", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1957, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:673836953": {"name": "Humalistonkatu 7a", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1956, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:315935258": {"name": "Humalistonkatu 9", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1976, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:684738369": {"name": "Humalistonkatu 6", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#eae6dc", "start_year": 1988, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:115739732": {"name": "Humalistonkatu 6", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#d2d0c8", "start_year": 1988, "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:220497449": {"name": "Humalistonkatu 15a", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#cbb898", "start_year": 1910, "roof_material": "metal", "roof_colour": "#46423e"}},
	"way:90088624": {"name": "Humalistonkatu 4", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#d2d0c8", "start_year": 2004, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:89812737": {"name": "Humalistonkatu 13", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#9c503c", "start_year": 1928, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	# Puutarhakatu
	"way:87366306": {"name": "Puutarhakadun yksikkö (Puutarhakatu 5)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8c8a8", "start_year": 1891, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#383c42"}},
	"way:673836961": {"name": "Lutherin kirkko (Puutarhakatu 8a)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e2ded4", "start_year": 1966, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:93892224": {"name": "Puutarhakatu 15", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1968, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:89811392": {"name": "Puutarhakatu 6", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e6e0d0", "start_year": 1958, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:89813113": {"name": "Puutarhakatu 8a", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1966, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:93892213": {"name": "Puutarhakatu 17", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ccc6b8", "start_year": 1981, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:1136720002": {"name": "Puutarhakatu 19a", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8d4c8", "start_year": 1982, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:88331042": {"name": "Puutarhakatu 16", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#a86448", "start_year": 1928, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#484440"}},
	"way:88331031": {"name": "Puutarhakatu 18", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1963, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:90243723": {"name": "Puutarhakatu 11", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8d4c8", "start_year": 1956, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:90243754": {"name": "Puutarhakatu 11", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1956, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:88331029": {"name": "Puutarhakatu 20", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ccc6b8", "start_year": 1963, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#45494e"}},
	# Kaskenkatu
	"way:133734095": {"name": "Turun suomenkielinen työväenopisto (Kaskenkatu 5)", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1962, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:315781408": {"name": "Kaskenkatu 11", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#9c503c", "start_year": 1929, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:265618367": {"name": "Kaskenkatu 4a", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#964836", "start_year": 1903, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#466e5e"}},
	"way:133734079": {"name": "Kaskenkatu 1", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#8c4230", "start_year": 1901, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#466e5e"}},
	"way:315811066": {"name": "Kaskenkatu 12", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ccc6b8", "start_year": 1967, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:90177280": {"name": "Kaskenkatu 16", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ccc6b8", "start_year": 1961, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:24207483": {"name": "Kaskenkatu 8", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1963, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:24207469": {"name": "Kaskenkatu 10", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d4cec2", "start_year": 1998, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:674748175": {"name": "Kaskenkatu 9b", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8d4c8", "start_year": 1976, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:265618838": {"name": "Kaskenkatu 6a", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1972, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:220316705": {"name": "Kaskenkatu 6b", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1965, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:687523275": {"name": "Kaskenkatu 4b", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1960, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#45494e"}},
	# Hämeenkatu
	"way:242549324": {"name": "Kåren (Hämeenkatu 22)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ebe7dc", "start_year": 1936, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#484440"}},
	"way:103351241": {"name": "Suomen Talousseuran talo (Hämeenkatu 28)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#dfca96", "start_year": 1762, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:136524051": {"name": "Hämeenkatu 7", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8d4c8", "start_year": 1963, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:119752315": {"name": "Hämeenkatu 2", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8d4c8", "start_year": 1972, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:117219900": {"name": "Hämeenkatu 1", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1961, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:265658728": {"name": "Hämeenkatu 14", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ccc6b8", "start_year": 1962, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:103351253": {"name": "Hämeenkatu 20", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8d4c8", "start_year": 1963, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:209598239": {"name": "Hämeenkatu 10", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ebe7dc", "start_year": 1936, "roof_material": "metal", "roof_colour": "#484440"}},
	"way:119752312": {"name": "Hämeenkatu 4", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8d4c8", "start_year": 1970, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:1019201398": {"name": "Hämeenkatu 32", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#cbb898", "start_year": 1911, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#46423e"}},
	"way:238173437": {"name": "Hämeenkatu 6", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1977, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:22662514": {"name": "Hämeenkatu 16", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1961, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#45494e"}},
	# Kauppiaskatu
	"way:316795991": {"name": "Kauppiaskadun yksikkö (Kauppiaskatu 14)", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1955, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:1074264772": {"name": "Uusi Börs (Kauppiaskatu 6)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b27c5c", "start_year": 2021, "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:103351259": {"name": "Turun Sanomien toimitalo (Kauppiaskatu 5a)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#9c503c", "start_year": 1930, "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:28174286": {"name": "Trappin talo (Kauppiaskatu 2)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ebdcb0", "start_year": 1830, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#2f3338"}},
	"way:687986076": {"name": "Vanha Börs (Kauppiaskatu 6)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8c494", "start_year": 1832, "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:103351236": {"name": "Dublin (Kauppiaskatu 5b)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e6cf8c", "start_year": 1831, "roof_material": "metal", "roof_colour": "#2f3338"}},
	"way:1034457940": {"name": "Kauppiaskatu 10", "source": CITYGML_SRC, "values": {"material": "glass", "colour": "#c0ccd4", "start_year": 1994, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:778359937": {"name": "Kauppiaskatu 2", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1961, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	# Brahenkatu
	"way:90081643": {"name": "Turun synagoga (Brahenkatu 17a)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#a65c44", "start_year": 1912, "roof_material": "metal", "roof_colour": "#5a3c34"}},
	"way:117166314": {"name": "Brahenkatu 20", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e8e2d4", "start_year": 1929, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:673942343": {"name": "Brahenkatu 7", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1955, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:315580316": {"name": "Brahenkatu 18b", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e8e2d4", "start_year": 1928, "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:672852926": {"name": "Brahenkatu 10", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1960, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:903929081": {"name": "Brahenkatu 12a", "source": CITYGML_SRC, "values": {"material": "glass", "colour": "#c0ccd4", "start_year": 2021, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:136526651": {"name": "Brahenkatu 9b", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#dfd4bc", "start_year": 1924, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#484440"}},
	"way:672507955": {"name": "Brahenkatu 15", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#a86448", "start_year": 1925, "roof_material": "metal", "roof_colour": "#484440"}},
	# Kristiinankatu
	"way:90088627": {"name": "Centrum (Kristiinankatu 8)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1969, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:733547252": {"name": "Kristiinankatu 11", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1977, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:136388021": {"name": "Kristiinankatu 1", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8c8a8", "start_year": 1909, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#5a3c34"}},
	"way:28120166": {"name": "Kristiinankatu 4", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b27c5c", "start_year": 2002, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3f444a"}},
	"way:90775549": {"name": "Kristiinankatu 2a", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8d4c8", "start_year": 1962, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:90775537": {"name": "Kristiinankatu 2b", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#a65c44", "start_year": 1914, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#383c42"}},
	"way:110126441": {"name": "Kristiinankatu 10a", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1963, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:96557648": {"name": "Kristiinankatu 5", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#b8baa8", "start_year": 1884, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#383c42"}},
	# Kiinamyllynkatu
	"way:29050045": {"name": "U-sairaala (Kiinamyllynkatu 4)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e6e2d8", "start_year": 1968, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#454a50"}},
	"way:119752314": {"name": "Kiinamyllynkatu 5a", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e6e2d8", "start_year": 1963, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#454a50"}},
	"way:504105559": {"name": "Kiinamyllynkatu 5a", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#eae8e2", "start_year": 2016, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#4a4e54"}},
	"way:88691553": {"name": "Kiinamyllynkatu 2", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#dfd4bc", "start_year": 1923, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3d4248"}},
	"way:111143721": {"name": "Kiinamyllynkatu 2", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#dfd4bc", "start_year": 1923, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3d4248"}},
	"way:95168611": {"name": "Kiinamyllynkatu 4", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ece6d8", "start_year": 1876, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3d4248"}},
	# Kupittaankatu
	"way:685818259": {"name": "St1 (Kupittaankatu 20)", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#d4d2ca", "start_year": 1996, "roof_material": "metal", "roof_colour": "#42464c"}},
	"way:119893592": {"name": "Kupittaankatu 49", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#984c38", "start_year": 1958, "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:112505747": {"name": "Kupittaankatu 59", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#a05a42", "start_year": 1997, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#42464c"}},
	"way:112505773": {"name": "Kupittaankatu 57", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#d4d2ca", "start_year": 2002, "roof_material": "metal", "roof_colour": "#42464c"}},
	"way:119893589": {"name": "Kupittaankatu 47", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#a86248", "start_year": 1959, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:1028459498": {"name": "Kupittaankatu 45", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#a86248", "start_year": 1959, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:90177257": {"name": "Kupittaankatu 23", "source": CITYGML_SRC, "values": {"material": "glass", "colour": "#c2ced6", "start_year": 1980, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#42464c"}},
	"way:90177205": {"name": "Kupittaankatu 27", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#a05a42", "start_year": 1962, "roof_material": "metal", "roof_colour": "#42464c"}},
	# Piispankatu
	"way:108160240": {"name": "Axelia (Piispankatu 8)", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#b88a68", "start_year": 1977, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:88692048": {"name": "Theologicum (Piispankatu 16)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ebdcb0", "start_year": 1831, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#2f3338"}},
	"way:28173278": {"name": "Grädda (Piispankatu 15)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#dfca96", "start_year": 1833, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:108159523": {"name": "Domus (Piispankatu 10)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ccc6b8", "start_year": 1965, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:88692047": {"name": "Teologiska annexet (Piispankatu 16)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8c494", "start_year": 1833, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:112503681": {"name": "Piispankatu 3", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#cbb898", "start_year": 1895, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#46423e"}},
	"way:105478509": {"name": "Piispankatu 3", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ebdcb0", "start_year": 1856, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#2f3338"}},
	"way:87365433": {"name": "Piispankatu 12", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e2ded4", "start_year": 1960, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#45494e"}},
	# Tuomiokirkonkatu
	"way:136524062": {"name": "Tuomiokirkonkatu 8", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1956, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:136524060": {"name": "Tuomiokirkonkatu 8", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1956, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:28173762": {"name": "Tuomiokirkonkatu 2", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1957, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:136524046": {"name": "Tuomiokirkonkatu 2", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e8e2d4", "start_year": 1936, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	# Uudenmaankatu
	"way:22662511": {"name": "Juseliuksentalo (Uudenmaankatu 1)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8c8a8", "start_year": 1892, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#383c42"}},
	"way:146488159": {"name": "Forenom Kivilinna (Uudenmaankatu 13)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#cbb898", "start_year": 1910, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#466e5e"}},
	"way:782098324": {"name": "Uudenmaankatu 14", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1976, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:146487862": {"name": "Uudenmaankatu 10", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#ccc6b8", "start_year": 1959, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:108604785": {"name": "Uudenmaankatu 8", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8d4c8", "start_year": 1962, "roof_shape": "skillion", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:91215116": {"name": "Uudenmaankatu 11", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#a86448", "start_year": 1932, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#484440"}},
	"way:146488118": {"name": "Uudenmaankatu 13", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8d4c8", "start_year": 1952, "roof_shape": "gabled", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:90177244": {"name": "Uudenmaankatu 19", "source": CITYGML_SRC, "values": {"material": "glass", "colour": "#c0ccd4", "start_year": 1991, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#3f444a"}},
	# Aninkaistenkatu
	"way:48408370": {"name": "Kansallisarkisto (Aninkaistenkatu 11)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#d8c6a4", "start_year": 1931, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#3a3e44"}},
	"way:96558882": {"name": "Turun konserttitalo (Aninkaistenkatu 9)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e2ded4", "start_year": 1952, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:673942340": {"name": "Matintalo (Aninkaistenkatu 8a)", "source": CITYGML_SRC, "values": {"material": "render", "colour": "#e2ded4", "start_year": 1977, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:96558877": {"name": "Aninkaistenkatu 7", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1969, "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:90088666": {"name": "Aninkaistenkatu 14", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#a65c44", "start_year": 1907, "roof_material": "metal", "roof_colour": "#383c42"}},
	"way:44683937": {"name": "Aninkaistenkatu 3", "source": CITYGML_SRC, "values": {"material": "concrete", "colour": "#c6c4bc", "start_year": 1959, "roof_shape": "flat", "roof_material": "metal", "roof_colour": "#45494e"}},
	"way:48260666": {"name": "Aninkaistenkatu 5", "source": CITYGML_SRC, "values": {"material": "brick", "colour": "#9c503c", "start_year": 1928, "roof_shape": "hipped", "roof_material": "metal", "roof_colour": "#3a3e44"}},
}

static func apply(buildings: Array) -> int:
	var n := 0
	for b in buildings:
		if not (b is Dictionary):
			continue
		var row := row_for(b as Dictionary)
		if row.is_empty():
			continue
		if not BuildingReferences.fill(b as Dictionary, row["values"], PROVENANCE).is_empty():
			n += 1
	return n

## The row for one building ({} when it has none).
static func row_for(b: Dictionary) -> Dictionary:
	for id in OsmParser.ids_of(b):
		if ROWS.has(id):
			return ROWS[id]
	return {}

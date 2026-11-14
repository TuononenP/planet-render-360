class_name CityStyles
extends RefCounted

## City style zones, checked by ArchitectureStyle.region_for before the
## coarse country boxes: a viewpoint inside one gets that city's own
## region row (which inherits from its country via ArchitectureData.BASE),
## so London is not "generic UK brick" and Manhattan is not "US suburb".
## BuildingEra then refines each building to a sub-style (era / type) of
## its city from real cues (start_date, heritage, building:architecture,
## levels, roof:shape, footprint) and its distance from the city core.
## Data only plus a few pure helpers; documented in
## docs/architecture-styles.md.

## [city, region, lat, lon, radius_km]. First match wins, so a city may
## list several circles (Manhattan + inner Brooklyn + inner Queens).
## Radii are deliberately tight: the zone is the historic/dense core
## whose fabric the city rows describe; suburbs fall to the country row.
## Paris keeps its ArchitectureData box too (the inner suburbs inside it
## stay "haussmann"); the zone only makes the city/era cues available.
const ZONES := [
	["paris", "haussmann", 48.8566, 2.3522, 5.5],
	["london", "london", 51.5074, -0.1278, 12.0],
	["amsterdam", "amsterdam", 52.3676, 4.9041, 7.0],
	["berlin", "berlin", 52.5200, 13.4050, 12.0],
	["barcelona", "barcelona", 41.3874, 2.1686, 8.0],
	["rome", "rome", 41.9028, 12.4964, 9.0],
	["venice", "venice", 45.4375, 12.3358, 3.0],        # old city + Giudecca
	["stockholm", "stockholm", 59.3293, 18.0686, 6.0],
	["stockholm", "stockholm", 59.2760, 17.9060, 1.0], # Skärholmen
	["stockholm", "stockholm", 59.3920, 17.9170, 1.8], # Tensta / Rinkeby
	["new_york", "new_york", 40.7831, -73.9712, 11.0],  # Manhattan
	["new_york", "new_york", 40.6800, -73.9600, 7.0],   # inner Brooklyn
	["new_york", "new_york", 40.7500, -73.8950, 5.5],   # inner Queens
	["chicago", "chicago", 41.8781, -87.6298, 11.0],
	["san_francisco", "san_francisco", 37.7749, -122.4194, 8.0],
	["tokyo", "tokyo", 35.6812, 139.7671, 18.0],
	["hong_kong", "hong_kong", 22.3193, 114.1694, 14.0],
	["singapore", "singapore", 1.3521, 103.8198, 22.0],
	["seoul", "seoul", 37.5400, 126.9900, 16.0],
	["dubai", "dubai", 25.1900, 55.2700, 9.0],          # Downtown, SZR, Business Bay
	["dubai", "dubai", 25.2630, 55.3000, 6.0],          # Deira, Bur Dubai
	["dubai", "dubai", 25.0800, 55.1400, 5.0],          # Marina, JLT
	["monaco", "monaco", 43.7384, 7.4246, 2.2],
	["interlaken", "interlaken", 46.6863, 7.8632, 3.5],  # with Matten, Unterseen
	["banff", "banff", 51.1784, -115.5708, 3.0],
	["copenhagen", "copenhagen", 55.6761, 12.5683, 5.0],
	["oslo", "oslo", 59.9139, 10.7522, 5.0],
	["espoo", "espoo", 60.1755, 24.8310, 1.0],          # Keilaniemi, before Helsinki's rim
	["helsinki", "helsinki", 60.1900, 24.9950, 9.0],
	["espoo", "espoo", 60.1900, 24.7700, 9.0],
	["edinburgh", "edinburgh", 55.9533, -3.1883, 5.0],
	["dublin", "dublin", 53.3498, -6.2603, 5.0],
	["brussels", "brussels", 50.8503, 4.3517, 5.0],
	["st_petersburg", "st_petersburg", 59.9343, 30.3351, 7.0],
	["madrid", "madrid", 40.4168, -3.7038, 7.0],
	["lisbon", "lisbon", 38.7223, -9.1393, 5.0],
	["milan", "milan", 45.4642, 9.1900, 6.0],
	["florence", "florence", 43.7696, 11.2558, 3.5],
	["istanbul", "istanbul", 41.0200, 28.9800, 9.0],   # peninsula, Beyoğlu, Beşiktaş, Levent
	["athens", "athens", 37.9838, 23.7275, 6.0],
	["vienna", "vienna", 48.2082, 16.3738, 7.0],
	["prague", "prague", 50.0755, 14.4378, 7.0],
	["budapest", "budapest", 47.4979, 19.0402, 7.0],
	["munich", "munich", 48.1351, 11.5820, 6.0],
	["kyoto", "kyoto", 35.0116, 135.7681, 5.0],
	["shanghai", "shanghai", 31.2304, 121.4737, 14.0],
	["beijing", "beijing", 39.9042, 116.4074, 14.0],
	["bangkok", "bangkok", 13.7563, 100.5018, 12.0],
	["mumbai", "mumbai", 19.0000, 72.8300, 12.0],     # the island city to Bandra
	["cairo", "cairo", 30.0444, 31.2357, 10.0],
	["cape_town", "cape_town", -33.9249, 18.4241, 5.0],
	["toronto", "toronto", 43.6532, -79.3832, 8.0],
	["montreal", "montreal", 45.5017, -73.5673, 6.0],
	["boston", "boston", 42.3601, -71.0589, 6.0],
	["washington", "washington", 38.9072, -77.0369, 7.0],
	["los_angeles", "los_angeles", 34.0522, -118.2437, 18.0],
	["mexico_city", "mexico_city", 19.4326, -99.1332, 9.0],
	["rio", "rio", -22.9500, -43.2000, 10.0],         # Centro to Ipanema
	["buenos_aires", "buenos_aires", -34.6037, -58.3816, 9.0],
	["sydney", "sydney", -33.8688, 151.2093, 7.0],
	["melbourne", "melbourne", -37.8136, 144.9631, 6.0],
	["warsaw", "warsaw", 52.2297, 21.0122, 9.0],
	["moscow", "moscow", 55.7558, 37.6173, 15.0],
	["havana", "havana", 23.1136, -82.3666, 10.0],
	["delhi", "delhi", 28.6139, 77.2090, 14.0],
	["reykjavik", "reykjavik", 64.1466, -21.9426, 6.0],
]

## Cores the era rules measure distance from (historic centre or CBD,
## not the zone centre). Several cores = distance to the nearest
## (New York: Midtown and Downtown).
const CORES := {
	"paris": [[48.8566, 2.3522]],                          # Île de la Cité
	"london": [[51.5136, -0.0890]],                        # Bank (City of London)
	"amsterdam": [[52.3731, 4.8922]],                      # Dam
	"berlin": [[52.5170, 13.3889]],                        # Mitte
	"barcelona": [[41.3874, 2.1686]],                      # Plaça de Catalunya
	"rome": [[41.8986, 12.4769]],                          # Pantheon
	"venice": [[45.4343, 12.3388]],                        # Piazza San Marco
	"stockholm": [[59.3251, 18.0711]],                     # Gamla stan
	"new_york": [[40.7549, -73.9840], [40.7075, -74.0113]],  # Midtown, Downtown
	"chicago": [[41.8819, -87.6278]],                      # the Loop
	"san_francisco": [[37.7936, -122.3965]],               # Financial District
	"tokyo": [[35.6812, 139.7671], [35.6896, 139.6995]],   # Marunouchi, Shinjuku
	"hong_kong": [[22.2830, 114.1585], [22.2980, 114.1720]],  # Central, Tsim Sha Tsui
	"singapore": [[1.2840, 103.8510]],                     # Raffles Place
	"seoul": [[37.5700, 126.9830], [37.4979, 127.0276]],   # Jongno, Gangnam
	"dubai": [[25.1972, 55.2744], [25.2697, 55.3095], [25.0805, 55.1403]],  # Downtown, Deira, Marina
	"monaco": [[43.7396, 7.4277]],                         # Casino
	"interlaken": [[46.6863, 7.8560]],                     # Höheweg
	"banff": [[51.1770, -115.5710]],                       # Banff Avenue
	"copenhagen": [[55.6795, 12.5850]],                    # Kongens Nytorv
	"oslo": [[59.9133, 10.7389]],                          # Karl Johans gate
	"espoo": [[60.1760, 24.8050], [60.2190, 24.8130], [60.1590, 24.7380], [60.2050, 24.6550]],
	"helsinki": [[60.1694, 24.9522]],                      # Senate Square
	"edinburgh": [[55.9500, -3.1880]],                     # the Royal Mile
	"dublin": [[53.3473, -6.2591]],                        # O'Connell Bridge
	"brussels": [[50.8467, 4.3525]],                       # Grand-Place
	"st_petersburg": [[59.9390, 30.3158]],                 # Palace Square
	"madrid": [[40.4169, -3.7035]],                        # Puerta del Sol
	"lisbon": [[38.7075, -9.1364]],                        # Praça do Comércio
	"milan": [[45.4642, 9.1900]],                          # the Duomo
	"florence": [[43.7731, 11.2560]],                      # the Duomo
	"istanbul": [[41.0170, 28.9700], [41.0370, 28.9850]],  # Eminönü, Taksim
	"athens": [[37.9755, 23.7348]],                        # Syntagma
	"vienna": [[48.2085, 16.3731]],                        # Stephansplatz
	"prague": [[50.0875, 14.4213]],                        # Old Town Square
	"budapest": [[47.4977, 19.0548]],                      # Deák tér
	"munich": [[48.1374, 11.5755]],                        # Marienplatz
	"kyoto": [[35.0037, 135.7596]],                        # Shijō-Karasuma
	"shanghai": [[31.2304, 121.4737], [31.2397, 121.4998]],  # People's Square, Lujiazui
	"beijing": [[39.9055, 116.3976], [39.9100, 116.4580]],   # Tiananmen, CBD
	"bangkok": [[13.7460, 100.5340], [13.7520, 100.4940]],   # Siam, Rattanakosin
	"mumbai": [[18.9320, 72.8340], [19.0660, 72.8680]],    # Fort, BKC
	"cairo": [[30.0444, 31.2357]],                         # Tahrir
	"cape_town": [[-33.9249, 18.4241]],                    # the CBD
	"toronto": [[43.6480, -79.3810]],                      # Financial District
	"montreal": [[45.5017, -73.5673]],                     # Downtown
	"boston": [[42.3550, -71.0600]],                       # Downtown Crossing
	"washington": [[38.8977, -77.0365]],                   # the White House
	"los_angeles": [[34.0505, -118.2550]],                 # Downtown
	"mexico_city": [[19.4326, -99.1332]],                  # the Zócalo
	"rio": [[-22.9068, -43.1729]],                         # Centro
	"buenos_aires": [[-34.6083, -58.3712]],                # Plaza de Mayo
	"sydney": [[-33.8650, 151.2094]],                      # the CBD
	"melbourne": [[-37.8136, 144.9631]],                   # the CBD
	"warsaw": [[52.2478, 21.0148]],                        # Castle Square
	"moscow": [[55.7539, 37.6208]],                        # Red Square
	"havana": [[23.1370, -82.3510]],                       # Plaza Vieja
	"delhi": [[28.6328, 77.2197], [28.6562, 77.2300]],     # Connaught Place, Chandni Chowk
	"reykjavik": [[64.1470, -21.9400]],                    # Austurstræti
}

## Named districts with a dominant sub-style: [city, era, lat, lon,
## radius_km, weight multiplier]. Soft — they only scale the era's
## weight in BuildingEra's last-resort seeded pick, never override a
## real cue (a tagged 1970 tower in the Marais stays modern). San
## Francisco's structural rules also read the most local circle a
## building stands in (its fabric changes block by block).
const DISTRICTS := [
	["paris", "paris_faubourg", 48.8590, 2.3620, 0.9, 5.0],      # Le Marais
	["paris", "paris_faubourg", 48.8867, 2.3431, 0.6, 5.0],      # Montmartre
	["paris", "paris_modern", 48.8920, 2.2380, 0.9, 30.0],       # La Défense
	["paris", "paris_modern", 48.8270, 2.3650, 0.7, 8.0],        # Olympiades
	["paris", "paris_modern", 48.8480, 2.2830, 0.4, 8.0],        # Front de Seine
	["london", "london_stucco", 51.4975, -0.1560, 1.2, 8.0],     # Belgravia
	["london", "london_stucco", 51.4990, -0.1900, 1.5, 6.0],     # Kensington
	["london", "london_stucco", 51.5115, -0.2050, 0.9, 6.0],     # Notting Hill
	["london", "london_georgian", 51.5220, -0.1260, 1.1, 5.0],   # Bloomsbury
	["london", "london_modern", 51.5054, -0.0235, 1.0, 20.0],    # Canary Wharf
	["london", "london_modern", 51.5140, -0.0830, 0.8, 8.0],     # the City
	["amsterdam", "amsterdam", 52.3700, 4.8880, 1.4, 4.0],       # Grachtengordel
	["amsterdam", "amsterdam_school", 52.3530, 4.8960, 1.0, 6.0],  # De Pijp
	["amsterdam", "amsterdam_school", 52.3480, 4.9010, 0.9, 6.0],  # Rivierenbuurt
	["amsterdam", "amsterdam_school", 52.3890, 4.8800, 0.6, 6.0],  # Spaarndammerbuurt
	["amsterdam", "amsterdam_modern", 52.3380, 4.8730, 0.9, 20.0],  # Zuidas
	["berlin", "berlin_plattenbau", 52.5250, 13.4700, 2.2, 8.0],  # Lichtenberg
	["berlin", "berlin_plattenbau", 52.5200, 13.4150, 0.8, 5.0],  # Alexanderplatz
	["berlin", "berlin_plattenbau", 52.5450, 13.5650, 2.5, 20.0],  # Marzahn
	["berlin", "berlin_modern", 52.5096, 13.3760, 0.6, 20.0],    # Potsdamer Platz
	["barcelona", "barcelona_gothic", 41.3830, 2.1760, 0.9, 10.0],  # Ciutat Vella
	["barcelona", "barcelona_modern", 41.4040, 2.2050, 1.2, 10.0],  # 22@ / Diagonal Mar
	["rome", "rome_modern", 41.8320, 12.4680, 1.5, 10.0],        # EUR
	["new_york", "nyc_brownstone", 40.6760, -73.9780, 1.8, 8.0],  # Park Slope
	["new_york", "nyc_brownstone", 40.6960, -73.9950, 0.8, 8.0],  # Brooklyn Heights
	["new_york", "nyc_brownstone", 40.6840, -73.9420, 1.5, 8.0],  # Bed-Stuy
	["new_york", "nyc_brownstone", 40.8100, -73.9450, 1.4, 5.0],  # Harlem
	["new_york", "nyc_glass", 40.7549, -73.9840, 1.3, 6.0],      # Midtown
	["new_york", "nyc_prewar", 40.7075, -74.0095, 0.65, 6.0],   # Financial District
	["new_york", "nyc_castiron", 40.7223, -74.0000, 0.65, 8.0], # SoHo / Tribeca
	["new_york", "nyc_loft", 40.7030, -73.9907, 0.42, 8.0],     # DUMBO
	["new_york", "new_york", 40.7182, -73.9860, 0.85, 7.0],    # Lower East Side
	["new_york", "nyc_nycha", 40.7148, -73.9828, 0.35, 8.0],  # LES housing towers
	["chicago", "chicago_greystone", 41.9214, -87.6513, 2.0, 5.0],  # Lincoln Park
	["chicago", "chicago_tower", 41.8819, -87.6278, 1.3, 10.0],  # the Loop
	["san_francisco", "sf_victorian", 37.7700, -122.4350, 2.2, 6.0],  # Haight / Alamo Sq
	["san_francisco", "sf_victorian", 37.7600, -122.4150, 1.2, 4.0],  # Mission
	["san_francisco", "sf_victorian", 37.7920, -122.4330, 0.9, 4.0],  # Pacific Heights
	["san_francisco", "sf_victorian", 37.7560, -122.4320, 1.1, 5.0],  # Noe Valley, Castro
	["san_francisco", "san_francisco", 37.7990, -122.4180, 0.8, 4.0],  # Russian Hill
	["san_francisco", "san_francisco", 37.8000, -122.4090, 0.5, 4.0],  # North Beach
	["san_francisco", "sf_stucco", 37.8020, -122.4370, 0.7, 8.0],  # Marina
	["san_francisco", "sf_stucco", 37.7530, -122.4940, 2.2, 10.0],  # Sunset
	["san_francisco", "sf_stucco", 37.7790, -122.4870, 1.8, 6.0],  # Richmond
	["san_francisco", "sf_prewar", 37.7915, -122.4140, 0.5, 10.0],  # Nob Hill
	["san_francisco", "sf_prewar", 37.7885, -122.4065, 0.45, 6.0],  # Union Square
	["san_francisco", "sf_chinatown", 37.7945, -122.4065, 0.3, 20.0],  # Chinatown
	["san_francisco", "sf_tower", 37.7936, -122.3965, 1.0, 20.0],  # FiDi
	["san_francisco", "sf_tower", 37.7880, -122.3930, 0.7, 15.0],  # SoMa, Rincon Hill
	["san_francisco", "sf_tower", 37.7700, -122.3920, 0.8, 10.0],  # Mission Bay
	["tokyo", "tokyo_tower", 35.6896, 139.6995, 0.9, 20.0],      # Shinjuku
	["tokyo", "tokyo_tower", 35.6812, 139.7671, 0.8, 20.0],      # Marunouchi
	["tokyo", "tokyo_tower", 35.6605, 139.7292, 0.5, 10.0],      # Roppongi
	["tokyo", "tokyo_tower", 35.6585, 139.7030, 0.3, 10.0],      # Shibuya station east (Hikarie, Stream)
	["tokyo", "tokyo_zakkyo", 35.6608, 139.6985, 0.35, 15.0],    # Center Gai, Udagawacho
	["tokyo", "tokyo_zakkyo", 35.6575, 139.6965, 0.3, 12.0],     # Dogenzaka
	["tokyo", "tokyo_zakkyo", 35.6945, 139.7030, 0.4, 20.0],     # Kabukicho
	["tokyo", "tokyo_zakkyo", 35.6717, 139.7650, 0.5, 10.0],     # Ginza
	["tokyo", "tokyo_zakkyo", 35.6984, 139.7731, 0.4, 15.0],     # Akihabara
	["tokyo", "tokyo_zakkyo", 35.7300, 139.7135, 0.4, 10.0],     # Ikebukuro east
	["tokyo", "tokyo_mansion", 35.6467, 139.7101, 0.8, 8.0],     # Ebisu
	["tokyo", "tokyo_mansion", 35.6340, 139.7160, 0.8, 8.0],     # Meguro
	["tokyo", "tokyo_mansion", 35.6700, 139.7100, 0.6, 6.0],     # Jingumae, Aoyama
	["tokyo", "tokyo_mokuchin", 35.7076, 139.6638, 1.5, 6.0],    # Nakano
	["tokyo", "tokyo_house", 35.6460, 139.6530, 3.0, 8.0],       # Setagaya
	["tokyo", "tokyo_house_modern", 35.6460, 139.6530, 3.0, 8.0],
	["tokyo", "tokyo_house", 35.6995, 139.6366, 2.5, 8.0],       # Suginami
	["tokyo", "tokyo_house_modern", 35.6995, 139.6366, 2.5, 8.0],
	["hong_kong", "hk_tenement", 22.3300, 114.1620, 1.2, 6.0],   # Sham Shui Po
	["hong_kong", "hk_tenement", 22.3190, 114.1700, 0.8, 4.0],   # Mong Kok
	["hong_kong", "hk_office", 22.2830, 114.1585, 0.8, 20.0],    # Central
	["singapore", "sg_shophouse", 1.2830, 103.8440, 0.7, 20.0],  # Chinatown
	["singapore", "sg_shophouse", 1.3020, 103.8590, 0.5, 20.0],  # Kampong Glam
	["singapore", "sg_shophouse", 1.3066, 103.8518, 0.6, 20.0],  # Little India
	["singapore", "sg_shophouse", 1.3120, 103.9010, 0.8, 10.0],  # Joo Chiat
	["singapore", "sg_tower", 1.2840, 103.8510, 1.0, 20.0],      # CBD
	["seoul", "seoul_palace", 37.5783, 126.9770, 0.25, 40.0],    # Gyeongbokgung, Heungnyemun to Gyeonghoeru
	["seoul", "seoul_palace", 37.5815, 126.9770, 0.22, 40.0],    # Gyeongbokgung, north courts
	["seoul", "seoul_palace", 37.5794, 126.9910, 0.3, 40.0],     # Changdeokgung
	["seoul", "seoul_palace", 37.5788, 126.9950, 0.25, 40.0],    # Changgyeonggung
	["seoul", "seoul_palace", 37.5744, 126.9941, 0.2, 40.0],     # Jongmyo
	["seoul", "seoul_palace", 37.5658, 126.9751, 0.12, 40.0],    # Deoksugung
	["seoul", "seoul_hanok", 37.5826, 126.9837, 0.6, 40.0],      # Bukchon
	["seoul", "seoul_hanok", 37.5744, 126.9897, 0.2, 40.0],      # Ikseon-dong
	["seoul", "seoul_hanok", 37.5790, 126.9700, 0.5, 12.0],      # Seochon
	["seoul", "seoul_tower", 37.5250, 126.9250, 1.0, 20.0],      # Yeouido
	["seoul", "seoul_tower", 37.5030, 127.0400, 1.2, 15.0],      # Teheran-ro
	["seoul", "seoul_tower", 37.5680, 126.9800, 0.7, 8.0],       # Jongno CBD
	["seoul", "seoul_shopping", 37.5715, 126.9880, 0.45, 10.0],  # Jongno 2–3-ga, Insadong
	["seoul", "seoul_shopping", 37.5636, 126.9850, 0.4, 20.0],   # Myeongdong
	["seoul", "seoul_shopping", 37.5560, 126.9230, 0.6, 15.0],   # Hongdae
	["seoul", "seoul_shopping", 37.5598, 126.9425, 0.4, 10.0],   # Sinchon
	["seoul", "seoul_shopping", 37.4980, 127.0276, 0.4, 10.0],   # Gangnam station
	["seoul", "seoul_officetel", 37.4950, 127.0280, 0.9, 8.0],   # Gangnam, Seocho
	["seoul", "seoul_officetel", 37.5440, 126.9510, 0.5, 8.0],   # Gongdeok, Mapo
	["seoul", "seoul_danji", 37.5110, 127.0850, 1.2, 20.0],      # Jamsil
	["seoul", "seoul_danji", 37.5290, 127.0300, 0.7, 20.0],      # Apgujeong
	["seoul", "seoul_danji", 37.5050, 126.9950, 0.9, 20.0],      # Banpo
	["seoul", "seoul_danji", 37.5200, 126.9700, 0.6, 15.0],      # Ichon
	["seoul", "seoul_danji", 37.5300, 126.8750, 1.2, 20.0],      # Mokdong
	["seoul", "seoul_danji", 37.6550, 127.0650, 1.8, 20.0],      # Nowon, Sanggye
	["seoul", "seoul_villa", 37.5600, 126.9100, 1.0, 10.0],      # Mangwon, Yeonnam
	["seoul", "seoul_villa", 37.5400, 126.8450, 1.2, 10.0],      # Hwagok
	["dubai", "dubai_tower", 25.2100, 55.2750, 1.5, 20.0],       # Sheikh Zayed Road
	["dubai", "dubai_tower", 25.1950, 55.2780, 1.0, 20.0],       # Downtown
	["dubai", "dubai_tower", 25.1860, 55.2650, 1.0, 15.0],       # Business Bay
	["dubai", "dubai_tower", 25.0800, 55.1400, 1.5, 20.0],       # Marina
	["dubai", "dubai_heritage", 25.2635, 55.2995, 0.25, 40.0],   # Al Fahidi
	["dubai", "dubai_heritage", 25.2680, 55.2900, 0.3, 30.0],    # Al Shindagha
	["dubai", "dubai_villa", 25.2050, 55.2450, 2.0, 6.0],        # Jumeirah
	["monaco", "monaco_old", 43.7311, 7.4197, 0.35, 40.0],       # Le Rocher
	["monaco", "monaco_tower", 43.7280, 7.4150, 0.4, 10.0],      # Fontvieille
	["monaco", "monaco_tower", 43.7460, 7.4330, 0.4, 8.0],       # Larvotto
	["interlaken", "interlaken_hotel", 46.6860, 7.8560, 0.5, 12.0],  # Höheweg
	["banff", "banff_heritage", 51.1640, -115.5617, 0.4, 20.0],  # Banff Springs
	["stockholm", "stockholm_medieval", 59.3251, 18.0711, 0.43, 20.0], # Gamla stan
	["stockholm", "stockholm_medieval", 59.3250, 18.0640, 0.22, 20.0], # Riddarholmen
	["stockholm", "stockholm_wood", 59.3195, 18.0595, 0.20, 12.0], # Mariaberget
	["stockholm", "stockholm_wood", 59.3125, 18.0925, 0.25, 12.0], # Vita Bergen
	["stockholm", "stockholm_stone", 59.3360, 18.0900, 0.85, 10.0], # Östermalm / Strandvägen
	["stockholm", "stockholm_grace", 59.3435, 18.0370, 0.65, 10.0], # Vasastan
	["stockholm", "stockholm_funkis", 59.3305, 18.0045, 0.55, 10.0], # Fredhäll
	["stockholm", "stockholm_funkis", 59.3180, 18.0450, 0.48, 10.0], # Söder Mälarstrand
	["stockholm", "stockholm_miljon", 59.2760, 17.9060, 1.0, 15.0], # Skärholmen
	["stockholm", "stockholm_miljon", 59.3945, 17.9025, 0.9, 15.0], # Tensta
	["stockholm", "stockholm_miljon", 59.3890, 17.9290, 0.8, 15.0], # Rinkeby
	["stockholm", "stockholm_eco", 59.3030, 18.0950, 0.8, 15.0], # Hammarby Sjöstad
	["stockholm", "stockholm_eco", 59.3580, 18.1060, 0.7, 15.0], # Norra Djurgårdsstaden
	["copenhagen", "copenhagen_old", 55.6800, 12.5900, 0.35, 20.0],  # Nyhavn
	["copenhagen", "copenhagen_modern", 55.6300, 12.5800, 1.2, 20.0],  # Ørestad
	["oslo", "oslo_wood", 59.9200, 10.7470, 0.2, 30.0],          # Damstredet
	["oslo", "oslo_modern", 59.9070, 10.7590, 0.5, 20.0],        # Bjørvika
	["helsinki", "helsinki_empire", 60.1720, 24.9550, 0.5, 8.0],  # Kruununhaka
	["helsinki", "helsinki_classicism", 60.1800, 24.9200, 1.0, 5.0],  # Töölö
	["helsinki", "helsinki_midrise", 60.1870, 24.9770, 0.6, 20.0],  # Kalasatama
	["helsinki", "helsinki_midrise", 60.1830, 24.9870, 0.4, 8.0],  # Sompasaari
	["helsinki", "helsinki", 60.1673, 24.9640, 0.33, 8.0],  # Katajanokka, Jugend west
	["helsinki", "helsinki_midrise", 60.1668, 24.9750, 0.45, 8.0],  # Katajanokanranta, 1976–83
	["helsinki", "helsinki", 60.1580, 24.9400, 0.55, 8.0],  # Eira
	["helsinki", "helsinki", 60.1580, 24.9500, 0.5, 8.0],  # Ullanlinna
	["helsinki", "helsinki", 60.1850, 24.9500, 0.65, 8.0],  # Kallio
	["helsinki", "helsinki_classicism", 60.1853, 24.9548, 0.2, 8.0],  # Torkkelinmäki, 1920s
	["helsinki", "helsinki", 60.1620, 24.9350, 0.5, 8.0],  # Punavuori
	["helsinki", "helsinki_classicism", 60.1950, 24.9570, 0.7, 8.0],  # Vallila
	["helsinki", "helsinki_wood", 60.2140, 24.9470, 0.65, 8.0],  # Käpylä
	["helsinki", "helsinki_wood", 60.1950, 24.9510, 0.25, 8.0],  # Puu-Vallila
	["helsinki", "helsinki_suburb", 60.1950, 25.0350, 0.8, 8.0],  # Herttoniemi
	["helsinki", "helsinki_suburb", 60.2030, 25.0570, 0.7, 8.0],  # Roihuvuori
	["helsinki", "helsinki_suburb", 60.2060, 24.8720, 0.7, 8.0],  # Munkkivuori
	["helsinki", "helsinki_functional", 60.1975, 24.8765, 0.5, 8.0],  # Munkkiniemen puistotie, 1935–54
	["helsinki", "helsinki_villa", 60.1935, 24.8670, 0.4, 8.0],  # Vanha Munkkiniemi villas
	["helsinki", "helsinki_villa", 60.1865, 24.8580, 0.5, 8.0],  # Kuusisaari
	["helsinki", "helsinki_villa", 60.1818, 24.8505, 0.45, 8.0],  # Lehtisaari
	["helsinki", "helsinki_element", 60.2100, 25.0830, 0.8, 8.0],  # Itäkeskus
	["helsinki", "helsinki_element", 60.2370, 25.0830, 1.0, 8.0],  # Kontula
	["helsinki", "helsinki_element", 60.1800, 24.9620, 0.28, 8.0],  # Merihaka
	["helsinki", "helsinki_midrise", 60.1565, 24.9130, 0.75, 8.0],  # Jätkäsaari
	["helsinki", "helsinki_midrise", 60.1625, 24.9110, 0.5, 8.0],  # Ruoholahti, 1990s brick
	["helsinki", "helsinki_functional", 60.1600, 24.8750, 1.5, 8.0],  # Lauttasaari
	["helsinki", "helsinki_midrise", 60.1530, 24.8590, 0.55, 8.0],  # Vattuniemi
	["espoo", "tapiola", 60.1760, 24.8050, 1.0, 8.0],  # Tapiola
	["espoo", "otaniemi", 60.1850, 24.8280, 0.85, 8.0],  # Otaniemi
	["espoo", "espoo_modern", 60.2190, 24.8130, 1.2, 8.0],  # Leppävaara
	["espoo", "espoo_modern", 60.1590, 24.7380, 1.1, 8.0],  # Matinkylä
	["espoo", "espoo_modern", 60.1700, 24.7650, 0.6, 8.0],  # Niittykumpu metro centre
	["espoo", "espoo_modern", 60.1755, 24.8310, 0.75, 8.0],  # Keilaniemi
	["espoo", "kauniainen", 60.2100, 24.7280, 1.5, 8.0],  # Kauniainen
	["edinburgh", "edinburgh_old", 55.9500, -3.1880, 0.4, 20.0],  # Royal Mile
	["edinburgh", "edinburgh_georgian", 55.9550, -3.1990, 0.7, 12.0],  # New Town
	["dublin", "dublin_modern", 53.3470, -6.2380, 0.8, 15.0],    # Docklands
	["brussels", "brussels_old", 50.8467, 4.3525, 0.4, 15.0],    # Grand-Place
	["brussels", "brussels_modern", 50.8400, 4.3800, 0.8, 15.0],  # European Quarter
	["st_petersburg", "spb_imperial", 59.9390, 30.3158, 0.8, 8.0],  # Palace Square
	["madrid", "madrid_austrias", 40.4140, -3.7100, 0.6, 15.0],  # Madrid de los Austrias
	["madrid", "madrid_modern", 40.4500, -3.6930, 0.6, 15.0],    # AZCA
	["madrid", "madrid_modern", 40.4770, -3.6880, 0.6, 20.0],    # Cuatro Torres
	["lisbon", "lisbon_pombaline", 38.7110, -9.1370, 0.4, 30.0],  # Baixa
	["lisbon", "lisbon_alfama", 38.7115, -9.1300, 0.4, 30.0],    # Alfama
	["lisbon", "lisbon_modern", 38.7630, -9.0950, 1.0, 20.0],    # Parque das Nações
	["milan", "milan_modern", 45.4840, 9.1900, 0.6, 20.0],       # Porta Nuova
	["milan", "milan_modern", 45.4780, 9.1560, 0.5, 20.0],       # CityLife
	["istanbul", "istanbul_pera", 41.0330, 28.9770, 1.0, 10.0],  # Beyoğlu
	["istanbul", "istanbul_wood", 41.0300, 28.9490, 0.6, 15.0],  # Fener-Balat
	["istanbul", "istanbul_tower", 41.0800, 29.0110, 1.2, 20.0],  # Levent
	["athens", "athens_neoclassical", 37.9720, 23.7290, 0.4, 20.0],  # Plaka
	["vienna", "vienna_baroque", 48.2085, 16.3731, 0.8, 4.0],    # Innere Stadt
	["vienna", "vienna_modern", 48.2330, 16.4130, 0.6, 20.0],    # Donau City
	["prague", "prague_old", 50.0875, 14.4213, 0.6, 8.0],        # Staré Město
	["prague", "prague_old", 50.0880, 14.4040, 0.5, 8.0],        # Malá Strana
	["budapest", "budapest_castle", 47.5000, 19.0340, 0.5, 20.0],  # Castle District
	["munich", "munich_altstadt", 48.1374, 11.5755, 0.7, 4.0],   # Altstadt
	["kyoto", "kyoto_machiya", 35.0037, 135.7788, 0.5, 30.0],    # Gion
	["kyoto", "kyoto_machiya", 34.9980, 135.7810, 0.6, 20.0],    # Higashiyama
	["kyoto", "kyoto_machiya", 35.0300, 135.7450, 0.8, 8.0],     # Nishijin
	["shanghai", "shanghai_bund", 31.2400, 121.4900, 0.5, 30.0],  # the Bund
	["shanghai", "shanghai_tower", 31.2390, 121.5050, 1.5, 30.0],  # Lujiazui
	["shanghai", "shanghai_shikumen", 31.2200, 121.4700, 1.0, 8.0],  # Xintiandi, Tianzifang
	["beijing", "beijing_hutong", 39.9370, 116.4030, 1.0, 25.0],  # Nanluoguxiang
	["beijing", "beijing_hutong", 39.9400, 116.3850, 0.8, 20.0],  # Shichahai
	["beijing", "beijing_hutong", 39.8960, 116.3980, 0.6, 15.0],  # Qianmen
	["beijing", "beijing_tower", 39.9100, 116.4580, 1.2, 25.0],  # CBD
	["bangkok", "bangkok_tower", 13.7240, 100.5290, 1.2, 20.0],  # Silom, Sathorn
	["bangkok", "bangkok_tower", 13.7380, 100.5600, 1.5, 10.0],  # Sukhumvit
	["bangkok", "bangkok_shophouse", 13.7400, 100.5080, 1.0, 10.0],  # Chinatown
	["mumbai", "mumbai_gothic", 18.9320, 72.8340, 1.0, 20.0],    # Fort
	["mumbai", "mumbai_deco", 18.9400, 72.8240, 0.8, 20.0],      # Marine Drive, the Oval
	["mumbai", "mumbai_tower", 19.0000, 72.8300, 1.2, 15.0],     # Lower Parel
	["cairo", "cairo_khedival", 30.0480, 31.2420, 1.0, 20.0],    # Downtown
	["cairo", "cairo_islamic", 30.0500, 31.2620, 0.6, 25.0],     # al-Muizz
	["cape_town", "cape_town_bokaap", -33.9210, 18.4150, 0.4, 40.0],  # Bo-Kaap
	["cape_town", "cape_town_modern", -33.9180, 18.4250, 0.8, 10.0],  # CBD, Foreshore
	["toronto", "toronto_tower", 43.6480, -79.3810, 1.2, 20.0],  # Financial District
	["montreal", "montreal_old", 45.5050, -73.5550, 0.6, 15.0],  # Vieux-Montréal
	["montreal", "montreal_tower", 45.5017, -73.5673, 0.8, 10.0],  # Downtown
	["boston", "boston_backbay", 42.3503, -71.0810, 0.8, 15.0],  # Back Bay
	["boston", "boston_backbay", 42.3588, -71.0707, 0.5, 15.0],  # Beacon Hill
	["boston", "boston_tower", 42.3550, -71.0550, 0.6, 15.0],    # Financial District
	["washington", "washington_federal", 38.8940, -77.0300, 1.2, 15.0],  # Federal Triangle, the Mall
	["los_angeles", "la_tower", 34.0505, -118.2550, 1.2, 20.0],  # Downtown
	["los_angeles", "la_spanish", 34.1100, -118.2900, 2.0, 4.0],  # Los Feliz, Silver Lake
	["mexico_city", "cdmx_colonial", 19.4326, -99.1332, 1.0, 15.0],  # Centro Histórico
	["mexico_city", "cdmx_modern", 19.4270, -99.1680, 1.0, 10.0],  # Reforma
	["rio", "rio_colonial", -22.9068, -43.1729, 1.0, 10.0],      # Centro
	["buenos_aires", "ba_tower", -34.6110, -58.3630, 0.8, 20.0],  # Puerto Madero
	["buenos_aires", "ba_chorizo", -34.6210, -58.3730, 0.7, 8.0],  # San Telmo
	["sydney", "sydney_tower", -33.8650, 151.2094, 1.0, 20.0],   # the CBD
	["sydney", "sydney_terrace", -33.8850, 151.2280, 1.0, 15.0],  # Paddington
	["sydney", "sydney_terrace", -33.8860, 151.2110, 0.7, 10.0],  # Surry Hills
	["melbourne", "melbourne_tower", -37.8136, 144.9631, 1.0, 20.0],  # the CBD
	["melbourne", "melbourne_terrace", -37.7990, 144.9780, 1.0, 15.0],  # Fitzroy, Carlton
	["warsaw", "warsaw_oldtown", 52.2497, 21.0122, 0.6, 8.0],        # Old Town Market Square
	["warsaw", "warsaw_socialist", 52.2190, 21.0190, 0.9, 8.0],      # MDM, Marszałkowska
	["warsaw", "warsaw_modern", 52.2330, 20.9850, 1.3, 10.0],        # Wola business district
	["moscow", "moscow_city", 55.7490, 37.5390, 1.0, 20.0],          # Moscow-City
	["moscow", "moscow_stalinka", 55.7600, 37.6000, 1.5, 6.0],       # Garden Ring
	["havana", "havana_colonial", 23.1370, -82.3500, 0.9, 12.0],     # Habana Vieja
	["havana", "havana_soviet", 23.1650, -82.2800, 1.5, 15.0],       # Alamar
	["delhi", "delhi_lutyens", 28.6143, 77.2000, 3.0, 20.0],         # Lutyens' Delhi
	["delhi", "delhi_old", 28.6562, 77.2300, 1.5, 20.0],             # Shahjahanabad
	["reykjavik", "reykjavik_iron", 64.1450, -21.9350, 1.0, 12.0],   # the old town
]

## The zone row containing (lat, lon), or [] outside every city.
static func zone_at(lat: float, lon: float) -> Array:
	for z in ZONES:
		var row: Array = z
		if _km(lat, lon, float(row[2]), float(row[3])) <= float(row[4]):
			return row
	return []

## City region for a viewpoint ("" outside every zone).
static func region_at(lat: float, lon: float) -> String:
	var z := zone_at(lat, lon)
	return "" if z.is_empty() else str(z[1])

## City key owning a region row ("haussmann" -> "paris"), "" if none.
static func city_of_region(region: String) -> String:
	for z in ZONES:
		if str((z as Array)[1]) == region:
			return str((z as Array)[0])
	return ""

## Per-build city frame for BuildingEra, in the local metre frame of a
## viewpoint (x east, z south, origin at the viewpoint — the frame the
## building dicts' x/z use): {"city", "cores": Array[Vector2],
## "districts": [[era, Vector2 centre, radius_m, mult], ...]}, or {}
## when the region is not a city's.
static func local_frame(region: String, lat: float, lon: float) -> Dictionary:
	var city := city_of_region(region)
	if city == "":
		return {}
	var cores: Array = []
	for c in (CORES.get(city, []) as Array):
		cores.append(WorldScale.xz_from_latlon(float(c[0]), float(c[1]), lat, lon))
	var districts: Array = []
	for d in DISTRICTS:
		var row: Array = d
		if str(row[0]) != city:
			continue
		var at := WorldScale.xz_from_latlon(float(row[2]), float(row[3]), lat, lon)
		# Only districts that can reach the detailed extent matter.
		if at.length() - float(row[4]) * 1000.0 > WorldScale.DETAILED_EXTENT_M * 2.0:
			continue
		districts.append([str(row[1]), at, float(row[4]) * 1000.0, float(row[5])])
	return {"city": city, "cores": cores, "districts": districts}

## Great-circle-ish distance in km (equirectangular; fine at city scale).
static func _km(lat_a: float, lon_a: float, lat_b: float, lon_b: float) -> float:
	var x := (lon_a - lon_b) * cos(deg_to_rad((lat_a + lat_b) * 0.5)) * 111.32
	var y := (lat_a - lat_b) * 110.54
	return sqrt(x * x + y * y)

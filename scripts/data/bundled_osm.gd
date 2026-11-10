class_name BundledOsm
extends RefCounted

## Immutable Overpass snapshots for exact preset origins. Each entry is
## [latitude, longitude, layer, query version, OSM timestamp, inflated bytes, SHA-256].
## Missing layers deliberately use the ordinary network/cache fallback.
const ENTRIES := {
	"berlin_detailed": [52.52437, 13.41053, "detailed", 12, "2026-11-02T21:21:26", 13533591, "3f0a06470629b5001a2113139bd48603ef2154e228edcc780838e129f5c9691e"],
	"berlin_ring1600": [52.52437, 13.41053, "ring1600", 1, "2026-11-02T21:21:26", 1120001, "8000d466f17a85d1cc42910eea335eea0ea50d51bef0d780131aba55f9c41403"],
	"berlin_ring2500": [52.52437, 13.41053, "ring2500", 1, "2026-11-02T21:21:26", 1153547, "624e92d7c212d04ff634288907a233bfb4639986e447bb5bac5285f8d96afb49"],
	"berlin_poi": [52.52437, 13.41053, "poi", 1, "2026-11-02T21:21:26", 1039539, "24899f6cc0d0864a1b762401fc2f19a198564f0935b8793f1cdf5179f38c9964"],
	"berlin_far": [52.52437, 13.41053, "far", 3, "2026-11-02T21:21:26", 28269591, "3a312f39b6d764d9500d8bd3a6c6a88cb938154706f47728782e4f4a6334318d"],
	"tokyo_far": [35.6595, 139.7005, "far", 3, "2026-11-03T21:24:23", 11510215, "d8dccef7a1f99659f416d67fe1ef6d72c84c243bdbcfdb78c37e5f80736c769a"],
	"tokyo_detailed": [35.6595, 139.7005, "detailed_extract", 12, "2026-11-03T21:24:23", 5074058, "9fda3f1dbbdc8210f99cfc88be149cc1a59216f0f3abe7fea6bf7ce68215971a"],
	"tokyo_ring1600": [35.6595, 139.7005, "ring1600", 1, "2026-11-03T21:24:23", 348939, "63505648aeb8f2a7d15c4c290cc9544af4f83e8f840e1181534c0f46e80c4a03"],
	"tokyo_ring2500": [35.6595, 139.7005, "ring2500", 1, "2026-11-03T21:24:23", 602576, "fabbe5fc00b9fb98ca202f48dd628b574c23fb6a6442ebd50a1f8043150c4a36"],
	"tokyo_poi": [35.6595, 139.7005, "poi", 1, "2026-11-03T21:24:23", 752591, "7b706a50c11f55ca4cb93c032380b81f5ff8de4eab2f5c7c04c568a4b09439b6"],
	"london_detailed": [51.5018, -0.1196, "detailed", 12, "2026-11-02T21:21:26", 14993747, "fbcb23019c17d6d96914db44428ccdb80bd9866800e8eb071e71ce7d7fd15f89"],
	"london_ring1600": [51.5018, -0.1196, "ring1600", 1, "2026-11-02T21:21:26", 774838, "665dfd7c004c9ac39b244e739d1450c870adc86c9e574434961420186b5126e8"],
	"london_ring2500": [51.5018, -0.1196, "ring2500", 1, "2026-11-02T21:21:26", 819172, "6c6f1e92a52d88489118fec735d75ff4174465dc6fb55c5319963aa630480c8d"],
	"london_poi": [51.5018, -0.1196, "poi", 1, "2026-11-02T21:21:26", 363400, "52d1c7339855ef2247d4378e3adcc64b6a91aab2abcf44b91cfc1c97627c30d2"],
	"london_far": [51.5018, -0.1196, "far", 3, "2026-10-31T00:00:00", 18047901, "ce66485b804e5a98fc538f21f0317bfbdb24729b5726c6c8493975b4d5f473ea"],
	"dubai_detailed": [25.1925, 55.2741, "detailed_extract", 12, "2026-11-03T21:24:23", 1936910, "47dd8ffd3bc0852c52391bb02045f77e0829d3a5627f2b1370f8e95d0202de6d"],
	"dubai_ring1600": [25.1925, 55.2741, "ring1600", 1, "2026-11-03T21:24:23", 441304, "beafd1d38965a750d11fc8f13e070d145913fcd225b9607663a52a1fd4a9d573"],
	"dubai_ring2500": [25.1925, 55.2741, "ring2500", 1, "2026-11-03T21:24:23", 575869, "dfd63379e17e7a73fa514f98951d2729e2b2c0207c81160ab377be35e90085e2"],
	"dubai_poi": [25.1925, 55.2741, "poi", 1, "2026-11-03T21:24:23", 102741, "555e250ccf2ed4c079d60fff758af48bcaf0c62f31f8aae3ba1e68442e3fc42a"],
	"dubai_far": [25.1925, 55.2741, "far", 3, "2026-11-03T21:24:23", 3172689, "cfb9058bf55c4e832e5816a64c2d4842402db787ad31eb9c60227f5bd939ed14"],
	"banff_detailed": [51.1720, -115.5640, "detailed_extract", 12, "2026-11-02T21:21:26", 1885275, "db8474155a8e83a8f81fd0147b3f6cb96049c9fdd42f913062ac645a2794853c"],
	"banff_ring1600": [51.1720, -115.5640, "ring1600", 1, "2026-11-02T21:21:26", 116200, "312f5b9a2b3e1b1acba8f4c58d97787461c84a5673ea02720ae5e784cf99d4de"],
	"banff_ring2500": [51.1720, -115.5640, "ring2500", 1, "2026-11-02T21:21:26", 170191, "5b71d3f7e58bd9d5892f4e7fe6cd3e442770abd48c2c98b242cddf5b9bf954c1"],
	"banff_poi": [51.1720, -115.5640, "poi", 1, "2026-11-02T21:21:26", 74267, "749c4c1dd60a4af7824f0729fbd0e8664baf664a23c0bfbc56caaf2164e50027"],
	"banff_far": [51.1720, -115.5640, "far", 3, "2026-11-02T21:21:26", 79382, "372bc36eb586296bbbd2443079c3cbf621190ec2bf5e03cc74f65468256dbbc9"],
	"big_sur_detailed": [36.3740, -121.9022, "detailed_extract", 12, "2026-11-03T00:45:53", 269124, "c4191c3049e74e170375dec22cf7e950681519f94fbd8dd548495e78e96ce226"],
	"big_sur_ring1600": [36.3740, -121.9022, "ring1600", 1, "2026-11-03T00:45:53", 51634, "de7870899c8c3b4a179379df7bb2b07b0697541dac9ed3eaf43961372f39b33a"],
	"big_sur_ring2500": [36.3740, -121.9022, "ring2500", 1, "2026-11-03T00:45:53", 68686, "806b3a13bfa0bbd381885b4ab69326763fe091e1071810eff6de81cdaf7d5296"],
	"big_sur_poi": [36.3740, -121.9022, "poi", 1, "2026-11-03T00:45:53", 1512, "509f627b095d9a0acb90eacfd9137e2a2960f04832d812dbb59611e0e30ec13d"],
	"big_sur_far": [36.3740, -121.9022, "far", 3, "2026-11-03T00:45:53", 10353, "a7897620dd7ad0e1aaa4678bdb8f7f3de50b369372ed8ca40a406797a0ccec27"],
	"seoul_detailed": [37.5728, 126.9769, "detailed_extract", 12, "2026-10-31T00:00:00", 4808914, "9c06ea1601e292042ec53158186edd27c6e355586aace2540df998abdd7feff8"],
	"seoul_ring1600": [37.5728, 126.9769, "ring1600", 1, "2026-10-31T00:00:00", 227498, "dee9b2703f69f5cf2556326a4158fd36728975d26603a75ef77608e4cae65c25"],
	"seoul_ring2500": [37.5728, 126.9769, "ring2500", 1, "2026-10-31T00:00:00", 436692, "3cde3c99675ba1a84eb4af397af10a5d09f5387800ab184066cee811f67967be"],
	"seoul_poi": [37.5728, 126.9769, "poi", 1, "2026-10-31T00:00:00", 451934, "8a271233ab5710075d1c46a144098748ee8bb56444c1ccb46d99488d420fb20e"],
	"seoul_far": [37.5728, 126.9769, "far", 3, "2026-10-31T00:00:00", 11629013, "c546588c1b1ddcf479ad6e19903bd7faf7db50dcc96417868fa3cdef5d8a06de"],
	"alps_detailed": [46.6900, 7.8580, "detailed", 12, "2026-11-02T21:21:26", 5325085, "f5b1947b982775759f232002696cccc38295394eea4ddf43f5e7c121215dee91"],
	"alps_ring1600": [46.6900, 7.8580, "ring1600", 1, "2026-11-02T21:21:26", 147804, "dd76d0d395ff1b23a83fb49eea5fd5e7de1290a4cb48c82f49f40bea3edef8b8"],
	"alps_ring2500": [46.6900, 7.8580, "ring2500", 1, "2026-11-02T21:21:26", 359107, "2204a3ad46f45489f81564abb6a213c29d74b93de8572e614ac5de2d6f6abec7"],
	"alps_poi": [46.6900, 7.8580, "poi", 1, "2026-11-02T21:21:26", 121242, "c369a95e32870f4bee16f4364fac00b7f006e691ace919a265905c69fa0a9c17"],
	"alps_far": [46.6900, 7.8580, "far", 3, "2026-11-02T21:21:26", 839192, "6aaec834d737b937cc44ae616fd92fa6310a1a73b8415304677cb9aaf7185ace"],
	"rome_detailed": [41.8916, 12.4916, "detailed", 12, "2026-11-02T21:21:26", 13599823, "623485a1103a4a3dff1c8b8de73e62a8153f2ab6d819b2ea25c07fce23867b63"],
	"rome_ring1600": [41.8916, 12.4916, "ring1600", 1, "2026-11-02T21:21:26", 699976, "a5dad8200190e8478ce563d75798441e5c18325b60cd7064ec9466addf24f5e1"],
	"rome_ring2500": [41.8916, 12.4916, "ring2500", 1, "2026-11-02T21:21:26", 814867, "b4ad2aea51ee0a25cc2fe39d8d8bce676ea56ac486230fdcb482c35827b8fdcc"],
	"rome_poi": [41.8916, 12.4916, "poi", 1, "2026-11-02T21:21:26", 295890, "420d836609c15c0f5dc45ab2baffe82ad9302631352f4f1415baf9d241e1dfca"],
	"rome_far": [41.8916, 12.4916, "far", 3, "2026-11-02T21:21:26", 12009509, "5a09b4eac178ba2a5fcb327279f6bd55ca044690fc67744bb7129d91579177f3"],
	"venice_detailed": [45.4318, 12.3290, "detailed", 12, "2026-11-02T21:21:26", 17199702, "e9a72fed9febdeeaa99c6f283d4be017ad13fac6277d2a9d09467eb96328a752"],
	"venice_ring1600": [45.4318, 12.3290, "ring1600", 1, "2026-11-02T21:21:26", 164699, "a14de708226d2b96bee68a4d9af482b66d555aa9ef7983bb675e05ff040ab8a0"],
	"venice_ring2500": [45.4318, 12.3290, "ring2500", 1, "2026-11-02T21:21:26", 179158, "3e3cd1d0927eeaa74686023ab7b8aebdee9caac8e74ca59d79d3eea41c1d66ba"],
	"venice_poi": [45.4318, 12.3290, "poi", 1, "2026-11-02T21:21:26", 387209, "c958ab4baa69afab8fcb3825972706b9048c4ee6e7e799f04f71589c588f06a4"],
	"venice_far": [45.4318, 12.3290, "far", 3, "2026-11-02T21:21:26", 3542326, "9919c1fe0bec551a2ec0195d1f6112c4f4c2edfdb81dc64741f2e43ea04fce3c"],
	"paris_detailed": [48.8622, 2.2887, "detailed", 12, "2026-11-04T15:35:21", 15300207, "b9c04cc24210b5f0d69811c5680eb3d4e716520536dde73d2b18c50b87df166a"],
	"paris_ring1600": [48.8622, 2.2887, "ring1600", 1, "2026-11-02T21:21:26", 685203, "8657941859a356789f5e7cbf37bec9dfb35a11533f6c8aa10ddda05025171901"],
	"paris_ring2500": [48.8622, 2.2887, "ring2500", 1, "2026-11-02T21:21:26", 1016449, "1c1de19f6cecad09ef7cafd01b04d92a574833ddcec8e9a8b9e672d998aa15db"],
	"paris_poi": [48.8622, 2.2887, "poi", 1, "2026-11-02T21:21:26", 474367, "a84539e0eeae6bcc9a6dce08960e5433ea7af0f06183c3c54099585f42a77db3"],
	"paris_far": [48.8622, 2.2887, "far", 3, "2026-11-04T16:59:38", 22812297, "43a6ceaba79c8f00fa4a067247a7874f5eed21b6d58629cce2c1ec216cf8b577"],
	"monaco_detailed": [43.7310, 7.4209, "detailed", 12, "2026-11-04T13:15:14", 5275707, "d02caed83d5f4310855a25e764ca20648e0dece79c860f582c92a4adad5e046b"],
	"monaco_ring1600": [43.7310, 7.4209, "ring1600", 1, "2026-11-02T21:21:26", 466090, "111f1095355d6e15937a9a8b3685850246524fd64afdedc40235edec1ca38705"],
	"monaco_ring2500": [43.7310, 7.4209, "ring2500", 1, "2026-11-04T13:14:21", 706988, "91643b2b1566052b6bbf4819ebd0b5e84126b3d0cc7614ded925f2c443d4bffe"],
	"monaco_poi": [43.7310, 7.4209, "poi", 1, "2026-11-02T21:21:26", 239987, "b3068a8335d58161f03dfae554a586da8242c4d76097be4d5837f15de2163b7f"],
	"monaco_far": [43.7310, 7.4209, "far", 3, "2026-11-02T21:21:26", 1877168, "b85208bd3abda1ede1fa50c96b81e5df9662c65388f29d844f217d2f2ebf1e33"],
	"espoo_detailed": [60.1760, 24.8050, "detailed", 12, "2026-11-02T21:21:26", 6958463, "fc0fd842d1536429595a37823667f60d85d71759fc0326ad88806c5e4ba18107"],
	"espoo_ring1600": [60.1760, 24.8050, "ring1600", 1, "2026-11-02T21:21:26", 648258, "e787924a0a8bfc35dedbcc61f6ae06b84fb5481e430da680cb5d7f86b0e77627"],
	"espoo_ring2500": [60.1760, 24.8050, "ring2500", 1, "2026-11-02T21:21:26", 1053409, "2d6f817e5b44611611ee6c5354cacf7e794344f66ca6813d73ffc537b5180e96"],
	"espoo_poi": [60.1760, 24.8050, "poi", 1, "2026-11-02T21:21:26", 196569, "b180bfa46bb8bb2f8220d22f3c25c0203f6f4444a64954126bb3767600f3a595"],
	"espoo_far": [60.1760, 24.8050, "far", 3, "2026-11-02T21:21:26", 18865438, "5b6845e2ff905522c8b79455e7e1e83cebdfcf13a775567529488f75e31970f6"],
	"san_francisco_far": [37.8040, -122.4195, "far", 3, "2026-11-02T21:21:26", 3389888, "76bd4a396b4f0ee9570354e7c8c94ca185bc750655e65af98f9b8a51bc45f66c"],
	"new_york_far": [40.7060, -74.0040, "far", 3, "2026-10-31T00:00:00", 20182951, "34411c39c87edab6b073f175b5bb959ee17d207758993ba2080aa7ac3e52142a"],
	"new_york_ring1600": [40.7060, -74.0040, "ring1600", 1, "2026-10-31T00:00:00", 527912, "b88cbaaf630dd9a68176988de26a301f67f1683c69a9feadfd3c82c83b47fa50"],
	"new_york_ring2500": [40.7060, -74.0040, "ring2500", 1, "2026-10-31T00:00:00", 630149, "fc2740b00ad16629d0f04b69d552ea042875f94866671a5ec180f23f76dac3a2"],
	"new_york_poi": [40.7060, -74.0040, "poi", 1, "2026-10-31T00:00:00", 452828, "f10d05bb8cce6f9b47485be68802ce883710c12b47e96fc3610aff15de0d4963"],
	"san_francisco_ring1600": [37.8040, -122.4195, "ring1600", 1, "2026-10-31T00:00:00", 290353, "3450e4b284d7a4b201c8d4f796cb8bf523bd1e7f2e02604e579672d35e3b2c92"],
	"san_francisco_ring2500": [37.8040, -122.4195, "ring2500", 1, "2026-10-31T00:00:00", 520242, "8e72644d2c2feafd058d1840c914bcb50e4a757b06c2729dccf26075d7bf171f"],
	"san_francisco_poi": [37.8040, -122.4195, "poi", 1, "2026-10-31T00:00:00", 142554, "6029a520ba637a8a6e7fbf81d119a086e56d7594fa040434fc74c2f3157281c3"],
	"helsinki_detailed": [60.1680, 24.9530, "detailed", 12, "2026-11-02T21:21:26", 14473370, "7fa53acf219303c800828119507e2fb6b2a0e5f65112cc3eb4e39aad8ad9101f"],
	"helsinki_ring1600": [60.1680, 24.9530, "ring1600", 1, "2026-11-02T21:21:26", 1047377, "015deaba1adf3f6b9bc568f8f99ffc00d2265b11a1557bd2769bd034ce3e5190"],
	"helsinki_ring2500": [60.1680, 24.9530, "ring2500", 1, "2026-11-02T21:21:26", 1351289, "948ccfa8b96d664562e9dba0d196f44a7ea092ae6bdbe8b37229618920b643ff"],
	"helsinki_poi": [60.1680, 24.9530, "poi", 1, "2026-11-02T21:21:26", 841295, "03c3ba96cf189dea3a06e7fcd753bb29f6725a5d4049dc1213eff98409d3436f"],
	"stockholm_detailed": [59.3207, 18.0604, "detailed", 12, "2026-11-02T21:21:26", 12094326, "825145148ea4a0051c7cb4395c1d11591d9bd447f365d44128ca33384c823664"],
	"stockholm_ring1600": [59.3207, 18.0604, "ring1600", 1, "2026-11-02T21:21:26", 586043, "a9edd795ac812dc252419252abeb97b4d13ee4ccba74addd6d037be6c0d98867"],
	"stockholm_ring2500": [59.3207, 18.0604, "ring2500", 1, "2026-11-02T21:21:26", 786911, "8a756def7d95094c8a2ec55d550419d8ce4c4eb85868a2d5805602091af59224"],
	"stockholm_poi": [59.3207, 18.0604, "poi", 1, "2026-11-02T21:21:26", 433030, "e7f768f8f5ded0ad3cdd4d4e189483f67466c98f0d2bfbc9a253a966e9d33b53"],
	"new_york_midtown_detailed": [40.7535, -73.9825, "detailed", 12, "2026-07-28T02:16:18", 14314437, "c6dccea141c93857855f909036e5c44b18a6e1b49f4aa3f1a355c2894ca442a1"],
	"new_york_midtown_ring1600": [40.7535, -73.9825, "ring1600", 1, "2026-07-24T11:04:51", 765885, "d8efcfda2272dba7166b2527d2ba2fade3fcd554f887fd0064d2b2b859b47625"],
	"new_york_midtown_ring2500": [40.7535, -73.9825, "ring2500", 1, "2026-05-31T22:37:44", 876470, "35b44ad45c40e1bb294d2c06326d0ce6cd2fe479b82e555e108a8d1aed0ce222"],
	"new_york_midtown_poi": [40.7535, -73.9825, "poi", 1, "2026-07-15T15:22:01", 919211, "bc43b0b8d7f97f2b904650849542747d1d60b9630efa59849170f1c6a13cd243"],
	"new_york_midtown_far": [40.7535, -73.9825, "far", 3, "2026-07-24T11:04:51", 40463913, "fe1f3021208431254cd880548be972aab6028f19222f62323218812c68935ede"],
	"new_york_detailed": [40.7060, -74.0040, "detailed", 12, "2026-11-04T13:18:25", 16752176, "961c08765d6877fd1aa6e511b6872b6db02b8c8990f5d712f296483380b0828e"],
	"san_francisco_detailed": [37.8040, -122.4195, "detailed", 12, "2026-11-04T13:16:20", 10341950, "10b158204da607694e7eea89616211d3c72251f3e2e04c63bfcd35bb749fb253"],
	"helsinki_far": [60.1680, 24.9530, "far", 3, "2026-11-04T14:47:51", 19509450, "0a4b68952ddcd3ed19d697480431bcc5d41defcfdbbf1d393beb06b259774777"],
	"stockholm_far": [59.3207, 18.0604, "far", 3, "2026-11-04T14:07:04", 14767350, "e8bc59790a3c35798a19cb6149e3d50e9baa744c453e43118bd7591f5b56be26"],
}
const DIRECTORY := "res://assets/osm_snapshots/"
const CAPITAL_MANIFEST := DIRECTORY + "capital_manifest.json"
## Midtown's 12 km far layer is ~39 MB of JSON (4.6 MB gzipped).
const MAX_BYTES := 48 * 1024 * 1024
static var _refreshing: Dictionary = {}
static var _all_entries: Dictionary = {}
## Vector2(lat, lon) -> snapshot keys at that point, in table order, so a
## lookup does not scan the ~1,300 rows.
static var _by_point: Dictionary = {}

static func _entries() -> Dictionary:
	if _all_entries.is_empty():
		_all_entries = ENTRIES.duplicate()
		_by_point.clear()
		var f := FileAccess.open(CAPITAL_MANIFEST, FileAccess.READ)
		if f != null:
			var manifest: Variant = JSON.parse_string(f.get_as_text())
			if manifest is Dictionary:
				for key in manifest:
					var row: Variant = manifest[key]
					if str(key).is_valid_identifier() and not _all_entries.has(key) and _valid_manifest_row(row):
						_all_entries[key] = row
		for key in _all_entries:
			var entry: Array = _all_entries[key]
			# Preset coordinates pass through Vector2 (32-bit components) before
			# reaching the fetchers. Index in that representation so the same
			# preset still matches after the round trip, without matching nearby pins.
			var point := Vector2(float(entry[0]), float(entry[1]))
			if not _by_point.has(point):
				_by_point[point] = []
			(_by_point[point] as Array).append(key)
	return _all_entries

static func _valid_manifest_row(row: Variant) -> bool:
	if not row is Array or row.size() != 7:
		return false
	if not (row[0] is float or row[0] is int) or not (row[1] is float or row[1] is int):
		return false
	return absf(float(row[0])) <= 90 and absf(float(row[1])) <= 180 \
		and row[2] is String and row[2] in ["detailed", "detailed_extract", "ring1600", "ring2500", "poi", "far"] \
		and (row[3] is float or row[3] is int) and row[4] is String \
		and str(row[4]).length() == 19 and Time.get_unix_time_from_datetime_string(row[4]) > 0 \
		and (row[5] is float or row[5] is int) and int(row[5]) > 0 and int(row[5]) <= MAX_BYTES \
		and row[6] is String and str(row[6]).length() == 64 and str(row[6]).is_valid_hex_number(false)

static func entry_for(lat: float, lon: float, layer: String, version: int) -> String:
	var entries := _entries()
	for key in _by_point.get(Vector2(lat, lon), []):
		var entry: Array = entries[key]
		var layer_matches: bool = layer == entry[2] or (layer == "detailed" and entry[2] == "detailed_extract")
		if layer_matches and version == entry[3]:
			return key
	return ""

## An older device cache must not hide the snapshot. A missing snapshot
## never disqualifies an otherwise usable cache.
static func cache_is_newer(path: String, key: String) -> bool:
	if key == "" or not FileAccess.file_exists(DIRECTORY + key + ".json.gz"):
		return true
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	return _response_is_newer(file.get_as_text(), key)

## Overpass puts osm3s (with the timestamp) ahead of the elements, so the
## timestamp sits within the first few hundred characters.
const HEADER_CHARS := 4096

## Whether `text` is a complete response at least as new as the snapshot.
## A normal response (timestamp in its header, an elements list, no remark)
## is judged from its text without parsing, because a cached city is
## 5-30 MB and a full parse cost ~0.3 s on the main thread. Anything else
## takes the full parse.
static func _response_is_newer(text: String, key: String) -> bool:
	var stamp := header_stamp(text)
	if stamp != "" and text.contains('"elements"') and not text.contains('"remark"'):
		return stamp >= str(_entries()[key][4])
	return _response_is_newer_parsed(text, key)

## The osm3s timestamp from the head of a response, "" when it is not there.
static func header_stamp(text: String) -> String:
	var head := text.substr(0, HEADER_CHARS)
	var at := head.find('"timestamp_osm_base"')
	if at < 0:
		return ""
	var colon := head.find(":", at)
	var open := head.find('"', colon + 1) if colon >= 0 else -1
	var close := head.find('"', open + 1) if open >= 0 else -1
	if close < 0:
		return ""
	return head.substr(open + 1, close - open - 1).trim_suffix("Z")

static func _response_is_newer_parsed(text: String, key: String) -> bool:
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary or not data.get("elements", null) is Array \
			or str(data.get("remark", "")).strip_edges() != "":
		return false
	var metadata: Variant = data.get("osm3s", {})
	if not metadata is Dictionary:
		return false
	var stamp := str(metadata.get("timestamp_osm_base", "")).trim_suffix("Z")
	return stamp != "" and stamp >= str(_entries()[key][4])

static func read(key: String) -> String:
	var entries := _entries()
	if not entries.has(key):
		return ""
	var path := DIRECTORY + key + ".json.gz"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var raw := file.get_buffer(file.get_length()).decompress_dynamic(MAX_BYTES, FileAccess.COMPRESSION_GZIP)
	if raw.size() != int(entries[key][5]):
		return ""
	var text := raw.get_string_from_utf8()
	if text.sha256_text() != entries[key][6]:
		return ""
	# The snapshot tool (tools/prepare_osm_snapshot.py) refuses a payload with
	# a remark or without elements, and the manifest pins this exact text by
	# length and SHA-256, so it is not parsed again here: that parse cost
	# 0.2-0.4 s on the main thread, and the fetchers parse it on a worker.
	if OverpassRequest.payload_error(text) != "" or not text.contains('"elements"'):
		return ""
	if entries[key][2] == "detailed" and (not OsmQuery.is_current(text) or not OsmFetcher._mentions_buildings(text)):
		return ""
	if entries[key][2] == "detailed_extract" and not OsmFetcher._mentions_buildings(text) and not OsmFetcher._mentions_shores(text):
		return ""
	return text

## Detached from the pipeline so finishing the world cannot cancel a refresh.
## At most one request per snapshot is in flight and only validated data is saved.
static func refresh(tree: SceneTree, key: String, path: String, body: String,
		validate: Callable, endpoints: Array[String]) -> void:
	if tree == null or key == "" or _refreshing.has(key):
		return
	_refreshing[key] = true
	var req := OverpassRequest.new(60.0)
	var started := int(Time.get_unix_time_from_system())
	tree.root.add_child(req)
	req.answered.connect(func(text: String) -> void:
		if not FileAccess.file_exists(path) or FileAccess.get_modified_time(path) <= started:
			OsmFetcher._write_cache(path, text)
		_refreshing.erase(key)
		req.queue_free())
	req.exhausted.connect(func(_reason: String, _attempts: int) -> void:
		_refreshing.erase(key)
		req.queue_free())
	var checked := func(text: String) -> String:
		if not _response_is_newer(text, key):
			return "response is older than the bundled snapshot"
		if _entries()[key][2] in ["detailed", "detailed_extract"] and not OsmQuery.is_current(text):
			return "response has an incompatible query version"
		return str(validate.call(text))
	req.run(body, checked, endpoints.slice(0, 1))

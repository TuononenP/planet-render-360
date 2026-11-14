class_name BundledOsm
extends RefCounted

## Immutable Overpass snapshots for exact preset origins. Each entry is
## [latitude, longitude, layer, query version, OSM timestamp, payload bytes, SHA-256].
## Files are .osmb (tools/osmb.py): a compact, zstd-compressed form of the
## Overpass JSON, checked by its payload size and SHA-256 and decoded back
## to JSON text (OsmbCodec) for the fetchers.
## Missing layers deliberately use the ordinary network/cache fallback.
## The "transit" layer (tools/prepare_transit_layer.py) adds the tram and bus
## stops, station nodes and train platforms the detailed snapshots lack; it is
## merged in only when a snapshot stands in for the live detailed answer.
## Snapshots are never refreshed from Overpass in the background: a preset
## shows the bundled data until the bundle itself is rebuilt, so opening one
## sends no map queries. Device caches newer than a snapshot (from older
## builds, which did refresh) are still used.
## The "horizon" layer (tools/prepare_horizon_layer.py) holds the skyline
## labels of every preset and capital; its rows live in HORIZON_MANIFEST.
const ENTRIES := {
	"berlin_detailed": [52.52437, 13.41053, "detailed", 12, "2026-11-02T21:21:26", 1072309, "3400be2858e295d54681b2bbfe3931a16f4f11f3688f2bac2823dc3be2bbdbf8"],
	"berlin_ring1600": [52.52437, 13.41053, "ring1600", 1, "2026-11-02T21:21:26", 97270, "ccc9616eeeff921c6626c371072ceca27b82a0e80a50f1b546885716c2236cd5"],
	"berlin_ring2500": [52.52437, 13.41053, "ring2500", 1, "2026-11-02T21:21:26", 107932, "03f702705c818c7d38ccaec1a44cadc63ea659fb3623527b8c10309f8f11c1e5"],
	"berlin_poi": [52.52437, 13.41053, "poi", 1, "2026-11-02T21:21:26", 217028, "c979a2f4439fa27be7dd9bf298e5ff8e3943e92fee9c5bc3436d0cf51fe595e6"],
	"berlin_far": [52.52437, 13.41053, "far", 3, "2026-11-02T21:21:26", 2297092, "29da154661a2ef4be57eab699816c97c1cff2510b4bbd6ecf55294e2a6b0d52f"],
	"tokyo_far": [35.6595, 139.7005, "far", 3, "2026-11-03T21:24:23", 1592557, "b7f351a396c1f51f96c3ee918c94d384496af21da2dca0a5a3419c4046ba9d42"],
	"tokyo_detailed": [35.6595, 139.7005, "detailed_extract", 12, "2026-11-03T21:24:23", 674294, "8988b2eb87093db00e6a99cda628d407ff56488e2e6fe6d210c53036d80ffcb0"],
	"tokyo_ring1600": [35.6595, 139.7005, "ring1600", 1, "2026-11-03T21:24:23", 46140, "7be814e7e9613f87d1ccf5cc673807b4a7676321439991eb59dc2abcc8cbc674"],
	"tokyo_ring2500": [35.6595, 139.7005, "ring2500", 1, "2026-11-03T21:24:23", 78185, "a2969689fad8be2a65017ef81f78589d1b577b6a69956835fc262116b8bd40af"],
	"tokyo_poi": [35.6595, 139.7005, "poi", 1, "2026-11-03T21:24:23", 201886, "e9b7aea64477b0bc1ae32bb98cd202c6ea027e0c750cd6dc7eda117961dbfe4e"],
	"london_detailed": [51.5018, -0.1196, "detailed", 12, "2026-11-02T21:21:26", 1209523, "c35781d4c45c319dbd2edae14199b1921cc2481853a5da9ef1605fd87aa561cb"],
	"london_ring1600": [51.5018, -0.1196, "ring1600", 1, "2026-11-02T21:21:26", 63010, "da821df80f2dea38f6fc3370d2e9d5959c76de70d34964892f9f7597dd5d1ab5"],
	"london_ring2500": [51.5018, -0.1196, "ring2500", 1, "2026-11-02T21:21:26", 73949, "5d802efeb6ff6a13513e39c3ce6df6f8b33a48292cae76d2b638e097a2154e80"],
	"london_poi": [51.5018, -0.1196, "poi", 1, "2026-11-02T21:21:26", 89957, "8b14c740b8f0188d4aea64109e3d6ecce7740cf89d2731094c87e1ae819dc631"],
	"london_far": [51.5018, -0.1196, "far", 3, "2026-10-31T00:00:00", 2263543, "1af8ada5820428a5ad3e8881b7c70b223249cf9b31b8a446dfa566a9ab8c2557"],
	"dubai_detailed": [25.1925, 55.2741, "detailed_extract", 12, "2026-11-03T21:24:23", 242092, "90d1b29d29884867f5598fd8c157a85a67278abd8577ead45446114da3429805"],
	"dubai_ring1600": [25.1925, 55.2741, "ring1600", 1, "2026-11-03T21:24:23", 47051, "88ecacff69125fb72cfd2ea29298f8c1067c7359c8abb5947e2d32fa62d2df61"],
	"dubai_ring2500": [25.1925, 55.2741, "ring2500", 1, "2026-11-03T21:24:23", 62780, "185a6dc7d698bbcc0df90f6974d568645607ac9bc49c6bd5ac81781de4cf839c"],
	"dubai_poi": [25.1925, 55.2741, "poi", 1, "2026-11-03T21:24:23", 28900, "06639a6839211c0340ae7401609cb92d1269629699072fccd4bb3707328a3616"],
	"dubai_far": [25.1925, 55.2741, "far", 3, "2026-11-03T21:24:23", 402904, "210a17412aefddb915a028afe3b8d7fd9f8a0ab21e322eaebea6df448297d959"],
	"banff_detailed": [51.1720, -115.5640, "detailed_extract", 12, "2026-11-02T21:21:26", 225739, "527d22b8b6e7d9bb8ffd6046454e3877e517da583fa5fa30fac7ae9526a9ac31"],
	"banff_ring1600": [51.1720, -115.5640, "ring1600", 1, "2026-11-02T21:21:26", 14577, "66c8be376632a5160b8ca9359f952f621950f4f2026f31cff8c06892d32858c8"],
	"banff_ring2500": [51.1720, -115.5640, "ring2500", 1, "2026-11-02T21:21:26", 20918, "2bc5f402c63658085ef98a9432ae638815a95baa2da824a8bc979178f805996d"],
	"banff_poi": [51.1720, -115.5640, "poi", 1, "2026-11-02T21:21:26", 24076, "fbdf19500cefbf39f61fbc34f2caaa5a8744e965fdd3a37c18ab5b2d4db9b079"],
	"banff_far": [51.1720, -115.5640, "far", 3, "2026-11-02T21:21:26", 10551, "ab44cf5320e0ec9326821639a6bb95b2c5582b8ba4837047cd003b72a54e26e8"],
	"big_sur_detailed": [36.3740, -121.9022, "detailed_extract", 12, "2026-11-03T00:45:53", 30444, "e7cdf1dc171eac43741d2636401d3d8bb5eb8e5aced9a787fb9cc56515ee687e"],
	"big_sur_ring1600": [36.3740, -121.9022, "ring1600", 1, "2026-11-03T00:45:53", 6432, "9d69fd9b3ac808f43452fa27d062ade2441d4e81e414e11132af064b6d2b33e0"],
	"big_sur_ring2500": [36.3740, -121.9022, "ring2500", 1, "2026-11-03T00:45:53", 8329, "e7d720a13335b2893042c127a22c04e1f4df06133d303bf787927a9b5cbe4a97"],
	"big_sur_poi": [36.3740, -121.9022, "poi", 1, "2026-11-03T00:45:53", 500, "c59f73410fac5214ac59b8914bb070cd6c9b4b2e2e3b2597b9f60815a510536f"],
	"big_sur_far": [36.3740, -121.9022, "far", 3, "2026-11-03T00:45:53", 1605, "fc225545601a7d28966053b49b78a177884f73c9ac334af076b452ebfe4ef37a"],
	"seoul_detailed": [37.5728, 126.9769, "detailed_extract", 12, "2026-10-31T00:00:00", 607535, "a651267d64cc2ba0853736511f179240c418bde329a586472ba985b461ebdbdc"],
	"seoul_ring1600": [37.5728, 126.9769, "ring1600", 1, "2026-10-31T00:00:00", 29440, "35ec25684166e3ad4ba20b6237893fc5bff125409e228648e561b58e88ef5f32"],
	"seoul_ring2500": [37.5728, 126.9769, "ring2500", 1, "2026-10-31T00:00:00", 54305, "c83242cc4d1a692bf22c6669a287e47310418783b30c47c57be8932df813a55c"],
	"seoul_poi": [37.5728, 126.9769, "poi", 1, "2026-10-31T00:00:00", 105218, "50eabcead51ac9698b4b4c0e3b30ed2ca15177f6cd7ccb4a17dce7b6ab1c5d9b"],
	"seoul_far": [37.5728, 126.9769, "far", 3, "2026-10-31T00:00:00", 1481035, "9b1a35b108a6f4a41d99c3633e24be6316150f27430f9cc8c81830d415a6b319"],
	"alps_detailed": [46.6900, 7.8580, "detailed", 12, "2026-11-02T21:21:26", 369427, "a5a6f5dc72b8748ca15989e65c34259f5dfca5223236b7ec387d4ec5a5475ea6"],
	"alps_ring1600": [46.6900, 7.8580, "ring1600", 1, "2026-11-02T21:21:26", 11425, "a8cad06fb3793fef610dc6bb1edbed221aa0e8b075879090ec9e8a72c4effcb5"],
	"alps_ring2500": [46.6900, 7.8580, "ring2500", 1, "2026-11-02T21:21:26", 26077, "14446f2a620f0fa4a5a7ac61791d749dfd76a5ea83a3f9f1a9e6c4a687e89d07"],
	"alps_poi": [46.6900, 7.8580, "poi", 1, "2026-11-02T21:21:26", 31483, "03811a3740d9792e0ccb5db21a34a3b38afeeffd242e11a41be7537bfa1e6b96"],
	"alps_far": [46.6900, 7.8580, "far", 3, "2026-11-02T21:21:26", 55969, "6658d2325cf41828466e83c5686cc05b481c30b2bc0fe07060e7333f963459c7"],
	"rome_detailed": [41.8916, 12.4916, "detailed", 12, "2026-11-02T21:21:26", 942024, "0edfb6407503eba2ce28675a1bc84137be8d47a78b8f1fa578a10d8d13033f74"],
	"rome_ring1600": [41.8916, 12.4916, "ring1600", 1, "2026-11-02T21:21:26", 51076, "147131ae794e00535e613affdeaa4efc4a0542177ae63c516a95c9718449d31e"],
	"rome_ring2500": [41.8916, 12.4916, "ring2500", 1, "2026-11-02T21:21:26", 62028, "79077713bf28447e9f0136245109d02a511082f832d67c50f6db97cbadb68e9a"],
	"rome_poi": [41.8916, 12.4916, "poi", 1, "2026-11-02T21:21:26", 79078, "08e475fcc029c5b4176848a3dc4d4aad7cf0cbf8545feffb00666aa4b41742af"],
	"rome_far": [41.8916, 12.4916, "far", 3, "2026-11-02T21:21:26", 763260, "c0eef1941e57900c4ccb58fe9f93c0a5140ae607c3f10c96f5dd67eb57ff149a"],
	"venice_detailed": [45.4318, 12.3290, "detailed", 12, "2026-11-02T21:21:26", 1242271, "168a5b6cf31c9d226f45682bd9149cbd78f2258c2c139fa05ee23fc02cab56c7"],
	"venice_ring1600": [45.4318, 12.3290, "ring1600", 1, "2026-11-02T21:21:26", 15718, "9c526909f4f5c463e7fedf21055dced1acd17877d4a38830557ae980b10e38c9"],
	"venice_ring2500": [45.4318, 12.3290, "ring2500", 1, "2026-11-02T21:21:26", 16973, "1cb3ef5f91add7420f9d84135f1d33e11735f88c6a8170fe3faaefca3e4d145a"],
	"venice_poi": [45.4318, 12.3290, "poi", 1, "2026-11-02T21:21:26", 98611, "58f26f76d1042bf1c700f1078740a0593c7ccffaa2c0f243218ae0a48dbae55b"],
	"venice_far": [45.4318, 12.3290, "far", 3, "2026-11-02T21:21:26", 228537, "99034d10e6930c0653edde4f9095cd7a0e5d5049cc16ac808cdda37261912321"],
	"paris_detailed": [48.8622, 2.2887, "detailed", 12, "2026-11-04T15:35:21", 1140664, "ee95782576b53ebee4f2cfc5490bc052955a6d1ff510c56a093b34448c8fc20c"],
	"paris_ring1600": [48.8622, 2.2887, "ring1600", 1, "2026-11-02T21:21:26", 53051, "43cee49f7239cb0b035318f502556ccb6fc262cc153b0f102cd41966d8bb7dee"],
	"paris_ring2500": [48.8622, 2.2887, "ring2500", 1, "2026-11-02T21:21:26", 82190, "818b43c73a51b8c58b4136d037c3dde1e57baaa64b56ceb227c2786aa7cb4ac9"],
	"paris_poi": [48.8622, 2.2887, "poi", 1, "2026-11-02T21:21:26", 109952, "1869286aff5aeeb5541ce78d787747feaad6119eb8ab7611ffebce339a397d4f"],
	"paris_far": [48.8622, 2.2887, "far", 3, "2026-11-04T16:59:38", 1462466, "a5a4dece54afad101dc2522ea9111a25970516bf89a9c37b5c9c31a5e3fd785b"],
	"monaco_detailed": [43.7310, 7.4209, "detailed", 12, "2026-11-04T13:15:14", 368286, "feecea501250ec1094dd444473f684cef46438f59f00845677bd09e88605293c"],
	"monaco_ring1600": [43.7310, 7.4209, "ring1600", 1, "2026-11-02T21:21:26", 36254, "431a26dd7a8b73c13ad2be68cbdc7e26501fc5ddf56c2740ebf8ec29593385c0"],
	"monaco_ring2500": [43.7310, 7.4209, "ring2500", 1, "2026-11-04T13:14:21", 53260, "0c891363c4b839fc6d540d7c916f690e5963b41341ba25210cfe516fef947511"],
	"monaco_poi": [43.7310, 7.4209, "poi", 1, "2026-11-02T21:21:26", 55876, "6a6810818672d2cab5d6690ce4dc40ed8024250b4ca17c9a899064d77d290bb8"],
	"monaco_far": [43.7310, 7.4209, "far", 3, "2026-11-02T21:21:26", 136048, "9e26a912569d70a3a639304c1193b54f23bc02fef6f487c1612dc87d080c2864"],
	"espoo_detailed": [60.1760, 24.8050, "detailed", 12, "2026-11-02T21:21:26", 498553, "e4e5e97ed73716321798a43332fd1006633f1bdd7aaf2297d2c25c1bb819ba1b"],
	"espoo_ring1600": [60.1760, 24.8050, "ring1600", 1, "2026-11-02T21:21:26", 47906, "7a411ebc9f2733a41b599b243f5bed354c20641d79091aa84e75bbac611a3965"],
	"espoo_ring2500": [60.1760, 24.8050, "ring2500", 1, "2026-11-02T21:21:26", 77519, "743482fa4499ab669ba7354c8686c2232e5e066afd5f068fcb813249730a39ca"],
	"espoo_poi": [60.1760, 24.8050, "poi", 1, "2026-11-02T21:21:26", 45149, "8eb47469ee19c614ea7eb49ac01c66c01cf2287afb5a64c62728ce1e610147cb"],
	"espoo_far": [60.1760, 24.8050, "far", 3, "2026-11-02T21:21:26", 1189696, "067a75098fbf6d240455b4af3c24edcd7fbf48a7c8fa373cbd3bfa9deba8f9b8"],
	"san_francisco_far": [37.8040, -122.4195, "far", 3, "2026-11-02T21:21:26", 399229, "e6311023ae3a4f8aa365df2194ba97b0fd8729385e6a1a37e97f851368855a0d"],
	"new_york_far": [40.7060, -74.0040, "far", 3, "2026-10-31T00:00:00", 2547914, "586cdcd0e957eddf906c70b5018c474272aabaeca132879bdbbef6dc47144e46"],
	"new_york_ring1600": [40.7060, -74.0040, "ring1600", 1, "2026-10-31T00:00:00", 66890, "335ba36ba1cec483f8279405a24d87e7b0c16f1816f1c606c2f9d069dc49902f"],
	"new_york_ring2500": [40.7060, -74.0040, "ring2500", 1, "2026-10-31T00:00:00", 83548, "c6990e9ba41bc5df405e384077532681742080e7d30d3d3fc1ff67d818413b20"],
	"new_york_poi": [40.7060, -74.0040, "poi", 1, "2026-10-31T00:00:00", 112001, "270fdcb2d61f326cf3cccf1563d0c3ff3797bc5657e09a79475d80c5ee477243"],
	"san_francisco_ring1600": [37.8040, -122.4195, "ring1600", 1, "2026-10-31T00:00:00", 33445, "5c56b3e79a1f6d18e7022cd6e56598c49b449931ff1411e695e0af04154cc3b7"],
	"san_francisco_ring2500": [37.8040, -122.4195, "ring2500", 1, "2026-10-31T00:00:00", 60190, "9c4dffd47d5f1f196e3760e429757c169f28b54a12405b4820dc46260a084340"],
	"san_francisco_poi": [37.8040, -122.4195, "poi", 1, "2026-10-31T00:00:00", 43295, "63d7d6e3ee8d0f16bf207706c3bdc994e1e122b9a232b6fff656868ea2764a7d"],
	"helsinki_detailed": [60.1680, 24.9530, "detailed", 12, "2026-11-02T21:21:26", 1033478, "f393363dbf399008f2f64a4d7ada58f2f8a0fa6997a6f966b13afbd0e13afaec"],
	"helsinki_ring1600": [60.1680, 24.9530, "ring1600", 1, "2026-11-02T21:21:26", 82371, "c6ab3cf77338aeada29628289f30595d190fcebea50c1468683d96b94448594c"],
	"helsinki_ring2500": [60.1680, 24.9530, "ring2500", 1, "2026-11-02T21:21:26", 103748, "102ff321033f281a2d676ec2cede123f1addab7c7695a941cea3db7ec557b440"],
	"helsinki_poi": [60.1680, 24.9530, "poi", 1, "2026-11-02T21:21:26", 203807, "713a0a3f137b291b76436e444f9883d36b9af395f9e0025dcaf854d59a5cd8ca"],
	"stockholm_detailed": [59.3207, 18.0604, "detailed", 12, "2026-11-02T21:21:26", 927566, "f198d27f16b93d163eed030556cd6b65c1cc91523e6194b24d63a707c1a7e6e6"],
	"stockholm_ring1600": [59.3207, 18.0604, "ring1600", 1, "2026-11-02T21:21:26", 47537, "b13fe248fa7cbc30e5a536cadeadc390e2ce80df1dbbca60f04c51c513b10203"],
	"stockholm_ring2500": [59.3207, 18.0604, "ring2500", 1, "2026-11-02T21:21:26", 63491, "3e22e493f8ed4925e876052b77c58dce957e823312e7d0e921ce73edc88bd019"],
	"stockholm_poi": [59.3207, 18.0604, "poi", 1, "2026-11-02T21:21:26", 127367, "3b1ecbfc47877569cf8fd1f87330f3fdf782653b2defc7a5ab4ac3b5f978709d"],
	"new_york_midtown_detailed": [40.7535, -73.9825, "detailed", 12, "2026-07-28T02:16:18", 1150965, "e1682790d3eb21bac87e51f1c2c9ee68a7ccb8ccf9a48b536d54db78ba542e1e"],
	"new_york_midtown_ring1600": [40.7535, -73.9825, "ring1600", 1, "2026-07-24T11:04:51", 62740, "aa8c9fbb1ae309bd3d1cb38e4fe0ba87944f845d98629ed9c77c9ab200ff7c23"],
	"new_york_midtown_ring2500": [40.7535, -73.9825, "ring2500", 1, "2026-05-31T22:37:44", 74128, "9f234176667de6bd790c317af2045d434f7db39196c3fb1b34277642a2a733b4"],
	"new_york_midtown_poi": [40.7535, -73.9825, "poi", 1, "2026-07-15T15:22:01", 244548, "86787e7dfd6d7d3048ce1c39fa8afe243ef13116cce83ec1e1d15b971d7a4033"],
	"new_york_midtown_far": [40.7535, -73.9825, "far", 3, "2026-07-24T11:04:51", 2812889, "f3ba7988710cc34057f962c0efdd5921ee8de137e2c4412cf8abf3d1db332c77"],
	"new_york_detailed": [40.7060, -74.0040, "detailed", 12, "2026-11-04T13:18:25", 1172636, "dc262ccf75f0cdc25ec05d2d866c6f72b6f828bb5a5f15e57ed88607c3dda262"],
	"san_francisco_detailed": [37.8040, -122.4195, "detailed", 12, "2026-11-04T13:16:20", 658733, "31a5fb4cc7aadef50eb310fa6ba1fd4fcd1aeb9c3037e36529dbc5ddd48175d5"],
	"helsinki_far": [60.1680, 24.9530, "far", 3, "2026-11-04T14:47:51", 1213581, "2ca4652c1d5f3884eca7d6df93e1e64b230d4ab4ead5208ceed1e716644c9dfd"],
	"stockholm_far": [59.3207, 18.0604, "far", 3, "2026-11-04T14:07:04", 990527, "acec897edd0eb498001fbd3dfeeac6ab262e931b5f3f2fa510c0b0d03c2cc443"],
	"helsinki_transit": [60.1680, 24.9530, "transit", 1, "2026-11-11T00:49:59", 26212, "a11b1df578399c2f7229b71be858b1c0c96509e4c3af5be57af306f9945601d5"],
	"berlin_transit": [52.5244, 13.4105, "transit", 1, "2026-11-11T00:50:42", 17865, "2ce7ec139d53d4a136617f7aaefcf27b9b4cb4b7d1d1585a18d244f4a12d6cfd"],
	"tokyo_transit": [35.6595, 139.7005, "transit", 1, "2026-11-11T00:51:14", 14153, "7bcd80d15b1e379fb07fb780fd95f36696cd57639256f18153cc9884043bcf52"],
	"london_transit": [51.5018, -0.1196, "transit", 1, "2026-11-11T00:51:49", 27253, "7b1e0afb062db82404fd19f699f114affcfd56f172b7ac0b878e86e17b3c5bc9"],
	"dubai_transit": [25.1925, 55.2741, "transit", 1, "2026-11-11T00:52:18", 2979, "7202076704881dd6bde40e985b7390685c297f68dcf5113ad530544222ec57c3"],
	"banff_transit": [51.1720, -115.5640, "transit", 1, "2026-11-11T00:52:46", 2463, "b0bca863e935bd682334a8b97334b6e54e0456bfeebcab42e123ce6ac71e6545"],
	"big_sur_transit": [36.3740, -121.9022, "transit", 1, "2026-11-11T00:53:12", 452, "37b954c7a5a22f39ca8dcc30652fc1f96697c5d8b47636f939987a144ba3b90a"],
	"seoul_transit": [37.5728, 126.9769, "transit", 1, "2026-11-11T00:53:45", 13666, "290e5f51339935d766495f114ee83aae47819ff06bad3b1d8fea6b9bbdfa5697"],
	"alps_transit": [46.6900, 7.8580, "transit", 1, "2026-11-11T00:54:16", 2924, "d94f9dc0205c6259bcb10eacfec3a4727cc0865e027353a2f5c7ee302dc04325"],
	"rome_transit": [41.8916, 12.4916, "transit", 1, "2026-11-11T00:54:53", 10777, "136600eaa234fb6431ca4bbc4ab764e710a657a07b00a9fc05f85d8b6d25a732"],
	"venice_transit": [45.4318, 12.3290, "transit", 1, "2026-11-11T00:55:28", 1380, "45ed67abfcd77362796edebc43f68b64e24622ceecb8c9a0244f4c431f030de7"],
	"paris_transit": [48.8622, 2.2887, "transit", 1, "2026-11-11T01:12:05", 16514, "36584382655248a98d9fa074f4449173061ad534568a3aa535ca00fc13cd7004"],
	"monaco_transit": [43.7310, 7.4209, "transit", 1, "2026-11-11T01:13:29", 6647, "7e06f9e4d643fefa92e35ed3db089d292a7acb21af7b55fe75f3f6d9ddce578b"],
	"espoo_transit": [60.1760, 24.8050, "transit", 1, "2026-11-11T01:14:56", 9512, "d727f9d0249ff5321defce2604e5d23b2e1930c40760e8b81b7c3a3f129ccd9d"],
	"stockholm_transit": [59.3207, 18.0604, "transit", 1, "2026-11-11T01:16:23", 10595, "0b26039978bc07d01ebac7ca801abde3e7cf9a95898a9e5cc5c6d5a2d003809d"],
	"new_york_midtown_transit": [40.7535, -73.9825, "transit", 1, "2026-11-11T01:17:52", 31550, "545a2a60b9d0dbdceb024cfaa5d5a3b76f9396bd5bcd71efee7d015042299c1a"],
	"new_york_transit": [40.7060, -74.0040, "transit", 1, "2026-11-11T01:19:20", 20384, "a357f1fc32655ee39ee7affe0415ca21fb5251c1987a961c20a1c4a18f96fccf"],
	"san_francisco_transit": [37.8040, -122.4195, "transit", 1, "2026-11-11T01:20:47", 15218, "80d325cb3da217c364d5ef0d76b91fa1aa4bad1db5c0071f0aa5245b21602579"],
}
const DIRECTORY := "res://assets/osm_snapshots/"
const CAPITAL_MANIFEST := DIRECTORY + "capital_manifest.json"
const HORIZON_MANIFEST := DIRECTORY + "horizon_manifest.json"
## Cap on a decompressed payload (the largest, a 12 km far layer, is a few MB).
const MAX_BYTES := 48 * 1024 * 1024
static var _all_entries: Dictionary = {}
## Vector2(lat, lon) -> snapshot keys at that point, in table order, so a
## lookup does not scan the ~1,300 rows.
static var _by_point: Dictionary = {}

static func _entries() -> Dictionary:
	if _all_entries.is_empty():
		_all_entries = ENTRIES.duplicate()
		_by_point.clear()
		for path in [CAPITAL_MANIFEST, HORIZON_MANIFEST]:
			var f := FileAccess.open(path, FileAccess.READ)
			if f == null:
				continue
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
		and row[2] is String and row[2] in ["detailed", "detailed_extract", "ring1600", "ring2500", "poi", "far", "transit", "horizon"] \
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

## Whether the place is a bundled preset: its detailed, ring, POI and
## far-city layers all ship with the app, so a load needs no Overpass query
## and no status check of the Overpass servers.
static func covers(lat: float, lon: float) -> bool:
	for layer in [["detailed", OsmQuery.QUERY_VERSION], ["ring1600", OsmQuery.RING_VERSION],
			["ring2500", OsmQuery.RING_VERSION], ["poi", OsmQuery.POI_VERSION],
			["far", FarCityFetcher.QUERY_VERSION]]:
		if entry_for(lat, lon, layer[0], layer[1]) == "":
			return false
	return true

## An older device cache must not hide the snapshot. A missing snapshot
## never disqualifies an otherwise usable cache.
static func cache_is_newer(path: String, key: String) -> bool:
	if key == "" or not FileAccess.file_exists(DIRECTORY + key + ".osmb"):
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
	var path := DIRECTORY + key + ".osmb"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	# Godot decompresses zstd only to a known size: the manifest's.
	var payload := file.get_buffer(file.get_length()).decompress(int(entries[key][5]), FileAccess.COMPRESSION_ZSTD)
	if payload.size() != int(entries[key][5]):
		return ""
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(payload)
	if hash.finish().hex_encode() != entries[key][6]:
		return ""
	var text := OsmbCodec.decode(payload)
	if text == "":
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

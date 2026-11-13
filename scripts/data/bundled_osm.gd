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
	"berlin_detailed": [52.52437, 13.41053, "detailed", 12, "2026-11-02T21:21:26", 951505, "48600c6f9d698f8cd4c24f7abb17e9d32a59437f687a3f46fc4dea5614b759cd"],
	"berlin_ring1600": [52.52437, 13.41053, "ring1600", 1, "2026-11-02T21:21:26", 94149, "3958a0e6abdde11f6a132ec17216a9f7f800f02e9d2d871807fb549a296c35e7"],
	"berlin_ring2500": [52.52437, 13.41053, "ring2500", 1, "2026-11-02T21:21:26", 104146, "db605b164f443680f676abb2906507f96076d35d13c453857710355a16ab26b0"],
	"berlin_poi": [52.52437, 13.41053, "poi", 1, "2026-11-02T21:21:26", 214228, "4838e649c13e9eb6ba540ac1a126a9e58e6bceb925e5f0a467ff63632921ed92"],
	"berlin_far": [52.52437, 13.41053, "far", 3, "2026-11-02T21:21:26", 1810595, "9ff77d1d52b97bfc3a5fb97bcfe0c9a0bee41b9839d9d4551a8177d7eb89dc25"],
	"tokyo_far": [35.6595, 139.7005, "far", 3, "2026-11-03T21:24:23", 1372121, "07a4c84d2be6b77a67e9848d094aaf46f7d50eb879e9a802a7d15709a731effe"],
	"tokyo_detailed": [35.6595, 139.7005, "detailed_extract", 12, "2026-11-03T21:24:23", 584321, "afa11b4bb8064ec1816669f05831879ff1f48031f5cdce14a3f39e8830294950"],
	"tokyo_ring1600": [35.6595, 139.7005, "ring1600", 1, "2026-11-03T21:24:23", 42419, "959bc7a1c2cbb4ed3cbd1719bfcdbac61a76f74d7fb2374c1a19bd8ce89aeff1"],
	"tokyo_ring2500": [35.6595, 139.7005, "ring2500", 1, "2026-11-03T21:24:23", 71489, "b32cdc021d847aba9a8a793499213104782cbe87162d51baea3cd682c8c90e2c"],
	"tokyo_poi": [35.6595, 139.7005, "poi", 1, "2026-11-03T21:24:23", 199463, "52b605bafdb88f5716c5eb39d8b4530456a6ac664abc297903bc76c0f9f4338a"],
	"london_detailed": [51.5018, -0.1196, "detailed", 12, "2026-11-02T21:21:26", 1075530, "1603a582851f3acc51d6254f945e9b630208b9a98842ba3ab0e35524061b310e"],
	"london_ring1600": [51.5018, -0.1196, "ring1600", 1, "2026-11-02T21:21:26", 59193, "9899bac5874d84b8f49edb230581926bccb7dc75fc1ade8a541cf58c39f73f91"],
	"london_ring2500": [51.5018, -0.1196, "ring2500", 1, "2026-11-02T21:21:26", 69465, "bc8cfed2119ea8b7ab8343f62f9f2a7c83081924274f8c44cdfffb2aaf8b0bdd"],
	"london_poi": [51.5018, -0.1196, "poi", 1, "2026-11-02T21:21:26", 88761, "67c651a3a6642a83ff52f3334fdb135b0074a7894515049ff320d27f347271c7"],
	"london_far": [51.5018, -0.1196, "far", 3, "2026-10-31T00:00:00", 1904416, "c50b216b8138fea5fed2c1707515cceb10692360b9b6fdb5ea16cc354475bfce"],
	"dubai_detailed": [25.1925, 55.2741, "detailed_extract", 12, "2026-11-03T21:24:23", 200353, "e9773f19bff94027746a00cd3baa8f03f79f410128eee73b46b5617500802085"],
	"dubai_ring1600": [25.1925, 55.2741, "ring1600", 1, "2026-11-03T21:24:23", 42740, "9d7f2d4bf85a15ca01b0a80231e72c0c1245045fbdbc7c07b671aa9e07312954"],
	"dubai_ring2500": [25.1925, 55.2741, "ring2500", 1, "2026-11-03T21:24:23", 56314, "648799f0c8d7ecdc70ffb0839c87b825dff688a8363b4cdf1aa0ba50d8d86416"],
	"dubai_poi": [25.1925, 55.2741, "poi", 1, "2026-11-03T21:24:23", 28468, "329a8a109c3eefa891cf6c5c1295a38d15745fed4937b4bb8c86883a563af391"],
	"dubai_far": [25.1925, 55.2741, "far", 3, "2026-11-03T21:24:23", 344451, "2d96e7055e441f90a981a7efc88dacd7392c7db6c4f20744319a09c8f93c22be"],
	"banff_detailed": [51.1720, -115.5640, "detailed_extract", 12, "2026-11-02T21:21:26", 189590, "d4018c0ea1862e9ba598de0486792529f5648cdcef6fffdc4c3f6a286b53de85"],
	"banff_ring1600": [51.1720, -115.5640, "ring1600", 1, "2026-11-02T21:21:26", 12821, "b753fec72fc40c291c985e0e91c53223cd598fb5dc1261c2a4f843380ec4e7c3"],
	"banff_ring2500": [51.1720, -115.5640, "ring2500", 1, "2026-11-02T21:21:26", 18484, "07c7c4628f9f7493ced3cd42d4e790eaa8c531baa78f7f2be9d0cfce3146626f"],
	"banff_poi": [51.1720, -115.5640, "poi", 1, "2026-11-02T21:21:26", 23720, "27a0a79ac860ffeb400f254554fc72f11f8bb5817d9fbd48f65cad2b4d118128"],
	"banff_far": [51.1720, -115.5640, "far", 3, "2026-11-02T21:21:26", 9003, "b35b7dc7ab4f31cd33ea5f33de5385d239f6069d28f94dd2a9007a00897e00af"],
	"big_sur_detailed": [36.3740, -121.9022, "detailed_extract", 12, "2026-11-03T00:45:53", 27047, "ec117f97f720ec55016e2f1d782c4be4545b6e92b8d5ff379ba60600d5feb3df"],
	"big_sur_ring1600": [36.3740, -121.9022, "ring1600", 1, "2026-11-03T00:45:53", 5728, "c31a8130434a8e485dc62988842f19d90b1097491bfa8a4f7694fae555a4b800"],
	"big_sur_ring2500": [36.3740, -121.9022, "ring2500", 1, "2026-11-03T00:45:53", 7381, "0d73f6a11d988d2bdb0214c08a6cd9feda7a83ba5327d00b445696af8cc5b04b"],
	"big_sur_poi": [36.3740, -121.9022, "poi", 1, "2026-11-03T00:45:53", 486, "d7046366240bc584065424b573c71c9c126954ace7d11e2a575f0b2f67e52aeb"],
	"big_sur_far": [36.3740, -121.9022, "far", 3, "2026-11-03T00:45:53", 1484, "43c075eb6d6578404a51364bd4429ff889428985c74703db5d10077192a024d6"],
	"seoul_detailed": [37.5728, 126.9769, "detailed_extract", 12, "2026-10-31T00:00:00", 523765, "43f5adcb1921c1a41f2703c29294cd2a9b56cd810a4e9f5bcc8c84f40be317c1"],
	"seoul_ring1600": [37.5728, 126.9769, "ring1600", 1, "2026-10-31T00:00:00", 27422, "88a6b16a25b34c7b90c9b91964d4981b3100c998cb150c8cadd86bb1b0bb109e"],
	"seoul_ring2500": [37.5728, 126.9769, "ring2500", 1, "2026-10-31T00:00:00", 50418, "f49ef686a4696b77eb6bae3ebb1622f118a4fa24981b436ea4e240277b24de38"],
	"seoul_poi": [37.5728, 126.9769, "poi", 1, "2026-10-31T00:00:00", 103677, "325de804c2baf1a00ce752366eba923b939bf720cf749a6948ade8c03ae5f42b"],
	"seoul_far": [37.5728, 126.9769, "far", 3, "2026-10-31T00:00:00", 1320434, "4764d0f1c7f511b95d09d591c0da130791036b2531c5b350b6a2a13ba4df7ef0"],
	"alps_detailed": [46.6900, 7.8580, "detailed", 12, "2026-11-02T21:21:26", 305027, "edc242cc4bfca5d32489783d06b2f92c299d73ea18d6b1cc2536c1ee4ed5663c"],
	"alps_ring1600": [46.6900, 7.8580, "ring1600", 1, "2026-11-02T21:21:26", 10131, "28726bb9bae6a563c0264fbc17a67e8b697479efa4b19beb14d3402ce7cf88f8"],
	"alps_ring2500": [46.6900, 7.8580, "ring2500", 1, "2026-11-02T21:21:26", 22786, "d608c87e7c611a67a3d51d972cbacc62743761898745cb55a11391c25d9b5477"],
	"alps_poi": [46.6900, 7.8580, "poi", 1, "2026-11-02T21:21:26", 30930, "7925ae9d1d1d3faa6dadabd88739586887e2036fb377460f49f43f33157f415d"],
	"alps_far": [46.6900, 7.8580, "far", 3, "2026-11-02T21:21:26", 44231, "0b4b2a726060037cd9e531559a45c853f5b671835e0d9f0a9cf38f40cf3437d6"],
	"rome_detailed": [41.8916, 12.4916, "detailed", 12, "2026-11-02T21:21:26", 787976, "90b784d68651679d778035c3728c31e904162130d9fd1c3d60f9de4584ce5bf6"],
	"rome_ring1600": [41.8916, 12.4916, "ring1600", 1, "2026-11-02T21:21:26", 44847, "20efc8892f1ddc0d23d1a7ec07b6b604ba332a97998dce665a3c96f121ffc895"],
	"rome_ring2500": [41.8916, 12.4916, "ring2500", 1, "2026-11-02T21:21:26", 53939, "1ed6f90637b32f88f564d4d583585cb4f7f9780493e7352a18bf90bc3d1fb931"],
	"rome_poi": [41.8916, 12.4916, "poi", 1, "2026-11-02T21:21:26", 77820, "3ef6bdcdb6ddb9c939589dad154ef500dcf06643fee5910048f48254c55cf898"],
	"rome_far": [41.8916, 12.4916, "far", 3, "2026-11-02T21:21:26", 645970, "85b7ba390e5179c3ca98758d6211f8aa63d74d5c454ddbeb9a34a9cfe4139916"],
	"venice_detailed": [45.4318, 12.3290, "detailed", 12, "2026-11-02T21:21:26", 1003697, "17f0fb7c449c7730e156cc20905acbd7e37301d6adebe3b74d0476ff3b4504bc"],
	"venice_ring1600": [45.4318, 12.3290, "ring1600", 1, "2026-11-02T21:21:26", 14580, "8b8b83951f75045d3618b9eb216a4b5971d6ef46281b0a8311f502052f6b66a4"],
	"venice_ring2500": [45.4318, 12.3290, "ring2500", 1, "2026-11-02T21:21:26", 15632, "f7dd32437340a5d93937a34e1112b1ec5c3538c4c3db718fbc033f5aa02b1533"],
	"venice_poi": [45.4318, 12.3290, "poi", 1, "2026-11-02T21:21:26", 97097, "ff404677d160766b160864ccbf82d02562223324f8c8ee457d745a1c63fc9301"],
	"venice_far": [45.4318, 12.3290, "far", 3, "2026-11-02T21:21:26", 188796, "deeeaf6f2f3cacb19d4f6b634a4d9592d9210db46f43ad5e113e646bb2a20c86"],
	"paris_detailed": [48.8622, 2.2887, "detailed", 12, "2026-11-04T15:35:21", 972490, "cde34fbc5d79b69217ecb2e5ccec0fd70321ff8fac1addef519524bdb5e782e4"],
	"paris_ring1600": [48.8622, 2.2887, "ring1600", 1, "2026-11-02T21:21:26", 49850, "8b2378825ce26281893a6fcd006597e62d4d8a7b2cf2c46d1532c7393d28c0e7"],
	"paris_ring2500": [48.8622, 2.2887, "ring2500", 1, "2026-11-02T21:21:26", 76151, "35e5015ad15828da52d10d52121a3f57d055b6f03847e03221dee90e618cf455"],
	"paris_poi": [48.8622, 2.2887, "poi", 1, "2026-11-02T21:21:26", 108144, "96e714727c4fb22e61698424a3da480357ad87aa60c54ac166bd29e832bc8941"],
	"paris_far": [48.8622, 2.2887, "far", 3, "2026-11-04T16:59:38", 1220355, "15293baad997d18aee2de53f5737245136e38db8b645c225415406d9fcc7eec3"],
	"monaco_detailed": [43.7310, 7.4209, "detailed", 12, "2026-11-04T13:15:14", 310661, "7ab12aaccbfd01f030713ac1d1bd30eca57c8e6a81369d7e845bd330bbef23a1"],
	"monaco_ring1600": [43.7310, 7.4209, "ring1600", 1, "2026-11-02T21:21:26", 31927, "ae38674012089c527c02e94a01dcb7c4731f5d53d1add9c4e2dbf1e2ff86433a"],
	"monaco_ring2500": [43.7310, 7.4209, "ring2500", 1, "2026-11-04T13:14:21", 46986, "1305cb0c4a8caad1388ebdbf5a1606ffdc1a7daa9ca077df84a1faea2f97b339"],
	"monaco_poi": [43.7310, 7.4209, "poi", 1, "2026-11-02T21:21:26", 54719, "fdcdd496d8b647b62d78194ad137cf4a54c1f05760288eb8b797b05bcf362feb"],
	"monaco_far": [43.7310, 7.4209, "far", 3, "2026-11-02T21:21:26", 114448, "6782b2b712261b9732b4cda322f0b7343d1d189877f151d652dfee53f8839098"],
	"espoo_detailed": [60.1760, 24.8050, "detailed", 12, "2026-11-02T21:21:26", 432169, "14e64f9b80f1e1012413f564e11d90adb36cfc17f645bdf44e610778ec9244ae"],
	"espoo_ring1600": [60.1760, 24.8050, "ring1600", 1, "2026-11-02T21:21:26", 43320, "5e828444e18cfecbe9585bc99c9123b4db738140a56c42a72e1ed7b4119f49aa"],
	"espoo_ring2500": [60.1760, 24.8050, "ring2500", 1, "2026-11-02T21:21:26", 69333, "e612a0f4373325f3ba96eabaf10e0f43bfb2ca4ff36f4b6b6e4dca54183db1eb"],
	"espoo_poi": [60.1760, 24.8050, "poi", 1, "2026-11-02T21:21:26", 44430, "bfcab2c04c6a28fc0d42ce5cec46c67c3bd7dd042730cff9e2269d63f645036d"],
	"espoo_far": [60.1760, 24.8050, "far", 3, "2026-11-02T21:21:26", 980070, "268d8c41b587625ffbdc5966e4e7137db3764120e693620a5eacb130a3d38144"],
	"san_francisco_far": [37.8040, -122.4195, "far", 3, "2026-11-02T21:21:26", 333309, "41ff7971b62e7deaaab4a133ae818c834d7f5c000b5ca29d33384210b6b83ff9"],
	"new_york_far": [40.7060, -74.0040, "far", 3, "2026-10-31T00:00:00", 2147928, "35ab67acc7134d9cd42dea4684717df2a61c9ec9db54c29303a6c1b2053f638e"],
	"new_york_ring1600": [40.7060, -74.0040, "ring1600", 1, "2026-10-31T00:00:00", 62488, "fd2a796b0235e84ddb18140fe65cf3d3aadefd2a7feaa51da54e911bb1e91d5d"],
	"new_york_ring2500": [40.7060, -74.0040, "ring2500", 1, "2026-10-31T00:00:00", 77288, "54817dc1d33d8b2540edc19e372833badb2d7b5f9efb5d597ec5dddfd46ee4e4"],
	"new_york_poi": [40.7060, -74.0040, "poi", 1, "2026-10-31T00:00:00", 109267, "970c39b7024cc47ae58d03731a803999d1ea358be993f75af0443a6b05938fab"],
	"san_francisco_ring1600": [37.8040, -122.4195, "ring1600", 1, "2026-10-31T00:00:00", 30856, "56623789a4d46a85b05e60e779804f0a9d8b665093349d08591113b14366d40c"],
	"san_francisco_ring2500": [37.8040, -122.4195, "ring2500", 1, "2026-10-31T00:00:00", 55769, "6238c21dd99ca7752f1547910d03b92bd60392fd908e6023598bc1a493daec91"],
	"san_francisco_poi": [37.8040, -122.4195, "poi", 1, "2026-10-31T00:00:00", 42597, "5faadbf2190a8611408d8e285d8eab043ea6717babc445dfe998bb01c3d8f319"],
	"helsinki_detailed": [60.1680, 24.9530, "detailed", 12, "2026-11-02T21:21:26", 904907, "644de8f58ccd030a01831c9b64d662dfbb9b2c01aaddd541e38962374fef3763"],
	"helsinki_ring1600": [60.1680, 24.9530, "ring1600", 1, "2026-11-02T21:21:26", 75432, "9869ca4f32355ab651563d60d796a5488d30e55752d10b4476bea12b716a7379"],
	"helsinki_ring2500": [60.1680, 24.9530, "ring2500", 1, "2026-11-02T21:21:26", 90763, "aaee38fffe39f6c4b255e06c6dca73c5c517748c796024c0e0ea013f967a8f18"],
	"helsinki_poi": [60.1680, 24.9530, "poi", 1, "2026-11-02T21:21:26", 201179, "beb8630e11dbab8885d60f6c7dd57d43ccfffc7caa114b0a341189c0336d9b5f"],
	"stockholm_detailed": [59.3207, 18.0604, "detailed", 12, "2026-11-02T21:21:26", 809621, "48aac17268c733c8a627c42555ff75536ff42abf9b3281897460fbb7534093c2"],
	"stockholm_ring1600": [59.3207, 18.0604, "ring1600", 1, "2026-11-02T21:21:26", 44988, "81aa95e400633dfe2ccb2877f40780c10839fbbe8ae794e1e73beb60d96aff99"],
	"stockholm_ring2500": [59.3207, 18.0604, "ring2500", 1, "2026-11-02T21:21:26", 58735, "d982598052d8f9050b17713162df48a8ee459e355c8a2a9c00a052c0080f2c17"],
	"stockholm_poi": [59.3207, 18.0604, "poi", 1, "2026-11-02T21:21:26", 126022, "95c4619704d679769794e1c3842024e5ea00bdaeda8915c2fc9eca6521f0b653"],
	"new_york_midtown_detailed": [40.7535, -73.9825, "detailed", 12, "2026-07-28T02:16:18", 1019646, "a676594225cdad71c1e306ad3477f36e9773692e4534b5dc2b3171b60e7d7d45"],
	"new_york_midtown_ring1600": [40.7535, -73.9825, "ring1600", 1, "2026-07-24T11:04:51", 58754, "272cca77b3241a20d1ffb481c2d7dda425e823412c59f7d21622f81ddd58b3ff"],
	"new_york_midtown_ring2500": [40.7535, -73.9825, "ring2500", 1, "2026-05-31T22:37:44", 68560, "39edbc0c25aac064946757d3bd90f3e15e6f4bc6deb184fa88acc38605716f67"],
	"new_york_midtown_poi": [40.7535, -73.9825, "poi", 1, "2026-07-15T15:22:01", 241985, "ff363e709b2b4e3e6644ce8285735723ab178b145df956452e69ccae8e75d9ef"],
	"new_york_midtown_far": [40.7535, -73.9825, "far", 3, "2026-07-24T11:04:51", 2382759, "1dfea6e84f8e454c4379e468891d339b56b1d24a9b05a47eff49abf25cfb791c"],
	"new_york_detailed": [40.7060, -74.0040, "detailed", 12, "2026-11-04T13:18:25", 989856, "ec4fc929d9042d021cfeb6526faf46c0d005573fa3a4c911178a8406c7b2b572"],
	"san_francisco_detailed": [37.8040, -122.4195, "detailed", 12, "2026-11-04T13:16:20", 547474, "5ae41a800c74caba66f832d95db065ddb8c836bd9929538147050d1a756a8239"],
	"helsinki_far": [60.1680, 24.9530, "far", 3, "2026-11-04T14:47:51", 993371, "45cca9dd990624b02fd6ea9cde286627206b10f9342be7fb398f2fc4debb4b3c"],
	"stockholm_far": [59.3207, 18.0604, "far", 3, "2026-11-04T14:07:04", 850088, "c87c4f686b2e3034de4aec0f15ccad69092ac8591dbdf8f24f77c90003c6fb93"],
	"helsinki_transit": [60.1680, 24.9530, "transit", 1, "2026-11-11T00:49:59", 25588, "ed4fb956c1474ff4833c989f38c354959e9bec8378e1cfb379593fa94de13666"],
	"berlin_transit": [52.5244, 13.4105, "transit", 1, "2026-11-11T00:50:42", 17428, "c48d9c453d986f2e1d68ec7958298fb90bf10aeca4190cacfd72fcb166989e71"],
	"tokyo_transit": [35.6595, 139.7005, "transit", 1, "2026-11-11T00:51:14", 13792, "396dd489c344f556fb9b006acc19265e4a50548e3fa1c25d3c3cb595134395b2"],
	"london_transit": [51.5018, -0.1196, "transit", 1, "2026-11-11T00:51:49", 26375, "2e4fc735a40d76b9a7b3107e7170ef5104ec7643ecb455b917fb3a35119bc738"],
	"dubai_transit": [25.1925, 55.2741, "transit", 1, "2026-11-11T00:52:18", 2923, "ac1f4b3ae2cec0a9d7103f223b12fdcd44e6d733e98848ade39c0ae95e5b6436"],
	"banff_transit": [51.1720, -115.5640, "transit", 1, "2026-11-11T00:52:46", 2397, "4e13b6539a36434a96c986489edff5a3af0c7d80608e01f5e24429f331dff9b4"],
	"big_sur_transit": [36.3740, -121.9022, "transit", 1, "2026-11-11T00:53:12", 450, "a560bdfff0b2ac7e0d920a731b6024237b40a8b3eee9d8dff4aa630054d29aca"],
	"seoul_transit": [37.5728, 126.9769, "transit", 1, "2026-11-11T00:53:45", 13445, "df8e950dd348ee5adbaaa08c557293fbba31c48e77b44b2d1a1b41ceb51a9c17"],
	"alps_transit": [46.6900, 7.8580, "transit", 1, "2026-11-11T00:54:16", 2801, "e19b8affdf1705666e81fd8033f0d261f33f4268559a32445f79df85fe068b07"],
	"rome_transit": [41.8916, 12.4916, "transit", 1, "2026-11-11T00:54:53", 10569, "4bcf354f19da31c5a0a05c2f49b50316e2515286607ff4217d83d0831f170bf9"],
	"venice_transit": [45.4318, 12.3290, "transit", 1, "2026-11-11T00:55:28", 1368, "c0aa70c2bd75bfbc5901a82268ce866f73d25deae589c3a78fe8ecf1e628ce2b"],
	"paris_transit": [48.8622, 2.2887, "transit", 1, "2026-11-11T01:12:05", 15946, "c35960eb6e3443afb7282967ceaedd8580faf2268e2404db01ddb6914576f133"],
	"monaco_transit": [43.7310, 7.4209, "transit", 1, "2026-11-11T01:13:29", 6488, "da4f59df123b52188e4e21d12c10fc2632bbcba68e899d02fc8c213fe5f889ec"],
	"espoo_transit": [60.1760, 24.8050, "transit", 1, "2026-11-11T01:14:56", 9402, "39d6a20ff2362e424e3490c0efefec68d867cc758d7480ce7cbfbf3b65fe728f"],
	"stockholm_transit": [59.3207, 18.0604, "transit", 1, "2026-11-11T01:16:23", 10048, "40a809789054549ee6e293f04b0f422a661dc7b0b761a430da32dfe1e513aee0"],
	"new_york_midtown_transit": [40.7535, -73.9825, "transit", 1, "2026-11-11T01:17:52", 30357, "b1aebd1df13347061f552d7a8917d61ef773bbf26e774b0f7a40cc30a1dd2622"],
	"new_york_transit": [40.7060, -74.0040, "transit", 1, "2026-11-11T01:19:20", 19892, "a6900c9599b88b64809c7f0f161ccf93e8d1855c81f124869c8d6981d79467ea"],
	"san_francisco_transit": [37.8040, -122.4195, "transit", 1, "2026-11-11T01:20:47", 14934, "34b6392d53ce3cca09a5f2c437067ff4100a03d8ee12ea5f98a1715b98341c3e"],
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

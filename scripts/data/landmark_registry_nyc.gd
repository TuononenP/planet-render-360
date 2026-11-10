class_name LandmarkRegistryNyc
extends RefCounted

## New York's skyscrapers on the SkyKit. Positions and yaw_deg are the
## centroid and long axis of each building's OSM outline, read from the
## bundled snapshots; height_m is Wikidata's height (P2048) unless noted.
## clear_m is half the plan's diagonal plus 8 m, less where a tall neighbour
## stands closer (nyc_skyscraper_sites_test). skyline_priority keeps the
## crowns that define each view inside the Fast and Balanced landmark caps.

static func _row(type: String, name: String, lat: float, lon: float, height: float, yaw: float, clear: float,
		wiki: String, radius: float, priority: int, aliases: Array) -> Dictionary:
	return {"type": type, "name": name, "lat": lat, "lon": lon, "radius_m": radius, "wiki_title": wiki,
		"height_m": height, "clear_m": clear, "yaw_deg": yaw, "kind": "Skyscraper",
		"skyline_priority": priority, "aliases": aliases}

static func entries() -> Array:
	return [
		_row("woolworth_building", "Woolworth Building", 40.712471, -74.008358, 241.0, 31.5, 44.0, "Woolworth Building", 6500.0, 2, ["woolworth building"]),
		_row("forty_wall_street", "40 Wall Street", 40.707007, -74.009732, 284.0, 38.1, 54.0, "40 Wall Street", 6500.0, 2, ["40 wall street", "trump building"]),
		_row("seventy_pine", "70 Pine Street", 40.706572, -74.0079, 290.2, 39.4, 52.0, "70 Pine Street", 6500.0, 2, ["70 pine street", "cities service building"]),
		_row("eight_spruce", "8 Spruce Street", 40.710928, -74.005612, 271.0, 51.1, 49.0, "8 Spruce Street", 3500.0, 2, ["8 spruce street", "new york by gehry"]),
		_row("thirty_park_place", "30 Park Place", 40.712829, -74.009177, 286.0, -59.2, 37.0, "30 Park Place", 3500.0, 1, ["30 park place", "four seasons downtown"]),
		_row("three_wtc", "3 World Trade Center", 40.711019, -74.011709, 352.0, 26.9, 44.0, "3 World Trade Center", 6500.0, 2, ["3 world trade center", "three world trade"]),
		_row("seven_wtc", "7 World Trade Center", 40.713335, -74.01202, 227.0, -79.1, 48.0, "7 World Trade Center", 3500.0, 1, ["7 world trade center", "seven world trade"]),
		_row("municipal_building", "Manhattan Municipal Building", 40.712922, -74.003649, 181.0, -54.1, 73.0, "Manhattan Municipal Building", 6500.0, 2, ["municipal building", "david dinkins building"]),
		_row("one_liberty_plaza", "One Liberty Plaza", 40.709732, -74.010862, 226.0, 30.4, 51.0, "One Liberty Plaza", 3500.0, 1, ["one liberty plaza"]),
		_row("twenty_eight_liberty", "28 Liberty Street", 40.707854, -74.008985, 247.8, 40.3, 54.0, "28 Liberty Street", 3500.0, 1, ["28 liberty street", "one chase manhattan plaza"]),
		_row("one_forty_broadway", "140 Broadway", 40.708545, -74.010011, 209.7, 37.0, 44.0, "140 Broadway", 3500.0, 1, ["140 broadway", "marine midland building"]),
		_row("fifty_six_leonard", "56 Leonard Street", 40.717603, -74.006289, 250.2, 30.9, 35.0, "56 Leonard Street", 3500.0, 1, ["56 leonard street", "jenga building"]),
		_row("one_vanderbilt", "One Vanderbilt", 40.752921, -73.978547, 427.0, 28.3, 52.0, "One Vanderbilt", 6500.0, 2, ["one vanderbilt"]),
		_row("bank_of_america_tower", "Bank of America Tower", 40.755615, -73.984914, 365.8, 29.1, 76.0, "Bank of America Tower (Manhattan)", 6500.0, 2, ["bank of america tower"]),
		_row("metlife_building", "MetLife Building", 40.753476, -73.97673, 246.0, -61.0, 79.0, "MetLife Building", 3500.0, 1, ["metlife building", "pan am building"]),
		_row("thirty_rockefeller", "30 Rockefeller Plaza", 40.759147, -73.97965, 259.0, 29.3, 94.0, "30 Rockefeller Plaza", 6500.0, 2, ["30 rockefeller plaza", "comcast building"]),
		_row("two_seventy_park", "270 Park Avenue", 40.75598, -73.975987, 423.1, 28.8, 62.0, "270 Park Avenue", 6500.0, 1, ["270 park avenue", "jpmorgan chase tower"]),
		_row("four_thirty_two_park", "432 Park Avenue", 40.761702, -73.971945, 425.5, -61.4, 37.0, "432 Park Avenue", 6500.0, 2, ["432 park avenue"]),
		_row("central_park_tower", "Central Park Tower", 40.766427, -73.980925, 472.4, -61.1, 50.0, "Central Park Tower", 6500.0, 2, ["central park tower", "nordstrom tower"]),
		_row("thirty_hudson_yards", "30 Hudson Yards", 40.753948, -74.000453, 395.0, 28.7, 66.0, "30 Hudson Yards", 6500.0, 2, ["30 hudson yards", "edge observation deck"]),
		_row("metlife_tower", "Metropolitan Life Insurance Company Tower", 40.740911, -73.987027, 213.0, 28.9, 56.0, "Metropolitan Life Insurance Company Tower", 3500.0, 1, ["metlife tower", "met life tower", "metropolitan life insurance"]),
		# Height and footprint from OSM ways 164105516 and 258744609.
		_row("citigroup_center", "Citigroup Center", 40.758424, -73.970265, 279.0, 29.4, 43.0, "Citigroup Center", 3500.0, 1, ["citigroup center", "citicorp center", "601 lexington avenue"]),
	]

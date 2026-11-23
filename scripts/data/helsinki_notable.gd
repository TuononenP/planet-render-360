class_name HelsinkiNotable
extends RefCounted

## Well-known central Helsinki buildings that have no hand-built landmark
## model: their real facade finish, colour, roof and storeys, keyed by OSM
## identity, so the district roll cannot turn the Pohjola soapstone, the
## Lundqvist red-brick palace or Katajanokka customs warehouses into random
## pastel blocks. Values fill only what the map leaves out
## (BuildingReferences.fill) and run inside OsmParser before the city
## register, so a mapped tag still wins and the curated row beats the
## register's coded guess. Each row names its source.

const PROVENANCE := "hel_notable"

## "way:<id>" or "relation:<id>" -> {name, source, values: {material, colour,
## roof_material, roof_colour, levels, start_year, ...}}.
const ROWS := {
	"way:17425472": {
		"name": "Pohjola Insurance building (Pohjolan toimitalo)",
		# Aleksanterinkatu 44, 1899-1901, Gesellius-Lindgren-Saarinen: rough-hewn
		# granite and soapstone, grey-green, the first National Romantic stone front.
		"source": "https://en.wikipedia.org/wiki/Pohjola_Insurance_building",
		"values": {"material": "stone", "colour": "#9a9d94", "roof_material": "metal", "roof_colour": "#466357", "start_year": 1901},
	},
	"way:123550797": {
		"name": "Stock Exchange building (Pörssitalo)",
		# Fabianinkatu 14, Lars Sonck, 1911-12: grey granite front.
		"source": "https://fi.wikipedia.org/wiki/P%C3%B6rssitalo_(Helsinki)",
		"values": {"material": "stone", "colour": "#918f8a", "roof_material": "metal", "roof_colour": "#3e4448", "start_year": 1912},
	},
	"way:224711434": {
		"name": "New Student House (Uusi ylioppilastalo)",
		# Mannerheimintie 5, Lindgren and Lönn, 1910: soapstone front, dark grey-green.
		"source": "https://en.wikipedia.org/wiki/New_Student_House,_Helsinki",
		"values": {"material": "stone", "colour": "#858c84", "roof_material": "metal", "roof_colour": "#456154", "start_year": 1910},
	},
	"way:122595243": {
		"name": "Old Student House (Vanha ylioppilastalo)",
		# Mannerheimintie 3, Hampus Dalström, 1870: pale yellow-cream Neo-Renaissance render.
		"source": "https://en.wikipedia.org/wiki/Old_Student_House,_Helsinki",
		"values": {"material": "render", "colour": "#e6dec8", "roof_material": "metal", "roof_colour": "#3f4648", "start_year": 1870},
	},
	"relation:12202211": {
		"name": "Lundqvist Commercial Building (Lundqvistin liiketalo)",
		# Aleksanterinkatu 13, Selim A. Lindqvist, 1900: red brick and carved stone pilasters.
		"source": "https://fi.wikipedia.org/wiki/Lundqvistin_liiketalo",
		"values": {"material": "brick", "colour": "#9a4f3b", "roof_material": "metal", "roof_colour": "#4c665a", "start_year": 1900},
	},
	"way:123551419": {
		"name": "Wuorio Building (Wuorion talo)",
		# Unioninkatu 30, Gesellius-Lindgren-Saarinen / Armas Lindgren, 1914: grey-beige stone/render.
		"source": "https://fi.wikipedia.org/wiki/Wuorion_talo",
		"values": {"material": "stone", "colour": "#b5afa4", "roof_material": "metal", "roof_colour": "#3e4348", "start_year": 1914},
	},
	"way:89532596": {
		"name": "Tallberg House (Tallbergin talo)",
		# Aleksanterinkatu 21, Elia Heikel & S. Michailoff, 1899: pale grey-buff stone & render.
		"source": "https://fi.wikipedia.org/wiki/Tallbergin_talo",
		"values": {"material": "stone", "colour": "#c6bfb2", "roof_material": "metal", "roof_colour": "#42474c", "start_year": 1899},
	},
	"way:122595279": {
		"name": "Central Building (Centralin talo)",
		# Aleksanterinkatu 46, Theodor Höijer, 1893: warm ochre Neo-Renaissance render.
		"source": "https://commons.wikimedia.org/wiki/Category:Aleksanterinkatu_46,_Helsinki",
		"values": {"material": "render", "colour": "#d4b483", "roof_material": "metal", "roof_colour": "#3d4246", "start_year": 1893},
	},
	"way:17341306": {
		"name": "Grönqvist House (Grönqvistin talo)",
		# Pohjoisesplanadi 25-27, Theodor Höijer, 1882: warm sandstone-ochre Neo-Renaissance render.
		"source": "https://fi.wikipedia.org/wiki/Gr%C3%B6nqvistin_talo",
		"values": {"material": "render", "colour": "#d8be8f", "roof_material": "metal", "roof_colour": "#3c4146", "start_year": 1882},
	},
	"way:123550176": {
		"name": "Merkurius Business Palace (Merkuriuksen liikepalatsi)",
		# Pohjoisesplanadi 33, Selim A. Lindqvist & Elia Heikel, 1890: warm terracotta brick & stone.
		"source": "https://fi.wikipedia.org/wiki/Merkuriuksen_liikepalatsi",
		"values": {"material": "brick", "colour": "#b87a5e", "roof_material": "metal", "roof_colour": "#454a4f", "start_year": 1890},
	},
	"way:122595282": {
		"name": "Wrede House (Wreden talo)",
		# Pohjoisesplanadi 35, K. A. Wrede, 1892: warm buff Neo-Renaissance render.
		"source": "https://fi.wikipedia.org/wiki/Wreden_talo",
		"values": {"material": "render", "colour": "#d8c49a", "roof_material": "metal", "roof_colour": "#43484c", "start_year": 1892},
	},
	"way:675858725": {
		"name": "Hermes House (Hermeksen talo)",
		# Aleksanterinkatu 19, Grahn-Hedman-Wasastjerna, 1898: pale sandstone-grey stone facade.
		"source": "https://commons.wikimedia.org/wiki/Category:Aleksanterinkatu_19,_Helsinki",
		"values": {"material": "stone", "colour": "#c4bdb0", "roof_material": "metal", "roof_colour": "#44494e", "start_year": 1898},
	},
	"relation:3839333": {
		"name": "World Trade Center Helsinki (former Liittopankki)",
		# Aleksanterinkatu 17, Pauli E. Blomstedt, 1929: pale travertine/stone Classicist palace.
		"source": "https://en.wikipedia.org/wiki/World_Trade_Center_(Helsinki)",
		"values": {"material": "stone", "colour": "#cfc8ba", "roof_material": "metal", "roof_colour": "#4e6a5e", "start_year": 1929},
	},
	"relation:1689811": {
		"name": "Fazer Commercial Building (Fazerin liiketalo)",
		# Kluuvikatu 3, Gösta Juslén, 1930: pale cream functionalist render.
		"source": "https://fi.wikipedia.org/wiki/Fazerin_liiketalo",
		"values": {"material": "render", "colour": "#dcd6c8", "roof_material": "metal", "roof_colour": "#45494e", "start_year": 1930},
	},
	"way:22957630": {
		"name": "Scandic Grand Marina (Satamamakasiini K5)",
		# Katajanokanlaituri 7, Selim A. Lindqvist, 1913: red-brown brick customs warehouse.
		"source": "https://commons.wikimedia.org/wiki/Category:Scandic_Grand_Marina,_Helsinki",
		"values": {"material": "brick", "colour": "#94483a", "roof_material": "metal", "roof_colour": "#3d4247", "start_year": 1913},
	},
	"way:23192801": {
		"name": "Old Customs and Packing House Katajanokka (Vanha tulli- ja pakkahuone)",
		# Katajanokanlaituri 5, Gustaf Nyström, 1901: red brick harbour customs hall.
		"source": "https://fi.wikipedia.org/wiki/Vanha_tulli-_ja_pakkahuone",
		"values": {"material": "brick", "colour": "#964a3a", "roof_material": "metal", "roof_colour": "#3b4045", "start_year": 1901},
	},
	"way:22957633": {
		"name": "Wanha Satama (Katajanokka Harbour Warehouse K12)",
		# Pikku Satamakatu 3-5, 1897: dark red brick harbour warehouse.
		"source": "https://en.wikipedia.org/wiki/Wanha_Satama",
		"values": {"material": "brick", "colour": "#914a3c", "roof_material": "metal", "roof_colour": "#3c4146", "start_year": 1897},
	},
	"relation:1689462": {
		"name": "Asunto-osakeyhtiö Panu (Katajanokka)",
		# Luotsikatu 8, Georg Wasastjerna & K. V. Polón, 1903: warm cream-ochre Jugend render.
		"source": "https://commons.wikimedia.org/wiki/Category:Luotsikatu_8,_Helsinki",
		"values": {"material": "render", "colour": "#ddd0b2", "roof_material": "metal", "roof_colour": "#4c665a", "start_year": 1903},
	},
	"way:22569124": {
		"name": "Marble Palace (Marmoripalatsi, Kaivopuisto)",
		# Itäinen Puistotie 1, Eliel Saarinen, 1918: white marble/stone facade.
		"source": "https://fi.wikipedia.org/wiki/Marmoripalatsi_(Helsinki)",
		"values": {"material": "stone", "colour": "#e6e2d8", "roof_material": "metal", "roof_colour": "#3c4246", "start_year": 1918},
	},
	"way:22563324": {
		"name": "Embassy of Estonia (Viron suurlähetystö, Kaivopuisto)",
		# Itäinen Puistotie 10, Konstantin Bölau, 1933: white functionalist render.
		"source": "https://fi.wikipedia.org/wiki/Viron_Helsingin-suurl%C3%A4hetyst%C3%B6",
		"values": {"material": "render", "colour": "#ebe7de", "roof_material": "metal", "roof_colour": "#44484d", "start_year": 1933},
	},
	"way:22563343": {
		"name": "Embassy of Italy (Italian suurlähetystö, Kaivopuisto)",
		# Itäinen Puistotie 4, Karl Lindahl, 1924: pale ochre-cream Neo-Classical villa.
		"source": "https://commons.wikimedia.org/wiki/Category:Embassy_of_Italy,_Helsinki",
		"values": {"material": "render", "colour": "#e2d4ad", "roof_material": "metal", "roof_colour": "#42474b", "start_year": 1924},
	},
	"way:22904621": {
		"name": "Merihaka Hakaniemenranta 12 Slab",
		# Hakaniemenranta 12, Merihaka, 1974: brutalist grey precast concrete residential slab.
		"source": "https://en.wikipedia.org/wiki/Merihaka",
		"values": {"material": "concrete", "colour": "#b5b3ac", "roof_material": "metal", "roof_colour": "#4c5054", "start_year": 1974},
	},
	"way:123921809": {
		"name": "Supreme Administrative Court (Korkein hallinto-oikeus)",
		# Fabianinkatu 15, Onni Tarjanne, 1905: warm ochre-yellow Jugend render.
		"source": "https://en.wikipedia.org/wiki/Supreme_Administrative_Court_of_Finland",
		"values": {"material": "render", "colour": "#ddd0a8", "roof_material": "metal", "roof_colour": "#476256", "start_year": 1905},
	},
	"way:22463157": {
		"name": "Rikhardinkatu Library (Rikhardinkadun kirjasto)",
		# Rikhardinkatu 3, Theodor Höijer, 1881: warm cream-ochre Neo-Renaissance render.
		"source": "https://fi.wikipedia.org/wiki/Rikhardinkadun_kirjasto",
		"values": {"material": "render", "colour": "#dfd0a6", "roof_material": "metal", "roof_colour": "#3f4448", "start_year": 1881},
	},
	"way:122885437": {
		"name": "Hankkija Building (Hankkijan talo)",
		# Salomonkatu 1 / Arkadiankatu 2, Jarl Eklund, 1913: dark red-brown brick.
		"source": "https://fi.wikipedia.org/wiki/Hankkijan_talo",
		"values": {"material": "brick", "colour": "#8e4a3b", "roof_material": "metal", "roof_colour": "#44494e", "start_year": 1913},
	},
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

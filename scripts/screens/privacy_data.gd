class_name PrivacyData
extends RefCounted

## What the Privacy page (Settings → Privacy) says: the same policy as
## site/privacy.html, word for word where it can be. tests/privacy_page_test.gd
## keeps the two in step, so a service added to one has to reach the other
## (and tests/store_readiness_test.gd checks the web page names every host the
## code contacts).

const UPDATED := "8 Nov 2026"
const LEDE := "Planet Render 360 has no account, no advertising and no analytics. It does not ask for your location. What you look at stays on your device."
const BODY := "To build a place, the app asks public data services for the map, terrain, imagery and weather around it. Those services see your IP address and the place you asked for. The developer receives none of this."

## [figure, caption]
const GLANCE := [
	["0", "accounts or sign-ins"],
	["0", "ads, analytics or trackers"],
	["0", "servers run by the developer"],
	["0", "requests once a place is saved for offline"],
]

const ON_DEVICE := [
	"Recent places, favourites and the camera position you left each place at.",
	"Your settings, such as theme, units and quality.",
	"Downloaded map, terrain, imagery and building data, and scenes the app has already built, so places open faster next time.",
	"Photos you save. They go to your Pictures folder, the app’s own photos folder, or the place you choose on a computer.",
]
const ON_DEVICE_NOTE := "The app reads the motion sensor to turn the view when you use gyro look-around. It does not store or send those readings."

const LEAVES_NOTE := "The app contacts only the services below, and only to answer something you did. Each one also sees your IP address and the app’s name, planet-render-360."

## [name, [hosts], what it receives]
const SERVICES := [
	["OpenStreetMap place search", ["nominatim.openstreetmap.org"],
		"The text you search for, only when you submit it. Typing alone sends nothing."],
	["OpenStreetMap map tiles", ["tile.openstreetmap.org"],
		"The tiles for the part of the globe you are viewing."],
	["OpenFreeMap vector tiles", ["tiles.openfreemap.org"],
		"The tiles for the part of the map you are viewing."],
	["Overpass API servers, for buildings, roads and shores",
		["overpass-api.de", "z.overpass-api.de", "overpass.private.coffee", "postpass.geofabrik.de",
			"api.openstreetmap.org"],
		"The area around the place you open. If one server does not answer, the app asks the next, so any of them may receive it. Different parties run them. The app never uses servers in Russia."],
	["Esri imagery", ["server.arcgisonline.com"],
		"The satellite image tiles for the place you open."],
	["AWS Terrain Tiles", ["s3.amazonaws.com"],
		"The elevation tiles for the place you open."],
	["Land cover and tree height",
		["esa-worldcover.s3.eu-central-1.amazonaws.com", "dataforgood-fb-data.s3.amazonaws.com"],
		"The data tiles for the place you open."],
	["CHELSA climate", ["os.zhdk.cloud.switch.ch"],
		"A request for the climate data that covers the place you open."],
	["Open-Meteo weather", ["api.open-meteo.com", "archive-api.open-meteo.com"],
		"The coordinates of the place you open, to 4 decimals."],
	["Wikipedia and Wikimedia Commons", ["wikipedia.org", "commons.wikimedia.org"],
		"The landmark’s name or article, when you open its details."],
	["This project’s pages", ["tuononenp.github.io"],
		"A request for a small settings file at launch. It lists service addresses so they can change without an app update. GitHub hosts it and sees your IP address."],
]
const SERVICES_NOTE := "Each service keeps its own records under its own policy. The links are on the privacy page online."

const NEVER := [
	"No accounts, sign-in or profiles.",
	"No advertising, analytics, crash reporting or tracking identifiers.",
	"No access to your location, contacts, camera, microphone or photo library.",
	"No sale or sharing of data. The developer runs no server for the app.",
]

const CHOICES := [
	"Remove places from History, or clear them all.",
	"Clear the downloaded data under Settings → Storage.",
	"Save a place for offline, then use the app with no connection and no requests.",
	"Uninstall the app to remove everything it stored. Photos you saved stay where you put them.",
]

const CHILDREN := "The app is not aimed at children, and it collects no personal information from anyone."
const CONTACT := "Questions go to the issue tracker on GitHub. The app is published by Petri Tuononen."

## Every host the page names, once each.
static func hosts() -> Array[String]:
	var out: Array[String] = []
	for service in SERVICES:
		for host in service[1]:
			if not out.has(host):
				out.append(host)
	return out

## The settings row's one-line summary.
static func summary() -> String:
	return "No account · %d public services" % SERVICES.size()

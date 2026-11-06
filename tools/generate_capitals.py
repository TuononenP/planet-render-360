#!/usr/bin/env python3
"""Generate the capital catalog from GeoNames countryInfo and cities1000.

Download both files from https://download.geonames.org/export/dump/. The
GeoNames data is CC BY 4.0; retain the attribution in Settings/Data sources.
"""
import argparse
import json
import unicodedata
import zipfile
from collections import defaultdict
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("country_info", type=Path)
parser.add_argument("cities_zip", type=Path)
parser.add_argument("output", type=Path)
args = parser.parse_args()


def normalize(text):
    return "".join(c for c in unicodedata.normalize("NFKD", text.casefold()) if c.isalnum())


countries = [line.rstrip("\n").split("\t") for line in args.country_info.read_text(encoding="utf-8").splitlines()
             if line and not line.startswith("#")]
by_country = defaultdict(list)
with zipfile.ZipFile(args.cities_zip) as archive:
    with archive.open("cities1000.txt") as source:
        for line in source:
            row = line.decode("utf-8").rstrip("\n").split("\t")
            if len(row) > 14:
                by_country[row[8]].append(row)


def find(code, name):
    wanted = normalize(name)
    candidates = [row for row in by_country[code]
                  if wanted in {normalize(n) for n in [row[1], row[2], *row[3].split(",")] }]
    if not candidates:
        raise SystemExit(f"Missing capital coordinates: {code} {name}")
    return max(candidates, key=lambda row: (row[7] == "PPLC", int(row[14] or 0)))


rows = []
for country in countries:
    code, country_name, capital = country[0], country[4].strip(), country[5].strip()
    # Historical GeoNames codes do not represent present countries/territories.
    if code in {"CS", "AN"} or not capital:
        continue
    # GeoNames countryInfo lists the Palau state; its PPLC is Ngerulmud.
    if code == "PW":
        capital = "Ngerulmud"
    # Sri Lanka's administrative capital; GeoNames lists Colombo.
    if code == "LK":
        capital = "Sri Jayewardenepura Kotte"
    city = find(code, capital)
    rows.append([code, capital, country_name, float(city[4]), float(city[5])])

# Countries with more than one recognized capital/seat of government.
for code, city_name, country_name in [
    ("ZA", "Cape Town", "South Africa"), ("ZA", "Bloemfontein", "South Africa"),
    ("BO", "La Paz", "Bolivia"), ("SZ", "Lobamba", "Eswatini"),
]:
    city = find(code, city_name)
    rows.append([code, city_name, country_name, float(city[4]), float(city[5])])
# GeoNames points 2-5 km from the centre, where the 1.2 km detailed view and
# 800 m POI layer would miss the city. These use the OSM place node (via
# Nominatim, 2026-11-06; © OpenStreetMap contributors, ODbL). Nay Pyi Taw keeps
# its GeoNames point: its OSM place node is in the near-empty ministry zone.
CENTRE_CORRECTIONS = {
    ("TJ", "Dushanbe"): (38.5767, 68.78543),
    ("SR", "Paramaribo"): (5.82476, -55.17039),
    ("BR", "Brasilia"): (-15.79399, -47.8828),
    ("CF", "Bangui"): (4.36351, 18.58359),
    ("TN", "Tunis"): (36.80021, 10.18578),
    ("SZ", "Lobamba"): (-26.44628, 31.20838),
    ("LC", "Castries"): (14.0096, -60.99024),
    ("LR", "Monrovia"): (6.32036, -10.80605),
}
for row in rows:
    corrected = CENTRE_CORRECTIONS.get((row[0], row[1]))
    if corrected:
        row[3], row[4] = corrected
missing = set(CENTRE_CORRECTIONS) - {(row[0], row[1]) for row in rows}
if missing:
    raise SystemExit(f"Centre corrections without a catalog row: {sorted(missing)}")
rows.sort(key=lambda row: (normalize(row[1]), normalize(row[2])))

header = '''class_name CapitalCatalog
extends RefCounted

## Country/territory capital locations from GeoNames countryInfo and
## cities1000 (CC BY 4.0). See docs/data-source-register.md for the source,
## attribution and the additional multi-capital entries.
## Rows are [country code, city, country or territory, latitude, longitude].
const ROWS := [
'''
with args.output.open("w", encoding="utf-8") as out:
    out.write(header)
    for row in rows:
        out.write("\t" + json.dumps(row, ensure_ascii=False) + ",\n")
    out.write(''']

## Existing curated views already supply these national capitals.
const CURATED := ["FR", "GB", "IT", "JP", "KR", "FI", "SE", "MC"]

static func additional_places() -> Array:
	var out: Array = []
	for row in ROWS:
		if str(row[0]) in CURATED:
			continue
		out.append({"name": "%s, %s" % [row[1], row[2]], "label": str(row[1]),
			"lat": float(row[3]), "lon": float(row[4])})
	return out
''')
print(f"Generated {len(rows)} capital/territory locations")

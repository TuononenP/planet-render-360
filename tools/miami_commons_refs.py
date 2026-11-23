#!/usr/bin/env python3
"""Fetch licence-checked Wikimedia Commons reference photos for Miami (MI-0.6).

  python3 -I tools/miami_commons_refs.py [--city] [--landmarks] [--only=t1,t2] [--dry] [--force]

Only commons.wikimedia.org / upload.wikimedia.org are contacted (HostPolicy).
Saves 1280 px JPEGs (gitignored) and README.md (tracked) with URL, author,
and licence for:
  - visual-plan/refs/miami/ (18 open-space city views matching PLAN_Miami_super_realistic.md)
  - visual-plan/refs/landmarks/<type>/ (3+ views for every Tier 1 Miami landmark)
"""
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_CITY = f"{ROOT}/visual-plan/refs/miami"
OUT_LM = f"{ROOT}/visual-plan/refs/landmarks"
API = "https://commons.wikimedia.org/w/api.php"
UA = "PlanetRender360/1.0 (https://github.com/TuononenP/planet-render-360; Miami CC/PD reference fetch)"
THUMB_W = 1280
MIN_W = 900

CITY_VIEWS = [
    ("01_A1_bayfront_north", "A1 Bayfront Park lawn looking north to Kaseya Center, One Thousand Museum & Park West wall",
     ["Bayfront Park Miami Kaseya Center", "American Airlines Arena Bayfront Park", "Park West skyline Bayfront Park Miami"]),
    ("02_A2_bayfront_downtown", "A2 Bayfront Park lawn looking west to Southeast Financial Center, Miami Tower & 50 Biscayne",
     ["Bayfront Park Downtown Miami skyline", "Southeast Financial Center Miami Tower Bayfront", "Downtown Miami from Bayfront Park"]),
    ("03_A3_bay_skyline", "A3 Biscayne Bay off Bayfront looking west at whole Downtown Miami wall, wheel & InterContinental",
     ["Downtown Miami skyline Biscayne Bay", "Miami skyline from Biscayne Bay", "InterContinental Miami Bayfront skyline"]),
    ("04_A4_museum_park", "A4 Maurice A. Ferré (Museum) Park baywalk toward PAMM, Frost Science sphere & Arsht Center",
     ["Perez Art Museum Miami Biscayne Bay", "Frost Museum of Science Miami", "Museum Park Miami"]),
    ("05_A5_freedom_tower", "A5 Biscayne Blvd median at NE 6th St looking at Freedom Tower front",
     ["Freedom Tower Miami Biscayne Boulevard", "Freedom Tower Miami front", "Miami News Tower"]),
    ("06_A6_portmiami", "A6 Port Boulevard bay side looking across PortMiami terminals, cruise ships & gantry cranes",
     ["PortMiami cruise ships", "Port of Miami cruise terminals", "Dodge Island PortMiami"]),
    ("07_B1_brickell_key_north", "B1 Brickell Key north tip looking toward Miami River mouth, Aston Martin Residences & One Miami",
     ["Miami River mouth Brickell Key", "Aston Martin Residences Miami", "One Miami Brickell Key"]),
    ("08_B2_brickell_bridge", "B2 Brickell Ave Bridge south approach looking north across bascule, Tequesta column & downtown",
     ["Brickell Avenue Bridge Miami", "Brickell Bridge Miami River", "Miami River Brickell Avenue"]),
    ("09_B3_brickell_canyon", "B3 S Miami Ave at SE 8th St looking through Brickell canyon, Brickell City Centre & Metromover",
     ["Brickell City Centre Miami", "Metromover Brickell Miami", "South Miami Avenue Brickell"]),
    ("10_B4_brickell_baywalk", "B4 Brickell Bay Dr baywalk looking north toward Four Seasons, Panorama Tower & Jade",
     ["Brickell skyline Biscayne Bay", "Panorama Tower Brickell", "Brickell Bay Drive Miami"]),
    ("11_M1_macarthur_skyline", "M1 MacArthur Causeway looking west at Downtown Miami skyline across Biscayne Bay",
     ["Miami skyline from MacArthur Causeway", "Downtown Miami from Watson Island", "Biscayne Bay Miami skyline"]),
    ("12_M2_macarthur_port_fisher", "M2 MacArthur Causeway looking southeast toward PortMiami cruise ships & Fisher Island",
     ["Cruise ships Government Cut Miami", "Port of Miami MacArthur Causeway", "Fisher Island PortMiami"]),
    ("13_C1_lummus_beach_dune", "C1 Lummus Park sand at 10th St looking west over dune to Ocean Drive Deco fronts",
     ["Lummus Park Ocean Drive Miami Beach", "South Beach lifeguard tower Lummus Park", "Miami Beach sand dune Lummus Park"]),
    ("14_C2_ocean_drive_8th", "C2 Ocean Drive at 8th St looking north along Colony, Pelican & Breakwater hotels",
     ["Colony Hotel Ocean Drive Miami Beach", "Ocean Drive Art Deco Miami Beach", "800 Ocean Drive Miami Beach"]),
    ("15_C3_ocean_drive_13th", "C3 Ocean Drive at 13th St looking south along Cardozo, Carlyle, Leslie & The Tides",
     ["Carlyle Hotel Ocean Drive", "Leslie Hotel Ocean Drive", "Cardozo Hotel Miami Beach"]),
    ("16_C4_south_pointe_pier", "C4 South Pointe Pier looking north along South Beach sand and South of Fifth towers",
     ["South Pointe Park Pier Miami Beach", "South Pointe Park skyline", "Continuum Portofino South Beach"]),
    ("17_C5_lincoln_road_1111", "C5 Lincoln Road at Alton Rd looking at 1111 Lincoln Road open concrete garage",
     ["1111 Lincoln Road Miami Beach", "Lincoln Road Mall Miami Beach", "Herzog de Meuron Miami Beach"]),
    ("18_D1_midbeach_fontainebleau", "D1 Mid-Beach at 44th St looking at Fontainebleau curve & Eden Roc",
     ["Fontainebleau Miami Beach", "Eden Roc Miami Beach", "Mid-Beach Collins Avenue Miami Beach"]),
]

LANDMARK_SPECS = {
    # MI-2A Downtown Bayfront
    "freedom_tower_miami": {"q": ["Freedom Tower Miami", "Miami News Tower"], "keys": ["freedom tower", "news tower"], "views": ["front", "quarter", "aerial", "night"]},
    "kaseya_center": {"q": ["Kaseya Center", "FTX Arena", "American Airlines Arena Miami"], "keys": ["kaseya", "ftx arena", "american airlines arena", "americanairlines"], "views": ["front", "quarter", "aerial", "night"]},
    "pamm_miami": {"q": ["Pérez Art Museum Miami", "Perez Art Museum Miami"], "keys": ["pérez", "perez", "pamm"], "views": ["front", "quarter", "side"]},
    "frost_science_miami": {"q": ["Frost Museum of Science", "Phillip and Patricia Frost Museum of Science"], "keys": ["frost", "planetarium"], "views": ["front", "quarter", "side"]},
    "adrienne_arsht_center": {"q": ["Adrienne Arsht Center", "Carnival Center for the Performing Arts"], "keys": ["arsht", "performing arts", "ziff ballet", "knight concert"], "views": ["front", "quarter", "night"]},
    "skyviews_miami_wheel": {"q": ["Skyviews Miami", "Bayside Marketplace Miami"], "keys": ["skyviews", "bayside", "wheel"], "views": ["front", "quarter", "night"]},
    "bacardi_building_miami": {"q": ["Bacardi Building Miami", "Bacardi Plaza Miami"], "keys": ["bacardi"], "views": ["front", "quarter", "side"]},
    # MI-2B Downtown Core
    "miami_tower": {"q": ["Miami Tower", "CenTrust Tower", "Bank of America Tower Miami"], "keys": ["miami tower", "centrust", "bank of america tower"], "views": ["front", "quarter", "aerial", "night"]},
    "southeast_financial_center": {"q": ["Southeast Financial Center", "Wachovia Financial Center Miami"], "keys": ["southeast financial", "wachovia financial", "first union"], "views": ["front", "quarter", "aerial"]},
    "miami_dade_courthouse": {"q": ["Miami-Dade County Courthouse", "Dade County Courthouse"], "keys": ["courthouse"], "views": ["front", "quarter", "side"]},
    "intercontinental_miami": {"q": ["InterContinental Miami", "Hotel InterContinental Miami"], "keys": ["intercontinental", "chopin plaza"], "views": ["front", "quarter", "night"]},
    "one_thousand_museum": {"q": ["One Thousand Museum", "1000 Museum Miami"], "keys": ["thousand museum", "1000 museum", "hadid"], "views": ["front", "quarter", "side"]},
    "miamicentral_station": {"q": ["MiamiCentral", "Brightline Miami station", "Stephen P. Clark Government Center"], "keys": ["miamicentral", "brightline", "government center", "clark center"], "views": ["front", "quarter", "side"]},
    "ferguson_us_courthouse": {"q": ["Wilkie D. Ferguson Jr. United States Courthouse", "United States Courthouse Miami", "Federal Courthouse Miami"], "keys": ["ferguson", "courthouse", "federal"], "views": ["front", "quarter", "side"]},
    "miami_dade_cultural_center": {"q": ["Miami-Dade Cultural Center", "HistoryMiami"], "keys": ["cultural center", "historymiami", "main library miami"], "views": ["front", "quarter", "side"]},
    # MI-2C PortMiami
    "portmiami_terminal_a": {"q": ["PortMiami Terminal A", "Royal Caribbean Terminal A Miami", "Port of Miami cruise terminal"], "keys": ["terminal", "royal caribbean", "portmiami", "port of miami"], "views": ["front", "quarter", "aerial"]},
    "portmiami_terminal_b": {"q": ["Norwegian Cruise Line Terminal B Miami", "PortMiami Cruise Terminal"], "keys": ["norwegian", "terminal", "portmiami", "port of miami"], "views": ["front", "quarter", "side"]},
    "portmiami_terminal_v": {"q": ["Virgin Voyages Terminal V", "PortMiami cruise ships"], "keys": ["virgin", "terminal", "portmiami", "cruise"], "views": ["front", "quarter", "side"]},
    "portmiami_carnival_msc": {"q": ["MSC Miami Cruise Terminal", "Carnival Cruise Terminal Miami", "Port of Miami"], "keys": ["msc", "carnival", "port of miami", "portmiami"], "views": ["front", "quarter", "aerial"]},
    # MI-3B / MI-6.5 Brickell & Mainland Bespoke
    "brickell_city_centre_ribbon": {"q": ["Brickell City Centre", "Climate Ribbon Brickell"], "keys": ["brickell city centre", "climate ribbon"], "views": ["front", "quarter", "side"]},
    "atlantis_condominium": {"q": ["Atlantis Condominium", "The Atlantis Miami"], "keys": ["atlantis"], "views": ["front", "quarter", "side"]},
    "loandepot_park": {"q": ["LoanDepot Park", "Marlins Park"], "keys": ["loandepot", "marlins park"], "views": ["front", "quarter", "aerial"]},
    "museum_garage_miami": {"q": ["Museum Garage Miami", "Miami Design District Fly's Eye Dome"], "keys": ["museum garage", "design district", "fly's eye"], "views": ["front", "quarter", "side"]},
    "wynwood_walls": {"q": ["Wynwood Walls", "Wynwood murals Miami"], "keys": ["wynwood"], "views": ["front", "quarter", "side"]},
    "tower_theater_miami": {"q": ["Tower Theater Miami", "Domino Park Little Havana"], "keys": ["tower theater", "domino park", "calle ocho"], "views": ["front", "quarter", "side"]},
    # MI-4A..4D Miami Beach
    "ocean_drive_colony_starlite": {"q": ["Colony Hotel Miami Beach", "Starlite Hotel Miami Beach"], "keys": ["colony", "starlite", "ocean drive"], "views": ["front", "quarter", "night"]},
    "ocean_drive_breakwater_edison": {"q": ["Hotel Breakwater South Beach", "Edison Hotel Miami Beach"], "keys": ["breakwater", "edison", "ocean drive"], "views": ["front", "quarter", "night"]},
    "art_deco_welcome_center": {"q": ["Art Deco Welcome Center Miami Beach", "Ocean Rescue Headquarters Miami Beach", "Lummus Park Miami Beach"], "keys": ["welcome center", "ocean rescue", "beach patrol", "lummus"], "views": ["front", "quarter", "side"]},
    "casa_casuarina_versace": {"q": ["Casa Casuarina", "Versace Mansion Miami Beach"], "keys": ["casuarina", "versace", "amsterdam palace"], "views": ["front", "quarter", "side"]},
    "ocean_drive_carlyle_cardozo": {"q": ["The Carlyle Miami Beach", "Leslie Hotel Miami Beach", "Cardozo Hotel Miami Beach"], "keys": ["carlyle", "leslie", "cardozo"], "views": ["front", "quarter", "night"]},
    "lincoln_road_1111": {"q": ["1111 Lincoln Road"], "keys": ["1111 lincoln", "herzog"], "views": ["front", "quarter", "night"]},
    "new_world_center_miami": {"q": ["New World Center Miami Beach", "SoundScape Park Miami Beach"], "keys": ["new world center", "soundscape", "gehry"], "views": ["front", "quarter", "night"]},
    "miami_beach_convention_center": {"q": ["Miami Beach Convention Center"], "keys": ["convention center"], "views": ["front", "quarter", "side"]},
    "holocaust_memorial_miami_beach": {"q": ["Holocaust Memorial Miami Beach"], "keys": ["holocaust memorial"], "views": ["front", "quarter", "side"]},
    "old_city_hall_miami_beach": {"q": ["Miami Beach Old City Hall", "Old City Hall 1130 Washington"], "keys": ["city hall"], "views": ["front", "quarter", "side"]},
    "south_pointe_pier_park": {"q": ["South Pointe Park", "South Pointe Pier Miami Beach"], "keys": ["south pointe"], "views": ["front", "quarter", "aerial"]},
    "fontainebleau_miami_beach": {"q": ["Fontainebleau Miami Beach"], "keys": ["fontainebleau"], "views": ["front", "quarter", "aerial", "night"]},
    "faena_forum_miami_beach": {"q": ["Faena Forum", "Saxony Hotel Miami Beach", "Faena Hotel Miami Beach"], "keys": ["faena", "saxony"], "views": ["front", "quarter", "side"]},
    "flagler_memorial_monument": {"q": ["Flagler Memorial Island", "Henry M. Flagler Monument Miami Beach"], "keys": ["flagler"], "views": ["front", "quarter", "side"]},
    # MI-5 Bridges & Signature Bridge
    "brickell_avenue_bridge": {"q": ["Brickell Avenue Bridge"], "keys": ["brickell avenue bridge", "brickell bridge"], "views": ["front", "quarter", "side"]},
    "i395_signature_bridge": {"q": ["I-395 Signature Bridge Miami", "MacArthur Causeway I-395 Miami"], "keys": ["395", "signature bridge", "macarthur"], "views": ["front", "quarter", "side"]},
    # MI-10 Outer Centres
    "vizcaya_museum_gardens": {"q": ["Vizcaya Museum and Gardens", "Villa Vizcaya"], "keys": ["vizcaya"], "views": ["front", "quarter", "aerial"]},
    "miami_city_hall_dinner_key": {"q": ["Miami City Hall", "Dinner Key Pan Am"], "keys": ["city hall", "dinner key", "pan am"], "views": ["front", "quarter", "side"]},
    "ermita_de_la_caridad": {"q": ["Ermita de la Caridad", "Shrine of Our Lady of Charity Miami"], "keys": ["caridad", "charity", "ermita"], "views": ["front", "quarter", "side"]},
    "biltmore_hotel_coral_gables": {"q": ["Biltmore Hotel Coral Gables", "Miami Biltmore Hotel"], "keys": ["biltmore"], "views": ["front", "quarter", "aerial"]},
    "venetian_pool_coral_gables": {"q": ["Venetian Pool Coral Gables", "Venetian Pool"], "keys": ["venetian pool"], "views": ["front", "quarter", "side"]},
    "coral_gables_city_hall": {"q": ["Coral Gables City Hall"], "keys": ["coral gables city hall", "city hall"], "views": ["front", "quarter", "side"]},
    "alhambra_water_tower": {"q": ["Alhambra Water Tower Coral Gables"], "keys": ["alhambra water tower", "water tower"], "views": ["front", "quarter", "side"]},
    "douglas_entrance_coral_gables": {"q": ["Douglas Entrance Coral Gables", "La Puerta del Sol Coral Gables"], "keys": ["douglas entrance", "puerta del sol"], "views": ["front", "quarter", "side"]},
    "cape_florida_lighthouse": {"q": ["Cape Florida Light", "Cape Florida Lighthouse"], "keys": ["cape florida"], "views": ["front", "quarter", "side"]},
    "miami_marine_stadium": {"q": ["Miami Marine Stadium"], "keys": ["marine stadium"], "views": ["front", "quarter", "aerial"]},
    "stiltsville_biscayne_bay": {"q": ["Stiltsville", "Stiltsville Biscayne Bay"], "keys": ["stiltsville"], "views": ["front", "quarter", "side"]},
    "hard_rock_stadium": {"q": ["Hard Rock Stadium", "Sun Life Stadium"], "keys": ["hard rock stadium", "sun life stadium", "joe robbie"], "views": ["front", "quarter", "aerial"]},
    "nu_stadium_freedom_park": {"q": ["Miami Freedom Park", "Inter Miami stadium"], "keys": ["freedom park", "inter miami", "stadium"], "views": ["front", "quarter", "side"]},
    "ancient_spanish_monastery": {"q": ["Ancient Spanish Monastery North Miami Beach", "St. Bernard de Clairvaux Church Florida"], "keys": ["spanish monastery", "clairvaux"], "views": ["front", "quarter", "side"]},
    "opa_locka_city_hall": {"q": ["Opa-locka Company Administration Building", "Opa-locka City Hall"], "keys": ["opa-locka", "opa locka"], "views": ["front", "quarter", "side"]},
}

GOOD_LIC = ("cc by", "cc-by", "cc0", "public domain", "pd-")
BAD_TITLE = re.compile(
    r"\b(map|plan|drawing|painting|poster|logo|postcard|tichnor|va medical|hurricane|irma|damage|"
    r"stamp|model|miniature|lego|interior|inside|altar|organ|ceiling|coat of arms|seal|flag|portrait|"
    r"exhibition|crowd|protest|diagram|section|etching|litho|screenshot|menu|ticket|plaque|brochure|book|pdf|svg)\b", re.I
)
BARRED_HOSTS = (".ru", ".su", ".xn--p1ai", "yandex", "vk.com", "mail.ru", "rambler", "2gis")


def check_url(url: str) -> None:
    host = (urllib.parse.urlparse(url).hostname or "").lower()
    if any(host.endswith(b) or b in host for b in BARRED_HOSTS):
        raise RuntimeError(f"Blocked host: {host}")


def curl_bytes(url: str, timeout: int = 35) -> bytes:
    check_url(url)
    res = subprocess.run(
        ["curl", "-sSL", "--max-time", str(timeout), "-A", UA, url],
        capture_output=True,
        timeout=timeout + 10,
    )
    if res.returncode != 0 or not res.stdout:
        raise RuntimeError(f"curl failed ({res.returncode}) for {url}")
    return res.stdout


def search(query: str, limit: int = 35) -> list[dict]:
    params = urllib.parse.urlencode({
        "action": "query",
        "format": "json",
        "generator": "search",
        "gsrsearch": f"filetype:bitmap {query}",
        "gsrnamespace": "6",
        "gsrlimit": str(limit),
        "prop": "imageinfo",
        "iiprop": "url|size|mime|extmetadata",
        "iiurlwidth": str(THUMB_W),
    })
    try:
        raw = curl_bytes(f"{API}?{params}")
        data = json.loads(raw)
    except Exception:
        return []
    pages = data.get("query", {}).get("pages", {})
    out = []
    for p in pages.values():
        title = p.get("title", "")
        if BAD_TITLE.search(title):
            continue
        ii_list = p.get("imageinfo") or []
        if not ii_list:
            continue
        ii = ii_list[0]
        if ii.get("mime") not in ("image/jpeg", "image/png"):
            continue
        w = int(ii.get("width", 0))
        h = int(ii.get("height", 0))
        if w < MIN_W or h < 500:
            continue
        ratio = w / max(h, 1)
        if ratio > 3.2 or ratio < 0.6:
            continue
        md = ii.get("extmetadata") or {}
        lic = (md.get("LicenseShortName", {}).get("value", "") or "").strip()
        if not any(g in lic.lower() for g in GOOD_LIC):
            continue
        desc = re.sub(r"<[^>]+>", " ", md.get("ImageDescription", {}).get("value", "") or "")
        cats = re.sub(r"<[^>]+>", " ", md.get("Categories", {}).get("value", "") or "")
        blob = f"{title} {desc} {cats}"
        artist = re.sub(r"<[^>]+>", "", md.get("Artist", {}).get("value", "") or "").strip()
        artist = re.sub(r"\s+", " ", artist) or "Wikimedia Commons user"
        if len(artist) > 80:
            artist = artist[:77] + "..."
        out.append({
            "title": title,
            "url": ii.get("descriptionurl", ""),
            "thumb": ii.get("thumburl", "") or ii.get("url", ""),
            "orig": ii.get("url", ""),
            "w": w,
            "h": h,
            "licence": lic,
            "artist": artist,
            "text": blob.lower(),
        })
    return out


def pick(pool: list[dict], view: str, taken: set[str]):
    words = {
        "aerial": ["aerial", "drone", "from above", "panorama", "skyline", "helicopter"],
        "night": ["night", "evening", "illuminated", "dusk", "blue hour", "sunset", "neon"],
    }.get(view, [])

    def score(c):
        s = 0.0
        t = c["text"]
        if words:
            s += 5.0 * sum(w in t for w in words)
        else:
            s -= 3.5 * sum(w in t for w in ["night", "interior", "inside"])
        if c["w"] >= c["h"]:
            s += 1.0
        s += min(c["w"], 4000) / 4000.0
        return s

    for c in sorted((c for c in pool if c["title"] not in taken), key=score, reverse=True):
        if words and not any(w in c["text"] for w in words):
            return None
        return c
    return None


def readme_rows(path: str) -> dict:
    if not os.path.exists(path):
        return {}
    rows = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"- `([^`]+)` — (.*)", line)
            if m:
                rows[m.group(1)] = line.rstrip("\n")
    return rows


def download_img(c: dict) -> bytes:
    url = c["thumb"] if c["thumb"] else c["orig"]
    data = curl_bytes(url, timeout=45)
    if len(data) < 4096:
        data = curl_bytes(c["orig"], timeout=45)
    return data


def fetch_city(dry: bool = False, force: bool = False) -> None:
    os.makedirs(OUT_CITY, exist_ok=True)
    readme = f"{OUT_CITY}/README.md"
    rows = readme_rows(readme)
    taken: set[str] = set()
    for slug, desc, queries in CITY_VIEWS:
        fname = f"{slug}.jpg"
        if not force and fname in rows and os.path.exists(f"{OUT_CITY}/{fname}"):
            print(f"CITY {slug}: exists", flush=True)
            continue
        pool = {}
        for q in queries:
            for c in search(q, limit=30):
                pool.setdefault(c["title"], c)
            time.sleep(0.5)
            if len(pool) >= 12:
                break
        c = pick([x for x in pool.values() if "miami" in x["text"] or "south beach" in x["text"] or "ocean drive" in x["text"] or "lincoln road" in x["text"]] or list(pool.values()), "front", taken)
        if not c:
            print(f"CITY {slug}: MISSING (pool={len(pool)})", flush=True)
            continue
        taken.add(c["title"])
        print(f"CITY {slug}: {c['title']} ({c['w']}x{c['h']}, {c['licence']})", flush=True)
        if dry:
            continue
        try:
            data = download_img(c)
            with open(f"{OUT_CITY}/{fname}", "wb") as f:
                f.write(data)
            rows[fname] = f"- `{fname}` — {c['url']} — {c['artist']} — {c['licence']} ({desc})"
        except Exception as err:
            print(f"  WARN CITY {slug}: {err}", flush=True)
        time.sleep(0.8)
    if not dry:
        lines = [
            "# Miami City Reference Photos (MI-0.6)",
            "",
            "18 CC/PD Wikimedia Commons reference photographs matching the 18 fixed open-space eyes in `PLAN_Miami_super_realistic.md`.",
            "Image binaries are gitignored; this README tracks provenance, authors, and licences.",
            "",
        ]
        for slug, _, _ in CITY_VIEWS:
            fname = f"{slug}.jpg"
            if fname in rows:
                lines.append(rows[fname])
        with open(readme, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")


def fetch_landmarks(only=None, dry: bool = False, force: bool = False) -> None:
    for type_, spec in LANDMARK_SPECS.items():
        if only and type_ not in only:
            continue
        folder = f"{OUT_LM}/{type_}"
        readme = f"{folder}/README.md"
        rows = readme_rows(readme)
        views = spec.get("views", ["front", "quarter", "side"])
        todo = [v for v in views if force or not (f"{v}.jpg" in rows and os.path.exists(f"{folder}/{v}.jpg"))]
        if not todo and len(rows) >= 3:
            print(f"LM {type_}: complete", flush=True)
            continue
        pool = {}
        for term in spec["q"]:
            for c in search(term, limit=40):
                pool.setdefault(c["title"], c)
            time.sleep(0.5)
            if len(pool) >= 15:
                break
        keys = [k.lower() for k in spec.get("keys", [])]
        cands = [c for c in pool.values() if any(k in c["title"].lower() or k in c["text"] for k in keys)]
        if len(cands) < 3:
            cands = list(pool.values())
        chosen = {}
        for v in todo:
            c = pick(cands, v, {x["title"] for x in chosen.values()})
            if c:
                chosen[v] = c
        for slot in ("front", "quarter", "side", "alt"):
            if len(chosen) + len([k for k in rows if os.path.exists(f"{folder}/{k}")]) >= 3:
                break
            if slot not in chosen and not os.path.exists(f"{folder}/{slot}.jpg"):
                c = pick(cands, "front", {x["title"] for x in chosen.values()})
                if c:
                    chosen[slot] = c
        print(f"LM {type_}: pool={len(cands)} picked={list(chosen.keys())}", flush=True)
        if dry:
            continue
        os.makedirs(folder, exist_ok=True)
        for v, c in chosen.items():
            try:
                data = download_img(c)
                with open(f"{folder}/{v}.jpg", "wb") as f:
                    f.write(data)
                rows[f"{v}.jpg"] = f"- `{v}.jpg` — {c['url']} — {c['artist']} — {c['licence']}"
            except Exception as err:
                print(f"  WARN {type_}:{v} download failed ({err})", flush=True)
            time.sleep(0.7)
        order = [v + ".jpg" for v in ("front", "quarter", "side", "aerial", "night", "alt")]
        ordered = [rows[k] for k in order if k in rows] + [r for k, r in sorted(rows.items()) if k not in order]
        with open(readme, "w", encoding="utf-8") as f:
            f.write(f"# {type_}\n" + "\n".join(ordered) + "\n")


def main() -> None:
    args = dict(a.lstrip("-").split("=", 1) if "=" in a else (a.lstrip("-"), "1") for a in sys.argv[1:])
    dry = "dry" in args
    force = "force" in args
    do_city = "city" in args or ("landmarks" not in args and "only" not in args)
    do_lm = "landmarks" in args or "only" in args or ("city" not in args)
    only = set(args["only"].split(",")) if "only" in args else None
    if do_city:
        fetch_city(dry=dry, force=force)
    if do_lm:
        fetch_landmarks(only=only, dry=dry, force=force)


if __name__ == "__main__":
    main()

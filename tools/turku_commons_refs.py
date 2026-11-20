#!/usr/bin/env python3
"""Fetch licence-checked Wikimedia Commons reference photos for Turku (T-0.2).

  python3 -I tools/turku_commons_refs.py [--city] [--landmarks] [--only=t1,t2] [--dry] [--force]

Only commons.wikimedia.org / upload.wikimedia.org are contacted (HostPolicy).
Saves 1600 px JPEGs (gitignored) and README.md (tracked) with URL, author,
and licence for:
  - visual-plan/refs/turku/ (13 open-space city views matching PLAN_Turku_super_realistic.md)
  - visual-plan/refs/landmarks/<type>/ (3+ views for the 17 existing Turku landmark types)
"""
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_CITY = f"{ROOT}/visual-plan/refs/turku"
OUT_LM = f"{ROOT}/visual-plan/refs/landmarks"
API = "https://commons.wikimedia.org/w/api.php"
UA = "PlanetRender360/1.0 (https://github.com/planet-render-360; Turku CC/PD reference fetch)"
THUMB_W = 1280
MIN_W = 1000

CITY_VIEWS = [
    ("01_auransilta_cathedral", "Auransilta east quay looking upstream to Turku Cathedral & Pinella",
     ["Aurajoki Turun tuomiokirkko", "Aura River Turku Cathedral", "Auransilta Turku"]),
    ("02_rantakatu_city_hall", "Läntinen Rantakatu at Qwensel / City Hall looking across Aurajoki",
     ["Turun kaupungintalo Aurajoki", "Läntinen Rantakatu Turku", "Turku City Hall"]),
    ("03_kauppatori", "Kauppatori central plaza looking toward Orthodox Church, Börs & Wiklund",
     ["Turku Market Square 2022", "Turun kauppatori 2023", "Turun kauppatori paviljonki", "Turun kauppatori"]),
    ("04_vanha_suurtori", "Vanha Suurtori cobbled square looking at Brinkkala & Old Town Hall",
     ["Vanha Suurtori Turku", "Brinkkalan talo", "Turun vanha raatihuone"]),
    ("05_kirjastosilta_library", "Kirjastosilta / Old Main Library quay looking toward New Library, Chappe & Rettig",
     ["Kirjastosilta Turku", "Turun pääkirjasto", "Turun kaupunginkirjasto"]),
    ("06_teatterisilta_theatre", "Teatterisilta looking toward City Theatre, WAM & Samppalinna hill",
     ["Turun kaupunginteatteri", "Teatterisilta Turku", "Wäinö Aaltosen museo"]),
    ("07_martinsilta_fori_kakola", "Martinsilta / Tervatori looking downstream to Föri, Kakola & Mikaelinkirkko",
     ["Föri Turku Aurajoki", "Martinsilta Turku", "Aurajoki Kakola"]),
    ("08_forum_marinum_ships", "Forum Marinum quay looking at Suomen Joutsen, Sigyn, Bore & harbour crane",
     ["Forum Marinum Turku", "Suomen Joutsen Turku", "S/S Bore Turku"]),
    ("09_turku_castle", "Linnanpuisto open lawn looking at Turku Castle (Päälinna & Esilinna)",
     ["Turun linna", "Turku Castle", "Åbo slott"]),
    ("10_puolalanmaki_art_museum", "Puolalanmäki granite steps looking at Turku Art Museum & down Aurakatu",
     ["Turun taidemuseo", "Turku Art Museum", "Puolalanmäki Turku"]),
    ("11_yliopistonmaki_utu", "Yliopistonmäki plaza between University Main Building & Feeniks Library",
     ["Turun yliopisto päärakennus", "Yliopistonmäki Turku", "University of Turku main building"]),
    ("12_tyks_hospital_area", "TYKS Hospital Area (Majakkasairaala, T-sairaala, Medisiina D & A-sairaala)",
     ["Majakkasairaala", "T-sairaala Turku", "TYKS Turku", "Turun yliopistollinen keskussairaala"]),
    ("13_aerial_aurajoki", "Aerial / elevated view over Aurajoki river corridor",
     ["Aurajoki Turku panorama", "Turku view from", "Turku skyline", "Aurajoki Turku"]),
]

LANDMARK_SPECS = {
    "turku_cathedral": {
        "q": ["Turun tuomiokirkko", "Turku Cathedral"],
        "keys": ["tuomiokirkko", "cathedral", "domkyrka"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "turku_castle": {
        "q": ["Turun linna", "Turku Castle"],
        "keys": ["turun linna", "turku castle", "åbo slott", "abo slott"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "mikaelinkirkko": {
        "q": ["Mikaelinkirkko Turku", "St. Michael's Church Turku"],
        "keys": ["mikaelinkirkko", "mikaelskyrkan", "michael"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "martinkirkko": {
        "q": ["Martinkirkko Turku", "St. Martin's Church Turku"],
        "keys": ["martinkirkko", "martinskyrkan", "martin"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "turku_orthodox_church": {
        "q": ["Turun ortodoksinen kirkko", "Turku Orthodox Church"],
        "keys": ["ortodoks", "orthodox", "aleksandra"],
        "views": ["front", "quarter", "side", "night"],
    },
    "turku_kauppatori": {
        "q": ["Turun kauppatori", "Turku Market Square"],
        "keys": ["kauppatori", "market square", "salutorget"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "turku_art_museum": {
        "q": ["Turun taidemuseo", "Turku Art Museum"],
        "keys": ["taidemuseo", "art museum", "konstmuseum"],
        "views": ["front", "quarter", "side", "night"],
    },
    "vartiovuori_observatory": {
        "q": ["Vartiovuoren tähtitorni", "Vartiovuori Observatory"],
        "keys": ["tähtitorni", "tahtitorni", "vartiovuor", "observator"],
        "views": ["front", "quarter", "side"],
    },
    "turku_market_hall": {
        "q": ["Turun kauppahalli", "Turku Market Hall"],
        "keys": ["kauppahalli", "market hall", "saluhall"],
        "views": ["front", "quarter", "side"],
    },
    "turku_main_library": {
        "q": ["Turun pääkirjasto", "Turun kaupunginkirjasto", "Turku Main Library"],
        "keys": ["kirjasto", "library", "bibliotek"],
        "views": ["front", "quarter", "side", "night"],
    },
    "turku_city_theatre": {
        "q": ["Turun kaupunginteatteri", "Turku City Theatre"],
        "keys": ["kaupunginteatteri", "city theatre", "stadsteater"],
        "views": ["front", "quarter", "side", "night"],
    },
    "kakola_prison": {
        "q": ["Kakola Turku", "Kakolan vankila", "Kakolanmäki"],
        "keys": ["kakola"],
        "views": ["front", "quarter", "aerial"],
    },
    "vanha_suurtori": {
        "q": ["Brinkkalan talo", "Vanha Suurtori Turku", "Turun vanha raatihuone"],
        "keys": ["brinkkala", "suurtori", "raatihuone"],
        "views": ["front", "quarter", "side"],
    },
    "suomen_joutsen": {
        "q": ["Suomen Joutsen Turku", "Suomen Joutsen"],
        "keys": ["suomen joutsen", "joutsen"],
        "views": ["front", "quarter", "side", "night"],
    },
    "fori_ferry": {
        "q": ["Föri Turku", "Förin lautta Turku"],
        "keys": ["föri", "fori"],
        "views": ["front", "quarter", "side"],
    },
    "samppalinnan_maauimala": {
        "q": ["Samppalinnan maauimala", "Samppalinna swimming"],
        "keys": ["samppalinna", "maauimala"],
        "views": ["front", "quarter", "side"],
    },
    "paavo_nurmen_stadion": {
        "q": ["Paavo Nurmen stadion", "Paavo Nurmi Stadium"],
        "keys": ["paavo nurm", "stadion", "stadium"],
        "views": ["front", "quarter", "aerial"],
    },
    # Phase T-3A / T-3B / T-3C (TYKS + UTU + Veritas) / T-3D key landmarks
    "hamburger_bors_turku": {
        "q": ["Hamburger Börs Turku", "Scandic Hamburger Börs"],
        "keys": ["hamburger", "börs", "bors"],
        "views": ["front", "quarter", "side"],
    },
    "wiklund_turku": {
        "q": ["Sokos Wiklund Turku", "Wiklund Turku"],
        "keys": ["wiklund"],
        "views": ["front", "quarter", "side"],
    },
    "abo_svenska_teater": {
        "q": ["Åbo Svenska Teater", "Abo Svenska Teater"],
        "keys": ["svenska teater", "teater"],
        "views": ["front", "quarter", "side"],
    },
    "turun_sanomat_building": {
        "q": ["Turun Sanomat building", "Turun Sanomien toimitalo"],
        "keys": ["turun sanom", "kauppiaskatu"],
        "views": ["front", "quarter", "side"],
    },
    "turku_city_hall": {
        "q": ["Turun kaupungintalo", "Turku City Hall"],
        "keys": ["kaupungintalo", "city hall", "stadshus"],
        "views": ["front", "quarter", "side"],
    },
    "qwensel_house": {
        "q": ["Qwensel house Turku", "Qwenselin talo"],
        "keys": ["qwensel", "apteekkimuseo"],
        "views": ["front", "quarter", "side"],
    },
    "chappe_art_house": {
        "q": ["Chappe Turku", "Taidetalo Chappe", "Läntinen Rantakatu Turku"],
        "keys": ["chappe", "rantakatu"],
        "views": ["front", "quarter", "side"],
    },
    "aboa_vetus_rettig": {
        "q": ["Rettigin palatsi", "Aboa Vetus Ars Nova"],
        "keys": ["rettig", "aboa vetus"],
        "views": ["front", "quarter", "side"],
    },
    "sibelius_museum": {
        "q": ["Sibelius Museum Turku", "Sibelius-museo"],
        "keys": ["sibelius"],
        "views": ["front", "quarter", "side"],
    },
    "wam_museum": {
        "q": ["Wäinö Aaltosen museo", "Wäinö Aaltonen Museum"],
        "keys": ["wäinö aalto", "waino aalto", "wam"],
        "views": ["front", "quarter", "side"],
    },
    "tyks_majakka": {
        "q": ["Majakkasairaala Turku", "TYKS Majakkasairaala", "Turku University Hospital"],
        "keys": ["majakkasairaala", "tyks", "åucs", "hospital", "sairaala"],
        "views": ["front", "quarter", "side"],
    },
    "tyks_t_hospital": {
        "q": ["T-sairaala Turku", "TYKS T-sairaala", "ÅUCS T"],
        "keys": ["t-sairaala", "tyks", "åucs", "sairaala"],
        "views": ["front", "quarter", "side"],
    },
    "tyks_a_u_hospitals": {
        "q": ["TYKS U-sairaala", "TYKS A-sairaala", "Turun yliopistollinen keskussairaala"],
        "keys": ["sairaala", "tyks", "åucs", "hospital"],
        "views": ["front", "quarter", "side"],
    },
    "utu_main_campus": {
        "q": ["University of Turku", "Turun yliopisto päärakennus"],
        "keys": ["turun yliopisto", "university of turku", "yliopisto", "feeniks"],
        "views": ["front", "quarter", "side"],
    },
    "veritas_stadion": {
        "q": ["Veritas Stadion Turku", "Veritas Stadium Turku"],
        "keys": ["veritas", "kupittaa", "stadion"],
        "views": ["front", "quarter", "side"],
    },
    "logomo_and_bridge": {
        "q": ["Logomo Turku", "Logomon silta"],
        "keys": ["logomo"],
        "views": ["front", "quarter", "side"],
    },
    "turku_central_station": {
        "q": ["Turku Central Railway Station", "Turun päärautatieasema"],
        "keys": ["rautatieasema", "railway station", "centralstation"],
        "views": ["front", "quarter", "side"],
    },
    "turku_bus_station": {
        "q": ["Turku Bus Station", "Turun linja-autoasema"],
        "keys": ["linja-autoasema", "bus station"],
        "views": ["front", "quarter", "side"],
    },
}

BAD_TITLE = re.compile(
    r"\b(map|kartta|karta|plan|piirustus|drawing|painting|maalaus|poster|juliste|logo|postcard|postikortti|"
    r"stamp|postimerkki|model|pienoismalli|lego|interior|sisätila|sisältä|inside|alttari|altar|organ|urut|"
    r"ceiling|katto|detail|yksityiskohta|sign|kyltti|vaakuna|coat of arms|flag|lippu|statue|patsas|bust|"
    r"portrait|muotokuva|exhibition|näyttely|concert|konsertti|diagram|kaavio|section|leikkaus|print|"
    r"litho|screenshot|plaque|laatta|grave|hauta|tomb|sarcophagus|sarkofagi|crypt|krypta|pulpit|saarnatuoli|"
    r"stained glass|lasimaalaus|chandelier|kattokruunu|painting|fresco|coin|medal|mitali|ticket|lippu)\b",
    re.I,
)
BAD_TEXT = re.compile(
    r"(interior|sisäkuva|sisätila|inside of|alttari|altarpiece|organ loft|pulpit|saarnatuoli|"
    r"sarcophagus|tomb of|grave of|museum object|artefact|artifact|collection item|"
    r"stained glass|lasimaalaus|fresco|sculpture detail|plaque|inscription)",
    re.I,
)
BAD_EXT = re.compile(r"\.(svg|png|gif|tif|tiff|pdf|webm|ogv|webp)$", re.I)
OK_LICENCE = re.compile(r"^(CC BY(?!-N)(?!.*ND)|CC BY-SA|CC0|Public domain|PD|CC-BY|CC-Zero)", re.I)
BAD_LICENCE = re.compile(r"(NC|ND)", re.I)


def get(url, params=None, binary=False):
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=45) as r:
                data = r.read()
            return data if binary else json.loads(data)
        except urllib.error.HTTPError as e:
            if attempt == 4 or e.code not in (429, 500, 502, 503, 504):
                raise
            wait = min(int(e.headers.get("Retry-After", 0) or 0) or (8 * (attempt + 1)), 20)
            print(f"  [retry {attempt+1} HTTP {e.code}, wait {wait}s]", flush=True)
            time.sleep(wait)
        except Exception as e:
            if attempt == 4:
                raise
            print(f"  [retry {attempt+1} {type(e).__name__}]", flush=True)
            time.sleep(4 + attempt * 3)


def download_img(c):
    """Download image, preferring orig to avoid upload.wikimedia.org thumb-scaler 429s."""
    url = c["orig"] if (c["w"] <= 4800 and c.get("orig")) else (c["thumb"] or c["orig"])
    try:
        return get(url, binary=True)
    except urllib.error.HTTPError:
        alt = c["thumb"] if url == c.get("orig") else c.get("orig")
        if alt and alt != url:
            time.sleep(3.0)
            return get(alt, binary=True)
        raise


def search(term, limit=40, min_year=2000):
    j = get(API, {
        "action": "query", "format": "json", "generator": "search", "gsrnamespace": 6,
        "gsrsearch": term + " filetype:bitmap", "gsrlimit": limit,
        "prop": "imageinfo", "iiprop": "url|size|mime|extmetadata|mediatype",
        "iiurlwidth": THUMB_W,
        "iiextmetadatafilter": "LicenseShortName|Artist|DateTimeOriginal|ImageDescription|Categories",
    })
    out = []
    for p in (j.get("query", {}).get("pages", {})).values():
        ii = (p.get("imageinfo") or [{}])[0]
        title = p["title"]
        md = ii.get("extmetadata", {})
        lic = md.get("LicenseShortName", {}).get("value", "")
        if ii.get("mime") != "image/jpeg" or BAD_EXT.search(title) or BAD_TITLE.search(title.replace("_", " ")):
            continue
        blob = title + " " + md.get("ImageDescription", {}).get("value", "") + " " + md.get("Categories", {}).get("value", "")
        if BAD_TEXT.search(blob):
            continue
        if ii.get("width", 0) < MIN_W or ii.get("height", 0) < 650:
            continue
        if not OK_LICENCE.match(lic) or BAD_LICENCE.search(lic.replace("BY-SA", "")):
            continue
        date = md.get("DateTimeOriginal", {}).get("value", "")
        m = re.search(r"(1[89]\d\d|20\d\d)", date)
        if m and int(m.group(1)) < min_year:
            continue
        ratio = ii["width"] / max(ii["height"], 1)
        if ratio > 2.8 or ratio < 0.65:
            continue
        artist = re.sub(r"<[^>]+>", "", md.get("Artist", {}).get("value", "")).strip()
        artist = re.sub(r"\s+", " ", artist) or "unknown"
        if len(artist) > 80:
            artist = artist[:77] + "..."
        out.append({
            "title": title,
            "url": ii.get("descriptionurl", ""),
            "thumb": ii.get("thumburl", ""),
            "orig": ii.get("url", ""),
            "w": ii["width"],
            "h": ii["height"],
            "licence": lic,
            "artist": artist,
            "text": blob.lower(),
        })
    return out


def pick(pool, view, taken):
    words = {
        "aerial": ["aerial", "ilmakuva", "drone", "flyg", "from above", "panorama", "ylhäältä"],
        "night": ["night", "yö", "ilta", "evening", "illuminated", "valaistu", "dusk", "blue hour", "kväll", "natt"],
    }.get(view, [])

    def score(c):
        s = 0.0
        t = c["text"]
        if words:
            s += 5.0 * sum(w in t for w in words)
        else:
            s -= 4.0 * sum(w in t for w in ["aerial", "ilmakuva", "drone", "night", "yö", "ilta", "winter", "talvi"])
        # Prefer landscape framing for exterior references
        if c["w"] > c["h"]:
            s += 1.0
        s += min(c["w"], 4000) / 4000.0
        return s

    for c in sorted((c for c in pool if c["title"] not in taken), key=score, reverse=True):
        if words and not any(w in c["text"] for w in words):
            return None
        return c
    return None


def readme_rows(path):
    if not os.path.exists(path):
        return {}
    rows = {}
    for line in open(path, encoding="utf-8"):
        m = re.match(r"- `([^`]+)` — (.*)", line)
        if m:
            rows[m.group(1)] = line.rstrip("\n")
    return rows


def fetch_city(dry=False, force=False):
    os.makedirs(OUT_CITY, exist_ok=True)
    readme = f"{OUT_CITY}/README.md"
    rows = readme_rows(readme)
    taken = set()
    for slug, desc, queries in CITY_VIEWS:
        fname = f"{slug}.jpg"
        if not force and fname in rows and os.path.exists(f"{OUT_CITY}/{fname}"):
            print(f"CITY {slug}: exists")
            continue
        pool = {}
        for q in queries:
            for c in search(q, limit=30):
                pool.setdefault(c["title"], c)
            time.sleep(1.0)
        view = "aerial" if "aerial" in slug else "front"
        c = pick(list(pool.values()), view, taken)
        if not c and view == "aerial":
            c = pick(list(pool.values()), "front", taken)
        if not c:
            print(f"CITY {slug}: MISSING (pool={len(pool)})")
            continue
        taken.add(c["title"])
        print(f"CITY {slug}: {c['title']} ({c['w']}x{c['h']}, {c['licence']})", flush=True)
        if dry:
            continue
        data = download_img(c)
        with open(f"{OUT_CITY}/{fname}", "wb") as f:
            f.write(data)
        rows[fname] = f"- `{fname}` — {c['url']} — {c['artist']} — {c['licence']} ({desc})"
        time.sleep(2.0)
    if not dry:
        lines = [
            "# Turku City Reference Photos (T-0.2)",
            "",
            "13 CC/PD Wikimedia Commons reference photographs matching the 13 fixed open-space eyes in `PLAN_Turku_super_realistic.md`.",
            "Image binaries are gitignored; this README tracks provenance, authors, and licences.",
            "",
        ]
        for slug, _, _ in CITY_VIEWS:
            fname = f"{slug}.jpg"
            if fname in rows:
                lines.append(rows[fname])
        with open(readme, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")


def fetch_landmarks(only=None, dry=False, force=False):
    for type_, spec in LANDMARK_SPECS.items():
        if only and type_ not in only:
            continue
        folder = f"{OUT_LM}/{type_}"
        readme = f"{folder}/README.md"
        rows = readme_rows(readme)
        views = spec.get("views", ["front", "quarter", "side"])
        todo = [v for v in views if force or not (f"{v}.jpg" in rows and os.path.exists(f"{folder}/{v}.jpg"))]
        if not todo:
            print(f"LM {type_}: complete")
            continue
        pool = {}
        for term in spec["q"][:2]:
            for c in search(term, limit=50):
                pool.setdefault(c["title"], c)
            time.sleep(0.8)
            if len(pool) >= 12:
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
        # Guarantee at least 3 ground/exterior photos if aerial or night wasn't found
        fallback_slots = ["front", "quarter", "side", "alt"]
        for slot in fallback_slots:
            if len(chosen) + len([k for k in rows if os.path.exists(f"{folder}/{k}")]) >= 3:
                break
            if slot not in chosen and not os.path.exists(f"{folder}/{slot}.jpg"):
                c = pick(cands, "front", {x["title"] for x in chosen.values()})
                if c:
                    chosen[slot] = c
        picked_str = ", ".join(f"{v}={c['title'][5:48]}" for v, c in chosen.items())
        print(f"LM {type_}: pool={len(cands)} picked=[{picked_str}]", flush=True)
        if dry:
            continue
        os.makedirs(folder, exist_ok=True)
        for v, c in chosen.items():
            try:
                data = download_img(c)
            except Exception as e:
                print(f"  WARN {type_}:{v} download failed ({e}), skipping", flush=True)
                continue
            with open(f"{folder}/{v}.jpg", "wb") as f:
                f.write(data)
            rows[f"{v}.jpg"] = f"- `{v}.jpg` — {c['url']} — {c['artist']} — {c['licence']}"
            time.sleep(1.2)
        order = [v + ".jpg" for v in ("front", "quarter", "side", "aerial", "night", "alt")]
        ordered = [rows[k] for k in order if k in rows] + [r for k, r in sorted(rows.items()) if k not in order]
        with open(readme, "w", encoding="utf-8") as f:
            f.write(f"# {type_}\n" + "\n".join(ordered) + "\n")


def main():
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

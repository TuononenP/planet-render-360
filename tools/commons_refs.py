#!/usr/bin/env python3
"""Fetch licence-checked Wikimedia Commons reference photos for landmarks.

  python3 -I tools/commons_refs.py [--only=type,type] [--dry] [--force]

For every type in SPECS (Stockholm plan S-0.2) it searches Commons for each
wanted view (front, quarter, aerial, night), keeps only CC BY / CC BY-SA /
CC0 / public-domain JPEGs at least 1400 px wide that look like modern
photographs, and saves the best per view to
visual-plan/refs/landmarks/<type>/<view>.jpg (JPGs are gitignored) with a
README.md row per file: URL, author, licence. Existing README rows and files
are kept unless --force. Only commons.wikimedia.org / upload.wikimedia.org
are contacted. The search is a heuristic: review the result (contact sheet)
before treating a file as the reference for a view.
"""
import json, os, re, subprocess, sys, time, urllib.parse, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = f"{ROOT}/visual-plan/refs/landmarks"
API = "https://commons.wikimedia.org/w/api.php"
UA = "planet-render-refs/1.0 (landmark reference fetch)"
THUMB_W = 1600
MIN_W = 1400

# type -> {"q": [search terms], "views": [...], "need": {view: [extra words]}}
# `q` terms are tried for every view; a view's extra words are appended.
VIEWS = {
    "front": [""],
    "quarter": ["", "sida", "corner"],
    "aerial": ["aerial", "från luften", "drone", "luftbild"],
    "night": ["night", "kväll", "natt", "illuminated"],
}
DEFAULT_VIEWS = ["front", "quarter", "aerial"]

SPECS = {
    # existing registry types
    "stockholm_city_hall": {"q": ["Stockholms stadshus", "Stockholm City Hall"], "views": ["front", "quarter", "aerial", "night"]},
    "riddarholmen": {"q": ["Riddarholmskyrkan", "Riddarholmen Stockholm"], "keys": ["riddarholm"], "views": ["front", "quarter", "aerial"]},
    "royal_palace_stockholm": {"q": ["Stockholms slott", "Stockholm Palace"], "keys": ["stockholms slott", "stockholm palace", "kungliga slottet", "royal palace"], "ban": ["rosersberg", "bogesund", "drottningholm", "haga", "ulriksdal", "gripsholm", "kalmar"], "views": ["front", "quarter", "aerial", "night"]},
    "storkyrkan": {"q": ["Storkyrkan", "Stockholm Cathedral"]},
    "katarina_church": {"q": ["Katarina kyrka Stockholm"]},
    "hedvig_eleonora_church": {"q": ["Hedvig Eleonora kyrka"]},
    "ericsson_globe": {"q": ["Avicii Arena", "Ericsson Globe"], "views": ["front", "quarter", "aerial", "night"]},
    "kaknas_tower": {"q": ["Kaknästornet"], "views": ["front", "quarter"]},
    "vasa_museum": {"q": ["Vasamuseet exterior", "Vasa Museum Djurgården building"], "keys": ["vasamuse", "vasa museum", "vasa museet"], "ban": ["ship", "skepp", "warship", "hull", "hall", "regalskeppet"]},
    "nordic_museum": {"q": ["Nordiska museet Djurgården", "Nordic Museum Stockholm exterior"], "keys": ["nordiska museet", "nordic museum"], "ban": ["NM\\.", "inv", "object"]},
    "stockholm_public_library": {"q": ["Stockholms stadsbibliotek Asplund", "Stockholm Public Library exterior"], "keys": ["stadsbibliotek", "public library", "stockholm city library"]},
    "stockholm_concert_hall": {"q": ["Konserthuset Stockholm"]},
    "riksdag_building": {"q": ["Riksdagshuset", "Riksdag building Stockholm"], "views": ["front", "quarter", "aerial", "night"]},
    "grona_lund_eclipse": {"q": ["Gröna Lund Eclipse", "Gröna Lund"], "views": ["front", "quarter", "aerial", "night"]},
    "hotorgsskraporna": {"q": ["Hötorgsskraporna"], "views": ["front", "quarter", "aerial", "night"]},
    "royal_opera_stockholm": {"q": ["Kungliga Operan Stockholm"]},
    "grand_hotel_stockholm": {"q": ["Grand Hôtel Stockholm"]},
    "nationalmuseum_stockholm": {"q": ["Nationalmuseum Stockholm"]},
    "riddarhuset_stockholm": {"q": ["Riddarhuset Stockholm"]},
    "wrangel_palace": {"q": ["Wrangelska palatset"]},
    "bonde_palace": {"q": ["Bondeska palatset", "Bonde Palace Stockholm", "Bonde Palace Riddarholmen"], "keys": ["bonde"]},
    "katarinahissen": {"q": ["Katarinahissen"], "views": ["front", "quarter", "aerial", "night"]},
    "kastellet_stockholm": {"q": ["Kastellet Kastellholmen", "Kastellholmen Stockholm"], "keys": ["kastellholm", "kastellet, stockholm", "kastellet stockholm"]},
    "soder_torn": {"q": ["Söder Torn Södermalm skyscraper", "Söder Torn Stockholm"], "keys": ["söder torn", "soder torn", "södertorn"], "ban": ["törn", "map", "karta"], "views": ["front", "quarter", "aerial", "night"]},
    "klara_church": {"q": ["Klara kyrka Stockholm"]},
    "sofia_church_stockholm": {"q": ["Sofia kyrka Stockholm"]},
    "tyska_kyrkan": {"q": ["Tyska kyrkan Stockholm", "Sankta Gertruds kyrka"]},
    "stockholm_central_station": {"q": ["Stockholms centralstation fasad", "Stockholm Central Station exterior Vasagatan"], "keys": ["central"], "ban": ["train", "tåg", "arlanda", "platform", "spår", "x2000", "x3", "ticket", "hall"], "views": ["front", "quarter", "aerial", "night"]},
    "vasterbron": {"q": ["Västerbron"], "views": ["front", "quarter", "aerial", "night"]},
    # S-3 Tier A
    "slussen_guldbron": {"q": ["Slussen Guldbron", "Slussen Stockholm"], "views": ["front", "quarter", "aerial"]},
    "stortorget_stockholm": {"q": ["Stortorget Gamla stan"]},
    "skeppsbron_stockholm": {"q": ["Skeppsbron Stockholm"]},
    "dramaten": {"q": ["Dramaten Stockholm", "Kungliga Dramatiska teatern"]},
    "stromsbron": {"q": ["Strömbron Stockholm", "Norrbro Stockholm"], "ban": ["cyclist", "cykl"]},
    "skeppsholmsbron": {"q": ["Skeppsholmsbron"], "ban": ["orion", "tug", "bogser", "gångbro", "kajen"]},
    "af_chapman": {"q": ["af Chapman Stockholm"]},
    "skeppsholmen_church": {"q": ["Skeppsholmskyrkan"]},
    "moderna_museet": {"q": ["Moderna museet Stockholm", "Moderna Museet Skeppsholmen"], "ban": ["sculpture", "skulptur", "niki"]},
    "stockholm_waterfront": {"q": ["Stockholm Waterfront Congress Centre"]},
    "kungstornen": {"q": ["Kungstornen Stockholm"]},
    "kulturhuset_sergels_torg": {"q": ["Kulturhuset Stockholm", "Sergels torg"], "ban": ["byggplats", "construction", "demoli", "1960", "1970"]},
    "rosenbad": {"q": ["Rosenbad Stockholm"]},
    "sagerska_huset": {"q": ["Sagerska huset"], "ban": ["balkong", "balcony", "portal", "monogram", "emblem", "vapen"]},
    "arvfurstens_palats": {"q": ["Arvfurstens palats"]},
    "munchenbryggeriet": {"q": ["Münchenbryggeriet"]},
    "hogalid_church": {"q": ["Högalidskyrkan", "Högalids kyrka"], "ban": ["statyett", "madonna", "magdala", "maria", "kolumbarium"]},
    "fotografiska": {"q": ["Fotografiska Stockholm"]},
    # existing refs folders from earlier rounds
    "engelbrektskyrkan": {"q": ["Engelbrektskyrkan"], "views": ["front", "quarter", "aerial", "night"]},
    "skansen_bredablick": {"q": ["Bredablick Skansen", "Bredablick tower Skansen Stockholm"], "keys": ["bredablick"], "ban": ["lovön", "drottningholm"]},
    "skansen_hazelius_gate": {"q": ["Skansen Hazelius port"]},
    "naturhistoriska_riksmuseet": {"q": ["Naturhistoriska riksmuseet", "Swedish Museum of Natural History building"], "keys": ["naturhistoriska", "natural history"]},
}

BAD_TITLE = re.compile(
    r"\b(map|karta|plan|ritning|drawing|painting|målning|poster|affisch|logo|logotyp|postcard|vykort|stamp|"
    r"frimärke|model|modell|miniature|lego|interior|interiör|inside|kyrkorum|altar|organ|orgel|ceiling|tak|"
    r"detail|detalj|sign|skylt|coat|vapen|flag|flagga|statue|staty|bust|byst|portrait|porträtt|exhibition|"
    r"utställning|concert|konsert|crowd|event|demonstration|protest|panorama_map|diagram|schema|section|"
    r"snitt|facsimile|print|gravyr|etching|litho|bild från|film|video|screenshot|banquet|cutlery|nobel|dinner|"
    r"table|ceremony|slussen|view from|utsikt|seen from)\b", re.I)
BAD_TEXT = re.compile(
    r"(interior|interiör|inside of|inifrån|columbarium|kolumbarium|\bgrave|gravar|organ loft|altarpiece|"
    r"altartavla|choir|\bnave\b|kyrkorummet|högmässa|mässa|guided tour|textile|textil|artefact|artifact|"
    r"museum object|collection|samling|copenhagen|köpenhamn|denmark|danmark|\bcharta\b|biurman|kartor|"
    r"scenen|stage|auditorium|salong|lucia|statyett|statuette|sculpture detail|plaque|inscription|detail of)", re.I)
BAD_EXT = re.compile(r"\.(svg|png|gif|tif|tiff|pdf|webm|ogv)$", re.I)
OK_LICENCE = re.compile(r"^(CC BY(?!-N)(?!.*ND)|CC BY-SA|CC0|Public domain|PD|CC-BY|CC-Zero)", re.I)
BAD_LICENCE = re.compile(r"(NC|ND)", re.I)


def get(url, params=None, binary=False):
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for attempt in range(7):
        if binary:  # upload.wikimedia.org answers 429 to HTTP/1.1 clients (urllib) but not to curl's HTTP/2
            r = subprocess.run(["curl", "-s", "-f", "-A", UA, url.split("?utm_")[0]], capture_output=True)
            if r.returncode == 0 and r.stdout:
                return r.stdout
            time.sleep(10 * (attempt + 1))
            continue
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                data = r.read()
            return data if binary else json.loads(data)
        except urllib.error.HTTPError as e:
            if attempt == 6 or e.code not in (429, 500, 502, 503, 504):
                raise
            time.sleep(int(e.headers.get("Retry-After", 0) or 0) or 20 * (attempt + 1))
        except Exception:  # noqa: BLE001
            if attempt == 6:
                raise
            time.sleep(5 + attempt * 5)
    raise RuntimeError("download failed: " + url)


def keys_for(spec):
    """Distinctive lower-case word stems a matching title must contain."""
    if "keys" in spec:
        return {k.lower() for k in spec["keys"]}
    stop = {"stockholm", "stockholms", "kyrka", "church", "palace", "the", "of", "gamla", "stan", "kungliga",
            "museum", "museet", "hotel", "hôtel", "bron", "tower", "torn", "slott", "palatset", "huset"}
    out = set()
    for q in spec["q"]:
        words = [w.lower() for w in re.findall(r"[\w]+", q) if w.lower() not in stop and len(w) > 3]
        out.update(w[:max(5, len(w) - 2)] for w in words)
    return out or {w.lower()[:5] for q in spec["q"] for w in q.split()}


EXTRA_BAN = re.compile(r"(?!x)x")  # per-type ban, set in main()


def search(term, limit=40):
    j = get(API, {
        "action": "query", "format": "json", "generator": "search", "gsrnamespace": 6,
        "gsrsearch": term + " filetype:bitmap", "gsrlimit": limit,
        "prop": "imageinfo", "iiprop": "url|size|mime|extmetadata|mediatype",
        "iiurlwidth": THUMB_W, "iiextmetadatafilter": "LicenseShortName|Artist|DateTimeOriginal|ImageDescription|Categories",
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
        if BAD_TEXT.search(blob) or EXTRA_BAN.search(blob):
            continue
        if ii.get("width", 0) < MIN_W or ii.get("height", 0) < 700:
            continue
        if not OK_LICENCE.match(lic) or BAD_LICENCE.search(lic.replace("BY-SA", "")):
            continue
        date = md.get("DateTimeOriginal", {}).get("value", "")
        m = re.search(r"(1[89]\d\d|20\d\d)", date)
        if m and int(m.group(1)) < 2005:
            continue
        ratio = ii["width"] / max(ii["height"], 1)
        if ratio > 2.6 or ratio < 0.7:
            continue
        artist = re.sub(r"<[^>]+>", "", md.get("Artist", {}).get("value", "")).strip() or "unknown"
        out.append({"title": title, "url": ii.get("descriptionurl", ""), "thumb": ii.get("thumburl", ""),
                    "w": ii["width"], "h": ii["height"], "licence": lic, "artist": artist,
                    "text": (title + " " + md.get("ImageDescription", {}).get("value", "") + " "
                             + md.get("Categories", {}).get("value", "")).lower()})
    return out


def pick(pool, view, taken):
    words = {"aerial": ["aerial", "luft", "drone", "drön", "ovan", "from above", "flyg"],
             "night": ["night", "natt", "kväll", "evening", "illuminated", "belysn", "dusk", "blue hour"]}.get(view, [])
    def score(c):
        s = 0
        t = c["text"]
        if words:
            s += 5 * sum(w in t for w in words)
        else:
            s -= 4 * sum(w in t for w in ["aerial", "luft", "drone", "night", "natt", "kväll", "winter"])
        s += min(c["w"], 4000) / 4000.0
        return s
    for c in sorted((c for c in pool if c["title"] not in taken), key=score, reverse=True):
        if words and not any(w in c["text"] for w in words):
            return None
        return c
    return None


def pin(type_, view, title):
    """Fetch one named Commons file as <type>/<view>.jpg (licence still checked)."""
    title = title if title.startswith("File:") else "File:" + title
    j = get(API, {"action": "query", "format": "json", "titles": title, "prop": "imageinfo",
                  "iiprop": "url|size|mime|extmetadata", "iiurlwidth": THUMB_W,
                  "iiextmetadatafilter": "LicenseShortName|Artist"})
    page = next(iter(j["query"]["pages"].values()))
    ii = (page.get("imageinfo") or [None])[0]
    if ii is None:
        print(f"PIN {type_}:{view}: {title} not found")
        return
    md = ii.get("extmetadata", {})
    lic = md.get("LicenseShortName", {}).get("value", "")
    if not OK_LICENCE.match(lic) or BAD_LICENCE.search(lic.replace("BY-SA", "")):
        print(f"PIN {type_}:{view}: licence {lic!r} not allowed")
        return
    artist = re.sub(r"<[^>]+>", "", md.get("Artist", {}).get("value", "")).strip() or "unknown"
    folder = f"{OUT}/{type_}"
    os.makedirs(folder, exist_ok=True)
    data = get(ii.get("thumburl") or ii["url"], binary=True)  # download first: no empty file on a failed fetch
    with open(f"{folder}/{view}.jpg", "wb") as f:
        f.write(data)
    rows = readme_rows(f"{folder}/README.md")
    rows[f"{view}.jpg"] = f"- `{view}.jpg` — {ii['descriptionurl']} — {artist} — {lic}"
    order = [x + ".jpg" for x in ("front", "quarter", "aerial", "night")]
    body = [rows[k] for k in order if k in rows] + [r for k, r in sorted(rows.items()) if k not in order]
    with open(f"{folder}/README.md", "w", encoding="utf-8") as f:
        f.write(f"# {type_}\n" + "\n".join(body) + "\n")
    print(f"PIN {type_}:{view} = {title} ({lic})")


def find(term, n=12):
    """Print candidate titles for a manual pick."""
    for c in search(term, n * 2)[:n]:
        print(f"  {c['w']}x{c['h']}  {c['title']}")


def readme_rows(path):
    if not os.path.exists(path):
        return {}
    rows = {}
    for line in open(path, encoding="utf-8"):
        m = re.match(r"- `([^`]+)` — (.*)", line)
        if m:
            rows[m.group(1)] = line.rstrip("\n")
    return rows


def main():
    args = dict(a.lstrip("-").split("=", 1) if "=" in a else (a.lstrip("-"), "1") for a in sys.argv[1:])
    if "find" in args:
        find(args["find"])
        return
    if "pin" in args:  # --pin=type|view|File:Name.jpg
        t, v, title = args["pin"].split("|", 2)
        pin(t, v, title)
        return
    only = set(args["only"].split(",")) if "only" in args else None
    dry, force = "dry" in args, "force" in args
    for item in filter(None, args.get("drop", "").split(",")):
        t, v = item.split(":")
        for ext in ("jpg",):
            path = f"{OUT}/{t}/{v}.{ext}"
            if os.path.exists(path):
                os.remove(path)
        rd = f"{OUT}/{t}/README.md"
        rows = readme_rows(rd)
        rows.pop(f"{v}.jpg", None)
        if os.path.exists(rd) or rows:
            order = [x + ".jpg" for x in ("front", "quarter", "aerial", "night")]
            body = [rows[k] for k in order if k in rows] + [r for k, r in sorted(rows.items()) if k not in order]
            with open(rd, "w", encoding="utf-8") as f:
                f.write(f"# {t}\n" + "\n".join(body) + ("\n" if body else ""))
    for type_, spec in SPECS.items():
        if only and type_ not in only:
            continue
        folder = f"{OUT}/{type_}"
        readme = f"{folder}/README.md"
        rows = readme_rows(readme)
        global EXTRA_BAN
        EXTRA_BAN = re.compile("(" + "|".join(spec["ban"]) + ")", re.I) if spec.get("ban") else re.compile(r"(?!x)x")
        views = spec.get("views", DEFAULT_VIEWS)
        todo = [v for v in views if force or not (f"{v}.jpg" in rows and os.path.exists(f"{folder}/{v}.jpg"))]
        if not todo:
            print(f"{type_}: complete")
            continue
        pool = {}
        for term in spec["q"][:2]:
            for extra in ("", "aerial", "night") if "night" in todo else ("", "aerial"):
                for c in search((term + " " + extra).strip()):
                    pool.setdefault(c["title"], c)
                time.sleep(2.0)
        keys = keys_for(spec)
        cands = [c for c in pool.values() if any(k in c["title"].lower() for k in keys)]
        chosen = {}
        for v in todo:
            c = pick(cands, v, {x["title"] for x in chosen.values()})
            if c:
                chosen[v] = c
        # No aerial found: a second ground-level angle stands in as `side`.
        if "aerial" in todo and "aerial" not in chosen and not os.path.exists(f"{folder}/side.jpg"):
            c = pick(cands, "side", {x["title"] for x in chosen.values()})
            if c:
                chosen["side"] = c
                todo = todo + ["side"]
        picked = ", ".join("%s=%s" % (v, c["title"][5:60]) for v, c in chosen.items())
        missing = [v for v in todo if v not in chosen]
        print(f"{type_}: pool {len(cands)}, picked {picked}" + (f"  MISSING {missing}" if missing else ""))
        if dry:
            continue
        os.makedirs(folder, exist_ok=True)
        for v, c in chosen.items():
            data = get(c["thumb"] or c["url"], binary=True)
            with open(f"{folder}/{v}.jpg", "wb") as f:
                f.write(data)
            rows[f"{v}.jpg"] = f"- `{v}.jpg` — {c['url']} — {c['artist']} — {c['licence']}"
            time.sleep(2.0)
        order = [v + ".jpg" for v in ("front", "quarter", "aerial", "night")]
        ordered = [rows[k] for k in order if k in rows] + [r for k, r in sorted(rows.items()) if k not in order]
        with open(readme, "w", encoding="utf-8") as f:
            f.write(f"# {type_}\n" + "\n".join(ordered) + "\n")


if __name__ == "__main__":
    main()

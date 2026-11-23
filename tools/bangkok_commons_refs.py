#!/usr/bin/env python3
"""Fetch licence-checked Wikimedia Commons reference photos for Bangkok (BK-0.4).

  python3 -I tools/bangkok_commons_refs.py [--city] [--landmarks] [--only=t1,t2] [--dry] [--force]

Only commons.wikimedia.org / upload.wikimedia.org are contacted (HostPolicy).
Saves 1600 px JPEGs (gitignored) and README.md (tracked) with URL, author,
and licence for:
  - visual-plan/refs/bangkok/ (city fabric, streets, canals, river, night, aerial)
  - visual-plan/refs/landmarks/<type>/ (3+ views per Bangkok landmark type)
"""
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_CITY = f"{ROOT}/visual-plan/refs/bangkok"
OUT_LM = f"{ROOT}/visual-plan/refs/landmarks"
API = "https://commons.wikimedia.org/w/api.php"
UA = "PlanetRender360/1.0 (Bangkok CC/PD landmark reference fetch)"
THUMB_W = 1600
MIN_W = 1000

CITY_VIEWS = [
    ("01_bamrung_mueang_shophouses", "Bamrung Mueang & Rattanakosin historic shophouses",
     ["Bamrung Mueang shophouse", "Phraeng Phuthon", "Bamrung Mueang Road Bangkok", "Sao Chingcha shophouses"]),
    ("02_ratchadamnoen_klang", "Ratchadamnoen Klang Avenue 1940s streamline blocks & median",
     ["Ratchadamnoen Klang Avenue", "Ratchadamnoen Avenue Bangkok", "Rattanakosin Exhibition Hall"]),
    ("03_khlong_old_town", "Old-town khlong (Khlong Khu Mueang Doem / Khlong Rop Krung) & white bridge",
     ["Khlong Khu Mueang Doem", "Khlong Rop Krung", "Phan Fa Lilat Bridge", "Pi Kun Bridge Bangkok"]),
    ("04_chao_phraya_tha_tien", "Chao Phraya River at Tha Tien with ferries & longtail boats",
     ["Chao Phraya River Tha Tien", "Chao Phraya Express Boat Bangkok", "Longtail boat Chao Phraya Bangkok"]),
    ("05_yaowarat_night", "Yaowarat Road Chinatown neon signboards at night",
     ["Yaowarat Road night", "Chinatown Bangkok night", "Yaowarat Bangkok neon"]),
    ("06_rattanakosin_aerial", "Aerial / elevated view over Rattanakosin Island & Grand Palace",
     ["Rattanakosin aerial", "Grand Palace Bangkok aerial", "Sanam Luang aerial", "Bangkok old town aerial"]),
    ("07_bangkok_city_hall_plaza", "Bangkok City Hall & Lan Khon Mueang plaza",
     ["Bangkok City Hall Sao Chingcha", "Lan Khon Mueang", "ศาลาว่าการกรุงเทพมหานคร"]),
]

LANDMARK_SPECS = {
    "grand_palace_bangkok": {
        "q": ["Grand Palace Bangkok exterior", "Wat Phra Kaew Bangkok", "Chakri Maha Prasat"],
        "keys": ["grand palace", "wat phra kaew", "chakri maha prasat", "phra borom", "emerald buddha"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "wat_pho": {
        "q": ["Wat Pho Bangkok", "Phra Maha Chedi Si Rajakarn", "Wat Pho chedi"],
        "keys": ["wat pho", "chetupon", "chetuphon", "rajakarn"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "wat_arun": {
        "q": ["Wat Arun prang", "Wat Arun Bangkok"],
        "keys": ["wat arun", "arunratchawararam", "temple of dawn"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "hua_lamphong": {
        "q": ["Hua Lamphong railway station exterior", "Bangkok railway station facade", "Hua Lamphong station"],
        "keys": ["hua lamphong", "hualamphong", "bangkok railway station"],
        "ban": ["ticket", "locomotive", "carriage", "seat", "mrt"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "giant_swing": {
        "q": ["Giant Swing Bangkok", "Sao Chingcha Bangkok"],
        "keys": ["giant swing", "sao chingcha", "ching cha", "เสาชิงช้า"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "wat_suthat": {
        "q": ["Wat Suthat Bangkok", "Wat Suthat Viharn Luang", "Wat Suthat ubosot"],
        "keys": ["wat suthat", "suthat", "วัดสุทัศน"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "democracy_monument": {
        "q": ["Democracy Monument Bangkok", "อนุสาวรีย์ประชาธิปไตย"],
        "keys": ["democracy monument", "ประชาธิปไตย"],
        "ban": ["protest", "rally", "crowd", "demonstration", "police", "riot"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "loha_prasat": {
        "q": ["Loha Prasat Bangkok", "Wat Ratchanatdaram Loha Prasat"],
        "keys": ["loha prasat", "ratchanatda", "โลหะปราสาท"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "golden_mount": {
        "q": ["Wat Saket Golden Mount", "Phu Khao Thong Bangkok", "Golden Mount Bangkok"],
        "keys": ["wat saket", "golden mount", "phu khao thong", "ภูเขาทอง", "วัดสระเกศ"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "mahakan_fort": {
        "q": ["Mahakan Fort Bangkok", "ป้อมมหากาฬ"],
        "keys": ["mahakan", "มหากาฬ"],
        "views": ["front", "quarter", "aerial"],
    },
    "wat_ratchabophit": {
        "q": ["Wat Ratchabophit Bangkok", "วัดราชบพิธ"],
        "keys": ["ratchabophit", "rajabopit", "ราชบพิธ"],
        "views": ["front", "quarter", "aerial"],
    },
    "wat_bowonniwet": {
        "q": ["Wat Bowonniwet Vihara", "Wat Bovornives Bangkok", "วัดบวรนิเวศ"],
        "keys": ["bowonniwet", "bovorn", "บวรนิเวศ"],
        "views": ["front", "quarter", "aerial"],
    },
    "bangkok_city_pillar": {
        "q": ["Bangkok City Pillar Shrine", "Lak Mueang Bangkok", "ศาลหลักเมืองกรุงเทพ"],
        "keys": ["city pillar", "lak mueang", "lak muang", "หลักเมือง"],
        "views": ["front", "quarter", "night"],
    },
    "ministry_of_defence_bangkok": {
        "q": ["Ministry of Defence Thailand building", "Ministry of Defence Bangkok", "ศาลาว่าการกลาโหม"],
        "keys": ["ministry of defence", "ministry of defense", "กลาโหม"],
        "views": ["front", "quarter", "aerial"],
    },
    "wat_ratchapradit": {
        "q": ["Wat Ratchapradit Bangkok", "วัดราชประดิษฐ"],
        "keys": ["ratchapradit", "rajapradit", "ราชประดิษฐ"],
        "views": ["front", "quarter", "aerial"],
    },
    "thammasat_dome": {
        "q": ["Dome Building Thammasat University", "Thammasat Tha Phra Chan Dome", "ตึกโดม ธรรมศาสตร์"],
        "keys": ["thammasat", "dome building", "ตึกโดม", "ธรรมศาสตร์"],
        "views": ["front", "quarter", "aerial"],
    },
    "national_museum_bangkok": {
        "q": ["Bangkok National Museum building", "Buddhaisawan Chapel Bangkok", "Siwamokhaphiman Hall"],
        "keys": ["national museum", "buddhaisawan", "siwamokhaphiman", "front palace", "พิพิธภัณฑสถานแห่งชาติ"],
        "ban": ["bronze", "statue", "sculpture", "head", "ceramic", "stele", "artifact"],
        "views": ["front", "quarter", "aerial"],
    },
    "phra_sumen_fort": {
        "q": ["Phra Sumen Fort", "ป้อมพระสุเมรุ"],
        "keys": ["phra sumen", "sumen fort", "พระสุเมรุ"],
        "views": ["front", "quarter", "night"],
    },
    "santa_cruz_church": {
        "q": ["Santa Cruz Church Bangkok", "โบสถ์ซางตาครู้ส"],
        "keys": ["santa cruz", "ซางตาครู้ส", "kudichin", "kudi chin"],
        "views": ["front", "quarter", "aerial"],
    },
    "wat_kalayanamit": {
        "q": ["Wat Kalayanamit Bangkok", "วัดกัลยาณมิตร"],
        "keys": ["kalayanamit", "กัลยาณมิตร"],
        "views": ["front", "quarter", "aerial"],
    },
    "wat_prayun": {
        "q": ["Wat Prayurawongsawas", "Wat Prayoon Bangkok", "วัดประยุรวงศาวาส"],
        "keys": ["prayurawong", "prayoon", "prayun", "ประยุรวงศ"],
        "views": ["front", "quarter", "night"],
    },
    "wat_benchamabophit": {
        "q": ["Wat Benchamabophit Bangkok", "Marble Temple Bangkok"],
        "keys": ["benchamabophit", "marble temple", "เบญจมบพิตร"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "chinatown_gate_wat_traimit": {
        "q": ["Wat Traimit Bangkok", "Chinatown Gate Bangkok Odeon Circle", "Phra Maha Mondop Wat Traimit"],
        "keys": ["wat traimit", "traimit", "chinatown gate", "odeon circle", "วัดไตรมิตร", "ซุ้มประตูเฉลิมพระเกียรติ"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "ananta_samakhom": {
        "q": ["Ananta Samakhom Throne Hall", "พระที่นั่งอนันตสมาคม"],
        "keys": ["ananta samakhom", "อนันตสมาคม"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "wat_mangkon_kamalawat": {
        "q": ["Wat Mangkon Kamalawat", "Wat Leng Noei Yi Bangkok", "วัดมังกรกมลาวาส"],
        "keys": ["mangkon", "leng noei yi", "มังกรกมลาวาส"],
        "views": ["front", "quarter"],
    },
    "san_chao_pho_suea": {
        "q": ["San Chao Pho Suea Bangkok", "Tiger God Shrine Bangkok", "ศาลเจ้าพ่อเสือ"],
        "keys": ["chao pho suea", "tiger god shrine", "เจ้าพ่อเสือ"],
        "views": ["front", "quarter", "aerial"],
    },
    "king_prajadhipok_museum": {
        "q": ["King Prajadhipok Museum", "พิพิธภัณฑ์พระบาทสมเด็จพระปกเกล้าเจ้าอยู่หัว"],
        "keys": ["prajadhipok", "ปกเกล้า"],
        "views": ["front", "quarter", "night"],
    },
    "rama_viii_bridge": {
        "q": ["Rama VIII Bridge Bangkok", "สะพานพระราม 8"],
        "keys": ["rama viii", "rama 8", "พระราม 8"],
        "views": ["front", "quarter", "aerial", "night"],
    },
    "memorial_bridge_bangkok": {
        "q": ["Memorial Bridge Bangkok", "Phra Phuttha Yodfa Bridge", "สะพานพุทธ"],
        "keys": ["memorial bridge", "phuttha yodfa", "phutthayotfa", "สะพานพุทธ"],
        "views": ["front", "quarter", "night"],
    },
}

VIEW_WORDS = {
    "front": [""],
    "quarter": ["", "view", "angle"],
    "aerial": ["aerial", "drone", "panorama", "from above", "view"],
    "night": ["night", "evening", "illuminated", "dusk"],
}

BAD_TITLE = re.compile(
    r"\b(map|plan|drawing|painting|poster|logo|postcard|stamp|coin|banknote|medal|"
    r"model|miniature|interior|inside|altar|ceiling|mural|fresco|manuscript|"
    r"plaque|sign|coat_of_arms|flag|bust|portrait|diagram|section|etching|lithograph|"
    r"video|webm|ogv|pdf)\b", re.I
)
BAD_EXT = re.compile(r"\.(svg|png|gif|tif|tiff|pdf|webm|ogv)$", re.I)
OK_LICENCE = re.compile(r"^(CC BY(?!-N)(?!.*ND)|CC BY-SA|CC0|Public domain|PD|CC-BY|CC-Zero)", re.I)
BAD_LICENCE = re.compile(r"(NC|ND)", re.I)


def get_json(params):
    url = API + "?" + urllib.parse.urlencode(params)
    for attempt in range(7):
        r = subprocess.run(["curl", "-s", "-f", "-A", UA, url], capture_output=True)
        if r.returncode == 0 and r.stdout:
            try:
                return json.loads(r.stdout.decode("utf-8"))
            except Exception:
                pass
        time.sleep(6 * (attempt + 1))
    raise RuntimeError("API request failed: " + url)


def download_bytes(url):
    clean = url.split("?utm_")[0]
    for attempt in range(5):
        r = subprocess.run(["curl", "-s", "-f", "-L", "-A", UA, clean], capture_output=True)
        if r.returncode == 0 and len(r.stdout) > 5000:
            return r.stdout
        time.sleep(4 * (attempt + 1))
    return b""


def clean_html(s):
    s = re.sub(r"<[^>]+>", " ", s or "")
    return re.sub(r"\s+", " ", s).strip()


def search_candidates(term, keys=None, ban=None, limit=30):
    j = get_json({
        "action": "query", "format": "json", "generator": "search", "gsrnamespace": 6,
        "gsrsearch": term + " filetype:bitmap", "gsrlimit": limit,
        "prop": "imageinfo", "iiprop": "url|size|mime|extmetadata|mediatype",
        "iiurlwidth": THUMB_W,
        "iiextmetadatafilter": "LicenseShortName|Artist|DateTimeOriginal|ImageDescription",
    })
    out = []
    ban_re = re.compile("|".join(ban), re.I) if ban else None
    for p in (j.get("query", {}).get("pages", {})).values():
        title = p.get("title", "")
        if BAD_EXT.search(title) or BAD_TITLE.search(title):
            continue
        if ban_re and ban_re.search(title):
            continue
        ii = (p.get("imageinfo") or [{}])[0]
        w = int(ii.get("width") or 0)
        h = int(ii.get("height") or 0)
        if w < MIN_W or h < 600 or ii.get("mime") not in ("image/jpeg", "image/jpg"):
            continue
        meta = ii.get("extmetadata") or {}
        lic = clean_html((meta.get("LicenseShortName") or {}).get("value", ""))
        if not OK_LICENCE.search(lic) or BAD_LICENCE.search(lic):
            continue
        desc = clean_html((meta.get("ImageDescription") or {}).get("value", ""))
        blob = (title + " " + desc).lower()
        if keys and not any(k.lower() in blob for k in keys):
            continue
        if ban_re and ban_re.search(desc):
            continue
        artist = clean_html((meta.get("Artist") or {}).get("value", "")) or "Unknown"
        dl_url = ii.get("thumburl") or ii.get("url") or ""
        page_url = ii.get("descriptionurl") or f"https://commons.wikimedia.org/wiki/{urllib.parse.quote(title.replace(' ', '_'))}"
        score = min(w, 4000) / 1000.0 + (1.5 if w > h else 0.0)
        out.append((score, title, dl_url, page_url, artist[:80], lic))
    out.sort(key=lambda x: -x[0])
    return out


def fetch_landmarks(only=None, force=False, dry=False):
    os.makedirs(OUT_LM, exist_ok=True)
    for ltype, spec in LANDMARK_SPECS.items():
        if only and ltype not in only:
            continue
        ldir = os.path.join(OUT_LM, ltype)
        readme = os.path.join(ldir, "README.md")
        if os.path.exists(readme) and not force:
            print(f"SKIP {ltype} (README exists)")
            continue
        os.makedirs(ldir, exist_ok=True)
        used = set()
        rows = []
        views = spec.get("views", ["front", "quarter", "aerial"])
        for v in views:
            picked = None
            for q in spec["q"]:
                for vw in VIEW_WORDS.get(v, [""]):
                    term = (q + " " + vw).strip()
                    cands = search_candidates(term, spec.get("keys"), spec.get("ban"))
                    for c in cands:
                        if c[1] not in used:
                            picked = c
                            break
                    if picked:
                        break
                if picked:
                    break
            if not picked:
                # Fallback without extra view keyword
                for q in spec["q"]:
                    for c in search_candidates(q, spec.get("keys"), spec.get("ban")):
                        if c[1] not in used:
                            picked = c
                            break
                    if picked:
                        break
            if not picked:
                print(f"  MISS {ltype}/{v}")
                continue
            used.add(picked[1])
            _, title, dl_url, page_url, artist, lic = picked
            if not dry:
                data = download_bytes(dl_url)
                if not data:
                    print(f"  DL FAIL {ltype}/{v}: {dl_url}")
                    continue
                with open(os.path.join(ldir, f"{v}.jpg"), "wb") as f:
                    f.write(data)
            rows.append((f"{v}.jpg", title, page_url, artist, lic))
            print(f"  OK {ltype}/{v}.jpg <- {title} ({lic})")
            time.sleep(0.4)
        if rows and not dry:
            with open(readme, "w") as f:
                f.write(f"# Reference photos: `{ltype}`\n\n")
                f.write("Wikimedia Commons CC/PD reference images (JPEGs gitignored; metadata tracked).\n\n")
                f.write("| File | Commons title | URL | Author | Licence |\n")
                f.write("| --- | --- | --- | --- | --- |\n")
                for fn, title, purl, art, lic in rows:
                    f.write(f"| `{fn}` | {title.replace('|', '/')} | {purl} | {art.replace('|', '/')} | {lic} |\n")


def fetch_city(force=False, dry=False):
    os.makedirs(OUT_CITY, exist_ok=True)
    readme = os.path.join(OUT_CITY, "README.md")
    if os.path.exists(readme) and not force:
        print("SKIP city refs (README exists)")
        return
    used = set()
    rows = []
    for slug, desc, queries in CITY_VIEWS:
        picked = None
        for q in queries:
            for c in search_candidates(q):
                if c[1] not in used:
                    picked = c
                    break
            if picked:
                break
        if not picked:
            print(f"  MISS city/{slug}")
            continue
        used.add(picked[1])
        _, title, dl_url, page_url, artist, lic = picked
        if not dry:
            data = download_bytes(dl_url)
            if data:
                with open(os.path.join(OUT_CITY, f"{slug}.jpg"), "wb") as f:
                    f.write(data)
                rows.append((f"{slug}.jpg", desc, title, page_url, artist, lic))
                print(f"  OK city/{slug}.jpg <- {title} ({lic})")
        time.sleep(0.4)
    if rows and not dry:
        with open(readme, "w") as f:
            f.write("# Bangkok city reference photos\n\n")
            f.write("Wikimedia Commons CC/PD street, canal, river, night and aerial references (JPEGs gitignored).\n\n")
            f.write("| File | View | Commons title | URL | Author | Licence |\n")
            f.write("| --- | --- | --- | --- | --- | --- |\n")
            for fn, desc, title, purl, art, lic in rows:
                f.write(f"| `{fn}` | {desc} | {title.replace('|', '/')} | {purl} | {art.replace('|', '/')} | {lic} |\n")


def main():
    args = sys.argv[1:]
    dry = "--dry" in args
    force = "--force" in args
    do_city = "--city" in args or ("--landmarks" not in args and not any(a.startswith("--only=") for a in args))
    do_lm = "--landmarks" in args or ("--city" not in args)
    only = None
    for a in args:
        if a.startswith("--only="):
            only = set(a.split("=", 1)[1].split(","))
    if do_city:
        fetch_city(force=force, dry=dry)
    if do_lm:
        fetch_landmarks(only=only, force=force, dry=dry)


if __name__ == "__main__":
    main()

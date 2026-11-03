#!/usr/bin/env python3
"""Side-by-side landmark review pages (visual quality plan, L-1.2/L-1.3).

  python3 -I tools/landmark_compare_sheets.py [--tag=all] [--per=6] [--h=330]

Reads visual-plan/captures/<tag>/<type>_sheet.jpg (tools/capture_landmarks.gd)
and the first reference image in visual-plan/refs/landmarks/<type>/ (Commons
photo or AI-made ai_front.jpg). Writes visual-plan/captures/<tag>/compare/
page_NN.jpg: per landmark, the reference on the left and the render's front
and quarter views on the right, labelled with the type, the model's
height, width and triangle count from stats.tsv.
"""
import glob, os, sys
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
args = dict(a.lstrip("-").split("=") for a in sys.argv[1:] if "=" in a)
tag, per, H = args.get("tag", "all"), int(args.get("per", 6)), int(args.get("h", 330))
cap = f"{ROOT}/visual-plan/captures/{tag}"
refs = f"{ROOT}/visual-plan/refs/landmarks"
out = f"{cap}/compare"
os.makedirs(out, exist_ok=True)

stats = {}
for line in open(f"{cap}/stats.tsv").read().splitlines()[1:]:
    t, w, d, h, lo, tr = line.split("\t")
    stats[t] = (float(w), float(d), float(h), float(lo), int(tr))

W = 1320
types = sorted(t for t in stats if os.path.exists(f"{cap}/{t}_sheet.jpg"))
for p in range(0, len(types), per):
    page = Image.new("RGB", (W, H * per), "white")
    d = ImageDraw.Draw(page)
    for i, t in enumerate(types[p:p + per]):
        y = i * H
        r = sorted(glob.glob(f"{refs}/{t}/*.jpg"))
        if r:
            im = Image.open(r[0]).convert("RGB"); im.thumbnail((430, H - 16)); page.paste(im, (0, y + 16))
        sheet = Image.open(f"{cap}/{t}_sheet.jpg").convert("RGB")
        w2 = sheet.width // 2
        for k in range(2):  # front and quarter views
            v = sheet.crop((k * w2, 0, (k + 1) * w2, sheet.height // 2)); v.thumbnail((440, H - 16))
            page.paste(v, (440 + k * 440, y + 16))
        w, dp, h, lo, tr = stats[t]
        d.text((2, y + 2), f"{t}  {h:.0f} m tall, {max(w, dp):.0f} m wide, {tr // 1000}k tris"
               + ("" if r else "  [no reference]"), fill="black")
    page.save(f"{out}/page_{p // per:02d}.jpg", quality=84)
print(f"{len(types)} landmarks -> {out}")

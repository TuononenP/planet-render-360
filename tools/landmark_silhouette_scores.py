#!/usr/bin/env python3
"""Score manually registered landmark masks, without inventing alignment.

For each type, place <type>_photo.png and <type>_render.png in --masks.
Masks must share a canvas and camera viewpoint; foreground pixels are white,
background is black. Mask creation, alignment, and viewpoint suitability are
reviewer responsibilities. Output includes the mask bounding-box proportions
so reviewers can inspect the score rather than treating it as ground truth.
"""

import argparse
import csv
from pathlib import Path

from PIL import Image


def measure(photo_path, render_path):
    photo = Image.open(photo_path).convert("L")
    render = Image.open(render_path).convert("L")
    if photo.size != render.size:
        raise ValueError("mask dimensions differ")
    p = photo.point(lambda value: 255 if value >= 128 else 0)
    r = render.point(lambda value: 255 if value >= 128 else 0)
    pbox, rbox = p.getbbox(), r.getbbox()
    if not pbox or not rbox:
        raise ValueError("mask is empty")
    pc, rc = p.tobytes(), r.tobytes()
    intersection = sum(a and b for a, b in zip(pc, rc)) // 255
    union = sum(bool(a or b) for a, b in zip(pc, rc))
    def ratio(box):
        return (box[3] - box[1]) / (box[2] - box[0])
    return intersection / union, ratio(pbox), ratio(rbox)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--masks", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    photos = sorted(args.masks.glob("*_photo.png"))
    if not photos:
        parser.error("no *_photo.png masks found")
    rows = []
    for photo in photos:
        name = photo.name.removesuffix("_photo.png")
        render = args.masks / f"{name}_render.png"
        if not render.is_file():
            parser.error(f"missing render mask: {render}")
        try:
            iou, photo_ratio, render_ratio = measure(photo, render)
        except ValueError as exc:
            parser.error(f"{name}: {exc}")
        rows.append((name, f"{iou:.4f}", f"{photo_ratio:.4f}", f"{render_ratio:.4f}"))
    with args.output.open("w", newline="") as output:
        writer = csv.writer(output, delimiter="\t")
        writer.writerow(("type", "iou", "photo_height_width", "render_height_width"))
        writer.writerows(sorted(rows, key=lambda row: float(row[1])))
    print(f"Scored {len(rows)} mask pairs -> {args.output}")


if __name__ == "__main__":
    main()

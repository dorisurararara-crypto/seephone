"""Composite a guru bead sprite from approved parts.

SDXL keeps collapsing 'guru bead with cap and tassel' into a full mala or
abstract object, so we build it deterministically:
  - bead body: an approved single-bead sprite (dark wood sphere)
  - tassel: alpha-cropped from a previous generation that had a clean red tassel
  - gold cap: drawn flat disc with simple vertical shading

Usage:
  python composite_guru_bead.py <bead.png> <tassel_src.png> <out.png>
        [--tassel-box L,T,R,B] [--bead-scale 0.5] [--bead-cy 0.42]
"""
import argparse
from PIL import Image, ImageDraw, ImageFilter
import numpy as np


def crop_alpha(img):
    arr = np.array(img)
    ys, xs = np.where(arr[:, :, 3] > 20)
    if len(xs) == 0:
        return img
    return img.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("bead")
    ap.add_argument("tassel_src")
    ap.add_argument("out")
    ap.add_argument("--tassel-box", default="150,268,295,480")
    ap.add_argument("--bead-scale", type=float, default=0.52)
    ap.add_argument("--bead-cy", type=float, default=0.40)
    args = ap.parse_args()

    SIZE = 512
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

    bead = crop_alpha(Image.open(args.bead).convert("RGBA"))
    bw = int(SIZE * args.bead_scale)
    bead = bead.resize((bw, int(bead.height * bw / bead.width)), Image.LANCZOS)
    bx = (SIZE - bead.width) // 2
    by = int(SIZE * args.bead_cy) - bead.height // 2

    l, t, r, b = [int(v) for v in args.tassel_box.split(",")]
    tassel = Image.open(args.tassel_src).convert("RGBA").crop((l, t, r, b))
    tassel = crop_alpha(tassel)
    th = int(SIZE * 0.34)
    tassel = tassel.resize((int(tassel.width * th / tassel.height), th), Image.LANCZOS)
    tx = (SIZE - tassel.width) // 2
    ty = by + bead.height - int(bead.height * 0.06)

    canvas.alpha_composite(tassel, (tx, ty))
    canvas.alpha_composite(bead, (bx, by))

    # flat gold cap: shaded ellipse resting flush on top of the bead
    cap_w = int(bead.width * 0.38)
    cap_h = max(8, int(cap_w * 0.22))
    cap = Image.new("RGBA", (cap_w, cap_h * 2), (0, 0, 0, 0))
    cd = ImageDraw.Draw(cap)
    # vertical gradient gold
    top_col = (212, 175, 96)
    bot_col = (140, 104, 42)
    for i in range(cap_h):
        f = i / max(1, cap_h - 1)
        col = tuple(int(top_col[c] + (bot_col[c] - top_col[c]) * f) for c in range(3)) + (255,)
        cd.ellipse((0, i, cap_w - 1, i + cap_h - 1), fill=col)
    # top face slightly lighter with rim
    cd.ellipse((0, 0, cap_w - 1, cap_h - 1), fill=(228, 196, 122, 255), outline=(120, 88, 36, 255), width=2)
    # thread hole
    hr = max(3, cap_w // 16)
    cd.ellipse((cap_w // 2 - hr, cap_h // 2 - hr // 2 - 1, cap_w // 2 + hr, cap_h // 2 + hr // 2 + 1),
               fill=(60, 42, 16, 255))
    cap = cap.filter(ImageFilter.GaussianBlur(0.6))
    cx = (SIZE - cap_w) // 2
    cy = by - cap_h + int(bead.height * 0.07)
    canvas.alpha_composite(cap, (cx, cy))

    canvas.save(args.out)
    print(f"saved {args.out}")


if __name__ == "__main__":
    main()

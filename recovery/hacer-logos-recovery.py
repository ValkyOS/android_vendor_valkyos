#!/usr/bin/env python3
# ValkyOS: replace the LineageOS logo in the recovery images (xxhdpi, 768x480)
# with the ValkyOS symbol (branding/valkyos-symbol.svg), drawn here with Pillow.
# Usage: python3 hacer-logos-recovery.py <folder with orig_*.png> <output folder>
import os
import sys
from PIL import Image, ImageDraw

SS = 4  # supersampling


def bezier(p0, p1, p2, p3, n=64):
    pts = []
    for i in range(n + 1):
        t = i / n
        a = (1 - t) ** 3
        b = 3 * (1 - t) ** 2 * t
        c = 3 * (1 - t) * t ** 2
        d = t ** 3
        pts.append((a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0],
                    a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1]))
    return pts


# Paths from valkyos-symbol.svg (viewBox 0 0 1024 1024).
LEFT = [((176, 190), (337, 210), (456, 322), (512, 760)),
        ((512, 760), (427, 594), (353, 463), (284, 355)),
        ((284, 355), (247, 297), (210, 239), (176, 190))]
RIGHT = [((848, 190), (687, 210), (568, 322), (512, 760)),
         ((512, 760), (597, 594), (671, 463), (740, 355)),
         ((740, 355), (777, 297), (814, 239), (848, 190))]
LEFT_STOPS = [(0.0, (0xFF, 0xFF, 0xFF)), (1.0, (0xC9, 0xD4, 0xE8))]
RIGHT_STOPS = [(0.0, (0x72, 0x5C, 0xFF)), (0.66, (0x52, 0x6C, 0xFF)), (1.0, (0x22, 0xD3, 0xEE))]
LEFT_G = ((290, 210), (512, 760))
RIGHT_G = ((734, 210), (512, 760))

# Symbol bounds in SVG units.
X0, Y0, X1, Y1 = 176, 190, 848, 760


def color_at(stops, t):
    t = max(0.0, min(1.0, t))
    for i in range(len(stops) - 1):
        o0, c0 = stops[i]
        o1, c1 = stops[i + 1]
        if t <= o1:
            f = 0.0 if o1 == o0 else (t - o0) / (o1 - o0)
            return tuple(int(round(c0[k] + (c1[k] - c0[k]) * f)) for k in range(3))
    return stops[-1][1]


def draw_symbol(height):
    scale = height * SS / (Y1 - Y0)
    w = int(round((X1 - X0) * scale))
    h = int(round((Y1 - Y0) * scale))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for segs, stops, (g0, g1) in ((LEFT, LEFT_STOPS, LEFT_G), (RIGHT, RIGHT_STOPS, RIGHT_G)):
        poly = []
        for s in segs:
            poly += bezier(*s)
        poly = [((x - X0) * scale, (y - Y0) * scale) for x, y in poly]
        mask = Image.new("L", (w, h), 0)
        ImageDraw.Draw(mask).polygon(poly, fill=255)
        grad = Image.new("RGBA", (w, h))
        px = grad.load()
        dx, dy = g1[0] - g0[0], g1[1] - g0[1]
        dd = dx * dx + dy * dy
        for y in range(h):
            sy = y / scale + Y0
            for x in range(w):
                sx = x / scale + X0
                t = ((sx - g0[0]) * dx + (sy - g0[1]) * dy) / dd
                px[x, y] = color_at(stops, t) + (255,)
        out.paste(grad, (0, 0), mask)
    return out.resize((w // SS, h // SS), Image.LANCZOS)


def main():
    src, dst = sys.argv[1], sys.argv[2]
    os.makedirs(dst, exist_ok=True)
    sym = draw_symbol(118)
    sw, sh = sym.size
    for name in ("logo_image", "logo_image_switch", "fastbootd"):
        im = Image.open(os.path.join(src, "orig_%s.png" % name)).convert("RGB")
        if im.size != (768, 480):
            sys.exit("SIZE_ERROR %s %s" % (name, im.size))
        # Clear the LineageOS logo (x 292-476, y 203-276) inside the pill.
        im.paste((0, 0, 0), (286, 197, 483, 283))
        im.paste(sym, (384 - sw // 2, 240 - sh // 2), sym)
        im = im.quantize(colors=128, method=Image.MEDIANCUT, dither=Image.NONE)
        im.save(os.path.join(dst, "%s.png" % name), optimize=True)
        print("OK", name)


if __name__ == "__main__":
    main()

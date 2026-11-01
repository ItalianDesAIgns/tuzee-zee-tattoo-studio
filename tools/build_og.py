"""Build the hero posters (webp) from media/hero-poster.jpg.

Outputs (under site/media/):
  hero-poster.webp    1600 px wide, q72 (desktop poster)
  hero-poster-m.webp  720 px wide, centre-cropped to the 3:4 frame of hero-mobile.mp4, q72

The link-preview image (og.jpg) is rendered separately from tools/og-card.html in Chrome,
so it uses the site's own OFL fonts (Unbounded) rather than a system font:
  node tools/build_og_card.mjs

Usage: python tools/build_og.py
"""
from pathlib import Path

from PIL import Image

MEDIA = Path(__file__).resolve().parents[1] / 'site' / 'media'
SRC = MEDIA / 'hero-poster.jpg'


def centre_crop(im: Image.Image, ratio: float) -> Image.Image:
    w, h = im.size
    if w / h > ratio:
        nw = round(h * ratio)
        return im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    nh = round(w / ratio)
    return im.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))


def main() -> None:
    src = Image.open(SRC).convert('RGB')

    d = src.resize((1600, round(src.height * 1600 / src.width)), Image.LANCZOS)
    d.save(MEDIA / 'hero-poster.webp', 'WEBP', quality=72, method=6)

    m = centre_crop(src, 600 / 800)
    m = m.resize((720, round(720 * 800 / 600)), Image.LANCZOS)
    m.save(MEDIA / 'hero-poster-m.webp', 'WEBP', quality=72, method=6)
    print({p.name: p.stat().st_size for p in [MEDIA / 'hero-poster.webp', MEDIA / 'hero-poster-m.webp']})


if __name__ == '__main__':
    main()

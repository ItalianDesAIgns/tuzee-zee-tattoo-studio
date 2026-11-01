"""Psy-gradient favicon set (Rasta, 02/11/26): the logo-lab icons recoloured with the site's
iridescent gradient (acid #c8ff2e > cyan #3de6ff > UV #9d5cff > magenta #ff3dbe).

Inputs:  logo-lab/favicon.svg (detailed, 48 px+), logo-lab/favicon-small.svg (16-32 px), both #151413.
Outputs: logo-lab/favicon-psy.svg, logo-lab/favicon-small-psy.svg,
         site/media/favicon.svg, site/media/favicon.ico (16/32/48), site/media/apple-touch-icon.png (180, black)

Usage: python tools/build_favicons.py   (needs Pillow + resvg_py)
"""
import io
from pathlib import Path

import resvg_py
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
LAB = ROOT / 'logo-lab'
MEDIA = ROOT / 'site' / 'media'

# Diagonal gradient across the 64-unit icon box, same stops as the site's --iridescent.
DEFS = (
    '<defs><linearGradient id="psy" x1="12" y1="12" x2="52" y2="52" gradientUnits="userSpaceOnUse">'
    '<stop offset="0" stop-color="#c8ff2e"/><stop offset="0.32" stop-color="#3de6ff"/>'
    '<stop offset="0.64" stop-color="#9d5cff"/><stop offset="1" stop-color="#ff3dbe"/>'
    '</linearGradient></defs>'
)


def recolour(src: Path) -> str:
    """The icon's petals are rotated <use> copies, and a gradient on them would rotate too
    (every petal would get the same colour slice). So the icon becomes a white mask over one
    unrotated gradient square, and the colours sweep across the whole mark."""
    svg = src.read_text(encoding='utf-8').replace('#151413', '#ffffff')
    open_end = svg.index('>', svg.index('<svg')) + 1
    close = svg.rindex('</svg>')
    head, body = svg[:open_end], svg[open_end:close]
    gradient = DEFS[len('<defs>'):-len('</defs>')]
    out = (head + '<defs>' + gradient + '<mask id="mark" maskUnits="userSpaceOnUse" x="0" y="0" width="64" height="64">'
           + body + '</mask></defs>'
           + '<rect width="64" height="64" fill="url(#psy)" mask="url(#mark)"/></svg>\n')
    # The root fill must not paint the mask contents dark.
    out = out.replace(' fill="#ffffff"', ' fill="#ffffff"', 1)
    assert '#151413' not in out, src.name
    return out


def raster(svg: str, n: int) -> Image.Image:
    return Image.open(io.BytesIO(bytes(resvg_py.svg_to_bytes(svg_string=svg, width=n, height=n)))).convert('RGBA')


def main() -> None:
    big = recolour(LAB / 'favicon.svg')
    small = recolour(LAB / 'favicon-small.svg')
    (LAB / 'favicon-psy.svg').write_text(big, encoding='utf-8')
    (LAB / 'favicon-small-psy.svg').write_text(small, encoding='utf-8')
    (MEDIA / 'favicon.svg').write_text(big, encoding='utf-8')

    ico = [raster(small, 16), raster(small, 32), raster(big, 48)]
    ico[2].save(MEDIA / 'favicon.ico', format='ICO', sizes=[(16, 16), (32, 32), (48, 48)], append_images=ico[:2])

    touch = Image.new('RGBA', (180, 180), (5, 5, 6, 255))  # site black
    mark = raster(big, 140)
    touch.paste(mark, (20, 20), mark)
    touch.convert('RGB').save(MEDIA / 'apple-touch-icon.png')
    print('ok', [p.name for p in (MEDIA / 'favicon.svg', MEDIA / 'favicon.ico', MEDIA / 'apple-touch-icon.png')])


if __name__ == '__main__':
    main()

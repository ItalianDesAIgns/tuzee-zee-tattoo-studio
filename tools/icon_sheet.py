"""Render SVG icons at real sizes (light + dark) and 16/32 px pixel blow-ups.
Usage: python icon_sheet.py out.png a.svg [b.svg ...]
"""
import io
import sys
from pathlib import Path

import resvg_py
from PIL import Image, ImageDraw, ImageFont

PAPER, INK = (245, 242, 236), (21, 20, 19)
SIZES = [128, 64, 48, 32, 16]


def render(svg_text: str, size: int, color: str) -> Image.Image:
    svg = svg_text.replace('#151413', color).replace('currentColor', color)
    png = resvg_py.svg_to_bytes(svg_string=svg, width=size, height=size)
    return Image.open(io.BytesIO(bytes(png))).convert('RGBA')


def main() -> None:
    out, files = sys.argv[1], sys.argv[2:]
    row_h = 220
    sheet = Image.new('RGB', (1500, row_h * len(files) + 10), PAPER)
    d = ImageDraw.Draw(sheet)
    font = ImageFont.truetype('arial.ttf', 14)
    for j, f in enumerate(files):
        svg = Path(f).read_text(encoding='utf-8')
        y = 10 + j * row_h
        d.text((10, y), Path(f).name, fill=INK, font=font)
        for i, (bg, fg) in enumerate([(PAPER, '#151413'), (INK, '#f5f2ec')]):
            x0 = 10 + i * 745
            d.rectangle([x0, y + 20, x0 + 730, y + 210], fill=bg)
            x = x0 + 12
            for s in SIZES:
                sheet.paste(render(svg, s, fg), (x, y + 30 + 128 - s), render(svg, s, fg))
                x += s + 18
            for s in (32, 16):  # pixel blow-ups, 5x nearest-neighbour
                im = render(svg, s, fg)
                big = im.resize((s * 5 if s == 32 else s * 10,) * 2, Image.NEAREST)
                sheet.paste(big, (x, y + 30 + 160 - big.height), big)
                x += big.width + 18
    sheet.save(out)
    print('saved', out)


if __name__ == '__main__':
    main()

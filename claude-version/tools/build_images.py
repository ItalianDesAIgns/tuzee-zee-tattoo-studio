"""Build web images + data for every asset in images/seo-image-manifest.json.

Outputs (under claude-version/site/):
  img/<id>-xs.webp  ~320 px wide (small thumbs, phone grid srcset)
  img/<id>-s.webp   ~560 px wide (grid thumbs)
  img/<id>-l.webp   ~1600 px wide (lightbox / hero use)
  data/works.js     window.WORKS = [...]  (one record per asset)

Usage: python claude-version/tools/build_images.py
"""
import json
import re
from pathlib import Path

from PIL import Image, ImageOps

REPO = Path(__file__).resolve().parents[2]
SRC = REPO / 'images'
SITE = REPO / 'claude-version' / 'site'
IMG = SITE / 'img'
# Same photo/drawing twice in the source set (Rasta, 02/11/26): keep 006 over 007, 088 over 121.
EXCLUDE = {'TUZEE-ASSET-007', 'TUZEE-ASSET-121'}
SIZES = {'xs': 320, 's': 560, 'l': 1600}

# Folder -> (group, style). Group drives which section an asset lands in.
FOLDER_MAP = {
    'applications/sacred-geometry-mandala': ('skin', 'mandala'),
    'applications/ornamental-spine-torso': ('skin', 'ornamental'),
    'applications/oriental-irezumi': ('skin', 'oriental'),
    'applications/fine-line-botanical': ('skin', 'fineline'),
    'applications/illustrative-realism-script': ('skin', 'realism'),
    'applications/dark-blackwork-psycore': ('skin', 'blackwork'),
    'concepts-drawings/hand-drawn-flash': ('drawing', None),
    'concepts-drawings/anatomical-placement-mockups': ('mockup', None),
    'artist-studio/artist-portraits': ('artist', 'artist'),
    'artist-studio/studio-sessions': ('artist', 'artist'),
}
STYLE_FROM_MANIFEST = {
    'sacred-geometry-mandala': 'mandala', 'ornamental-spine-torso': 'ornamental',
    'oriental-irezumi': 'oriental', 'fine-line-botanical': 'fineline',
    'illustrative-realism': 'realism', 'lettering-script': 'realism',
    'dark-blackwork-psycore': 'blackwork', 'artist-studio': 'artist',
}

# The site does not target base personnel, so alt text must not either.
MILITARY = [
    (r'\s*(?:right )?(?:outside|near|by) (?:the )?Camp Humphreys(?: Gate 6)?', ' in Pyeongtaek'),
    (r'\s*(?:at )?Gate 6,?', ''),
    (r'Camp Humphreys', 'Pyeongtaek'),
    (r'캠프\s*험프리스\s*(?:게이트\s*6)?\s*(?:인근|근처)?', ''),
    (r'게이트\s*6\s*(?:인근|근처)?', ''),
]


def clean(text: str) -> str:
    for pat, rep in MILITARY:
        text = re.sub(pat, rep, text)
    # Brand is a studio, not an atelier.
    text = re.sub(r'[Aa]telier', 'studio', text).replace('아틀리에', '스튜디오')
    # Drop a trailing "in Pyeongtaek" when the place is already named earlier.
    if text.count('Pyeongtaek') > 1:
        text = re.sub(r' in Pyeongtaek$', '', text)
    return re.sub(r'\s{2,}', ' ', text).strip()


def main() -> None:
    IMG.mkdir(parents=True, exist_ok=True)
    (SITE / 'data').mkdir(parents=True, exist_ok=True)
    manifest = json.loads((SRC / 'seo-image-manifest.json').read_text(encoding='utf-8'))
    records = []
    for a in manifest['assets']:
        if a['id'] in EXCLUDE:
            continue
        rel = a['seo_relative_path']
        folder = rel.rsplit('/', 1)[0]
        group, style = FOLDER_MAP[folder]
        style = style or STYLE_FROM_MANIFEST.get(a['style'], 'mandala')
        num = a['id'].rsplit('-', 1)[1]
        im = ImageOps.exif_transpose(Image.open(SRC / rel)).convert('RGB')
        w, h = im.size
        for key, target in SIZES.items():
            out = IMG / f'{num}-{key}.webp'
            if not out.exists():
                copy = im.copy()
                if copy.width > target:
                    copy = copy.resize((target, round(copy.height * target / copy.width)), Image.LANCZOS)
                copy.save(out, 'WEBP', quality={'l': 80, 's': 76, 'xs': 74}[key], method=6)
        records.append({
            'id': num, 'group': group, 'style': style, 'placement': a['placement'],
            'w': w, 'h': h, 'orig': rel, 'file': rel.rsplit('/', 1)[1].removesuffix('.jpg'),
            'en': clean(a['alt_en']), 'ko': clean(a['alt_kr']),
        })
    js = 'window.WORKS = ' + json.dumps(records, ensure_ascii=False, indent=0) + ';\n'
    (SITE / 'data' / 'works.js').write_text(js, encoding='utf-8')
    groups = {}
    for r in records:
        groups[r['group']] = groups.get(r['group'], 0) + 1
    print('records', len(records), groups)
    print('webp bytes', sum(p.stat().st_size for p in IMG.glob('*.webp')))
    leftovers = [r['en'] for r in records if re.search('Humphreys|Gate 6', r['en'])] + [r['ko'] for r in records if re.search('험프리스|게이트', r['ko'])]
    print('military mentions left:', len(leftovers), leftovers[:3])


if __name__ == '__main__':
    main()

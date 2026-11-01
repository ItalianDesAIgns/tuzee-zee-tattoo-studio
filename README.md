# TUZEE Tattoo Studio — Pyeongtaek, South Korea

Official bilingual (`EN` / `KO`) web project, SEO image archive, brand research dossier, and engineering review for **TUZEE Tattoo Studio** (`@tuzee_tattoo`), located at Capitolium Building Suite 114, 16 Anjeongshopping-ro, Paengseong-eup, Pyeongtaek-si, Gyeonggi-do.

---

## Canonical Repository Structure

```text
├── site/                           # Production static web bundle (deployed to Vercel)
│   ├── index.html                  # Single-page bilingual (EN/KO) "Blacklight" site
│   ├── css/styles.css              # Design system, responsive layout & motion
│   ├── js/app.js                   # Gallery filter, UV torch, compare slider, brief builder
│   ├── data/works.js               # 125 indexed works & flash pieces + 10 paper→skin pairs
│   ├── img/                        # 500+ responsive WebP derivatives (-xs, -s, -m, -l)
│   ├── media/                      # Hero MP4s, WebP posters, OG card, compass SVG mark
│   └── vercel.json                 # Clean URLs & immutable asset cache headers
│
├── tools/                          # Build, asset optimization & local preview scripts
│   ├── build_images.py             # Converts images/ to WebP variants & generates site/data/works.js
│   ├── build_og.py                 # Builds desktop & mobile WebP hero posters
│   ├── build_og_card.mjs           # Renders tools/og-card.html to site/media/og.jpg
│   ├── icon_sheet.py               # SVG icon & favicon sheet renderer
│   └── serve.mjs                   # Local HTTP preview server with gzip support
│
├── images/                         # Source SEO image archive (127 high-res studio assets)
│   ├── seo-image-manifest.json     # Master SEO metadata manifest read by tools/build_images.py
│   ├── IMAGE_CATALOG.md            # Human-readable visual catalog of all 127 assets
│   ├── logo/                       # Studio logo & SVG crest variations
│   ├── artist-studio/              # Artist portraits & live studio session photography
│   ├── applications/               # 68 real skin tattoo works organized by anatomical placement
│   └── concepts-drawings/          # 55 1-of-1 flash drawings & 3D anatomical mockups
│
├── suggestions-to-claude/          # Hygiene, tool safety & audit recommendations (applied on `staging`)
│   ├── 01-hygiene-tool-safety-and-aftercare.md          # Bilingual Hygiene, Single-Use Tool Safety & 30-Day Aftercare
│   ├── 02-drop-in-hygiene-section-for-claude-site.html  # Ready-to-paste HTML/CSS/i18n module in Blacklight style
│   ├── 03-claude-version-audit-and-suggestions.md       # Technical, SEO & CRO audit of site/
│   └── 04-preserved-atelier-hygiene-reference.html      # Archived interactive Sacred Geometry & C7–Sacrum Topology Lab
│
├── specs/                          # Polish & QA specifications (polish-01.spec.md, polish-01b.addendum.md)
├── hero-video/                     # HyperFrames source project for the 145 BPM UV hero reel
├── logo-lab/                       # Vectorized 8-fold compass lotus & wordmark candidates
├── prototypes/                     # Early visual direction prototypes (rounds 1–2)
├── BRAINSTORM.md                   # Product direction, audience decisions & build log
├── COMPETITORS.md                  # Local Pyeongtaek / Seoul competitor scan
├── tuzee_tattoo_brand_research_digital_strategy_dossier.md  # Brand & market research dossier
└── vercel.json                     # Vercel project configuration (outputDirectory: "site")
```

---

## Local Development

```bash
# Start the local static preview server on http://localhost:4180
node tools/serve.mjs 4180

# Open the production site locally:
# http://localhost:4180/site/
```

## Rebuilding Derived Assets

```bash
# Rebuild responsive WebP images & site/data/works.js from images/seo-image-manifest.json
python tools/build_images.py

# Rebuild desktop & mobile WebP hero posters
python tools/build_og.py
```

## Branches & Deployment (Vercel)

- **`main`:** Canonical production build (`site/`).
- **`staging`:** Includes all hygiene, single-use tool safety, aftercare, SEO (`alt` attributes, canonical/OG URLs, `robots.txt`, `sitemap.xml`), and UX/CRO enhancements from [`suggestions-to-claude/`](./suggestions-to-claude).

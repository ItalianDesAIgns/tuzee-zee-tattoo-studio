# TUZEE Tattoo Studio — Gate 6, Camp Humphreys (Pyeongtaek)

Official bilingual (`EN` / `KO`) web project, SEO image archive, brand research dossier, and engineering review for **TUZEE Tattoo Studio** (`@tuzee_tattoo`), located outside **Gate 6, Camp Humphreys** (Capitolium Building Suite 114, 16 Anjeongshopping-ro, Paengseong-eup, Pyeongtaek-si, Gyeonggi-do).

---

## Repository Structure

```text
├── claude-version/
│   ├── site/                       # Production static site (deployed to Vercel)
│   │   ├── index.html              # Single-page bilingual (EN/KO) "Blacklight" build
│   │   ├── css/styles.css          # Design system, responsive layout & motion
│   │   ├── js/app.js               # Gallery filter, UV torch, compare slider, brief builder
│   │   ├── data/works.js           # 125 indexed works & flash pieces + 10 paper→skin pairs
│   │   ├── img/                    # 500+ responsive WebP derivatives (-xs, -s, -m, -l)
│   │   ├── media/                  # Hero MP4s, WebP posters, OG card, compass SVG mark
│   │   └── vercel.json             # Vercel cleanUrls & immutable asset cache headers
│   ├── tools/                      # Image, OG card & local preview scripts
│   ├── specs/                      # Polish & QA specifications
│   ├── hero-video/                 # HyperFrames source project for the hero reel
│   ├── logo-lab/                   # Vectorized sacred-geometry compass & wordmark assets
│   ├── BRAINSTORM.md               # Product & design direction notes
│   └── COMPETITORS.md              # Local Anjeong-ri / Camp Humphreys competitor notes
│
├── suggestions-to-claude/
│   ├── 01-hygiene-tool-safety-and-aftercare.md          # Bilingual Hygiene, Single-Use Tool Safety & 30-Day Aftercare
│   ├── 02-drop-in-hygiene-section-for-claude-site.html  # Ready-to-paste HTML/CSS/i18n module in Claude's Blacklight style
│   ├── 03-claude-version-audit-and-suggestions.md       # Technical, SEO & CRO audit of claude-version/site/
│   └── 04-preserved-atelier-hygiene-reference.html      # Archived interactive Sacred Geometry & C7–Sacrum Topology Lab
│
├── images/
│   ├── seo-image-manifest.json     # Master SEO metadata manifest for all 127 studio assets
│   ├── IMAGE_CATALOG.md            # Human-readable visual catalog of all 127 assets
│   ├── logo/                       # Studio logo & SVG crest variations
│   ├── artist-studio/              # Artist portraits & live studio session photography
│   ├── applications/               # 68 real skin tattoo works organized by anatomical placement
│   └── concepts-drawings/          # 55 1-of-1 flash drawings & 3D anatomical mockups
│
└── tuzee_tattoo_brand_research_digital_strategy_dossier.md  # Comprehensive brand & market research dossier
```

---

## Local Development

```bash
# Serve the repository root on http://localhost:4180
node claude-version/tools/serve.mjs 4180
# Open http://localhost:4180/claude-version/site/
```

## Deployment (Vercel)

The production site lives in [`claude-version/site/`](./claude-version/site).

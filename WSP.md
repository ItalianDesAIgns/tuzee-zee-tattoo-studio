# WSP.md — Workflow State Protocol & Shared Agent Handover (Claude + Antigravity)

> **Last Updated:** 2026-11-02  
> **Repository:** https://github.com/ItalianDesAIgns/tuzee-zee-tattoo-studio  
> **Purpose:** Shared source of truth for **Claude** and **Antigravity (Gemini)** so either agent can resume work on **TUZEE Tattoo Studio** without losing context, breaking paths, or violating editorial/brand decisions.

---

## 1. Live Environments & Git Branch Topology

| Branch | Role | Live Vercel URL | Status |
| :--- | :--- | :--- | :--- |
| **`main`** | Baseline canonical build (promoted from `/claude-version` with all paths reconciled) | https://tuzee-zee-tattoo-studio.vercel.app | Live (`200 OK`) |
| **`staging`** | Enhanced streamlined single-page build with all `/suggestions-to-claude` improvements, horizontal footer socials fix, and rewritten `H2`/body copy | https://tuzee-zee-tattoo-studio-git-staging-italiandesaigns-projects.vercel.app<br>*(Latest deploy: https://tuzee-zee-tattoo-studio-hpulmkxfl-italiandesaigns-projects.vercel.app)* | Live (`200 OK`) |

---

## 2. Canonical Directory Structure (Root Reorganized)

The temporary `/claude-version` wrapper folder and the superseded 6-page root HTML files have been removed. The repository now follows a flat, canonical structure at the root:

```text
D:\GitHub\tuzee-zee-tattoo-studio\
├── site/                           # Production static web root (Vercel outputDirectory: "site")
│   ├── index.html                  # Streamlined single-page bilingual (EN/KO) build
│   ├── css/styles.css              # "Blacklight" design system (#050506 void, #c8ff2e acid, Unbounded/Archivo)
│   ├── js/app.js                   # State, i18n dictionary (T.en / T.ko), gallery filters, UV torch, compare slider, DM builder
│   ├── data/works.js               # 125 studio works & flash items + 10 paper-to-skin comparison pairs
│   ├── img/                        # 500+ responsive WebP derivatives (<id>-xs.webp, -s.webp, -l.webp)
│   ├── media/                      # hero-1080.mp4, hero-mobile.mp4, hero-poster*.webp, og.jpg, a-compass.svg, favicons
│   ├── robots.txt                  # [staging] Crawler directives + sitemap pointer
│   ├── sitemap.xml                 # [staging] Bilingual hreflang XML sitemap
│   └── vercel.json                 # Immutable cache headers for /(img|media|css|js|data)/(.*)
│
├── tools/                          # Build, asset generation & local server scripts (paths reconciled to repo root)
│   ├── build_images.py             # Reads images/seo-image-manifest.json -> writes site/img/*.webp & site/data/works.js
│   ├── build_og.py                 # Generates site/media/hero-poster.webp & hero-poster-m.webp
│   ├── build_og_card.mjs           # Renders tools/og-card.html -> site/media/og.jpg via Puppeteer (:4180/tools/og-card.html)
│   ├── icon_sheet.py               # Renders SVG favicon test sheets via resvg_py
│   ├── og-card.html                # 1200x630 OpenGraph card template
│   └── serve.mjs                   # Local static server with gzip on http://localhost:4180 (serves repo root)
│
├── images/                         # Master source image archive (127 unique studio assets)
│   ├── seo-image-manifest.json     # Canonical metadata manifest consumed by tools/build_images.py (DO NOT DELETE)
│   ├── IMAGE_CATALOG.md            # Human-readable visual index of all 127 assets
│   ├── logo/                       # Source logo files
│   ├── artist-studio/              # 4 artist portraits & studio session photos (001–004)
│   ├── applications/               # 68 real skin tattoo photos across 5 style folders
│   └── concepts-drawings/          # 55 hand-drawn flash designs & 3D body placement mockups
│
├── suggestions-to-claude/          # Extracted Hygiene/Tool-Safety content & engineering audit
│   ├── 01-hygiene-tool-safety-and-aftercare.md
│   ├── 02-drop-in-hygiene-section-for-claude-site.html
│   ├── 03-claude-version-audit-and-suggestions.md
│   └── 04-preserved-atelier-hygiene-reference.html
│
├── specs/                          # QA & polish specifications (polish-01.spec.md, polish-01b.addendum.md)
├── hero-video/                     # HyperFrames source project (raw >70MB renders in renders/ & .hyperframes/ are gitignored)
├── logo-lab/                       # Traced 8-fold compass lotus SVG/PNG candidates & hand-drawn favicons
├── prototypes/                     # Early round 1–2 visual prototypes (IMG path updated to ../images/)
├── BRAINSTORM.md                   # Product direction, user decisions & build log
├── COMPETITORS.md                  # Pyeongtaek / Seoul competitor analysis
├── tuzee_tattoo_brand_research_digital_strategy_dossier.md  # Initial brand & market research dossier
├── vercel.json                     # Root Vercel config ("outputDirectory": "site")
└── WSP.md                          # This shared handover file
```

---

## 3. Hard Editorial, Brand & Legal Guardrails (DO NOT VIOLATE)

Both agents must strictly enforce these rules established by the user (`Rasta`) in [`BRAINSTORM.md`](./BRAINSTORM.md):

1. **Zero Military-Targeted Copy:**
   - Do **not** mention USFK, DoD, Camp Humphreys, Gate 6, AR 670-1, PCS/DEROS, uniforms, or "for soldiers" anywhere in visible copy or image `alt` attributes.
   - Present the location purely as a civilian address: `Capitorium #114, 52 Anjeongshopping-ro, Paengseong-eup, Pyeongtaek` (`경기도 평택시 팽성읍 안정쇼핑로 52, 캐피토리움 114호`).
2. **Zero Unverified Legal / Medical / Rating Claims:**
   - This is a **pitch preview** (`Pitch preview: some details await Zee’s confirmation`).
   - Do **not** invent star ratings, review counts, prices, hourly rates, deposit amounts, specific ink brand certifications ("EU REACH vegan"), or unverified government statutes ("2026 MOHW 3-zone compliance" / "Supreme Court May 2026") unless Zee explicitly confirms them.
   - In the `#hygiene` section and `#aftercare` modal, stick strictly to observable, universal single-use studio practices (single-use membrane cartridges unsealed from the blister pack in front of the client, disposable barrier film on machine/grip/armrest/lamp/bed, single-use ink caps, sealed sharps container, standing stencil mapping, and breathable dermal film + SPF 50+ aftercare).
3. **Brand Name & Mark:**
   - The studio is **TUZEE Tattoo Studio** (never "Atelier").
   - The brand mark (`site/media/a-compass.svg`) is the **8-fold compass lotus** traced from Zee's own drawing `#084` (never use a 6-fold hexagram or 5-fold pentagram).
4. **Copywriting Discipline (No AI Tells):**
   - Never use `"It's not X, it's Y"` contrast reveals (e.g., *"Drawn to fit you, not copied onto you"*), `"No X, no Y"` negation lists, or cryptic two-word fragments (*"Lights down."*, *"Already living on someone."*).
   - Keep `H2`s and body copy concrete, craft-focused, and natural in both English and Korean.

---

## 4. What Was Added on the `staging` Branch (vs. `main`)

The `staging` branch implements a **streamlined single-page architecture** combining Claude's `site/` build with all recommendations from [`suggestions-to-claude/`](./suggestions-to-claude):

1. **Footer Social Icons Horizontal Layout Fix (`site/css/styles.css`):**
   - *Bug on `main`:* `.footer-grid ul { display: grid; gap: 8px; }` had higher CSS specificity (`0,1,1`) than `.socials { display: flex; }` (`0,1,0`), causing the 4 social icons in the footer to stack vertically.
   - *Fix on `staging`:* Changed `.footer-grid ul` to `.footer-grid ul:not(.socials)` and defined `ul.socials, .socials { display: flex; flex-direction: row; flex-wrap: wrap; align-items: center; gap: 10px; }` with `.socials li { display: inline-flex; }`.
2. **Rewritten Section `H2`s & Body Copy (`site/index.html` & `site/js/app.js`):**
   - **01 / Hand-Drawn Geometry (`#uv`):** *"Eight-fold symmetry, drawn from a single center."* / *"하나의 중심에서 시작된 8각 대칭."*
   - **02 / Paper to Skin (`#paper`):** *"Shaped around collarbone, spine, and muscle."* / *"쇄골과 척추, 근육의 흐름에 맞춘 설계."*
   - **03 / Selected Work (`#work`):** *"Finished work on skin."* / *"피부 위에 완성된 작업들."*
   - **04 / Available Designs (`#designs`):** *"Original drawings ready to claim."* / *"주인을 기다리는 오리지널 도안."*
   - **05 / The Artist · 지경은 (`#zee`):** *"Fifteen years of ink across six countries."* / *"6개국을 거쳐 쌓아온 15년의 밀도."*
   - **Hygiene & Tool Safety (`#hygiene`):** *"Unsealed in front of you. Wrapped fresh for every session."* / *"눈앞에서 개봉하는 1회용 멸균 니들, 매 세션 새 배리어 래핑."*
   - **06 / Book a Session (`#book`):** *"Send your idea straight to Zee."* / *"원하는 작업을 Zee에게 직접 보내보세요."*
   - **07 / Studio & Directions (`#visit`):** *"Private studio in Paengseong-eup, Pyeongtaek."* / *"평택 팽성읍 안정쇼핑로 52, 캐피토리움 114호."*
3. **Compact 4-Pillar Hygiene & Tool Safety Strip (`#hygiene`) + `<dialog id="aftercare">` Modal:**
   - Added between `#zee` and `#book` (with nav links in Header, Mobile Menu, and Footer).
   - Includes a `30-day aftercare & safety guide` button that opens `<dialog class="aftercare" id="aftercare">` with the 4-stage 30-day dermal healing timeline and 4-zone anatomical stencil calibration notes.
4. **Progressive Gallery Reveal (`#workMore` & `#designMore`):**
   - Shows the first `16` works in `#workGrid` (when filter is `All`) and first `12` pieces in `#designGrid`, with a `Show all 67 works` / `Show all 28 pieces` button to prevent scroll fatigue while keeping all 125 `<img>` nodes in the DOM.
5. **Image Search SEO (`alt` Attributes) & Checkmark Fix:**
   - Populated `alt="${esc(w[lang])} (#${w.id})"` directly on all 125 gallery `<img>` elements and compare-pair thumbnails (instead of `alt=""`).
   - Fixed corrupted UTF-8 `content: "¹3"` on `.tile-save[aria-pressed="true"]::before` in `site/css/styles.css` to `content: "\2713"` (`✓`).
6. **Technical SEO & CRO Polish:**
   - Added `<link rel="canonical">`, absolute `https://` URLs for `og:image`, `og:url`, `twitter:image`, and JSON-LD `image`/`url`, `fetchpriority="high"` on hero poster preloads, `site/robots.txt`, and `site/sitemap.xml`.
   - Added live saved-reference counter badge (`Start your design (2)` / `Book (2)`) and a `Clear all` button when 2+ references are saved.
   - Added a polite clipboard fallback toast when clicking the placeholder `hello@example.com` email button.

---

7. **Hero Claim Revert (`site/index.html` & `site/js/app.js`):**
   - Reverted hero claim strictly back to *"I draw every tattoo by hand, for one body only: yours."* / *"모든 타투를 손으로 그립니다. 오직 당신의 몸을 위해."* with artist signature *"Zee, artist"*.
8. **Location Heading Word-Wrap & Hyphenation Fix (`#visit-title`):**
   - Wrapped `Paengseong‑eup, Pyeongtaek.` in `<span class="visit-loc" data-i18n="visitLoc">` at `0.68em` inside a scaled `#visit-title` (`clamp(1.85rem, 1rem + 2.5vw, 3.6rem)`).
   - Added a non-breaking hyphen (`\u2011` / `&#8209;`) to `Paengseong‑eup` to prevent awkward line breaks and hyphen wrapping across screens.
9. **Footer Brand Lockup (`TATTOO STUDIO`):**
   - Replaced standalone `TUZEE` text with a stacked brand lockup: `TUZEE` on the left and stacked two-line `TATTOO<br>STUDIO` on the right.
   - Configured `.footer-brand` with flex `align-items: stretch` and `.footer-sub` (`font-size: 0.385em; line-height: 0.82; justify-content: space-between; text-transform: uppercase;`) so the two stacked words together have the exact height from the top edge to the bottom baseline of `TUZEE`.
   - Applied the continuous `.irid.liquid` UV neon gradient across both `TUZEE` and `TATTOO STUDIO`.

---

## 5. Pending Items & Next Steps

1. **Merge `staging` → `main` (Upon User Approval):**
   - Once the user approves the `staging` preview, merge `staging` into `main` (`git checkout main && git merge staging && git push origin main`) so https://tuzee-zee-tattoo-studio.vercel.app serves the updated build.
2. **Post-Pitch Confirmations from Zee:**
   - Replace `LINKS.email = 'hello@example.com'` in `site/js/app.js` with Zee's real email address (or remove the email button if she only uses Instagram DM + KakaoTalk).
   - Native Korean copy check by Zee on `T.ko` strings in `site/js/app.js` and `data/works.js`.
   - Confirm whether the 10 drawing-to-skin pairs in `PAIRS` (`site/js/app.js`) are exact matches.
   - Remove `.ft-fine` pitch disclaimer (`ftPitch`) once Zee approves the site for official launch.


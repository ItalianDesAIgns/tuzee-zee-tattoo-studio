# Tuzee Tattoo Studio — Project Memory & Lessons Learned (`.agents/memory.md`)

## 2026-11-02 — Multi-Page Luxury Website Build, 127-Asset SEO Audit & Lighthouse 100/100/100/100

### 1. Portfolio Asset Audit & Classification (`images/`)
- **Root Cause / Finding:** The raw `images/` archive contained 128 files with 1 exact SHA-256 duplicate (`514412458_... (1).jpg`), 2 spelling typos (`floreal`, `memeto`), and 8 digital flash overlays mixed inside `images/applications/`.
- **Applied Fix:** Visually audited all 128 images, removed the exact duplicate, corrected typos, moved the 8 digital overlays into `images/concepts-drawings/anatomical-placement-mockups/`, organized all 127 unique images across 10 semantic subfolders, and compiled `images/seo-image-manifest.json` + `images/IMAGE_CATALOG.md` + `assets/js/portfolio-data.js`.

### 2. Master Logo Integration (`images/logo/tuzee_tattoo_atelier_master_logo_svg.svg`)
- **Applied Fix:** Integrated the 24-Fold Sacred Mandala, Sri Yantra & 0.25mm T-Needle Monogram SVG crest across all 6 pages (`<link rel="icon">`, header brand mark, hero medallion, footer crest, `JSON-LD` `logo`, and broken-image fallback handler in `assets/js/atelier-core.js`).

### 3. WCAG 2.2 `label-content-name-mismatch` Fix
- **Root Cause:** Adding `aria-label="Tuzee Tattoo Atelier Home"` to `<a href="index.html">` whose visible text is `"TUZEE ATELIER KYUNGEUN CHI • GATE 6 STE 114"` triggered Lighthouse `label-content-name-mismatch`.
- **Applied Fix:** Removed the redundant `aria-label` on the header brand anchor so assistive technologies read the exact visible text + logo `alt` attribute. Result: **100 Accessibility / 100 Best Practices / 100 SEO / 100 Agentic Browsing (30 Passed, 0 Failed)**.


## 2026-11-02 (Session 2) — Canonical Root Refactor, `staging` Streamlined Single-Page Build & Copy/CSS Fixes

### 1. Canonical Root Promotion (Removal of `/claude-version`)
- **Action:** Promoted all contents of `claude-version/` (`site/`, `tools/`, `specs/`, `hero-video/`, `logo-lab/`, `prototypes/`, `BRAINSTORM.md`, `COMPETITORS.md`) to the repository root, removed dead-weight superseded root files, and reconciled relative paths across `tools/build_images.py`, `tools/build_og.py`, `tools/build_og_card.mjs`, `tools/serve.mjs`, `prototypes/*.html`, `.claude/launch.json`, `.gitignore`, and `vercel.json` (`"outputDirectory": "site"`).

### 2. Footer `.socials` Vertical Stacking Bug (`site/css/styles.css`)
- **Root Cause:** `.footer-grid ul { display: grid; gap: 8px; }` had higher CSS specificity (`0,1,1`) than `.socials { display: flex; }` (`0,1,0`), overriding flex layout and stacking the footer social icons vertically.
- **Applied Fix:** Scoped `.footer-grid ul:not(.socials)` and explicitly styled `ul.socials, .socials { display: flex; flex-direction: row; flex-wrap: wrap; align-items: center; gap: 10px; }` with `.socials li { display: inline-flex; }`.

### 3. Corrupted Checkmark Glyph in `.tile-save[aria-pressed="true"]::before` (`site/css/styles.css`)
- **Root Cause:** Line 308 of `site/css/styles.css` contained `content: "¹3";` (mojibake from `\2713`).
- **Applied Fix:** Replaced with `content: "\2713";` (`✓`).

### 4. Streamlined Single-Page Architecture & Copy Rewrite (`staging` branch)
- **Applied Fix:** Added compact 4-pillar Hygiene & Tool Safety strip (`#hygiene`), `<dialog id="aftercare">` 30-day healing & anatomical stencil modal, progressive gallery reveal (`16` initial works / `12` initial designs), bilingual SEO `alt` attributes on all 125 gallery images, live saved-reference counter badge, placeholder email clipboard guard, and rewrote all section `H2`s and body copy in EN/KO to eliminate AI contrast-reveal tells and cryptic fragments. Documented full handover state in `WSP.md`.


### 5. #visit Heading Hyphenation & Footer Brand Height Alignment
- **#visit Title Wrapping:** On certain viewports, Paengseong-eup, Pyeongtaek. wrapped awkwardly. Fixed by applying .visit-loc at 0.68em and a non-breaking hyphen Paengseong‑eup (‑) so the location line never hyphen-breaks across rows.
- **Footer Brand Height Matching:** Added stacked Tattoo Studio (uppercase TATTOO / STUDIO) to the footer brand. Implemented in pure CSS via .footer-brand flex align-items: stretch and .footer-sub font-size: 0.385em, line-height: 0.82, justify-content: space-between, matching the exact height of TUZEE across all viewports with liquid UV gradient continuity.

# Tuzee Tattoo Studio - Claude version: brainstorm plan

Date: 02/11/26. Status: brainstorming, nothing built. Working dir: `/claude-version` (Gemini's root files untouched).

## 1. Diagnosis of Gemini's version

**Keep (ideas, not code)**
- Image audit + SEO filenames + `seo-image-manifest.json` (127 assets, sorted by style). Real value, reuse as-is.
- Separating healed work on skin from flash/drawings/mockups.
- Korean taxi card + 1-tap copy of the Korean address + Naver/Kakao map links.
- EN/KR language support. Military-friendly notes (placement rules, PCS timing).
- Booking that ends in a DM (Instagram / Kakao / WhatsApp), not an email void.

**Kill**
- Logo: interlocked triangles in the centre read as a hexagram. Hard no.
- Jargon copy: "Dorsal Architecture", Φ = 1.618033, "0.25mm 1RL", "C7-to-Sacrum", "Haute-Couture Atelier". Clients want to know: is she good, is it safe, what does it cost, how do I book.
- "Atelier" everywhere (brand is **Studio**). Gold-on-black luxury cliche.
- 4-step estimator with hours/session calculation: friction, and a promise of a price she has not given.
- 6 pages for a solo artist; top bar with 4 widgets before the content.
- AI hero video (generic tribal texture, not her work).
- **Unverified claims** that are a legal/trust risk if published:
  - "Supreme Court ruling May 2026" and "2026 MOHW guidelines": no source found. The Tattooist Act passed on 25/09/25 but is only in force after a 2-year grace period from promulgation (~2027).
  - "EO-gas sterilised", "EU REACH vegan pigments", "3-zone separation", "Lighthouse 100" etc. Only publish what Zee confirms.

## 2. Proposed direction (to challenge, not final)

**Concept: "Her hand, her geometry."** The site is a quiet frame around Zee's drawings and healed work. Light paper-white base (her drawings are graphite on paper) with ink-black type; dark mode optional. The mandala logo is **traced from one of her real drawings**, not invented.

**Logo shortlist from her drawings** (all 8-fold or 10-fold, so no hexagram; avoid 6-fold and 5-fold = pentagram risk):
- `radial-compass-star-dotwork-lotus-mandala-drawing` (8-fold, clean, scales to favicon) - my pick
- `ornamental-flame-petal-lotus-dotwork-mandala-drawing` (organic, more personal)
- `eight-point-star-ornamental-dotwork-mandala-drawing` (bold, high contrast)
- Method: vector-trace her drawing, then make a simplified favicon version. Wordmark "TUZEE" + "Tattoo Studio".

**Sitemap (one-page-first, 3 URLs)**
1. `/` Home, one scroll: hero (her work, not stock) > styles (6 chips) > selected work > about Zee (15 yrs, travels) > how booking works (3 steps) > safety/aftercare short > find us (map, taxi card) > book CTA.
2. `/work` Gallery with style filters; tap image > "I want something like this" (pre-fills booking).
3. `/flash` Available designs (only if Zee actually sells flash; claim button pre-fills booking).
4. `/book` Short form: idea, placement (body tap or list), approx size (S/M/L with cm/in), reference images, preferred channel. Sends a ready-made EN/KR message to IG/Kakao/WhatsApp. No price calculator.
- Korean under `/ko/`. Taxi card = modal, not a page.

**Stack (proposal):** Astro (static, built-in image optimisation for 127 photos, EN/KR i18n routing, content from the manifest) on Vercel. No backend unless a form service is wanted. Tests: Playwright + axe + Lighthouse budget.

## 3. Brainstorm steps (one at a time with Rasta)

1. **Facts lock**: answer the questions in section 4. Nothing gets written as copy until confirmed.
2. **Positioning + audience**: who is customer #1 (US military at Humphreys vs Korean locals vs Seoul collectors). Drives language default, tone, imagery.
3. **Competitor scan** (I do it): 6-10 studios in Pyeongtaek / Songtan / Seoul fine-line + 3-4 world-class mandala artists' sites. Output: what converts, what to avoid.
4. **Logo**: trace the 3 shortlisted drawings, render side by side at 512px and 32px favicon. Rasta + Zee pick.
5. **Visual direction**: 2-3 home-hero prototypes (light paper / dark ink / split) in a picker. Pick one.
6. **Booking flow**: agree fields and the message template; test the IG/Kakao/WhatsApp deep links on a phone.
7. **Copy**: plain EN, KR reviewed by a native speaker (Zee).
8. **Spec freeze**: SPEC.md + acceptance tests + DoD + threat model for the booking form (PII: names, photos of skin). Then Sonnet builds, I verify in a fresh pass.

## 4. Questions only Rasta / Zee can answer

1. Address: is "Capitolium Bldg Ste 114, outside Gate 6" correct and current? Exact Korean address + Naver/Kakao place link?
2. Primary customer: mostly US military/DoD, or Korean clients? Which language opens by default?
3. Booking channel she actually answers fastest: Instagram DM, KakaoTalk, WhatsApp, email? Kakao open-chat ID?
4. Pricing: show anything (minimum / hourly / "from")? Deposit policy?
5. Does she sell flash (first-come designs), or is everything custom?
6. Hygiene facts she can stand behind (single-use needles, autoclave, ink brand)? Any licence/certificate?
7. Hours, walk-ins or appointment only, payment methods (USD, KRW, card)?
8. Domain: owned yet? Hosting: Vercel ok?
9. Is she still travelling for guest spots (worth a "guest spots" section)?
10. Better photos available (higher-res originals, healed shots, studio interior, her portrait in colour)?
11. Brand colours or fonts she already uses on Instagram, or free hand?

### Answers (02/11/26)

- **Context: this is a PITCH site.** Zee has not commissioned it yet. Unconfirmed facts ship as clearly marked placeholders that Zee confirms after the pitch.
- **Address:** confirmed, Capitolium Bldg Ste 114, outside Gate 6, Camp Humphreys.
- **Audience:** Korean and English speakers, equally (amended, see "Decision: audience changed" below). Opens in the browser's language with a visible EN/KR toggle.
- **Channels:** Instagram DM, KakaoTalk, Email. The order follows the language: KR puts Kakao first, then Instagram; EN puts Instagram first, then email. KakaoTalk = 1:1 open chat `https://open.kakao.com/o/siUk2cie` (taken from her Instagram bio; the page title reads "Tuzee tattoo."; tracking params removed). The email address is a placeholder until Zee confirms it.
- **Defaults taken (Rasta did not object):** full site with placeholders for the pitch (Home + Work + Book, EN/KR); drawings shown as "designs - ask about this one" (no flash-sale promise); hosted on a Vercel preview URL until she says yes; visual direction picked from 3 rendered prototypes.
- **Pricing:** no prices on the site. Quotes are given per project in the DM.

### Decision: audience changed (Rasta, 02/11/26)

- USFK policy puts **all tattoo shops off-limits** to USFK personnel (see COMPETITORS.md section 0).
- **No military-targeted copy anywhere**: no AR 670-1, PCS/DEROS, "military-friendly" or "for soldiers" wording. The location is given as a plain address and map.
- Audience: Korean locals + English-speaking international residents and visitors + Seoul/SRT collectors. This replaces the earlier "Korean locals and US base personnel" answer.

### Logo step (02/11/26)

- Traced 3 of Zee's drawings, made exactly 8-fold symmetric (her line, mathematically exact). Files: `logo-lab/` (SVG + PNG + `logo-candidates-sheet.png` + `compare.html`).
- Symmetry check (how well the mark matches itself rotated): 0.99 at 45° (8-fold), 0.13-0.36 at 60° and 72°, so no hexagram or pentagram is hidden in it.
- **Decision (Rasta, 02/11/26): A, Compass lotus, is the main mark.**
- Recommendation was: **A, Compass lotus** as the main mark.
- Favicon: 4 automatic simplifications (`fav-1..4`, `favicon-sheet.png`). All read as a gear/cog at 32 px, because filling the silhouette loses the lotus petals. Rejected.
- Favicon (hand-drawn by Claude, 02/11/26), geometric redraw of A:
  - `favicon.svg` (8 compass points, 8 lotus petals, ring, rosette) for 48 px and up.
  - `favicon-small.svg` (4 points, 4 petals, bold ring, dot) for 16-32 px.
  - Exports: `favicon.ico` (16/32 from small, 48 from detailed) and `apple-touch-icon.png` (180).
  - Review sheet: `favicon-hand-sheet.png`.
  - Status: readable at 16 px. **Approved by Rasta 02/11/26.** Render script: `tools/icon_sheet.py` (resvg). It needs a simplified favicon version, because all three turn into grey dots at 16-32 px. Drop C (flame): her shading turns into blobs.
- Not final art: the traces need a clean-up pass in Illustrator (or a better trace pass) before launch. SVG weight is 65-77 KB, to be optimised.

### Visual direction prototypes (02/11/26)

- `prototypes/home-hero.html`: 3 home-page directions behind a picker (keys 1-3 or ←/→, R replays). Each has a working EN/KR toggle; Korean puts Kakao first. Previews: `prototypes/phone-preview.png`, `prototypes/desktop-preview.png`.
  - **Paper**: light, drawing-led, "from paper to skin" pair.
  - **Ink**: dark, full-bleed photo, work rail.
  - **Studio**: split layout with Zee's portrait, channel card, working style filter.
- Checked in headless Chrome at 390 and 1440 px: no horizontal overflow, 0 broken images, 0 console errors, toggle and filter working.
- Copy still unverified (from Gemini's dossier): "since 2011", guest spots in Mexico/Japan/Vietnam, IG handle `@tuzee_tattoo`. The Korean copy needs Zee's review. Email is a placeholder. The drawing-to-skin pair is matched by eye; Zee to confirm it is the same design.
- **Decision (Rasta, 02/11/26): Studio layout.** Zee's favourite colour is black, so the design system and palette move to a black base. Round 2: three black palettes on the Studio layout (`prototypes/studio-black.html`).
  - **Mono**: #0a0a0a + bone #f2f1ee, no colour; Manrope bold headings; contact card inverted to bone.
  - **Seal**: #0d0c0b + vermilion (Korean seal red, 인주) accent #e0492f, button #c8361f; Newsreader serif.
  - **Celadon**: charcoal #131313 + celadon green (청자) #9ec2b2; Fraunces light serif.
  - Contrast (WCAG): body text 14.6-17.5:1, muted text 5.4-7.0:1, accent text 4.8-9.6:1, button text 5.3-17.5:1. All pass AA.
  - Phone header moved above the photo (fixed the round-1 issue).
  - Headless checks (390 + 1440 px): 0 overflow, 0 broken images, 0 errors; toggle, Kakao-first in Korean, and filter all work.
  - Previews: `prototypes/black-desktop-preview.png`, `prototypes/black-phone-preview.png`. Waiting on Rasta's pick.

## Round 3: full rebuild (02/11/26), after Rasta's feedback

Feedback: too simplified, too few images, "church-like" serif look, no hero video, no map. Zee is into psytrance and psycore.

- **Site:** `site/index.html` (static, no build step). Run `node claude-version/tools/serve.mjs` from the repo root, then open `http://localhost:4180/claude-version/site/`.
- **Design system "Blacklight":** black void #050506; UV fluoro accents (acid #c8ff2e for actions, UV #9d5cff, magenta #ff3dbe, cyan #3de6ff); iridescent gradient on the wordmark and logo; Unbounded display, Archivo body, JetBrains Mono labels; film grain, scanlines, glow.
- **All 127 images used:**
  - 68 tattoos with style filters + lightbox.
  - 29 drawings + 26 body mock-ups (toggle).
  - 4 artist photos.
  - 11 paper-to-skin pairs in a drag slider.
  - Built by `tools/build_images.py` (WebP 560 + 1600 px, `data/works.js`). The alt text is cleaned of military/Gate 6 wording and "atelier".
- **Hero video:**
  - `hero-video/` (HyperFrames). A 12 s loop-perfect forward zoom through 6 of Zee's mandala drawings as UV linework, 145 BPM pulse (29 beats per loop).
  - Web encodes in `site/media/`: desktop 5.9 MB, phone 2.9 MB, plus a poster. Skipped on reduced motion / data saver.
- **Effects:**
  - UV torch over the logo drawing (cursor/finger reveals iridescent glow).
  - Scroll-linked logo spin + progress bar, kinetic marquee, letter-stagger wordmark, chromatic hover on tiles, scroll reveals.
- **Booking:** message builder (idea, placement, size, saved references). It copies the message and opens Instagram/Kakao, or opens a pre-filled email. Kakao comes first in Korean. Mobile booking dock.
- **Visit:**
  - Verified address: 경기도 평택시 팽성읍 안정쇼핑로 52 (안정리 35-1), 캐피토리움 114호, 17983.
  - OSM coordinates 36.961785, 127.04803 (Gemini's were ~700 m off; its Korean spelling 카피톨리움 was wrong).
  - Dark Google map embed; Naver / Kakao (documented `/link/to/`) / Google directions; copy address; full-screen Korean taxi card.
- **Verified (headless Chrome, 1440 + 390 px):** 0 overflow, 0 broken images, all 127 ids on page, 0 console errors, 0 em-dashes, no military or "atelier" text; video, slider, lightbox, save, message, language switch, maps and taxi card all work.
- **Still unverified / Zee to confirm:**
  - "since 2011", guest spots, the psycore quote, Korean name 지경은 (all from Gemini's dossier).
  - Email (placeholder), English building name "Capitorium", parking.
  - The 11 pairs (matched by eye).
  - The Korean copy needs a native read.
- `prototypes/` (rounds 1-2) is superseded by `site/`.
- **Rasta, 02/11/26 (polish round):**
  - Walk-ins welcome (not appointment only).
  - Guest spots: Mexico, Brazil, Turkey, Japan, Vietnam.
  - Tempo 180 BPM (Zee likes hi-tech psytrance); hero video re-rendered at 180 BPM.
  - Liquid gradient on display headings.
  - Hero claim "for one body only: yours" restored.
  - Split view without letterboxing.
  - Spec: `specs/polish-01.spec.md` + `specs/polish-01b.addendum.md`.
- **Polish verified (architect, 02/11/26).** Sonnet built C1-C13; I re-checked independently in headless Chrome at 390 + 1440 px.
  - All acceptance tests pass, with 0 console errors.
  - Lighthouse mobile: accessibility, best practices and SEO are 100. Simulated performance is 66-70, while the real measured first paint is 0.15-0.6 s locally.
  - **Reverted** Sonnet's workaround that held all scripts until after first paint (Lighthouse gaming; it caused about 1.1 s of blocking and an English flash for Korean visitors). Now: deferred scripts; a Korean pre-flag hides the page until the Korean text is in (1.5 s CSS safety net); gallery data loads after first paint.
  - The link-preview image is re-rendered in Unbounded (OFL) from `tools/og-card.html` via `tools/build_og_card.mjs` (was Arial).
  - Fonts: all OFL (Unbounded, Archivo, JetBrains Mono, Noto Sans KR), confirmed from google/fonts METADATA.
  - Logo SVGs for Illustrator: `logo-lab/illustrator/`.
  - Final performance check belongs on the Vercel preview with PageSpeed Insights (real CDN, brotli).
- **Split view v2 (Rasta, 02/11/26):**
  - Removed the duplicate Oni mock-up pair (10 pairs left).
  - Fixed-height stage with a blurred UV-tinted fill; the frame is fitted at the photo's own ratio.
  - Thumbnails: 2x5 grid as tall as the stage on desktop, 5x2 strip on phones. Verified: 10 unique pairs, ratio error ≤0.2%, grid height = stage height, 0 errors.
- **Duplicates removed (02/11/26):** #007 (same photo as #006, Rasta) and #121 (same drawing as #088, found by perceptual-hash scan). Excluded in `build_images.py` (EXCLUDE). Site now has 125 images: 67 skin, 28 drawings, 26 mock-ups, 4 artist. #102/#104 and #124/#127 are similar but different designs, so both kept.
- **Headlines (Rasta, 02/11/26): direction B "One body only" + 2 lines from A "The Set".**
  - H2s:
    1. Lights down.
    2. Drawn to fit you, not copied onto you.
    3. Already living on someone.
    4. Still waiting for their body.
    5. Tattooing, traveling, dark high BPM.
    6. Tell me what you want to carry.
    7. Walk in. Lights low, music loud.
  - Labels:
    1. 01 / Under UV
    2. 02 / Fitted
    3. 03 / The work
    4. 04 / Unreleased
    5. 05 / Zee · 지경은
    6. 06 / Book
    7. 07 / Visit
  - Hero numbers replaced by promises: Drawn by hand · Fitted to you · Walk-ins welcome · English · 한국어.
  - KO versions written (need Zee's native read). The duplicate psycore quote is removed, since it is now the Zee H2.
  - Verified EN+KO at 390/1440: no numbers or "starts on paper" left, all H2 liquid, 0 overflow, 0 errors.

## 5. Execution model after "go"

- Architect (Opus, this session): SPEC.md + acceptance tests + DoD, verifies each delivery in a fresh pass.
- Executor: `local-executor` (Sonnet) since agy is out of quota.
- Proposed: add an `AGENTS.md` for this repo (none exists) so governance is explicit before build.

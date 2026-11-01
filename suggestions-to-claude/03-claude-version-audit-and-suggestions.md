# Comprehensive Audit & High-Impact Suggestions for `claude-version`
**Reviewed Codebase:** `claude-version/site/` (`index.html`, `css/styles.css`, `js/app.js`, `data/works.js`, `vercel.json`)  
**Reviewer:** Antigravity Agent  
**Overall Assessment:** `claude-version/site/` is an extraordinarily strong, cohesive single-page experience. The `"Blacklight"` design system (`#050506` void + `--acid: #c8ff2e` + liquid UV display typography), the interactive UV torch (`#uvStage`), the 10-pair paper-to-skin comparison slider (`#cmpStage`), the zero-dependency architecture, and the honest pitch discipline (no unverified ratings or prices) are top-tier.

Below are **8 concrete, high-leverage improvements** discovered during our line-by-line review of `claude-version/site/`, ordered by impact on **Trust/CRO, Image SEO, Social Sharing, and UX Polish**.

---

## 1. [Trust & CRO — High Priority] Missing Hygiene, Single-Use Tool Safety & Aftercare Section
- **Where:** `claude-version/site/index.html` (between `#zee` line 216 and `#book` line 219)
- **What we found:** In `claude-version/COMPETITORS.md` (line 17) and `BRAINSTORM.md` (lines 36 & 234), Claude noted that several Anjeong-ri / Gate 6 shops are on the USFK off-limits list for health/safety reasons and that *"Hygiene is a trust lever"* + planned a *"safety/aftercare short"* block. However, the final `site/index.html` has no hygiene, sterilization, or aftercare section at all.
- **Solution Ready to Paste:** We extracted all hygiene, single-use cartridge, medical barrier-film wrapping, sharps disposal, standing stencil posture, and 30-day SecondSkin aftercare protocols into:
  - [`01-hygiene-tool-safety-and-aftercare.md`](./01-hygiene-tool-safety-and-aftercare.md) (full bilingual reference, separated into pitch-safe universal studio hygiene vs. post-pitch regulatory/ink-brand items)
  - [`02-drop-in-hygiene-section-for-claude-site.html`](./02-drop-in-hygiene-section-for-claude-site.html) (ready-to-paste `<section class="section flush-top" id="hygiene">` + CSS + `T.en`/`T.ko` keys matching Claude's exact `.facts` and `.steps` classes).

---

## 2. [Image Search SEO — High Priority] All 125 Gallery `<img>` Tags Have Empty `alt=""`
- **Where:** `claude-version/site/js/app.js` line 379 (`tileHTML`)
- **What we found:**
  ```js
  // claude-version/site/js/app.js lines 375-380
  return `<article class="tile" data-id="${w.id}" data-cat="${w.cat}"${hide}>
    <button type="button" class="tile-open" data-open="${w.id}" aria-label="${label}">
      <img src="img/${w.id}-m.webp" srcset="img/${w.id}-s.webp 480w, img/${w.id}-m.webp 960w" sizes="(min-width: 1100px) 22vw, (min-width: 700px) 30vw, 46vw" width="${w.w}" height="${w.h}" alt="" loading="lazy" decoding="async">
  ```
- **Why it matters:** While putting `aria-label="${label}"` on the `<button>` and `alt=""` on the `<img>` avoids double-announcing in some screen readers, **Google Images and Naver Image Search index `<img alt="...">`, NOT `<button aria-label="...">`**. Leaving `alt=""` on all 125 portfolio and flash images throws away the rich bilingual SEO descriptions that `tools/build_images.py` compiled from `images/seo-image-manifest.json` into `data/works.js`!
- **Recommended Fix (`js/app.js` lines 375–380 & 446–451):**
  Populate `alt="${label}"` directly on the `<img>` (and remove the redundant `aria-label` from `<button class="tile-open">`, since the button's accessible name will automatically be computed from its child `<img alt="${label}">`!).
  ```js
  // In tileHTML(w, idx, limit):
  return `<article class="tile" data-id="${w.id}" data-cat="${w.cat}"${hide}>
    <button type="button" class="tile-open" data-open="${w.id}">
      <img src="img/${w.id}-m.webp" srcset="img/${w.id}-s.webp 480w, img/${w.id}-m.webp 960w" sizes="(min-width: 1100px) 22vw, (min-width: 700px) 30vw, 46vw" width="${w.w}" height="${w.h}" alt="${label}" loading="lazy" decoding="async">
      <span class="tile-cap" aria-hidden="true"><span>${short}</span><code>#${w.id}</code></span>
    </button>
    <button type="button" class="tile-save" data-save="${w.id}" aria-pressed="${isSaved}" aria-label="${esc(t("lb.save"))} #${w.id}"></button>
  </article>`;
  ```
  And in `refreshTileLanguage()` (`js/app.js` line 448), update `const img = tile.querySelector("img"); if (img) img.alt = w[lang];`.

---

## 3. [Social Sharing / OpenGraph / JSON-LD — High Priority] Relative `og:image` & Missing Canonical / Sitemap
- **Where:** `claude-version/site/index.html` lines 12 & 45
- **What we found:**
  ```html
  <meta property="og:image" content="media/og.jpg">
  ```
  and inside `<script type="application/ld+json">` (line 45):
  ```json
  "image": "media/og.jpg",
  ```
- **Why it matters:** The OpenGraph protocol and KakaoTalk / Instagram DM / iMessage / X scrapers require `og:image` (and `og:url` + `<link rel="canonical">`) to be **absolute HTTPS URLs**. A relative `"media/og.jpg"` often fails to render a link preview card when shared in KakaoTalk or Instagram DMs.
- **Recommended Fix:**
  Once the Vercel production domain is live (e.g., `https://tuzee-tattoo-studio.vercel.app` or Zee's custom domain), update `index.html`:
  ```html
  <link rel="canonical" href="https://tuzee-tattoo-studio.vercel.app/">
  <meta property="og:url" content="https://tuzee-tattoo-studio.vercel.app/">
  <meta property="og:image" content="https://tuzee-tattoo-studio.vercel.app/media/og.jpg">
  ```
  Also add a minimal `robots.txt` and `sitemap.xml` inside `claude-version/site/`.

---

## 4. [CRO / Mobile UX — Medium-High Priority] Live Saved-Reference Counter Badge on the Floating Dock (`#dock`) & Header CTA
- **Where:** `claude-version/site/index.html` lines 42 & 346; `claude-version/site/js/app.js` line 521 (`renderSaved()`)
- **What we found:** Visitors can tap the `+` button (`.tile-save`) on any of the 125 tiles in `#workGrid` or `#designGrid`. However, on mobile—or while scrolling halfway through the 70-photo gallery—there is **no toast or badge count** on the sticky bottom `#dock` (`Start your design`) or header CTA showing how many pieces they have saved. Visitors only discover their saved pills when they scroll all the way down to `#book`.
- **Recommended Fix (`js/app.js` inside `renderSaved()`):**
  Update the floating dock and header book buttons to show the count whenever `saved.length > 0`, e.g. `Start your design (3)` / `도안 상담 신청 (3)`:
  ```js
  // Inside renderSaved() in claude-version/site/js/app.js:
  const countSuffix = saved.length ? ` (${saved.length})` : "";
  document.querySelectorAll('[data-i18n="dock.book"], [data-i18n="nav.book"]').forEach((el) => {
    const key = el.dataset.i18n;
    el.textContent = t(key) + countSuffix;
  });
  ```

---

## 5. [Pitch Safety — Medium Priority] Guarding the Placeholder `hello@example.com` Email Button
- **Where:** `claude-version/site/js/app.js` line 10 (`EMAIL: "hello@example.com"`) and `claude-version/site/index.html` line 287 (`id="sendEmail"`)
- **What we found:** In the `#book` section, the 3-column `.send` bar shows **Instagram DM**, **WhatsApp**, and **Email**. Because Zee's email is not yet public, clicking **Email** opens the visitor's mail client addressed to `hello@example.com`. If Zee or a client taps that button during the pitch review, seeing `hello@example.com` feels unfinished.
- **Recommended Fix:**
  Either:
  1. Change `.send` to a 2-column grid (`Instagram DM` + `WhatsApp`) until Zee provides her email address, **or**
  2. Intercept `#sendEmail` click when `STUDIO.EMAIL === "hello@example.com"` to copy the brief to the clipboard and show a polite toast (`"Brief copied — send via Instagram DM or WhatsApp"`).

---

## 6. [Bilingual UX — Medium Priority] Dual-Unit (`cm / in`) Clarity on Size Pills for USFK Visitors
- **Where:** `claude-version/site/index.html` lines 267–270 and `claude-version/site/js/app.js` lines 64–67
- **What we found:**
  Currently the English size chips read:
  - `Small (5–8 cm)`
  - `Medium (10–15 cm)`
  - `Large (15–25 cm)`
- **Why it matters:** American soldiers and DoD civilians stationed at Camp Humphreys think in **inches** (`2–3"`, `4–6"`, `6–10"`), whereas Korean visitors think in **centimeters**.
- **Recommended Fix (`js/app.js` lines 64–67):**
  Update the English strings in `T.en` (no extra UI toggle required!):
  ```js
  "book.s.s": 'Small (5–8 cm / 2–3")',
  "book.s.m": 'Medium (10–15 cm / 4–6")',
  "book.s.l": 'Large (15–25 cm / 6–10")',
  ```

---

## 7. [Core Web Vitals / LCP — Low-Medium Priority] Add `fetchpriority="high"` to Hero Poster `<link rel="preload">`
- **Where:** `claude-version/site/index.html` lines 37–38
- **What we found:**
  ```html
  <link rel="preload" as="image" href="media/hero-poster-m.webp" media="(max-width: 700px)">
  <link rel="preload" as="image" href="media/hero-poster.webp" media="(min-width: 701px)">
  ```
- **Recommended Fix:** Add `fetchpriority="high"` to both `<link rel="preload">` tags so Chromium prioritizes the hero poster ahead of below-the-fold requests on slow 4G connections around Pyeongtaek.

---

## 8. [Interactive Concept Lab — Optional Enhancement] Preserved 24-Fold Sacred Geometry & C7–Sacrum Topology Lab
- **Where:** Archived in [`04-preserved-atelier-hygiene-reference.html`](./04-preserved-atelier-hygiene-reference.html)
- **What it is:** In our multi-page exploration, we built an interactive `<canvas>` **Radial Harmonic Compass (12 / 24 / 36-Fold Symmetry & Φ=1.618 Ring Density)** alongside a **5-Zone Standing-Posture Anatomical Calibration Inspector** (C7 Cervical Anchor, T1–T12 Scapular Glide, L1–S1 Standing Gravity Plumb-Line, Radius/Ulna Pronation, and Elbow/Knee Flexion Buffering).
- If Claude ever wants to expand Section `02 / Sacred Geometry` (`#uvStage`) with an interactive anatomical placement explainer showing *how* flat stencils are engineered for 3D muscle torsion, the complete code and bilingual copy are preserved in `04-preserved-atelier-hygiene-reference.html`.

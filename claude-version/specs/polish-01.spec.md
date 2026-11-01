# Spec: polish-01, Tuzee site polish pass

Architect: Opus (this session). Executor: Sonnet (`local-executor`). Date: 02/11/26.
Scope: `claude-version/site/` and `claude-version/tools/build_images.py` only. Do not touch the repo root (Gemini's files), `images/`, `hero-video/` or `prototypes/`.

## Why

The rebuilt pitch site passed its functional checks. A Lighthouse run plus a manual review found:
- Mobile LCP is 9.0 s (performance 63). The LCP element is the hero lede; it fades in from `opacity: 0` and waits on a render-blocking Google Fonts stylesheet (117 KB).
- Footer and small labels fail contrast: `--dim` #6d6a76 on #050506 is 3.85:1.
- `label-content-name-mismatch` on the header brand link.
- A JPEG poster, a PNG mask, and gallery thumbs oversized on phones.
- The copy promises a "+" save button on tiles that does not exist.
- The video, marquee and grain animate indefinitely with no pause control (WCAG 2.2.2).
- Phones have no way to reach sections except scrolling.
- No link-preview image for sharing the pitch link with Zee over Kakao or Instagram.

## Hard constraints (do not violate)

1. Visual design stays as is: palette, type, layout, copy tone. Only the changes listed below.
2. No em-dash characters (U+2014) anywhere in files you write or edit.
3. No military wording (Camp Humphreys, Gate 6, AR 670-1, PCS, DEROS, soldiers) and no "atelier" in visible text, alts or meta.
4. No new runtime dependencies, frameworks or build step. Plain HTML/CSS/JS. Python + Pillow for images (already installed). Google Fonts stays the font source.
5. Every interactive control works with keyboard and touch, and has a visible focus style (the existing `:focus-visible` rule).
6. Reduced motion (`prefers-reduced-motion: reduce`) keeps working as now: no hero video, no marquee scroll, no grain shift, no torch auto-path.
7. Keep `data/works.js` record fields as they are; you may add fields.
8. Bilingual: every new visible string gets an EN and a KO entry in `T` in `js/app.js`, rendered via `data-i18n` or the render functions.

## Changes

### C1. LCP: hero text paints immediately
- The hero lede (`.hero-row .lede`), the eyebrow and the CTAs must not start at `opacity: 0`. Keep a rise only via `transform` (`translateY(24px)` → 0, same duration and ease), with opacity always 1. Apply this to the `.rise` class.
- The wordmark letters (`.hero-title .ch`) keep their clip-path rise. It is decorative and not the LCP.

### C2. Fonts stop blocking render
- Split the Google Fonts request in two `<link>`s:
  - (a) Latin families: Unbounded 700;800;900, Archivo 400;500;600;700, JetBrains Mono 400. Drop the unused weights; check usage in `styles.css` and keep only weights actually used.
  - (b) Noto Sans KR 400;700;800 only.
- Load both non-blocking: `<link rel="preload" as="style" href="…" onload="this.onload=null;this.rel='stylesheet'">` with a `<noscript><link rel="stylesheet" href="…"></noscript>` fallback for each. Keep the `preconnect` links.

### C3. Contrast + accessible names
- `--dim` → `#8a8794` (5.26:1 or better on all three surfaces; verified).
- Remove `aria-label` from `.brand` in the header. The visible text "TUZEE Tattoo Studio" is the name. Keep `href="#top"`.
- Move the inline `style="padding-top:0"` on sections into a class `.section.flush-top { padding-top: 0; }`, and the footer inline styles into classes.

### C4. Images
- `build_images.py`: add a third size `xs` = 320 px wide (quality 74) → `img/<id>-xs.webp`. Existing files are skipped if present, so only the new size gets generated.
- Gallery tiles: `<img src="img/<id>-s.webp" srcset="img/<id>-xs.webp 320w, img/<id>-s.webp 560w" sizes="(min-width:1500px) 18vw, (min-width:1100px) 23vw, (min-width:700px) 31vw, 48vw">`.
- Pair thumbnails in `#pairList`: use `-xs`.
- Saved-reference chips in `#rRefs`: use `-xs`.
- UV torch base image `084-l.webp` → use `084-s.webp` with `srcset` `-s 560w, -l 1600w` and `sizes="(min-width:960px) 45vw, 92vw"`.
- Poster: create `media/hero-poster.webp` (1600 px wide, quality 72) and `media/hero-poster-m.webp` (720 px wide, cropped centre to the same 600:855 ratio as `hero-mobile.mp4`, quality 72) from `media/hero-poster.jpg`.
  - The `<video poster>` = the desktop webp.
  - In the existing hero JS, set `poster` to the mobile file when the mobile video is chosen.
  - Update the `<link rel="preload" as="image">`: two preloads with `media="(max-width: 700px)"` and `media="(min-width: 701px)"`.
- `media/uv-lines.png` → `media/uv-lines.webp` (lossless or quality 90, alpha kept). Update both mask URLs in `styles.css`. Delete the PNG.

### C5. Save button on every tile
- Restructure a tile: `<div class="tile" data-id>` containing:
  - (a) `<button class="tile-open" type="button" aria-label="Open #<id>: <alt>">` wrapping the image and caption;
  - (b) `<button class="tile-save" type="button" aria-pressed="true|false" aria-label="Save #<id> to request">`, top-right, 36×36 px.
- `.tile-save` styling:
  - Circle with `rgba(5,5,6,.7)` background and a white "+".
  - When pressed: acid background, dark "✓".
  - Always visible on touch (`hover: none`); on hover devices visible on tile hover / focus-within, and always when pressed.
  - Replaces the current `.saved-dot`; remove `.saved-dot`.
- Clicking `.tile-save` toggles saved (existing `toggleSaved`) and must NOT open the lightbox. Clicking `.tile-open` opens the lightbox as today.
- Update the lightbox-open handler, the hidden/filter logic and the selectors in `toggleSaved` to the new structure. Keep the chromatic hover and caption behaviour.

### C6. Motion control (WCAG 2.2.2)
- Add a small toggle button in the header actions, before `.lang`: `#motionToggle`, icon only (pause bars / play triangle as inline SVG), `aria-pressed` reflecting "motion paused".
  - Accessible name, EN: "Pause motion" / "Play motion". KO: "움직임 일시정지" / "움직임 재생".
- When paused:
  - add `data-motion="off"` on `<html>`;
  - pause the hero video;
  - CSS under `html[data-motion="off"]` stops the marquee, grain, torch auto-path and `.reveal` scroll animations, and shows the uv-glow fully (like reduced motion).
- Persist the choice in localStorage `tuzee-motion` (wrapped in the existing `store` try/catch helper).
- Default: on, unless reduced motion, where it starts paused and the button still works.
- The `IntersectionObserver` that resumes the video must respect the paused state.

### C7. Phone menu
- Below 980 px, show a menu button `#menuBtn` (two-line icon, `aria-expanded`, `aria-controls="menu"`) in header actions, after `.lang`.
- It opens a `<dialog id="menu" class="menu">` styled as a full-screen sheet in the site palette. Contents:
  - the four section links (Work, Designs, Zee, Visit) plus Book, in large Unbounded type;
  - then Instagram and KakaoTalk buttons, ordered by language like the dock.
- Clicking a link closes the dialog and scrolls to the section. ESC and the close button close it. The existing dialog backdrop close works.
- Hidden at ≥980 px.

### C8. Link preview + meta
- Add OG and Twitter meta:
  - `og:type website`, `og:title`, `og:description` (EN, same as the meta description);
  - `og:image` = `media/og.jpg`, `og:image:width` 1200, `og:image:height` 630, `twitter:card summary_large_image`.
- Generate `media/og.jpg` (1200×630, under 250 KB):
  - from `hero-poster.jpg`, centre-cropped;
  - darkened 45%;
  - the `media/a-compass.svg` mark is not required.
  - Render "TUZEE" in white or light text, large, centred, using Pillow with any available bold system font (e.g. `arialbd.ttf`). Add a line below: "Tattoo Studio · Pyeongtaek" at about 40 px.
  - Put the generator in `claude-version/tools/build_og.py`.
- On language switch, also set `document.title` and the meta description content from `T` (add the `title` and `desc` keys to EN/KO).
  - EN title: unchanged.
  - KO title: "TUZEE 타투 스튜디오 · 평택 만다라, 오너먼트, 동양화 타투".
  - KO desc: "Zee가 직접 손으로 그리는 맞춤 만다라, 신성 기하학, 오너먼트, 동양화 타투. 평택 팽성읍 프라이빗 타투 스튜디오. 한국어 · English 상담."
- Add `<noscript>` inside `main`, after the hero: one short paragraph. EN: "Turn on JavaScript to see the full gallery. You can also message Zee on Instagram @tuzee_tattoo or KakaoTalk." Link both.

### C9. Deploy config (do not deploy)
- Add `claude-version/site/vercel.json`:
  - `cleanUrls true`;
  - headers: `/img/(.*)`, `/media/(.*)` → `Cache-Control: public, max-age=31536000, immutable`;
  - `/(css|js|data)/(.*)` → `public, max-age=86400, stale-while-revalidate=604800`;
  - all routes: `X-Content-Type-Options nosniff`, `Referrer-Policy strict-origin-when-cross-origin`, `Permissions-Policy camera=(), microphone=(), geolocation=()`.
- No `X-Frame-Options DENY` issue (the site embeds a Google map, not the reverse), so add `X-Frame-Options SAMEORIGIN`.

## Acceptance tests (the architect runs these; you run them too before reporting)

Server: `node claude-version/tools/serve.mjs` from the repo root (Rasta may already have it running on 4180; if port 4180 answers, reuse it, do not start another).

1. **Function suite:** `node <scratchpad>/pp/site-check.mjs <outdir>` must report for desktop and phone:
   - overflow 0, brokenImgs [], idsNotOnPage [], errors [], emDash 0, militaryText false, atelierText false;
   - lightbox opens/closes; refs saved; KO send order `kakao, instagram, email`.
   - The architect updates the script for the new tile structure (`.tile-open` click); executor: if your change breaks a selector in it, note which in your report rather than editing the script.
2. **Lighthouse mobile** (`npx -y lighthouse@12 <url> --only-categories=performance,accessibility,best-practices,seo --chrome-flags="--headless=new"`):
   - accessibility = 100;
   - LCP ≤ 3.5 s on the local server;
   - no `color-contrast` and no `label-content-name-mismatch` failures.
   - Known local-server-only failures that are NOT in scope: text compression, minify CSS/JS, bf-cache no-store, document latency.
3. **Tile save:** clicking `.tile-save` on the first work tile sets `aria-pressed="true"`, adds the id to `#rRefs`, and does not open `#lightbox`. Clicking it again removes it.
4. **Motion toggle:**
   - Pause makes `video.paused === true`, and the computed `animation-play-state` or `animation-name` of `.marquee-track` stops motion.
   - Reload keeps the state.
   - Play resumes the video.
5. **Phone menu (390 px):**
   - `#menuBtn` is visible and opens `#menu`; clicking "Visit" closes it, and `#visit` is in view.
   - At 1440 px `#menuBtn` is not displayed.
6. **Meta:**
   - `media/og.jpg` is 1200×630 and under 250 KB.
   - Switching to KO changes `document.title` to the KO string.
7. **Static checks:**
   - `grep -rP "\x{2014}"` over `site/` and `tools/` returns nothing;
   - no file references `uv-lines.png` or `hero-poster.jpg` except `build_og.py` / the poster conversion;
   - `img/*-xs.webp` count = 127.

## Definition of done

All acceptance tests pass. Report back:
- the files changed;
- a one-line note per change C1-C9;
- the Lighthouse mobile scores + LCP;
- any test you could not run, and why.

Do not self-certify beyond what you ran; the architect verifies independently.

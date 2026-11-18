# WSP.md — Workflow State Protocol & Shared Agent Handover (Claude + Antigravity)

> **Last Updated:** 2026-11-10 (moved from repo root to `.agents/WSP.md`, the standard path in every repo)  
> **Repository:** https://github.com/ItalianDesAIgns/tuzee-zee-tattoo-studio  
> **Purpose:** Shared source of truth for **Claude** and **Antigravity (Gemini)** so either agent can resume work on **TUZEE Tattoo Studio** without losing context, breaking paths, or violating editorial/brand decisions.

---

> **17/11/26:** model-routing liveness watchdog, 4h ceiling, and acceptance gate (Spec 0012, commit `d0353be`, branch `staging`).
> **15/11/26:** repo carries its own model routing (.agents/MODEL-ROUTING.md, utomations/model-routing/); AGENTS.md no longer points outside the repo (commit 2625bdf, branch staging).

## 1. Live Environments & Git Branch Topology

| Branch | Role | Live Vercel URL | Status |
| :--- | :--- | :--- | :--- |
| **`main`** | Baseline canonical build (promoted from `/claude-version` with all paths reconciled) | https://tuzee-zee-tattoo-studio.vercel.app | Live (`200 OK`) |
| **`staging`** | Enhanced streamlined single-page build with all `/suggestions-to-claude` improvements, horizontal footer socials fix, and rewritten `H2`/body copy | https://tuzee-zee-tattoo-studio-git-staging-italiandesaigns-projects.vercel.app<br>*(Latest deploy: https://tuzee-zee-tattoo-studio-hpulmkxfl-italiandesaigns-projects.vercel.app)* | Live (`200 OK`) |

---

## 2. Canonical Directory Structure

Canonical directory map lives in [`../README.md`](../README.md) (`## Repository Structure`) — inspect `README.md` and disk directly rather than maintaining a second copy here.

---

## 3. Hard Editorial, Brand & Legal Guardrails (DO NOT VIOLATE)

Both agents must strictly enforce these rules established in [`../BRAINSTORM.md`](../BRAINSTORM.md):

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
4. **Voice (Rasta, 02/11/26):** all site copy is written by Zee in the first person ("I draw…", "제가…"), speaking directly to the client. Exceptions: the client's own message template (`msg*`) and the pitch disclaimer (`ftPitch`).
5. **Copywriting Discipline (No AI Tells):**
   - Never use `"It's not X, it's Y"` contrast reveals (e.g., *"Drawn to fit you, not copied onto you"*), `"No X, no Y"` negation lists, or cryptic two-word fragments (*"Lights down."*, *"Already living on someone."*).
   - Keep `H2`s and body copy concrete, craft-focused, and natural in both English and Korean.
   - No em-dashes (U+2014) anywhere, and no unverifiable figures (the "4–9 mm spine twist" and "35% joint stretch" claims were removed on 02/11/26).

---

## 4. What Was Added on the `staging` Branch (vs. `main`)

The `staging` branch implements a **streamlined single-page architecture** combining Claude's `site/` build with all recommendations from [`../suggestions-to-claude/`](../suggestions-to-claude):

1. **Footer Social Icons Horizontal Layout Fix (`site/css/styles.css`):**
   - *Bug on `main`:* `.footer-grid ul { display: grid; gap: 8px; }` had higher CSS specificity (`0,1,1`) than `.socials { display: flex; }` (`0,1,0`), causing the 4 social icons in the footer to stack vertically.
   - *Fix on `staging`:* Changed `.footer-grid ul` to `.footer-grid ul:not(.socials)` and defined `ul.socials, .socials { display: flex; flex-direction: row; flex-wrap: wrap; align-items: center; gap: 10px; }` with `.socials li { display: inline-flex; }`.
2. **Initial `staging` section copy (superseded by item 10, First-Person Voice Pass, below).**
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

10. **First-Person Voice Pass (Claude, 02/11/26):** 36 EN + 35 KO strings rewritten in Zee's own voice via `tools/copy_first_person.py` (also refreshes the static HTML fallbacks). H2s: "I love drawing, but mandalas are my passion." · "Every line is adjusted to your shape before the needle starts." (Rasta's pick, replaced "I shape each design around…") · "Pieces I’ve tattooed." · "Drawings I’d love to tattoo next." · "I’ve tattooed for fifteen years, in six countries." · "I open every needle in front of you and wrap my station fresh for each session." · "Send your idea straight to me." · "Find my studio in Paengseong‑eup, Pyeongtaek." Removed the two em-dashes and the unverifiable 4–9 mm / 35% figures from the aftercare dialog. Hygiene section content confirmed by Rasta.
11. **Psy-Gradient Favicon Set:** `tools/build_favicons.py` renders the logo-lab icons as a mask over one unrotated iridescent gradient (acid → cyan → UV → magenta). Outputs `site/media/favicon.svg`, `favicon.ico` (16/32/48) and a black-background `apple-touch-icon.png`; sources kept as `logo-lab/favicon-psy.svg` and `favicon-small-psy.svg`.
12. **Vercel Config:** root `vercel.json` now caches `css/js/data` for 1 h (+1 day stale-while-revalidate) and `img/media` for 7 days; they are not fingerprinted, so year-long immutable caching would have served stale files after redeploys. Security headers restored, plus `X-Robots-Tag: noindex, nofollow` while the site is a pitch (**remove at launch**). The unused `site/vercel.json` was deleted: with `outputDirectory: site`, Vercel reads only the root file.
13. **README:** address corrected to `Capitorium #114, 52 Anjeongshopping-ro` (was "Capitolium … 16"), hero reel 180 BPM.
14. **Page Background "Mix" (Rasta, 02/11/26):** after a 5-option comparison (Obsidian / Stipple / Watermark / Ambience / Mix), the site uses:
   - a faint 16 px dotwork grid on a fixed `html::before` layer behind the text sections;
   - pure obsidian on `#paper`, `#work` and `#designs`, so the tattoo photos keep a clean ground;
   - one iridescent mandala watermark (`media/uv-lines.webp`, Zee's #084 compass lotus) behind `#zee`, turning slowly via a `view()` scroll timeline.

   Static under reduced motion and with the motion toggle off; `#zee` clips horizontally so the overhang never causes sideways scroll. CSS lives at the end of `site/css/styles.css`.
15. **More Mandala Watermarks (Rasta, 02/11/26):** for consistency, every text section now carries one of Zee's own drawings, each different and spinning in alternate directions:
   - `#zee` #084 compass lotus;
   - `#hygiene` #125 ten-point star;
   - `#book` #088 eight-point star (left, behind the steps; the form panel would hide it on the right);
   - `#visit` #086 ouroboros star;
   - footer #117 flame lotus.

   The new layers (`site/media/mandala-*.webp`, 720 px, alpha-only, 260 KB total) come from `hero-video/assets/m*.png`. Photo sections stay clean. The shared rule clips each section horizontally (no sideways scroll).

---

## 5. Pending Items & Next Steps

1. **`staging` → `main` (done 02/11/26, Rasta approved):** `main` fast-forwarded to `e9c3b46` (identical to `staging`, no merge commit); production at https://tuzee-zee-tattoo-studio.vercel.app verified anonymously (200, new copy, favicon, background, `noindex`). Future releases: fast-forward only (`git push origin origin/staging:main`) after the staging preview is approved; preview URLs need a Vercel login, so Zee only ever sees production.
2. **Post-Pitch Confirmations from Zee:**
   - Replace `LINKS.email = 'hello@example.com'` in `site/js/app.js` with Zee's real email address (or remove the email button if she only uses Instagram DM + KakaoTalk).
   - Native Korean copy check by Zee on `T.ko` strings in `site/js/app.js` and `data/works.js`.
   - Confirm whether the 10 drawing-to-skin pairs in `PAIRS` (`site/js/app.js`) are exact matches.
   - Remove `.ft-fine` pitch disclaimer (`ftPitch`) once Zee approves the site for official launch.
   - **At launch:** delete the `X-Robots-Tag: noindex, nofollow` header from root `vercel.json` so search engines can index the site.


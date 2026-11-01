# Addendum to polish-01 (Rasta, 02/11/26): C10-C13

Same constraints and acceptance rules as polish-01. Bilingual EN/KO for every new string. No em-dashes.

## C10. Liquid fluid gradient on display headings
- Applies to:
  - the hero wordmark `h1.hero-title` (TUZEE);
  - every section title `.h-l` (7 of them);
  - `.footer-word`.
- Look: a slow, flowing gradient made of the UV palette (acid #c8ff2e, cyan #3de6ff, UV #9d5cff, magenta #ff3dbe), clipped to the text.
  - Build it from 3-4 layered `radial-gradient`s over a `linear-gradient` base, `background-size` around 200-300%.
  - Animate `background-position` (and optionally a registered `@property` angle) on a 10-16 s `ease-in-out infinite alternate` loop, so colour pools drift through the letters like liquid. Not a hard scrolling stripe.
  - Use one shared class `.liquid` and one keyframes block.
- The hero wordmark must read as ONE continuous gradient across all five letters, not a repeating slice per letter. The letters still keep their clip-path entrance.
  - Approach: put the background on the `h1 .irid` wrapper with `background-clip: text`. Only if that fails to paint through the animated inline-block letters, fall back to per-letter with `background-attachment` / position offsets.
  - Remove the per-letter `.ch` slice rule once the shared gradient works. Verify by screenshot: no colour seams between letters.
- Section titles are currently solid off-white; they become liquid gradient. Keep contrast readable: lightest stops on dark ground, and no stop darker than #7a4dff at the text's darkest point.
- Motion: static (no animation) under `prefers-reduced-motion: reduce` and under `html[data-motion="off"]` (C6).

## C11. Walk-ins welcome
Zee accepts walk-ins as well as appointments. Replace every "by appointment only" claim.
- `T.en.how3` → "Walk-ins welcome. Booking ahead guarantees your slot; parking details come with your booking."
- `T.ko.how3` → "워크인 환영합니다. 미리 예약하시면 시간을 확보해 드리고, 주차 안내도 함께 드립니다."
- `T.en.ftAppt` → "Walk-ins welcome · bookings recommended"; `T.ko.ftAppt` → "워크인 환영 · 예약 권장".
- `T.en.fStudioV` → "Private studio. Walk-ins welcome."; `T.ko.fStudioV` → "프라이빗 스튜디오. 워크인 환영."
- Add a small badge in the Visit section, above the address: a pill with a pulsing acid dot (static under reduced motion / motion off). Text: EN "Walk-ins welcome", KO "워크인 환영".
- Also update any remaining "appointment only" / "100% 예약제" text and the JSON-LD (add nothing about hours; hours are unknown).
- Then grep `site/` for `appointment only|예약제` and confirm nothing is left.

## C12. Hero statement: "for one body only: yours"
- Under the TUZEE wordmark, before the lede, add a large statement line, `<p class="hero-claim">`.
  - EN: "I draw every tattoo by hand, for one body only: yours."
  - KO: "모든 타투를 손으로 그립니다. 오직 당신의 몸을 위해."
  - Style: Unbounded 700, `clamp(1.5rem, 1rem + 2.4vw, 3rem)`, line-height 1.08, `max-width: 22ch`, white (not gradient, so the gradient wordmark stays the hero), `text-wrap: balance`.
  - A small signature after it on its own line: mono label "Zee, artist" / "Zee, 아티스트" in `--muted`.
- Shorten the lede so the hero is not over-texted.
  - EN: "Mandalas, sacred geometry, ornamental and oriental work. Private studio in Pyeongtaek, tattooed to a high-BPM soundtrack."
  - KO: "만다라, 신성 기하학, 오너먼트, 동양화. 평택의 프라이빗 스튜디오, 하이 BPM 사운드트랙과 함께."
- The claim and lede must not start at opacity 0 (C1 applies). Re-check the hero at 390x844 and 1440x900:
  - the CTAs and stats still fit, and nothing overlaps;
  - on phone, the hero may grow taller than the viewport rather than squash. Keep `min-height: 100svh`, and let content push it.

## C13. Split view without letterboxing
Problem: the compare frame has a fixed aspect ratio, so drawings and photos of other shapes leave bars at the sides, or crop so the two halves no longer line up.
- The frame takes the aspect ratio of the AFTER image (the tattoo on skin), from `WORKS` `w`/`h`:
  - set `style.aspectRatio = w / h` on `#cmp` in `showPair()`;
  - cap the size so a tall photo does not run off screen: `width: min(100%, calc(78svh * var(--ar)))` with `--ar` set to the same ratio. Centre the frame in its column.
- Both images use `object-fit: cover` inside that frame, so the frame edges are the photo edges. The after image fills exactly (same ratio). The before image (drawing / mock-up) covers the same frame, cropped where needed.
  - Remove the dark background bars: no `#0d0d10` visible inside the frame at any slider position.
- Pair thumbnails, the caption row and the range input keep working. Re-run the slider test (value 20 → `--pos` 20%).
- Acceptance: for every one of the 11 pairs, at 1440 and 390 widths, `#cmp`'s rendered aspect ratio is within 1% of the after image's `w/h`, and the frame width is no wider than its column and no taller than 78% of viewport height. Add this to your polish-check script and report the 11 ratios.

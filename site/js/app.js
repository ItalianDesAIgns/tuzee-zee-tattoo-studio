/* TUZEE Tattoo Studio: site behaviour (no framework, no build step). */
(() => {
  'use strict';
  const boot = () => {

  // ---------- constants ----------
  const LINKS = {
    instagram: 'https://www.instagram.com/tuzee_tattoo/',
    kakao: 'https://open.kakao.com/o/siUk2cie',
    email: 'hello@example.com', // PLACEHOLDER: Zee's address not confirmed yet
  };
  // Social profiles (handles confirmed by Rasta, 02/11/26). Icons are simple hand-drawn glyphs, no brand-asset files.
  const SOCIALS = [
    { k: 'instagram', label: 'Instagram', href: 'https://www.instagram.com/tuzee_tattoo/',
      svg: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><rect x="3" y="3" width="18" height="18" rx="5"/><circle cx="12" cy="12" r="4.2"/><circle cx="17.4" cy="6.6" r="1.1" fill="currentColor" stroke="none"/></svg>' },
    { k: 'tiktok', label: 'TikTok', href: 'https://www.tiktok.com/@tuzeetattoo',
      svg: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M14.6 3h3.1c.2 1.9 1.6 3.4 3.4 3.6v3.2c-1.3 0-2.5-.4-3.4-1v6.4a5.6 5.6 0 1 1-5.6-5.6l.9.1v3.3a2.4 2.4 0 1 0 1.6 2.2V3z"/></svg>' },
    { k: 'facebook', label: 'Facebook', href: 'https://www.facebook.com/kyungeun.chi.5',
      svg: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M13.6 21v-7.4h2.6l.4-3.1h-3V8.6c0-.9.3-1.5 1.6-1.5h1.6V4.4c-.3 0-1.2-.1-2.3-.1-2.3 0-3.9 1.4-3.9 4v2.2H8v3.1h2.6V21h3z"/></svg>' },
    { k: 'kakao', label: 'KakaoTalk', href: 'https://open.kakao.com/o/siUk2cie',
      svg: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 4C7 4 3 7.1 3 10.9c0 2.4 1.6 4.6 4.1 5.8l-1 3.6c-.1.4.3.7.6.4l4.3-2.8 1 .1c5 0 9-3.1 9-7.1S17 4 12 4z"/></svg>' },
  ];
  const GEO = { lat: 36.961785, lng: 127.04803 }; // Capitorium building (OSM way 1422225952)
  const ADDR_KO = '경기도 평택시 팽성읍 안정쇼핑로 52, 캐피토리움 114호';
  const MAPS = {
    naver: 'https://map.naver.com/p/search/' + encodeURIComponent('평택시 팽성읍 안정쇼핑로 52'),
    // Directions to Zee's own KakaoMap listing 투지타투(tuzeetattoo), place id 2118907749.
    kakao: 'https://map.kakao.com/link/to/2118907749',
    google: `https://www.google.com/maps/dir/?api=1&destination=${GEO.lat},${GEO.lng}`,
  };
  // Gallery data (75 KB) is not needed for the hero, so it loads after the first paint.
  let WORKS = [];
  let byId = {};
  function loadWorks() {
    return new Promise((resolve) => {
      if (window.WORKS) { resolve(); return; }
      const s = document.createElement('script');
      s.src = 'data/works.js';
      s.onload = resolve; s.onerror = resolve;
      document.head.append(s);
    }).then(() => {
      WORKS = window.WORKS || [];
      byId = Object.fromEntries(WORKS.map((w) => [w.id, w]));
      [...saved].forEach((id) => { if (!byId[id]) saved.delete(id); });
    });
  }
  const img = (id, size = 's') => `img/${id}-${size}.webp`;
  const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

  const STYLES = {
    mandala: { en: 'Mandala & geometry', ko: '만다라 & 지오메트릭' },
    ornamental: { en: 'Ornamental & spine', ko: '오너먼트 & 척추' },
    oriental: { en: 'Oriental & irezumi', ko: '동양화 & 이레즈미' },
    fineline: { en: 'Fine line & botanical', ko: '파인라인 & 보태니컬' },
    realism: { en: 'Realism & script', ko: '리얼리즘 & 레터링' },
    blackwork: { en: 'Dark blackwork', ko: '다크 블랙워크' },
    artist: { en: 'Studio', ko: '스튜디오' },
  };
  const STYLE_ORDER = ['mandala', 'ornamental', 'oriental', 'fineline', 'realism', 'blackwork'];

  // Drawing / mock-up / first session (left) -> finished tattoo (right). Matched by eye; Zee to confirm.
  const PAIRS = [
    { b: '084', a: '021', kind: 'drawing', en: 'Compass lotus mandala, upper back', ko: '컴퍼스 연꽃 만다라, 등' },
    { b: '081', a: '019', kind: 'drawing', en: 'Lunar phases, full spine', ko: '달의 위상, 척추' },
    { b: '082', a: '020', kind: 'drawing', en: 'Lotus and prism, spine', ko: '연꽃과 프리즘, 척추' },
    { b: '123', a: '071', kind: 'drawing', en: 'Shield mandala, full upper back', ko: '방패형 만다라, 등 전체' },
    { b: '086', a: '023', kind: 'drawing', en: 'Ouroboros star mandala, shoulder', ko: '우로보로스 별 만다라, 어깨' },
    { b: '096', a: '060', kind: 'drawing', en: 'Oni-mask warrior, shoulder', ko: '오니 가면 전사, 어깨' },
    { b: '090', a: '024', kind: 'drawing', en: 'Koi and lotus, thigh', ko: '잉어와 연꽃, 허벅지' },
    { b: '085', a: '022', kind: 'drawing', en: 'Lilies, upper arm', ko: '백합, 상완' },
    { b: '114', a: '065', kind: 'drawing', en: 'Coffee branch, leg', ko: '커피나무 가지, 다리' },
    { b: '010', a: '015', kind: 'session', en: 'Buddha lotus: first session to finished', ko: '부처 연꽃: 첫 세션에서 완성까지' },
  ];

  const PLACEMENTS = [
    ['forearm', 'Forearm', '팔뚝'], ['upper-arm', 'Upper arm / shoulder', '상완 / 어깨'], ['sleeve', 'Full sleeve', '긴팔 (슬리브)'],
    ['back', 'Back', '등'], ['spine', 'Spine', '척추'], ['chest', 'Chest / sternum', '가슴 / 흉골'],
    ['leg', 'Leg / calf', '다리 / 종아리'], ['thigh', 'Thigh', '허벅지'], ['hand-neck', 'Hand / neck / behind ear', '손 / 목 / 귀 뒤'], ['unsure', 'Not sure yet', '아직 모르겠어요'],
  ];
  const SIZES = [
    ['s', 'Small · under 10 cm / 4 in', '작게 · 10cm / 4in 이하'], ['m', 'Medium · 10–20 cm / 4–8 in', '중간 · 10–20cm / 4–8in'],
    ['l', 'Large · 20 cm+ / 8 in+', '크게 · 20cm / 8in 이상'], ['xl', 'Sleeve or back piece', '슬리브 또는 등 전체'],
  ];

  const T = {
    en: {
      ftCredit: 'Website by',
      title: 'TUZEE Tattoo Studio · Mandala, Ornamental & Oriental Tattoos in Pyeongtaek',
      desc: 'Custom mandala, sacred geometry, ornamental and oriental tattoos, drawn by hand by Zee. Private tattoo studio in Paengseong-eup, Pyeongtaek. English and Korean.',
      motionPause: 'Pause motion', motionPlay: 'Play motion', menuOpen: 'Menu', menuClose: 'Close', saveTile: 'Save to request', openTile: 'Open',
      brandSub: 'Tattoo Studio', navWork: 'Work', navDesigns: 'Designs', navZee: 'Zee', navHygiene: 'Hygiene', navVisit: 'Visit', navBook: 'Book',
      heroClaim: 'Custom geometry and oriental work, drawn by hand for your body.', heroSign: 'Zee · Artist & Founder',
      heroEyebrow: 'Tattoo studio · Pyeongtaek, Korea', heroSr: ' Tattoo Studio',
      heroLede: 'Precision dotwork mandalas, ornamental spine pieces, and irezumi from a private studio in Pyeongtaek.',
      ctaStart: 'Start your design', ctaWork: 'See the work',
      uvHint: 'Move to trace the linework', uvEyebrow: '01 / Hand-Drawn Geometry', uvTitle: 'Eight-fold symmetry, drawn from a single center.',
      uvLede: 'Every mandala starts on paper with a compass, ruler, and graphite—including the eight-point lotus that became the studio mark. Move the light across the drawing to inspect the dotwork and line weights up close.',
      uvAll: 'Reveal full drawing', uvAllOff: 'Back to spotlight',
      cmpEyebrow: '02 / Paper to Skin', cmpTitle: 'Shaped around collarbone, spine, and muscle.',
      cmpLede: 'Flat paper distorts the moment it wraps around a shoulder or follows a spine. Zee redraws the proportions on your skin before tattooing so circles stay true when your arm moves. Drag the slider to compare the original drawing with the finished tattoo.',
      tagDrawing: 'Drawing', tagMockup: 'Mock-up', tagSession: 'Session 1', tagSkin: 'On skin', pairOf: 'Pair',
      workEyebrow: '03 / Selected Work', workTitle: 'Finished work on skin.',
      workLede: 'Sixty-seven pieces across sacred geometry, ornamental spine work, oriental irezumi, and fine-line botanicals. Tap any photo to inspect the linework full screen, or press + to attach it to your booking message as a reference.',
      all: 'All', showAllWork: 'Show all {n} works', showLessWork: 'Show fewer works',
      desEyebrow: '04 / Available Designs', desTitle: 'Original drawings ready to claim.',
      desLede: 'Hand-drawn flash sheets and body-placement studies from Zee’s sketchbook. Claim a piece as drawn, or save one with + to adapt the scale and placement for your body.',
      segDrawings: 'Drawings', segBody: 'On the body', showAllDes: 'Show all {n} pieces', showLessDes: 'Show fewer pieces',
      zeeEyebrow: '05 / The Artist · 지경은',
      zeeTitle: 'Fifteen years of ink across six countries.', p1: 'Drawn by hand', p2: 'Fitted to you', p3: 'Walk-ins welcome', p4: 'English · 한국어',
      zeeLede: 'Tattooing since 2011 with guest residencies across Mexico, Brazil, Turkey, Japan, and Vietnam. Zee specializes in high-contrast dotwork mandalas, spine ornamentals, and large-scale oriental compositions from her private studio in Pyeongtaek.',
      fSinceK: 'Since', fSinceV: 'Tattooing since 2011', fGuestK: 'Guest spots', fGuestV: 'Mexico · Brazil · Turkey · Japan · Vietnam', fLangK: 'Languages', fStudioK: 'Studio', fStudioV: 'Private studio. Walk-ins welcome.', walkIn: 'Walk-ins welcome',
      hygEyebrow: 'Hygiene & Tool Safety', hygTitle: 'Unsealed in front of you. Wrapped fresh for every session.',
      aftercareBtn: '30-day aftercare & safety guide',
      hygP1K: 'Single-use cartridges', hygP1V: 'Individually sterilized membrane cartridges unsealed from the blister pack in front of you.',
      hygP2K: 'Full barrier wrap', hygP2V: 'Machine, grip, armrest, lamp, and bed wrapped in fresh disposable barrier film for every client.',
      hygP3K: 'Sterile caps & sharps', hygP3V: 'Single-use ink caps dispensed before setup; used needles ejected straight into a sealed sharps container.',
      hygP4K: 'Standing stencil fit', hygP4V: 'Spine and geometric axes mapped while you stand naturally on level ground before lying on the bed.',
      acEyebrow: 'Hygiene, Tool Safety & 30-Day Aftercare', acTitle: 'How we protect your skin in the chair and for 30 days after',
      acCol1: '30-Day Dermal Healing Timeline', acCol2: 'Anatomical Stencil & Tool Calibration',
      hygS1T: 'Days 1–4 · Breathable dermal film', hygS1D: 'A waterproof, breathable second-skin film is applied before you leave to lock in natural healing and block friction or dust.',
      hygS2T: 'Days 4–7 · Warm-water peel & gentle wash', hygS2D: 'Peel the film slowly under warm running shower water, wash gently with fragrance-free soap, pat dry with clean paper towel, and apply a thin layer of ointment.',
      hygS3T: 'Days 8–21 · Natural flaking (no picking or soaking)', hygS3D: 'Fine line and dotwork skin flakes lightly like sunburn. Never scratch or pick, and avoid baths, pools, saunas, or heavy sweat until settled.',
      hygS4T: 'Day 30+ · Broad-spectrum SPF 50+', hygS4D: 'Once the skin fully regenerates at week 4, apply SPF 50+ in direct sun so fine lines and blackwork stay crisp for decades.',
      acZ1K: 'Spine & back', acZ1V: 'Lying face-down twists the spine by 4–9 mm. All spine and back stencils are mapped while you stand barefoot on level ground first.',
      acZ2K: 'Shoulder & blade', acZ2V: 'Mandalas are anchored inside the stable center corridor with dotwork buffering across the shoulder blade so circles stay round in motion.',
      acZ3K: 'Forearm wrap', acZ3V: 'As your wrist turns, forearm bones cross in a spiral. Geometric sleeves are wrapped along that natural spiral so lines stay parallel.',
      acZ4K: 'Elbow & knee', acZ4V: 'Joint skin stretches over 35% when bent. Negative-space framing and layered dotwork heal evenly across creases without ink dropout.',
      bookEyebrow: '06 / Book a Session', bookTitle: 'Send your idea straight to Zee.',
      bookLede: 'Describe your idea, pick the placement and size, and choose Instagram DM or KakaoTalk. Your message is formatted automatically with any reference pieces you saved above.',
      s1h: 'Send your idea', s1p: 'A few words, where on the body, rough size, and any references you saved.',
      s2h: 'Zee draws it', s2p: 'You get a custom design and a quote. Changes are part of the process.',
      s3h: 'Your session', s3p: 'A private session, then aftercare notes in English or Korean.',
      fIdea: 'Your idea', fIdeaPh: 'e.g. A lotus mandala on my upper back, black and grey, a bit like #021',
      fPlace: 'Placement', fSize: 'Rough size', fRefs: 'Saved references', fSend: 'Send it on',
      refsEmpty: 'Nothing saved yet. Tap + on any tattoo or design.', clearRefs: 'Clear all',
      fFine: 'Instagram and KakaoTalk can’t take a pre-written message, so we copy it for you: open the chat and paste.',
      hintIg: 'Copy + open DM', hintKakao: 'Copy + open chat', hintEmail: 'Copy message',
      copied: 'Message copied. Paste it in the chat.', emailPending: 'Message copied — paste in Instagram DM or KakaoTalk while email is being confirmed.',
      copiedAddr: 'Korean address copied', saved: 'Saved to your request', unsaved: 'Removed from your request',
      visitEyebrow: '07 / Studio & Directions', visitTitle: 'Private studio in Paengseong-eup, Pyeongtaek.',
      addrEn: 'Capitorium #114, 52 Anjeongshopping-ro, Paengseong-eup, Pyeongtaek',
      mapFallback: 'Open the studio on KakaoMap', toTop: 'Back to top', dNaver: 'Naver Map', dKakao: 'KakaoMap', dGoogle: 'Google Maps', copyKo: 'Copy Korean address', taxiBtn: 'Show taxi card',
      how1: 'By taxi: show the driver the taxi card. It has the address in big Korean text.',
      how2: 'From Pyeongtaek Station or SRT Pyeongtaek-Jije Station, a taxi takes you to the door.',
      how3: 'Walk-ins welcome. Booking ahead guarantees your slot; parking details come with your booking.',
      ftStudio: 'Studio', ftAppt: 'Walk-ins welcome · bookings recommended', ftContact: 'Contact', ftExplore: 'Explore', ftPitch: 'Pitch preview: some details await Zee’s confirmation.',
      dockBook: 'Start your design', dockIg: 'Instagram DM', dockKakao: 'KakaoTalk',
      lbAsk: 'Ask about this', lbSave: '+ Save to request', lbSaved: '✓ Saved', close: 'Close',
      msgHello: 'Hi Zee! I’d like to get a tattoo.', msgIdea: 'Idea', msgPlace: 'Placement', msgSize: 'Size', msgRefs: 'References from your site', msgEnd: 'Thanks!',
    },
    ko: {
      ftCredit: '웹사이트 제작',
      title: 'TUZEE 타투 스튜디오 · 평택 만다라, 오너먼트, 동양화 타투',
      desc: 'Zee가 직접 손으로 그리는 맞춤 만다라, 신성 기하학, 오너먼트, 동양화 타투. 평택 팽성읍 프라이빗 타투 스튜디오. 한국어 · English 상담.',
      motionPause: '움직임 일시정지', motionPlay: '움직임 재생', menuOpen: '메뉴', menuClose: '닫기', saveTile: '상담에 저장', openTile: '열기',
      brandSub: '타투 스튜디오', navWork: '작업', navDesigns: '도안', navZee: '아티스트', navHygiene: '위생·안전', navVisit: '오시는 길', navBook: '예약',
      heroClaim: '당신의 체형과 움직임에 맞춰 모든 도안을 직접 손으로 그립니다.', heroSign: 'Zee · 아티스트',
      heroEyebrow: '타투 스튜디오 · 평택', heroSr: ' 타투 스튜디오',
      heroLede: '정교한 도트워크 만다라, 척추 오너먼트, 이레즈미를 선보이는 평택 프라이빗 타투 스튜디오.',
      ctaStart: '도안 상담 시작', ctaWork: '작업 보기',
      uvHint: '움직여 선의 디테일을 확인하세요', uvEyebrow: '01 / 수작업 기하학', uvTitle: '하나의 중심에서 시작된 8각 대칭.',
      uvLede: '스튜디오 심볼이 된 8각 연꽃 만다라를 비롯해 모든 기하학 도안은 종이 위에서 컴퍼스와 연필로 직접 설계합니다. 빛을 움직여 점묘의 밀도와 선의 디테일을 가까이서 확인해 보세요.',
      uvAll: '도안 전체 보기', uvAllOff: '스포트라이트 모드로',
      cmpEyebrow: '02 / 도안에서 피부까지', cmpTitle: '쇄골과 척추, 근육의 흐름에 맞춘 설계.',
      cmpLede: '평면 도안은 어깨나 척추의 곡면을 감싸는 순간 형태가 달라집니다. 팔과 몸이 움직여도 대칭이 흐트러지지 않도록 체형에 맞춰 비율을 다시 잡습니다. 슬라이더를 움직여 원본 도안과 실제 시술 결과를 비교해 보세요.',
      tagDrawing: '도안', tagMockup: '목업', tagSession: '1차 세션', tagSkin: '시술 후', pairOf: '작업',
      workEyebrow: '03 / 포트폴리오', workTitle: '피부 위에 완성된 작업들.',
      workLede: '신성 기하학, 척추 오너먼트, 이레즈미, 파인라인 보태니컬까지 실제 시술된 67점의 아카이브입니다. 사진을 눌러 디테일을 크게 보거나, + 버튼을 눌러 상담 메시지에 참고 이미지로 담아보세요.',
      all: '전체', showAllWork: '전체 {n}점 모두 보기', showLessWork: '간략히 보기',
      desEyebrow: '04 / 오리지널 도안 & 목업', desTitle: '주인을 기다리는 오리지널 도안.',
      desLede: 'Zee의 스케치북에서 완성된 수작업 도안과 부위별 바디 목업입니다. 마음에 드는 도안을 그대로 예약하거나, + 버튼으로 저장해 내 체형에 맞춘 커스텀 작업의 출발점으로 삼아보세요.',
      segDrawings: '도안', segBody: '바디 목업', showAllDes: '전체 {n}점 모두 보기', showLessDes: '간략히 보기',
      zeeEyebrow: '05 / 아티스트 · 지경은',
      zeeTitle: '6개국을 거쳐 쌓아온 15년의 밀도.', p1: '손으로 그린 도안', p2: '몸에 맞춘 디자인', p3: '워크인 환영', p4: '한국어 · English',
      zeeLede: '2011년 작업을 시작해 멕시코, 브라질, 튀르키예, 일본, 베트남에서 게스트 워크를 거치며 다양한 피부 톤과 체형을 다뤄왔습니다. 평택 프라이빗 스튜디오에서 정교한 도트워크 만다라와 척추 오너먼트, 대형 오리엔탈 작업을 선보입니다.',
      fSinceK: '경력', fSinceV: '2011년부터 타투 작업', fGuestK: '게스트 작업', fGuestV: '멕시코 · 브라질 · 튀르키예 · 일본 · 베트남', fLangK: '언어', fStudioK: '스튜디오', fStudioV: '프라이빗 스튜디오. 워크인 환영.', walkIn: '워크인 환영',
      hygEyebrow: '무균 위생 & 1회용 툴 안전 수칙', hygTitle: '눈앞에서 개봉하는 1회용 멸균 니들, 매 세션 새 배리어 래핑.',
      aftercareBtn: '30일 애프터케어 및 안전 가이드',
      hygP1K: '1회용 멸균 카트리지', hygP1V: '역류 방지 멤브레인이 내장된 개별 멸균 니들 카트리지를 시술 직전 고객 눈앞에서 직접 개봉합니다.',
      hygP2K: '전 장비 배리어 필름 래핑', hygP2V: '머신, 그립, 암레스트, 작업 조명, 시술 베드 전체를 매 고객마다 새 일회용 배리어 필름으로 래핑합니다.',
      hygP3K: '일회용 잉크캡 & 폐기물 밀폐', hygP3V: '잉크는 일회용 캡에 소분하여 사용하며, 사용된 니들은 즉시 전용 밀폐 용기에 분리 폐기합니다.',
      hygP4K: '직립 자세 스텐실 설계', hygP4V: '베드에 누웠을 때의 피부 왜곡을 막기 위해 수평 바닥에 바르게 선 상태에서 척추 축과 대칭을 먼저 맞춥니다.',
      acEyebrow: '무균 위생 · 툴 안전 수칙 & 30일 애프터케어', acTitle: '시술 순간부터 30일 회복까지 피부를 지키는 원칙',
      acCol1: '30일 진피 회복 타임라인', acCol2: '부위별 직립 스텐실 & 맞춤 설계',
      hygS1T: '1~4일차 · 방수 브리더블 보호 필름', hygS1D: '시술 직후 부착해 드리는 방수·투습 메디컬 필름이 외부 마찰과 먼지를 차단하고 자연 치유 진물을 보호합니다.',
      hygS2T: '4~7일차 · 미온수 필름 제거 및 약산성 세정', hygS2D: '샤워 시 미온수를 흘려보내며 필름을 천천히 떼어낸 뒤, 무향 약산성 비누로 가볍게 씻고 전용 연고를 얇게 펴 바릅니다.',
      hygS3T: '8~21일차 · 각질 자연 탈락 (뜯거나 불리지 않기)', hygS3D: '일어나는 얇은 각질은 절대 손으로 뜯지 마시고, 통목욕·수영장·사우나 및 과도한 땀이 나는 운동을 피해 주세요.',
      hygS4T: '30일 이후~ · SPF 50+ 자외선 차단', hygS4D: '표피가 완전히 재생된 4주 이후부터 야외 활동 시 자외선 차단제를 발라주시면 극세선과 블랙워크의 대비가 오래 유지됩니다.',
      acZ1K: '척추 & 등 전체', acZ1V: '베드에 엎드리면 척추 축이 4~9mm 비틀립니다. 모든 척추와 등 작업은 바르게 선 자세에서 수직 중심선을 먼저 잡습니다.',
      acZ2K: '어깨 & 날개뼈', acZ2V: '팔을 움직일 때 늘어나는 견갑골 가동 범위를 계산하여 중심 만다라와 도트워크 그라데이션을 설계합니다.',
      acZ3K: '팔뚝 & 슬리브', acZ3V: '손목을 회전할 때 교차하는 하박 근육의 자연스러운 나선 궤적을 따라 기하학 그리드를 감싸 왜곡을 방지합니다.',
      acZ4K: '팔꿈치 & 무릎', acZ4V: '굽힐 때 35% 이상 팽창하는 관절 부위는 네거티브 스페이스(여백)와 고밀도 도트워크를 조화시켜 주름 사이까지 균일하게 발색시킵니다.',
      bookEyebrow: '06 / 상담 및 예약', bookTitle: '원하는 작업을 Zee에게 직접 보내보세요.',
      bookLede: '생각 중인 구도와 부위, 대략적인 크기를 고른 뒤 인스타그램 DM이나 카카오톡으로 바로 전송하세요. 위에서 + 버튼으로 담아둔 참고 작업들이 메시지에 자동으로 포함됩니다.',
      s1h: '아이디어 보내기', s1p: '간단한 설명, 부위, 대략적인 크기, 저장한 참고 이미지.',
      s2h: '도안 작업', s2p: '맞춤 도안과 견적을 받아보세요. 수정도 과정의 일부입니다.',
      s3h: '시술', s3p: '프라이빗 시술 후 한국어 또는 영어로 애프터케어를 안내해 드립니다.',
      fIdea: '아이디어', fIdeaPh: '예: 등 상단에 연꽃 만다라, 블랙 앤 그레이, #021 느낌으로',
      fPlace: '부위', fSize: '대략적인 크기', fRefs: '저장한 참고 이미지', fSend: '보낼 앱',
      refsEmpty: '아직 저장한 이미지가 없습니다. 작업이나 도안에서 +를 눌러보세요.', clearRefs: '전체 삭제',
      fFine: '인스타그램과 카카오톡은 메시지를 미리 채울 수 없어서, 메시지를 복사해 드립니다. 채팅창에 붙여넣기 하세요.',
      hintIg: '복사 + DM 열기', hintKakao: '복사 + 채팅 열기', hintEmail: '메시지 복사',
      copied: '메시지가 복사되었습니다. 채팅창에 붙여넣어 주세요.', emailPending: '메시지가 복사되었습니다 — 이메일 확인 중이니 인스타그램 DM이나 카카오톡에 붙여넣어 주세요.',
      copiedAddr: '한국어 주소가 복사되었습니다', saved: '상담 메시지에 저장됨', unsaved: '상담 메시지에서 제거됨',
      visitEyebrow: '07 / 스튜디오 위치 & 오시는 길', visitTitle: '평택 팽성읍 안정쇼핑로 52, 캐피토리움 114호.',
      addrEn: '평택시 팽성읍 안정쇼핑로 52, 캐피토리움 114호',
      mapFallback: '카카오맵에서 스튜디오 보기', toTop: '맨 위로', dNaver: '네이버 지도', dKakao: '카카오맵', dGoogle: '구글 지도', copyKo: '주소 복사', taxiBtn: '택시 카드 보기',
      how1: '택시: 기사님께 택시 카드를 보여주세요. 주소가 크게 적혀 있습니다.',
      how2: '평택역 또는 SRT 평택지제역에서 택시로 바로 오실 수 있습니다.',
      how3: '워크인 환영합니다. 미리 예약하시면 시간을 확보해 드리고, 주차 안내도 함께 드립니다.',
      ftStudio: '스튜디오', ftAppt: '워크인 환영 · 예약 권장', ftContact: '연락처', ftExplore: '둘러보기', ftPitch: '제안용 미리보기: 일부 정보는 Zee의 확인이 필요합니다.',
      dockBook: '도안 상담 시작', dockIg: '인스타그램 DM', dockKakao: '카카오톡',
      lbAsk: '이 작업 문의하기', lbSave: '+ 상담에 저장', lbSaved: '✓ 저장됨', close: '닫기',
      msgHello: '안녕하세요 Zee님! 타투 상담 받고 싶어요.', msgIdea: '아이디어', msgPlace: '부위', msgSize: '크기', msgRefs: '사이트에서 고른 참고 작업', msgEnd: '감사합니다!',
    },
  };

  // ---------- state ----------
  const store = {
    get(k, d) { try { const v = localStorage.getItem(k); return v === null ? d : JSON.parse(v); } catch { return d; } },
    set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch { /* private mode: fine */ } },
  };
  let lang = store.get('tuzee-lang', (navigator.language || 'en').toLowerCase().startsWith('ko') ? 'ko' : 'en');
  const saved = new Set(store.get('tuzee-saved', [])); // unknown ids are dropped once data loads
  let workFilter = 'all';
  let workExpanded = false;
  let designSeg = 'drawing';
  let designExpanded = false;
  const WORK_INITIAL = 16;
  const DESIGN_INITIAL = 12;
  let pairIndex = 0;
  const t = (k) => T[lang][k] ?? T.en[k] ?? k;
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

  // ---------- toast + clipboard ----------
  let toastTimer;
  function toast(msg) {
    const el = $('#toast');
    el.textContent = msg;
    el.setAttribute('data-show', '');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => el.removeAttribute('data-show'), 2600);
  }
  async function copy(text) {
    try { await navigator.clipboard.writeText(text); return true; } catch {
      const ta = Object.assign(document.createElement('textarea'), { value: text });
      ta.style.cssText = 'position:fixed;opacity:0';
      document.body.append(ta); ta.select();
      let ok = false; try { ok = document.execCommand('copy'); } catch { /* ignore */ }
      ta.remove(); return ok;
    }
  }

  // ---------- language ----------
  function renderSavedBadges() {
    const suffix = saved.size ? ` (${saved.size})` : '';
    $$('[data-i18n="dockBook"], [data-i18n="navBook"]').forEach((el) => {
      el.textContent = t(el.dataset.i18n) + suffix;
    });
  }
  // Cheap: static text, labels, title. Runs before first paint so a Korean visit never shows English.
  function applyText() {
    document.documentElement.lang = lang;
    $$('[data-lang]').forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.lang === lang)));
    $$('[data-i18n]').forEach((el) => { el.textContent = t(el.dataset.i18n); });
    $$('[data-i18n-placeholder]').forEach((el) => { el.placeholder = t(el.dataset.i18nPlaceholder); });
    renderDock();
    renderSavedBadges();
    $('#uvAll').textContent = $('#uvStage').hasAttribute('data-full') ? t('uvAllOff') : t('uvAll');
    document.title = t('title');
    $('meta[name="description"]').setAttribute('content', t('desc'));
    renderMenuContact(); renderMotionLabel(); renderSocials();
    $('#toTop').setAttribute('aria-label', t('toTop'));
    $('#menuBtn').setAttribute('aria-label', t('menuOpen'));
    $$('dialog [data-close]:not([data-i18n])').forEach((b) => b.setAttribute('aria-label', t('menuClose')));
  }
  // Heavy: 127 gallery tiles, pairs, the request form. All below the fold, so on first load
  // they are built right after the first paint instead of holding the hero text back.
  function renderHeavy() {
    renderFilters(); renderWork(); renderDesigns(); renderZee(); renderPairs(); showPair(pairIndex);
    renderPlacement(); renderSizes(); renderRefs(); renderSend();
  }
  function applyLang() { applyText(); renderHeavy(); }
  $$('[data-lang]').forEach((b) => b.addEventListener('click', () => {
    if (b.dataset.lang === lang) return;
    lang = b.dataset.lang; store.set('tuzee-lang', lang); applyLang();
  }));

  // ---------- header, dock, hero ----------
  const header = $('#header');
  const dock = $('#dock');
  const hero = $('#top');
  const onScroll = () => {
    header.toggleAttribute('data-scrolled', scrollY > 40);
    const past = hero.getBoundingClientRect().bottom < 120;
    const nearBook = $('#book').getBoundingClientRect().top < innerHeight && $('#book').getBoundingClientRect().bottom > 0;
    dock.toggleAttribute('data-show', past && !nearBook);
    $('#toTop').toggleAttribute('data-show', scrollY > innerHeight * 1.2);
  };
  addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  // Split the wordmark into letters for the staggered rise.
  $$('[data-split]').forEach((el) => {
    el.innerHTML = [...el.textContent].map((c, i) => `<span class="ch" style="--i:${i}">${c}</span>`).join('');
  });

  // Motion control (WCAG 2.2.2): paused state lives on <html data-motion="off"> and in localStorage.
  const heroVid = $('#heroVideo');
  let motionOff = store.get('tuzee-motion', reduceMotion ? 'off' : 'on') === 'off';
  let heroInView = true;
  const mobileVideo = matchMedia('(max-width: 700px)').matches;
  function renderMotionLabel() {
    const b = $('#motionToggle');
    b.setAttribute('aria-pressed', String(motionOff));
    b.setAttribute('aria-label', motionOff ? t('motionPlay') : t('motionPause'));
  }
  function applyMotion() {
    if (motionOff) document.documentElement.setAttribute('data-motion', 'off');
    else document.documentElement.removeAttribute('data-motion');
    if (motionOff) heroVid.pause(); else if (heroVid.src && heroInView) heroVid.play().catch(() => {});
    renderMotionLabel();
  }
  // Hero video: small file on phones; skipped on data saver or while motion is paused.
  function startHeroVideo() {
    const saveData = navigator.connection && navigator.connection.saveData;
    if (saveData || heroVid.src) return;
    heroVid.src = mobileVideo ? 'media/hero-mobile.mp4' : 'media/hero-1080.mp4';
    if (!motionOff) heroVid.play().catch(() => { /* autoplay blocked: poster stays */ });
  }
  $('#motionToggle').addEventListener('click', () => {
    motionOff = !motionOff; store.set('tuzee-motion', motionOff ? 'off' : 'on');
    if (!motionOff) startHeroVideo();
    applyMotion();
  });
  heroVid.poster = mobileVideo ? 'media/hero-poster-m.webp' : 'media/hero-poster.webp';
  // Start the video after load so it never competes with first paint.
  if (!motionOff) addEventListener('load', () => setTimeout(startHeroVideo, 0), { once: true });
  // Pause when the hero is off screen to save battery; never resume while the visitor paused motion.
  new IntersectionObserver(([e]) => {
    heroInView = e.isIntersecting;
    if (heroInView && !motionOff && heroVid.src) heroVid.play().catch(() => {}); else heroVid.pause();
  }).observe(hero);

  // ---------- marquee ----------
  (function marquee() {
    const words = ['Mandala', 'Sacred geometry', 'Dotwork', 'Ornamental', 'Irezumi', 'Fine line', 'Blackwork', 'Psycore', 'Hi-tech', '만다라', '이레즈미'];
    const run = words.map((w) => `<span>${w}</span><i>✦</i>`).join('');
    $('#marquee').innerHTML = run + run;
  })();

  // ---------- UV torch ----------
  (function uv() {
    const stage = $('#uvStage');
    let raf = 0;
    const move = (e) => {
      const r = stage.getBoundingClientRect();
      const x = ((e.clientX - r.left) / r.width) * 100;
      const y = ((e.clientY - r.top) / r.height) * 100;
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(() => {
        stage.style.setProperty('--x', `${x}%`);
        stage.style.setProperty('--y', `${y}%`);
      });
      stage.setAttribute('data-touched', '');
    };
    new IntersectionObserver((es, o) => { if (es[0].isIntersecting) { stage.setAttribute('data-ready', ''); o.disconnect(); } }, { rootMargin: '600px' }).observe(stage);
    stage.addEventListener('pointermove', move);
    stage.addEventListener('pointerdown', move);
    $('#uvAll').addEventListener('click', (e) => {
      const on = stage.toggleAttribute('data-full');
      e.currentTarget.textContent = on ? t('uvAllOff') : t('uvAll');
    });
  })();

  // ---------- paper -> skin compare ----------
  function renderPairs() {
    $('#pairList').innerHTML = PAIRS.map((p, i) => `
      <li><button type="button" data-pair="${i}" aria-pressed="${i === pairIndex}">
        <img src="${img(p.a, 'xs')}" alt="${esc(p[lang])}" loading="lazy" decoding="async"><span>${esc(p[lang])}</span>
      </button></li>`).join('');
  }
  function showPair(i) {
    pairIndex = i;
    const p = PAIRS[i];
    const before = $('#cmpBefore'); const after = $('#cmpAfter');
    before.src = img(p.b, 'l'); before.alt = byId[p.b][lang];
    after.src = img(p.a, 'l'); after.alt = byId[p.a][lang];
    // The stage has a fixed height; the frame is fitted inside it at the after-image ratio,
    // so the photo edges are the frame edges and the space around it is a blurred fill.
    $('#cmpFill').src = img(p.a, 's');
    fitFrame();
    $('#cmpTagL').textContent = t({ drawing: 'tagDrawing', mockup: 'tagMockup', session: 'tagSession' }[p.kind]);
    $('#cmpCaption').textContent = p[lang];
    $('#cmpCount').textContent = `${t('pairOf')} ${String(i + 1).padStart(2, '0')} / ${String(PAIRS.length).padStart(2, '0')} · #${p.b} → #${p.a}`;
    $$('#pairList [data-pair]').forEach((b) => b.setAttribute('aria-pressed', String(Number(b.dataset.pair) === i)));
  }
  $('#pairList').addEventListener('click', (e) => {
    const b = e.target.closest('[data-pair]');
    if (b) showPair(Number(b.dataset.pair));
  });
  $('#cmpRange').addEventListener('input', (e) => $('#cmp').style.setProperty('--pos', `${e.target.value}%`));
  function fitFrame() {
    const p = PAIRS[pairIndex];
    if (!byId[p.a]) return;
    const ar = byId[p.a].w / byId[p.a].h;
    const box = $('#cmpStage').getBoundingClientRect();
    let w = box.width; let h = w / ar;
    if (h > box.height) { h = box.height; w = h * ar; }
    const frame = $('#cmp');
    frame.style.width = `${Math.floor(w)}px`;
    frame.style.height = `${Math.floor(h)}px`;
  }
  new ResizeObserver(fitFrame).observe($('#cmpStage'));

  // ---------- galleries (SEO alt attributes + progressive reveal) ----------
  const tile = (w) => {
    const h = Math.round(560 * (w.h / w.w));
    const on = saved.has(w.id);
    const altText = `${w[lang]} (#${w.id})`;
    return `<div class="tile" data-id="${w.id}"${on ? ' data-saved' : ''}>
      <button class="tile-open" type="button">
        <img src="${img(w.id)}" srcset="${img(w.id, 'xs')} 320w, ${img(w.id)} 560w" sizes="(min-width:1500px) 18vw, (min-width:1100px) 23vw, (min-width:700px) 31vw, 48vw" alt="${esc(altText)}" width="560" height="${h}" loading="lazy" decoding="async">
        <span class="tile-cap" aria-hidden="true"><span>${esc(STYLES[w.style]?.[lang] || '')}</span><code>#${w.id}</code></span>
      </button>
      <button class="tile-save" type="button" data-save="${w.id}" aria-pressed="${on}" aria-label="${esc(t('saveTile'))} #${w.id}"></button>
    </div>`;
  };
  // Big statement pieces open the gallery; the rest follow by style.
  const FEATURED = ['071', '058', '047', '026', '067', '060', '079', '044', '064', '019', '070', '051'];
  const rank = (w) => (FEATURED.includes(w.id) ? FEATURED.indexOf(w.id) : 100 + STYLE_ORDER.indexOf(w.style));
  const skin = () => WORKS.filter((w) => w.group === 'skin')
    .sort((a, b) => rank(a) - rank(b) || b.id.localeCompare(a.id));

  function renderFilters() {
    const list = skin();
    const counts = Object.fromEntries(STYLE_ORDER.map((s) => [s, list.filter((w) => w.style === s).length]));
    $('#workFilters').innerHTML = [['all', t('all'), list.length], ...STYLE_ORDER.filter((s) => counts[s]).map((s) => [s, STYLES[s][lang], counts[s]])]
      .map(([k, label, n]) => `<button type="button" class="chip" data-filter="${k}" aria-pressed="${workFilter === k}">${esc(label)} <sup>${n}</sup></button>`).join('');
  }
  function renderWork() {
    $('#workGrid').innerHTML = skin().map(tile).join('');
    applyWorkFilter();
  }
  function applyWorkFilter() {
    const tiles = $$('#workGrid .tile');
    const matching = tiles.filter((el) => workFilter === 'all' || byId[el.dataset.id].style === workFilter);
    const shouldCap = workFilter === 'all' && !workExpanded && matching.length > WORK_INITIAL;
    let shown = 0;
    tiles.forEach((el) => {
      const match = workFilter === 'all' || byId[el.dataset.id].style === workFilter;
      if (!match) { el.hidden = true; return; }
      shown += 1;
      el.hidden = shouldCap && shown > WORK_INITIAL;
    });
    const moreBtn = $('#workMore');
    if (moreBtn) {
      const canToggle = workFilter === 'all' && matching.length > WORK_INITIAL;
      moreBtn.parentElement.hidden = !canToggle;
      moreBtn.textContent = workExpanded ? t('showLessWork') : t('showAllWork').replace('{n}', String(matching.length));
    }
  }
  $('#workFilters').addEventListener('click', (e) => {
    const b = e.target.closest('[data-filter]');
    if (!b) return;
    workFilter = b.dataset.filter;
    $$('#workFilters .chip').forEach((c) => c.setAttribute('aria-pressed', String(c === b)));
    applyWorkFilter();
  });
  $('#workMore').addEventListener('click', () => {
    workExpanded = !workExpanded;
    applyWorkFilter();
  });

  function renderDesigns() {
    const list = WORKS.filter((w) => w.group === designSeg);
    $('#designGrid').innerHTML = list.map(tile).join('');
    applyDesignCap(list.length);
  }
  function applyDesignCap(total) {
    const tiles = $$('#designGrid .tile');
    const shouldCap = !designExpanded && total > DESIGN_INITIAL;
    tiles.forEach((el, idx) => { el.hidden = shouldCap && idx >= DESIGN_INITIAL; });
    const moreBtn = $('#designMore');
    if (moreBtn) {
      moreBtn.parentElement.hidden = total <= DESIGN_INITIAL;
      moreBtn.textContent = designExpanded ? t('showLessDes') : t('showAllDes').replace('{n}', String(total));
    }
  }
  $$('[data-seg]').forEach((b) => b.addEventListener('click', () => {
    designSeg = b.dataset.seg;
    designExpanded = false;
    $$('[data-seg]').forEach((x) => x.setAttribute('aria-pressed', String(x === b)));
    renderDesigns();
  }));
  $('#designMore').addEventListener('click', () => {
    designExpanded = !designExpanded;
    applyDesignCap(WORKS.filter((w) => w.group === designSeg).length);
  });

  function renderZee() {
    const ids = ['003', '004', '001', '002'];
    $('#zeePhotos').innerHTML = ids.map((id) => `<figure><img src="${img(id, 'l')}" alt="${esc(byId[id][lang])}" loading="lazy" decoding="async"></figure>`).join('');
  }

  // ---------- aftercare & hygiene dialog ----------
  $('#openAftercare').addEventListener('click', () => $('#aftercare').showModal());

  // ---------- lightbox ----------
  const lb = $('#lightbox');
  let lbList = []; let lbIndex = 0;
  function openLightbox(id, grid) {
    lbList = $$('.tile:not([hidden])', grid).map((el) => el.dataset.id);
    lbIndex = Math.max(0, lbList.indexOf(id));
    renderLightbox();
    lb.showModal();
  }
  function renderLightbox() {
    const w = byId[lbList[lbIndex]];
    const im = $('#lbImg');
    im.src = img(w.id, 'l'); im.alt = w[lang];
    $('#lbCaption').textContent = w[lang];
    $('#lbCount').textContent = `#${w.id} · ${lbIndex + 1} / ${lbList.length}`;
    $('#lbSave').textContent = saved.has(w.id) ? t('lbSaved') : t('lbSave');
    // Warm the neighbours so stepping feels instant.
    [lbIndex - 1, lbIndex + 1].forEach((i) => { const n = lbList[(i + lbList.length) % lbList.length]; if (n) new Image().src = img(n, 'l'); });
  }
  const step = (d) => { lbIndex = (lbIndex + d + lbList.length) % lbList.length; renderLightbox(); };
  $('#lbPrev').addEventListener('click', () => step(-1));
  $('#lbNext').addEventListener('click', () => step(1));
  lb.addEventListener('keydown', (e) => { if (e.key === 'ArrowLeft') step(-1); if (e.key === 'ArrowRight') step(1); });
  (function swipe() {
    let x0 = null;
    $('#lbStage').addEventListener('pointerdown', (e) => { x0 = e.clientX; });
    $('#lbStage').addEventListener('pointerup', (e) => {
      if (x0 === null) return;
      const dx = e.clientX - x0; x0 = null;
      if (Math.abs(dx) > 50) step(dx < 0 ? 1 : -1);
    });
  })();
  $('#lbSave').addEventListener('click', () => { toggleSaved(lbList[lbIndex]); renderLightbox(); });
  $('#lbAsk').addEventListener('click', () => { const id = lbList[lbIndex]; if (!saved.has(id)) toggleSaved(id); lb.close(); });
  ['#workGrid', '#designGrid'].forEach((sel) => $(sel).addEventListener('click', (e) => {
    const sv = e.target.closest('.tile-save');
    if (sv) { toggleSaved(sv.dataset.save); return; }
    const el = e.target.closest('.tile-open');
    if (el) openLightbox(el.closest('.tile').dataset.id, $(sel));
  }));

  // Generic dialog close: buttons + backdrop click.
  $$('dialog').forEach((d) => {
    d.addEventListener('click', (e) => { if (e.target.closest('[data-close]') || e.target === d) d.close(); });
  });

  // ---------- saved references + request builder ----------
  function toggleSaved(id) {
    if (!byId[id]) return;
    if (saved.has(id)) { saved.delete(id); toast(t('unsaved')); } else { saved.add(id); toast(t('saved')); }
    store.set('tuzee-saved', [...saved]);
    $$(`.tile[data-id="${id}"]`).forEach((el) => {
      el.toggleAttribute('data-saved', saved.has(id));
      $('.tile-save', el).setAttribute('aria-pressed', String(saved.has(id)));
    });
    renderRefs(); renderSend(); renderSavedBadges();
  }
  function clearAllSaved() {
    saved.clear();
    store.set('tuzee-saved', []);
    $$('.tile[data-saved]').forEach((el) => {
      el.removeAttribute('data-saved');
      $('.tile-save', el).setAttribute('aria-pressed', 'false');
    });
    renderRefs(); renderSend(); renderSavedBadges();
    toast(t('unsaved'));
  }
  function renderRefs() {
    const box = $('#rRefs');
    if (!saved.size) {
      box.innerHTML = `<p class="refs-empty">${esc(t('refsEmpty'))}</p>`;
      return;
    }
    const pills = [...saved].map((id) => `<span class="ref"><img src="${img(id, 'xs')}" alt="">#${id}<button type="button" data-unsave="${id}" aria-label="Remove #${id}">×</button></span>`).join('');
    const clearBtn = saved.size > 1 ? `<button type="button" class="refs-clear" data-clear-refs>${esc(t('clearRefs'))}</button>` : '';
    box.innerHTML = pills + clearBtn;
  }
  $('#rRefs').addEventListener('click', (e) => {
    const b = e.target.closest('[data-unsave]');
    if (b) { toggleSaved(b.dataset.unsave); return; }
    if (e.target.closest('[data-clear-refs]')) clearAllSaved();
  });

  function renderPlacement() {
    const sel = $('#rPlace'); const cur = sel.value;
    sel.innerHTML = PLACEMENTS.map(([v, en, ko]) => `<option value="${v}">${lang === 'ko' ? ko : en}</option>`).join('');
    if (cur) sel.value = cur;
  }
  function renderSizes() {
    const cur = ($('#rSize input:checked') || {}).value || 'm';
    $('#rSize').innerHTML = SIZES.map(([v, en, ko]) => `<label><input type="radio" name="size" value="${v}"${v === cur ? ' checked' : ''}><span>${lang === 'ko' ? ko : en}</span></label>`).join('');
  }
  function message() {
    const place = PLACEMENTS.find((p) => p[0] === $('#rPlace').value) || PLACEMENTS[0];
    const size = SIZES.find((s) => s[0] === (($('#rSize input:checked') || {}).value || 'm'));
    const pick = (row) => (lang === 'ko' ? row[2] : row[1]);
    const idea = $('#rIdea').value.trim();
    const base = location.protocol.startsWith('http') ? location.href.split('#')[0].replace(/[^/]*$/, '') : '';
    const lines = [t('msgHello')];
    if (idea) lines.push(`${t('msgIdea')}: ${idea}`);
    lines.push(`${t('msgPlace')}: ${pick(place)}`, `${t('msgSize')}: ${pick(size)}`);
    if (saved.size) {
      lines.push(`${t('msgRefs')}:`);
      saved.forEach((id) => lines.push(base ? `#${id} ${base}${img(id, 'l')}` : `#${id}`));
    }
    lines.push(t('msgEnd'));
    return lines.join('\n');
  }
  function renderSend() {
    const order = lang === 'ko' ? ['kakao', 'instagram', 'email'] : ['instagram', 'kakao', 'email'];
    const label = { instagram: 'Instagram', kakao: lang === 'ko' ? '카카오톡' : 'KakaoTalk', email: lang === 'ko' ? '이메일' : 'Email' };
    const hint = { instagram: t('hintIg'), kakao: t('hintKakao'), email: t('hintEmail') };
    $('#rSend').innerHTML = order.map((k, i) => {
      const isPlaceholderEmail = k === 'email' && LINKS.email === 'hello@example.com';
      const href = k === 'email' ? (isPlaceholderEmail ? '#book' : `mailto:${LINKS.email}?subject=${encodeURIComponent('Tattoo idea')}&body=${encodeURIComponent(message())}`) : LINKS[k];
      const target = k === 'email' ? '' : ' target="_blank" rel="noopener"';
      return `<a class="${i === 0 ? 'primary' : ''}" data-send="${k}" href="${esc(href)}"${target}>${label[k]}<small>${hint[k]}</small></a>`;
    }).join('');
  }
  $('#request').addEventListener('input', () => {
    const mail = $('#rSend [data-send="email"]');
    if (mail && LINKS.email !== 'hello@example.com') {
      mail.href = `mailto:${LINKS.email}?subject=${encodeURIComponent('Tattoo idea')}&body=${encodeURIComponent(message())}`;
    }
  });
  $('#rSend').addEventListener('click', (e) => {
    const a = e.target.closest('[data-send]');
    if (!a) return;
    if (a.dataset.send === 'email' && LINKS.email === 'hello@example.com') {
      e.preventDefault();
      copy(message()).then((ok) => ok && toast(t('emailPending')));
      return;
    }
    if (a.dataset.send === 'email') return;
    copy(message()).then((ok) => ok && toast(t('copied')));
  });

  function renderSocials() {
    const html = SOCIALS.map((s) => {
      const label = s.k === 'kakao' && lang === 'ko' ? '카카오톡' : s.label;
      return `<li><a class="social social-${s.k}" href="${s.href}" target="_blank" rel="noopener" aria-label="${label}" title="${label}">${s.svg}</a></li>`;
    }).join('');
    $$('[data-socials]').forEach((ul) => { ul.innerHTML = html; });
  }
  function renderDock() {
    const k = lang === 'ko' ? 'kakao' : 'instagram';
    const a = $('#dockPrimary');
    a.href = LINKS[k];
    a.textContent = k === 'kakao' ? t('dockKakao') : t('dockIg');
  }
  const ftEmail = $('#ftEmail');
  if (ftEmail) {
    ftEmail.href = LINKS.email === 'hello@example.com' ? '#book' : `mailto:${LINKS.email}`;
    ftEmail.addEventListener('click', (e) => {
      if (LINKS.email === 'hello@example.com') {
        e.preventDefault();
        copy(message()).then((ok) => ok && toast(t('emailPending')));
      }
    });
  }

  // ---------- phone menu ----------
  const menu = $('#menu');
  const menuBtn = $('#menuBtn');
  function renderMenuContact() {
    const order = lang === 'ko' ? ['kakao', 'instagram'] : ['instagram', 'kakao'];
    const label = { instagram: 'Instagram', kakao: lang === 'ko' ? '카카오톡' : 'KakaoTalk' };
    $('#menuContact').innerHTML = order.map((k, i) => `<a class="btn${i === 0 ? ' btn-acid' : ''}" href="${LINKS[k]}" target="_blank" rel="noopener">${label[k]}</a>`).join('');
  }
  menuBtn.addEventListener('click', () => { menu.showModal(); menuBtn.setAttribute('aria-expanded', 'true'); });
  menu.addEventListener('close', () => menuBtn.setAttribute('aria-expanded', 'false'));
  menu.addEventListener('click', (e) => { if (e.target.closest('.menu-links a')) menu.close(); });
  matchMedia('(min-width: 980px)').addEventListener('change', (e) => { if (e.matches && menu.open) menu.close(); });

  // ---------- visit ----------
  // KakaoMap embed: load Kakao's roughmap script only when the map is about to scroll into view.
  (function kakaoMap() {
    const box = $('#map');
    let started = false;
    const start = () => {
      if (started) return;
      started = true;
      const s = document.createElement('script');
      s.charset = 'UTF-8';
      s.className = 'daum_roughmap_loader_script';
      s.src = 'https://t1.kakaocdn.net/kakaomapweb/roughmap/loader/prod/roughmapLoader.js';
      s.onload = () => {
        const rm = window.daum && window.daum.roughmap;
        if (!rm) return;
        if (rm.Lander) { render(); return; }
        const l = document.createElement('script');
        l.charset = 'UTF-8';
        l.src = `${rm.url_protocal}${rm.url_cdn_domain}/kakaomapweb/roughmap/place/${rm.phase}/${rm.cdn}/roughmapLander.js`;
        l.onload = render;
        document.head.append(l);
      };
      const render = () => {
        try {
          const r = box.getBoundingClientRect();
          new window.daum.roughmap.Lander({
            timestamp: box.dataset.roughmapTs,
            key: box.dataset.roughmapKey,
            mapWidth: String(Math.round(r.width)),
            mapHeight: String(Math.max(360, Math.round(r.height))),
          }).render();
          box.setAttribute('data-loaded', '');
        } catch (err) { /* keep the fallback link visible */ }
      };
      document.head.append(s);
    };
    new IntersectionObserver(([e], o) => { if (e.isIntersecting) { o.disconnect(); start(); } }, { rootMargin: '600px' }).observe(box);
  })();
  $('#dirNaver').href = MAPS.naver;
  $('#dirKakao').href = MAPS.kakao;
  $('#dirGoogle').href = MAPS.google;
  $('#copyKo').addEventListener('click', () => copy(ADDR_KO).then((ok) => ok && toast(t('copiedAddr'))));
  $('#openTaxi').addEventListener('click', () => $('#taxi').showModal());

  applyText();
  document.documentElement.removeAttribute('data-i18n-pending');
  applyMotion();
  // Let the browser paint the hero first, then build the galleries.
  requestAnimationFrame(() => setTimeout(() => loadWorks().then(renderHeavy), 0));
  };
  boot();
})();

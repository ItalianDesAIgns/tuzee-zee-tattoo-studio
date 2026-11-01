"""One-off copy pass (Rasta, 02/11/26): site copy in Zee's own first-person voice, EN + KO.

Rules (WSP §3): no em-dashes, no "not X, Y" contrasts, no "No X, no Y" lists, no cryptic
fragments, no unverifiable numbers. Customer-voice strings (message template) stay as they are.
Updates T.en / T.ko in site/js/app.js and the static fallback text in site/index.html.

Usage: python tools/copy_first_person.py
"""
import re
from pathlib import Path

SITE = Path(__file__).resolve().parents[1] / 'site'

EN = {
    'desc': 'I’m Zee. I draw custom mandala, sacred geometry, ornamental and oriental tattoos by hand in my private studio in Paengseong-eup, Pyeongtaek. English and Korean.',
    'heroLede': 'Dotwork mandalas, ornamental spine pieces and irezumi, tattooed in my private studio in Pyeongtaek.',
    'uvTitle': 'I love drawing, but mandalas are my passion.',
    'uvLede': 'Every design starts on my desk with a compass, a ruler and graphite. This eight-point lotus became my studio mark. Move the light across it to see the dotwork and line weights up close.',
    'cmpTitle': 'Every line is adjusted to your shape before the needle starts.',
    'cmpLede': 'A flat drawing changes shape once it wraps a shoulder or follows a spine, so I redraw the proportions on your skin before I start. That keeps circles round when you move. Drag the slider to compare my drawing with the finished tattoo.',
    'workTitle': 'Pieces I’ve tattooed.',
    'workLede': 'Sixty-seven pieces across sacred geometry, ornamental spine work, oriental irezumi and fine-line botanicals. Tap a photo to see the linework full screen, or press + to add it to your message as a reference.',
    'desTitle': 'Drawings I’d love to tattoo next.',
    'desLede': 'Flash sheets and body-placement studies from my sketchbook. Claim one as it is, or save it with + and I’ll adapt the scale and placement to your body.',
    'zeeTitle': 'I’ve tattooed for fifteen years, in six countries.',
    'zeeLede': 'I started in 2011 and have worked guest spots in Mexico, Brazil, Turkey, Japan and Vietnam. My focus is high-contrast dotwork mandalas, ornamental spine pieces and large oriental compositions, and I tattoo to dark, high-BPM psytrance.',
    'fStudioV': 'My own private studio. Walk-ins welcome.',
    'hygTitle': 'I open every needle in front of you and wrap my station fresh for each session.',
    'hygP1V': 'I open each sterile membrane cartridge from its sealed blister pack in front of you.',
    'hygP2V': 'Machine, grip, armrest, lamp and bed get fresh disposable barrier film for every client.',
    'hygP3V': 'I pour ink into single-use caps before we start, and used needles go straight into a sealed sharps container.',
    'hygP4V': 'I map spine and geometric axes while you stand naturally, before you lie down.',
    'acTitle': 'How I look after your skin in the chair and for the 30 days after',
    'hygS1D': 'Before you leave, I cover the tattoo with a breathable, waterproof second-skin film that keeps out friction and dust while it starts to heal.',
    'hygS2D': 'Peel the film slowly under warm shower water, wash gently with fragrance-free soap, pat dry with a clean paper towel and apply a thin layer of ointment.',
    'hygS3T': 'Days 8–21 · Natural flaking',
    'hygS3D': 'Fine line and dotwork flake lightly, like a mild sunburn. Leave the flakes alone, and keep away from baths, pools, saunas and heavy sweat until the skin settles.',
    'hygS4D': 'From week four, wear SPF 50+ in direct sun so fine lines and blackwork stay sharp for years.',
    'acZ1V': 'Lying face-down shifts the spine, so I map every spine and back stencil while you stand barefoot on level ground.',
    'acZ2V': 'On the shoulder blade I anchor the mandala in the stable center and let the dotwork around it absorb movement, so circles stay round when you move your arm.',
    'acZ3V': 'The forearm bones rotate as your wrist turns, so I wrap geometric sleeves along that natural spiral to keep the lines parallel.',
    'acZ4V': 'Skin over elbows and knees stretches a lot when you bend, so I use negative space and layered dotwork that heal evenly across the crease.',
    'bookTitle': 'Send your idea straight to me.',
    'bookLede': 'Tell me your idea, pick the placement and size, and send it on Instagram or KakaoTalk. I read and answer every message myself, and anything you saved above comes along as a reference.',
    's2h': 'I draw it',
    's2p': 'I send you a custom design and a quote, and we adjust it together until it feels right.',
    's3p': 'A private session with me, then aftercare notes in English or Korean.',
    'emailPending': 'Message copied. Paste it into Instagram or KakaoTalk while my email address is being set up.',
    'visitTitle': 'Find my studio\\u00a0in',
    'how3': 'Walk-ins are welcome. Book ahead to guarantee your slot, and I’ll send parking details with your booking.',
}

KO = {
    'desc': '저는 Zee입니다. 평택 팽성읍의 프라이빗 스튜디오에서 만다라, 신성 기하학, 오너먼트, 동양화 타투를 직접 손으로 그립니다. 한국어 · English 상담.',
    'heroLede': '도트워크 만다라, 척추 오너먼트, 이레즈미를 평택의 제 프라이빗 스튜디오에서 작업합니다.',
    'uvTitle': '그림 그리는 것을 좋아하지만, 만다라는 제 열정입니다.',
    'uvLede': '모든 도안은 제 책상 위에서 컴퍼스와 자, 연필로 시작합니다. 이 8각 연꽃은 스튜디오 마크가 되었어요. 빛을 움직여 도트워크와 선의 굵기를 가까이 살펴보세요.',
    'cmpTitle': '니들이 닿기 전에, 모든 선을 당신의 몸에 맞춥니다.',
    'cmpLede': '평면 도안은 어깨를 감싸거나 척추를 따라가면 형태가 달라집니다. 그래서 시술 전에 피부 위에서 비율을 다시 잡아, 움직여도 원이 둥글게 유지되도록 합니다. 슬라이더를 움직여 제 도안과 완성된 타투를 비교해 보세요.',
    'workTitle': '제가 피부 위에 완성한 작업들.',
    'workLede': '신성 기하학, 척추 오너먼트, 동양화 이레즈미, 파인라인 보태니컬까지 67점의 작업입니다. 사진을 눌러 선을 크게 보거나, +를 눌러 상담 메시지에 참고 이미지로 담아보세요.',
    'desTitle': '다음에 새기고 싶은 제 오리지널 도안.',
    'desLede': '제 스케치북의 플래시 도안과 부위별 바디 목업입니다. 그대로 가져가셔도 되고, +로 저장해 주시면 크기와 위치를 당신의 몸에 맞게 조정해 드립니다.',
    'zeeTitle': '15년 동안, 6개국에서 타투를 해왔습니다.',
    'zeeLede': '2011년에 시작해 멕시코, 브라질, 튀르키예, 일본, 베트남에서 게스트 작업을 했습니다. 고대비 도트워크 만다라, 척추 오너먼트, 대형 동양화 작업이 제 중심이고, 작업할 때는 어둡고 빠른 BPM의 사이트랜스를 틀어둡니다.',
    'fStudioV': '저만의 프라이빗 스튜디오. 워크인 환영.',
    'hygTitle': '모든 니들은 당신 앞에서 개봉하고, 매 세션마다 작업대를 새로 래핑합니다.',
    'hygP1V': '개별 멸균 멤브레인 카트리지를 시술 직전 당신 앞에서 직접 개봉합니다.',
    'hygP2V': '머신, 그립, 암레스트, 조명, 베드 모두 고객마다 새 일회용 배리어 필름으로 감쌉니다.',
    'hygP3V': '잉크는 시작 전에 일회용 캡에 덜어 쓰고, 사용한 니들은 바로 밀폐된 전용 용기에 폐기합니다.',
    'hygP4V': '척추와 기하학 축은 편하게 서 계신 자세에서 먼저 잡고, 그 다음에 눕습니다.',
    'acTitle': '시술 중, 그리고 시술 후 30일 동안 제가 피부를 지키는 방법',
    'hygS1D': '돌아가시기 전에 통기성 있는 방수 세컨드스킨 필름을 붙여 드립니다. 마찰과 먼지를 막아 자연스럽게 아물도록 돕습니다.',
    'hygS3T': '8~21일차 · 각질 자연 탈락',
    'hygS3D': '파인라인과 도트워크는 가벼운 햇볕 화상처럼 살짝 벗겨집니다. 각질은 그대로 두시고, 피부가 안정될 때까지 목욕, 수영장, 사우나, 심한 땀은 피해 주세요.',
    'hygS4D': '4주차부터는 직사광선 아래에서 SPF 50+ 선크림을 발라 주세요. 가는 선과 블랙워크가 오래 선명하게 유지됩니다.',
    'acZ1V': '엎드리면 척추가 틀어지기 때문에, 척추와 등 스텐실은 평평한 바닥에 맨발로 서 계신 상태에서 먼저 잡습니다.',
    'acZ2V': '견갑골 위의 만다라는 움직임이 적은 중심에 고정하고, 주변 도트워크가 움직임을 흡수하게 해서 팔을 움직여도 원이 둥글게 보이도록 합니다.',
    'acZ3V': '손목을 돌리면 팔뚝 뼈가 나선형으로 교차합니다. 그래서 기하학 슬리브를 그 자연스러운 나선을 따라 감아 선이 평행하게 유지되도록 합니다.',
    'acZ4V': '팔꿈치와 무릎 피부는 구부릴 때 많이 늘어납니다. 그래서 네거티브 스페이스와 겹친 도트워크로 주름 부분까지 고르게 아물도록 디자인합니다.',
    'bookTitle': '아이디어를 저에게 직접 보내주세요.',
    'bookLede': '원하는 아이디어와 부위, 크기를 정해 인스타그램이나 카카오톡으로 보내주세요. 모든 메시지는 제가 직접 읽고 답장하며, 위에서 저장한 작업도 참고 이미지로 함께 전달됩니다.',
    's2h': '제가 그립니다',
    's2p': '맞춤 도안과 견적을 보내드리고, 마음에 들 때까지 함께 다듬습니다.',
    's3p': '저와의 프라이빗 시술 후, 한국어 또는 영어로 애프터케어를 안내해 드립니다.',
    'emailPending': '메시지가 복사되었습니다. 이메일 주소를 준비하는 동안 인스타그램이나 카카오톡에 붙여넣어 주세요.',
    'visitTitle': '제 스튜디오로 오세요.',
    'how3': '워크인 환영합니다. 미리 예약하시면 시간을 확보해 드리고, 주차 안내도 예약과 함께 보내드립니다.',
}


def sub_block(block: str, values: dict, lang: str) -> str:
    for k, v in values.items():
        assert "'" not in v, (lang, k)
        block, n = re.subn(r"(\b" + k + r": )'(?:[^'\\]|\\.)*'", lambda m: m.group(1) + "'" + v + "'", block, count=1)
        assert n == 1, f'{lang}.{k} not found'
    return block


def main() -> None:
    js_path = SITE / 'js' / 'app.js'
    js = js_path.read_text(encoding='utf-8')
    en_s = js.index('en: {'); ko_s = js.index('ko: {'); ko_e = js.index('\n    },', ko_s)
    js = js[:en_s] + sub_block(js[en_s:ko_s], EN, 'en') + sub_block(js[ko_s:ko_e], KO, 'ko') + js[ko_e:]
    js_path.write_text(js, encoding='utf-8')

    html_path = SITE / 'index.html'
    html = html_path.read_text(encoding='utf-8')
    changed = 0
    for k, v in EN.items():
        text = v.replace('\\u00a0', '&nbsp;')
        html, n = re.subn(r'(data-i18n="' + k + r'">)[^<]*(<)', lambda m: m.group(1) + text + m.group(2), html)
        changed += n
    if 'name="description"' in html:
        html = re.sub(r'(<meta name="description" content=")[^"]*(")', lambda m: m.group(1) + EN['desc'] + m.group(2), html, count=1)
    html_path.write_text(html, encoding='utf-8')
    print(f'app.js: {len(EN)} EN + {len(KO)} KO strings; index.html: {changed} static fallbacks')


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""pillarseer Play Console listing PATCH — K-pop lead 메타데이터 (iOS R111 와 동일 톤).

사용:
    python3 scripts/play_listing_patch.py

전제: ~/.googleplay/pillarseer-key.json 서비스 계정 권한 부여 + Play Console 앱 생성 완료.
"""
import os, sys
from googleapiclient.discovery import build
from google.oauth2 import service_account

PACKAGE_NAME = 'com.seephone.pillarseer'
KEY_PATH = os.path.expanduser('~/.googleplay/pillarseer-key.json')
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']

# ─── 한국어 ─────────────────────────────────────────────────────
KO_TITLE = '필러시어 - 최애의 사주'
KO_SHORT = 'K-pop 아이돌 203명 사주 + 인터넷소설 전생 66편'
KO_FULL = (
    "필러시어는 K-pop 팬을 위한 셀럽 사주 + 인터넷소설 앱입니다.\n\n"
    "▶ 최애의 사주 · 셀럽 203명\n"
    "아이유, 뷔(BTS), 제니(BLACKPINK), 카리나(aespa) 등 K-pop 아이돌 203명의 실제 생년월일"
    "(위키 검증)을 기반으로 일주(日柱) 차트와 분석을 보여드려요. 최애의 성향, 너와의 케미, "
    "같은 일주 셀럽 끼리 묶어보는 재미까지.\n\n"
    "▶ 인터넷소설 전생 66편\n"
    "한국 웹소설 스타일로 직접 집필한 66편 장편 서사. 너의 사주 일주에 맞춰 '전생에 너는 "
    "누구였을까' 를 한 편 한 편 읽는 소설처럼 풀어드려요. 한국어 66편 + 영문 66편 — 총 "
    "132편의 오리지널 픽션 컨텐츠.\n\n"
    "▶ 음악 처방 (Music Pharmacy)\n"
    "K-pop·OST 큐레이션. 너의 성향에 맞는 곡을 처방전처럼 알려드려요.\n\n"
    "▶ 최애와의 케미 (K-pop Compatibility)\n"
    "너 vs 아이돌 일주 비교. 같은 점, 다른 점, 케미 점수.\n\n"
    "▶ 한국 전통 문화 · 사주 입문\n"
    "부가 기능으로, 1000년 한국 전통의 사주(四柱) 개념을 십신·오행·격국·용신 등 한국 문화 "
    "키워드로 친절히 안내해요. 어려운 한자는 줄이고 일상 언어로.\n\n"
    "본 앱은 일반적인 일일 운세 앱이 아닙니다. K-pop 팬덤을 위한 셀럽 데이터 + 오리지널 "
    "서사 + 큐레이션 음악 + 한국 문화 입문이 메인 surface 입니다.\n\n"
    "수익 모델: 1회 결제 프리미엄 팩 (구독 X). 무료 5 카테고리 + 전생 1편, 프리미엄 12 "
    "카테고리 + 전생 66편."
)

# ─── English (en-US) ────────────────────────────────────────────
EN_TITLE = 'Pillarseer - K-pop Charts'
EN_SHORT = '203 K-pop idol charts + 66 past-life web-novel episodes'
EN_FULL = (
    "Pillarseer is a K-pop fandom app — original celebrity charts, hand-written fiction, "
    "and curated music — built around a Korean cultural framework.\n\n"
    "▶ My Favorite's Chart · 203 K-pop Idols\n"
    "IU, V (BTS), Jennie (BLACKPINK), Karina (aespa), and 199 more. Each idol's publicly "
    "known birth date is sourced from Korean Wikipedia and mapped to a traditional Korean "
    "day-pillar chart. Read your favorite's personality, compare chemistry with yours, "
    "and discover idols who share your pillar.\n\n"
    "▶ Past-Life Series · 66 Original Web-Novel Episodes\n"
    "66 hand-written longform episodes in the format of Korean web fiction. Tied to your "
    "day pillar, each episode tells you who you might have been in a past life — like "
    "reading a novel, one chapter at a time. 66 Korean episodes + 66 English episodes — "
    "132 original fiction stories.\n\n"
    "▶ Music Pharmacy — Personalized Song Prescriptions\n"
    "Curated K-pop and OST songs matched to your personality profile.\n\n"
    "▶ K-pop Compatibility — You vs Your Bias\n"
    "Compare day pillars with K-pop idols. Where you align, where you differ, chemistry score.\n\n"
    "▶ Korean Cultural Framework\n"
    "A 1,000-year-old Korean personality system (Saju / Four Pillars) explained in plain "
    "language — Ten Gods, Five Elements, structure charts — without the kanji wall.\n\n"
    "This is not a daily horoscope app. The main surfaces are K-pop celebrity content, "
    "original web-novel fiction, music curation, and a Korean cultural framework explainer.\n\n"
    "Monetization: one-time premium pack (no subscription). Free tier includes 5 categories "
    "+ 1 past-life episode; premium unlocks 12 categories + all 66 episodes."
)

assert len(KO_SHORT) <= 80, f"KO_SHORT {len(KO_SHORT)} > 80"
assert len(EN_SHORT) <= 80, f"EN_SHORT {len(EN_SHORT)} > 80"
assert len(KO_TITLE) <= 30, f"KO_TITLE {len(KO_TITLE)} > 30"
assert len(EN_TITLE) <= 30, f"EN_TITLE {len(EN_TITLE)} > 30"
assert len(KO_FULL) <= 4000, f"KO_FULL {len(KO_FULL)} > 4000"
assert len(EN_FULL) <= 4000, f"EN_FULL {len(EN_FULL)} > 4000"


def main():
    creds = service_account.Credentials.from_service_account_file(KEY_PATH, scopes=SCOPES)
    service = build('androidpublisher', 'v3', credentials=creds, cache_discovery=False)

    print(f'[1/4] edit 시작 ({PACKAGE_NAME}) ...')
    edit = service.edits().insert(packageName=PACKAGE_NAME, body={}).execute()
    eid = edit['id']

    for lang, title, short, full in [
        ('ko-KR', KO_TITLE, KO_SHORT, KO_FULL),
        ('en-US', EN_TITLE, EN_SHORT, EN_FULL),
    ]:
        print(f'[2/4] listing PATCH {lang} title={title!r} ...')
        service.edits().listings().update(
            editId=eid, packageName=PACKAGE_NAME, language=lang,
            body={'title': title, 'shortDescription': short, 'fullDescription': full}
        ).execute()

    print('[3/4] validate ...')
    service.edits().validate(editId=eid, packageName=PACKAGE_NAME).execute()

    print('[4/4] commit ...')
    service.edits().commit(editId=eid, packageName=PACKAGE_NAME).execute()
    print('🎉 Play Console listing K-pop lead 적용 완료')


if __name__ == '__main__':
    main()

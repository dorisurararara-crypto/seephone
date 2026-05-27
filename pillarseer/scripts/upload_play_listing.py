#!/usr/bin/env python3
"""pillarseer Play Console store listing — 한 edit 안에 이미지 + 텍스트 + commit.

사용:
    python3 scripts/upload_play_listing.py

전제: ~/.googleplay/pillarseer-key.json (service account JSON) 가
Play Console > 사용자 및 권한 (또는 API 액세스) 에서 com.seephone.pillarseer 에 대해
"앱 출시본 만들고 수정" + "스토어 등록정보, 가격 책정, 배포 관리" 권한 보유.

권한 부족 시 HTTP 401/403 — 그땐 Play Console UI 한 번 권한 부여 필요.
"""
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from googleapiclient.errors import HttpError
from pathlib import Path
import sys, os

PKG = 'com.seephone.pillarseer'
LANG = 'ko-KR'
KEY = os.path.expanduser('~/.googleplay/pillarseer-key.json')
ASSETS = Path('/Users/seunghyeon/seephone/pillarseer/.playwright-mcp')
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']

TITLE = '필러시어 - 최애의 사주'
SHORT = 'K-pop 아이돌 203명 사주 + 인터넷소설 전생 66편'
FULL = """필러시어는 K-pop 팬을 위한 셀럽 사주 + 인터넷소설 앱입니다.

▶ 최애의 사주 · 셀럽 203명
아이유, 뷔(BTS), 제니(BLACKPINK), 카리나(aespa) 등 K-pop 아이돌 203명의 실제 생년월일(위키 검증)을 기반으로 일주(日柱) 차트와 분석을 보여드려요. 최애의 성향, 너와의 케미, 같은 일주 셀럽 끼리 묶어보는 재미까지.

▶ 인터넷소설 전생 66편
한국 웹소설 스타일로 직접 집필한 66편 장편 서사. 너의 사주 일주에 맞춰 "전생에 너는 누구였을까" 를 한 편 한 편 읽는 소설처럼 풀어드려요. 한국어 66편 + 영문 66편 — 총 132편의 오리지널 픽션 컨텐츠.

▶ 음악 처방 (Music Pharmacy)
K-pop·OST 큐레이션. 너의 성향에 맞는 곡을 처방전처럼 알려드려요.

▶ 최애와의 케미 (K-pop Compatibility)
너 vs 아이돌 일주 비교. 같은 점, 다른 점, 케미 점수.

▶ 한국 전통 문화 · 사주 입문
부가 기능으로, 1000년 한국 전통의 사주(四柱) 개념을 십신·오행·격국·용신 등 한국 문화 키워드로 친절히 안내해요. 어려운 한자는 줄이고 일상 언어로.

본 앱은 일반적인 일일 운세 앱이 아닙니다. K-pop 팬덤을 위한 셀럽 데이터 + 오리지널 서사 + 큐레이션 음악 + 한국 문화 입문이 메인 surface 입니다.

수익 모델: 1회 결제 프리미엄 팩 (구독 X). 무료 5 카테고리 + 전생 1편, 프리미엄 12 카테고리 + 전생 66편."""


def main():
    creds = service_account.Credentials.from_service_account_file(KEY, scopes=SCOPES)
    svc = build('androidpublisher', 'v3', credentials=creds, cache_discovery=False)

    # 1) Edit insert
    print(f'[1/5] edit insert ({PKG})…')
    try:
        edit = svc.edits().insert(packageName=PKG, body={}).execute()
    except HttpError as e:
        print(f'❌ edit insert FAIL: {e}')
        print('→ Play Console > 사용자 및 권한 (또는 API 액세스) 에서')
        print(f'  서비스 계정 play-deploy@automakeapp.iam.gserviceaccount.com 에')
        print(f'  Pillarseer 앱 권한 (앱 출시본 만들고 수정 + 스토어 등록정보) 부여 후 재시도')
        sys.exit(1)
    edit_id = edit['id']
    print(f'  edit_id={edit_id}')

    # 2) 이미지 deleteall (idempotent)
    print('[2/5] 기존 이미지 정리 (deleteall)…')
    for t in ('icon', 'featureGraphic', 'phoneScreenshots'):
        try:
            svc.edits().images().deleteall(
                packageName=PKG, editId=edit_id, language=LANG, imageType=t
            ).execute()
            print(f'  {t} cleared')
        except HttpError as e:
            print(f'  {t} cleared (or no prior): {e.resp.status}')

    # 3) 이미지 업로드
    print('[3/5] 이미지 업로드…')
    def upload(image_type, path):
        media = MediaFileUpload(str(path), mimetype='image/png', resumable=True)
        r = svc.edits().images().upload(
            packageName=PKG, editId=edit_id, language=LANG,
            imageType=image_type, media_body=media
        ).execute()
        print(f'  ✅ {image_type} ← {path.name}')
        return r

    upload('icon', ASSETS / 'pillarseer-icon-512.png')
    upload('featureGraphic', ASSETS / 'pillarseer-feature-graphic.png')
    play_dir = ASSETS / 'play_screenshots'
    shots = sorted(play_dir.glob('*.png'))[:8]
    print(f'  phoneScreenshots: {len(shots)} files')
    for p in shots:
        upload('phoneScreenshots', p)

    # 4) 텍스트 listing update
    print('[4/5] listing 텍스트 update…')
    svc.edits().listings().update(
        packageName=PKG, editId=edit_id, language=LANG,
        body={
            'language': LANG,
            'title': TITLE,
            'shortDescription': SHORT,
            'fullDescription': FULL,
        }
    ).execute()
    print(f'  ✅ title/short/full set ({LANG})')

    # 5) commit
    print('[5/5] edit commit…')
    try:
        result = svc.edits().commit(packageName=PKG, editId=edit_id).execute()
        print(f'🎉 committed id={result["id"]}')
        print('Play Console 에 listing 게시됨. 5~30분 후 반영.')
    except HttpError as e:
        print(f'❌ commit FAIL: {e}')
        print('→ 콘텐츠 등급/데이터 안전/타겟 사용자 폼 등 다른 필수 항목 누락일 수 있음')
        print('  Play Console 웹에서 "할 일" 패널 확인')
        sys.exit(1)


if __name__ == '__main__':
    main()

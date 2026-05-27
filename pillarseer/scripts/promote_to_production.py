#!/usr/bin/env python3
"""기존 internal track 의 1.0.0(77) AAB 를 production 트랙으로 promotion. 전 세계 게재."""
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
import os, sys, json

PKG = 'com.seephone.pillarseer'
KEY = os.path.expanduser('~/.googleplay/pillarseer-key.json')
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']

VERSION_CODE = '77'
TARGET_TRACK = os.environ.get('PLAY_TRACK', 'production')  # production | alpha (closed) | open-testing | internal

WHATS_NEW_KO = (
    'K-pop 팬덤 + 인터넷소설 중심으로 첫 출시합니다.\n'
    '• 최애의 사주 — K-pop 아이돌 203명 위키 검증 차트\n'
    '• 인터넷소설 전생 66편 (한국어 + 영문 132편)\n'
    '• 음악 처방 — K-pop·OST 큐레이션\n'
    '• 최애와의 케미 — 너 vs 아이돌 일주 비교\n'
    '• 프리미엄팩 1회 결제 ₩5,900 (구독 X)'
)
WHATS_NEW_EN = (
    'First release — K-pop fandom + original web-novel fiction.\n'
    '• My Favorite\'s Chart — 203 K-pop idols (wiki-verified)\n'
    '• Past-Life Series — 66 web-novel episodes (KO + EN = 132)\n'
    '• Music Pharmacy — curated K-pop/OST prescriptions\n'
    '• K-pop Compatibility — you vs your bias\n'
    '• Premium Pack one-time $4.99 (no subscription)'
)


def main():
    creds = service_account.Credentials.from_service_account_file(KEY, scopes=SCOPES)
    svc = build('androidpublisher', 'v3', credentials=creds, cache_discovery=False)

    print(f'[1/4] edit insert ({PKG})')
    eid = svc.edits().insert(packageName=PKG, body={}).execute()['id']
    print(f'  edit_id={eid}')

    print(f'[2/4] production 트랙에 versionCode {VERSION_CODE} 게재')
    track_body = {
        'releases': [{
            'name': f'1.0.0 ({VERSION_CODE})',
            'versionCodes': [VERSION_CODE],
            'status': 'completed',
            'releaseNotes': [
                {'language': 'ko-KR', 'text': WHATS_NEW_KO},
                {'language': 'en-US', 'text': WHATS_NEW_EN},
            ],
        }]
    }
    try:
        track = svc.edits().tracks().update(
            editId=eid, packageName=PKG, track=TARGET_TRACK, body=track_body
        ).execute()
        print(f'  ✅ track={track["track"]} releases={len(track["releases"])}')
    except HttpError as e:
        print(f'  ❌ {e}')
        sys.exit(1)

    print('[3/4] validate')
    try:
        svc.edits().validate(editId=eid, packageName=PKG).execute()
        print('  ✅ valid')
    except HttpError as e:
        msg = str(e)
        if 'Only releases with status draft' in msg or 'no longer accepting changes' in msg:
            print('  ⚠️ draft 상태로 fallback')
            track_body['releases'][0]['status'] = 'draft'
            svc.edits().tracks().update(
                editId=eid, packageName=PKG, track=TARGET_TRACK, body=track_body
            ).execute()
            svc.edits().validate(editId=eid, packageName=PKG).execute()
            print('  ✅ valid (draft)')
        else:
            print(f'  ❌ {e}')
            sys.exit(1)

    print('[4/4] commit')
    result = svc.edits().commit(packageName=PKG, editId=eid).execute()
    print(f'🎉 commit id={result["id"]}')
    print('Production 게재 완료. Google Play 검토 1~3일.')


if __name__ == '__main__':
    main()

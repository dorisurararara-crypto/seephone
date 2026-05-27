#!/usr/bin/env python3
"""pillarseer Play Console 자동 배포 — aab 업로드 + release notes + 트랙 게재 + commit.

사용:
    python3 scripts/deploy_play.py --aab ~/Downloads/pillarseer-1.0.0-77.aab --track internal
    python3 scripts/deploy_play.py --aab <path> --track production

전제: ~/.googleplay/pillarseer-key.json 에 service account JSON 존재 +
Play Console 에서 해당 service account 에 "앱 출시본 만들고 수정" + "트랙에 출시본 게재" 권한 부여 완료.
"""
import argparse
import json
import os
import sys
from pathlib import Path

from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.oauth2 import service_account

PACKAGE_NAME = 'com.seephone.pillarseer'
KEY_PATH = os.path.expanduser('~/.googleplay/pillarseer-key.json')
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']

WHATS_NEW_KO = (
    'K-pop 팬덤·서사 중심으로 첫 출시합니다.\n'
    '• 최애의 사주 — K-pop 아이돌 203명 위키 검증 차트\n'
    '• 인터넷소설 전생 66편 (한국어 + 영문 132편)\n'
    '• 음악 처방 — 너의 성향에 맞는 K-pop·OST 큐레이션\n'
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
    ap = argparse.ArgumentParser()
    ap.add_argument('--aab', required=True, help='경로: aab 파일')
    ap.add_argument('--track', default='production',
                    choices=['internal', 'alpha', 'beta', 'production'])
    ap.add_argument('--status', default='completed',
                    choices=['draft', 'inProgress', 'halted', 'completed'])
    args = ap.parse_args()

    aab_path = Path(args.aab).expanduser()
    if not aab_path.exists():
        sys.exit(f'❌ aab not found: {aab_path}')

    creds = service_account.Credentials.from_service_account_file(
        KEY_PATH, scopes=SCOPES)
    service = build('androidpublisher', 'v3', credentials=creds, cache_discovery=False)

    # 1. edit 시작
    print(f'[1/5] edit 시작 (package={PACKAGE_NAME})...')
    edit = service.edits().insert(packageName=PACKAGE_NAME, body={}).execute()
    edit_id = edit['id']
    print(f'  ✅ edit_id={edit_id}')

    # 2. aab 업로드
    print(f'[2/5] aab 업로드: {aab_path.name} ({aab_path.stat().st_size // 1024 // 1024} MB)...')
    media = MediaFileUpload(str(aab_path),
                            mimetype='application/octet-stream',
                            resumable=True)
    bundle = service.edits().bundles().upload(
        editId=edit_id,
        packageName=PACKAGE_NAME,
        media_body=media).execute()
    version_code = bundle['versionCode']
    print(f'  ✅ versionCode={version_code} sha1={bundle.get("sha1", "")[:16]}...')

    # 3. 트랙에 release 추가 + release notes
    print(f'[3/5] track={args.track} 에 release 등록...')
    track_body = {
        'releases': [{
            'name': f'1.0.0 ({version_code})',
            'versionCodes': [str(version_code)],
            'status': args.status,
            'releaseNotes': [
                {'language': 'ko-KR', 'text': WHATS_NEW_KO},
                {'language': 'en-US', 'text': WHATS_NEW_EN},
            ],
        }]
    }
    track = service.edits().tracks().update(
        editId=edit_id,
        packageName=PACKAGE_NAME,
        track=args.track,
        body=track_body).execute()
    print(f'  ✅ track={track["track"]} releases={len(track["releases"])}')

    # 4. validate — draft app 일 때 completed release 면 자동 fallback
    print('[4/5] edit 검증...')
    try:
        service.edits().validate(
            editId=edit_id, packageName=PACKAGE_NAME).execute()
        print('  ✅ valid')
    except Exception as e:
        if 'Only releases with status draft' in str(e):
            print('  ⚠️ 앱이 draft 상태 → release status를 draft 으로 재설정')
            track_body['releases'][0]['status'] = 'draft'
            service.edits().tracks().update(
                editId=edit_id,
                packageName=PACKAGE_NAME,
                track=args.track,
                body=track_body).execute()
            service.edits().validate(
                editId=edit_id, packageName=PACKAGE_NAME).execute()
            print('  ✅ valid (draft release)')
        else:
            raise

    # 5. commit
    print('[5/5] edit commit (실제 게재)...')
    result = service.edits().commit(
        editId=edit_id, packageName=PACKAGE_NAME).execute()
    print(f'  ✅ committed id={result["id"]}')

    print('')
    print(f'🎉 Play Console {args.track} 트랙 게재 완료. Google Play 검토 1~3일.')


if __name__ == '__main__':
    main()

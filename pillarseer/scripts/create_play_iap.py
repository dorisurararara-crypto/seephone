#!/usr/bin/env python3
"""pillarseer Play Console IAP 생성 — iOS 와 동일한 Premium Pack ₩5,900 / $4.99 non-consumable.

iOS productId = com.ganziman.pillarseer.premium_pack 와 동일 (code 호환).
"""
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
import os, sys, json

PKG = 'com.seephone.pillarseer'
KEY = os.path.expanduser('~/.googleplay/pillarseer-key.json')
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']

# iOS 와 동일 product ID
SKU = 'com.ganziman.pillarseer.premium_pack'

# 가격: iOS App Store 기준 $4.99 / ₩5,900
# Google Play 는 micros 단위 (5900000 = ₩5,900)
PRICES = {
    'KR': {'currency': 'KRW', 'priceMicros': '5900000000'},  # ₩5,900
    'US': {'currency': 'USD', 'priceMicros': '4990000'},      # $4.99
}


def main():
    creds = service_account.Credentials.from_service_account_file(KEY, scopes=SCOPES)
    svc = build('androidpublisher', 'v3', credentials=creds, cache_discovery=False)

    body = {
        'packageName': PKG,
        'sku': SKU,
        'status': 'active',
        'purchaseType': 'managedUser',   # non-consumable equivalent
        'defaultPrice': {
            'currency': 'USD',
            'priceMicros': '4990000',
        },
        'listings': {
            'ko-KR': {
                'title': '프리미엄팩',
                'description': '필러시어 프리미엄 — 내 사주 17카테고리 풀버전 + 전생 66편 + 신년 12개월 + 궁합 심화 + 자미두수 상세. 1회 결제, 구독 X.',
            },
            'en-US': {
                'title': 'Premium Pack',
                'description': 'Pillarseer Premium — unlock all 17 Saju categories, 66 past-life stories, full 12-month outlook, deeper compatibility, and Zi Wei details. One-time purchase, no subscription.',
            },
        },
        'prices': {
            'KR': {'currency': 'KRW', 'priceMicros': '5900000000'},
            'US': {'currency': 'USD', 'priceMicros': '4990000'},
        },
        'defaultLanguage': 'ko-KR',
    }

    try:
        # 우선 GET 으로 존재 여부 확인
        try:
            existing = svc.inappproducts().get(packageName=PKG, sku=SKU).execute()
            print(f'기존 IAP 발견 — PATCH 로 업데이트')
            r = svc.inappproducts().update(packageName=PKG, sku=SKU, body=body).execute()
        except HttpError as e:
            if e.resp.status == 404:
                print(f'IAP 신규 생성 (sku={SKU})')
                r = svc.inappproducts().insert(packageName=PKG, body=body).execute()
            else:
                raise

        print(f"✅ status={r.get('status')}  sku={r.get('sku')}")
        print(f"   defaultPrice={r.get('defaultPrice')}")
        print(f"   prices={list((r.get('prices') or {}).keys())}")
        print(f"   listings={list((r.get('listings') or {}).keys())}")
    except HttpError as e:
        print(f'❌ HTTP {e.resp.status}: {e._get_reason()}')
        try:
            err = json.loads(e.content)
            print(json.dumps(err, indent=2, ensure_ascii=False))
        except:
            print(e.content)
        sys.exit(1)


if __name__ == '__main__':
    main()

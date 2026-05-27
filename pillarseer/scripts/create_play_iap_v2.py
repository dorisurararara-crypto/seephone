#!/usr/bin/env python3
"""pillarseer Play Console IAP — 신규 monetization.onetimeproducts API.

iOS productId 와 동일 com.ganziman.pillarseer.premium_pack.
"""
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
import os, sys, json

PKG = 'com.seephone.pillarseer'
KEY = os.path.expanduser('~/.googleplay/pillarseer-key.json')
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']

SKU = 'com.ganziman.pillarseer.premium_pack'


def main():
    creds = service_account.Credentials.from_service_account_file(KEY, scopes=SCOPES)
    svc = build('androidpublisher', 'v3', credentials=creds, cache_discovery=False)

    # 신규 OneTimeProduct API 본문
    body = {
        'packageName': PKG,
        'productId': SKU,
        'listings': [
            {
                'languageCode': 'ko-KR',
                'title': '프리미엄팩',
                'description': '필러시어 프리미엄 — 내 사주 17카테고리 풀버전 + 전생 66편 + 신년 12개월 + 궁합 심화 + 자미두수 상세. 1회 결제, 구독 X.',
            },
            {
                'languageCode': 'en-US',
                'title': 'Premium Pack',
                'description': 'Pillarseer Premium — unlock all 17 Saju categories, 66 past-life stories, full 12-month outlook, deeper compatibility, and Zi Wei details. One-time purchase, no subscription.',
            },
        ],
        'taxAndComplianceSettings': {
            'eeaWithdrawalRightType': 'WITHDRAWAL_RIGHT_DIGITAL_CONTENT',
        },
        'purchaseOptions': [
            {
                'state': 'ACTIVE',
                'newRegionsConfig': {
                    'newRegionsPrice': {
                        'currencyCode': 'USD',
                        'units': '4',
                        'nanos': 990000000,
                    },
                    'availability': 'AVAILABLE',
                },
                'buyOption': {
                    'legacyCompatible': True,
                    'multiQuantityEnabled': False,
                },
                'regionalPricingAndAvailabilityConfigs': [
                    {
                        'regionCode': 'KR',
                        'price': { 'currencyCode': 'KRW', 'units': '5900', 'nanos': 0 },
                        'availability': 'AVAILABLE',
                    },
                    {
                        'regionCode': 'US',
                        'price': { 'currencyCode': 'USD', 'units': '4', 'nanos': 990000000 },
                        'availability': 'AVAILABLE',
                    },
                ],
            },
        ],
    }

    try:
        # 신규 endpoint: monetization.onetimeproducts.create
        try:
            existing = svc.monetization().onetimeproducts().get(
                packageName=PKG, productId=SKU).execute()
            print(f'기존 IAP 발견 — patch')
            r = svc.monetization().onetimeproducts().patch(
                packageName=PKG, productId=SKU, body=body,
                updateMask='listings,purchaseOptions,taxAndComplianceSettings'
            ).execute()
        except HttpError as e:
            if e.resp.status == 404:
                print(f'IAP 신규 생성 (productId={SKU})')
                r = svc.monetization().onetimeproducts().create(
                    packageName=PKG, productId=SKU, body=body).execute()
            else:
                raise

        print(f"✅ productId={r.get('productId')}")
        print(json.dumps(r, indent=2, ensure_ascii=False)[:1500])
    except HttpError as e:
        print(f'❌ HTTP {e.resp.status}')
        print(e.content.decode() if isinstance(e.content, bytes) else e.content)
        sys.exit(1)
    except AttributeError as e:
        print(f'⚠️ monetization.onetimeproducts API 미가용 — googleapiclient discovery 갱신 필요')
        print(f'직접 REST 호출 fallback')
        # Fallback: 직접 REST 호출
        import json as j
        import requests
        token = creds.token or _refresh(creds)
        url = f'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PKG}/onetimeproducts/{SKU}'
        headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}
        # 우선 GET
        rg = requests.get(url, headers=headers)
        if rg.status_code == 404:
            # CREATE
            r2 = requests.post(
                f'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PKG}/onetimeproducts?productId={SKU}',
                headers=headers,
                data=j.dumps(body)
            )
            print(f'CREATE HTTP {r2.status_code}: {r2.text[:1500]}')
        else:
            print(f'GET HTTP {rg.status_code}: {rg.text[:500]}')


def _refresh(creds):
    from google.auth.transport.requests import Request
    creds.refresh(Request())
    return creds.token


if __name__ == '__main__':
    main()

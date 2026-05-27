#!/usr/bin/env python3
"""pillarseer Play Console IAP — 정확한 monetization.onetimeproducts REST endpoint.

URL: PATCH applications/{pkg}/monetization/onetimeproducts/{productId}?allowMissing=true&regionsVersion.version=2022/02
"""
import os, sys, json, requests, urllib.parse
from google.oauth2 import service_account
from google.auth.transport.requests import Request

PKG = 'com.seephone.pillarseer'
KEY = os.path.expanduser('~/.googleplay/pillarseer-key.json')
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']

# iOS 와 동일 productId
SKU = 'com.ganziman.pillarseer.premium_pack'

BODY = {
    'packageName': PKG,
    'productId': SKU,
    'listings': [
        {
            'languageCode': 'ko-KR',
            'title': '프리미엄팩',
            'description': '필러시어 프리미엄 — 내 사주 17카테고리 + 전생 66편 + 신년 12개월 + 궁합 심화 + 자미두수 상세. 1회 결제, 구독 X.',
        },
        {
            'languageCode': 'en-US',
            'title': 'Premium Pack',
            'description': 'Pillarseer Premium — unlock all 17 Saju categories, 66 past-life stories, full 12-month outlook, deeper compatibility, and Zi Wei details. One-time purchase, no subscription.',
        },
    ],
    'taxAndComplianceSettings': {
        'isTokenizedDigitalAsset': False,
    },
    'purchaseOptions': [
        {
            'purchaseOptionId': 'premium-pack-buy',
            'state': 'ACTIVE',
            'buyOption': {
                'legacyCompatible': True,
                'multiQuantityEnabled': False,
            },
            # 한국 + 미국 명시 가격 + newRegionsConfig 로 전 세계 USD 4.99 환산
            'regionalPricingAndAvailabilityConfigs': [
                { 'regionCode': 'KR', 'price': { 'currencyCode': 'KRW', 'units': '5900', 'nanos': 0 }, 'availability': 'AVAILABLE' },
                { 'regionCode': 'US', 'price': { 'currencyCode': 'USD', 'units': '4',    'nanos': 990000000 }, 'availability': 'AVAILABLE' },
            ],
            'newRegionsConfig': {
                'usdPrice': { 'currencyCode': 'USD', 'units': '4', 'nanos': 990000000 },
                'eurPrice': { 'currencyCode': 'EUR', 'units': '4', 'nanos': 490000000 },
                'availability': 'AVAILABLE',
            },
        },
    ],
}


def get_token():
    creds = service_account.Credentials.from_service_account_file(KEY, scopes=SCOPES)
    creds.refresh(Request())
    return creds.token


def main():
    token = get_token()
    product_id_enc = urllib.parse.quote(SKU, safe='')
    url = (
        f'https://androidpublisher.googleapis.com/androidpublisher/v3/'
        f'applications/{PKG}/onetimeproducts/{product_id_enc}'
        f'?allowMissing=true&regionsVersion.version=2022%2F02'
        f'&updateMask=listings,taxAndComplianceSettings,purchaseOptions'
    )
    print(f'PATCH {url[:120]}…')
    r = requests.patch(
        url,
        headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'},
        data=json.dumps(BODY),
    )
    print(f'HTTP {r.status_code}')
    if r.status_code >= 400:
        print(r.text[:2000])
        sys.exit(1)
    data = r.json()
    print(f"✅ productId={data.get('productId')}")
    print(f"   purchaseOptions={[po.get('purchaseOptionId') + ':' + po.get('state', '?') for po in data.get('purchaseOptions', [])]}")
    print(f"   listings={[l['languageCode'] for l in data.get('listings', [])]}")
    print(json.dumps(data, indent=2, ensure_ascii=False)[:1500])


if __name__ == '__main__':
    main()

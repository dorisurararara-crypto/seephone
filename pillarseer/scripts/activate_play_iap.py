#!/usr/bin/env python3
"""IAP purchase option 활성화 (DRAFT → ACTIVE)."""
import os, sys, json, requests, urllib.parse
from google.oauth2 import service_account
from google.auth.transport.requests import Request

PKG = 'com.seephone.pillarseer'
KEY = os.path.expanduser('~/.googleplay/pillarseer-key.json')
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']

SKU = 'com.ganziman.pillarseer.premium_pack'
OPT_ID = 'premium-pack-buy'


def main():
    creds = service_account.Credentials.from_service_account_file(KEY, scopes=SCOPES)
    creds.refresh(Request())
    token = creds.token

    product_id_enc = urllib.parse.quote(SKU, safe='')
    url = (
        f'https://androidpublisher.googleapis.com/androidpublisher/v3/'
        f'applications/{PKG}/oneTimeProducts/{product_id_enc}/purchaseOptions:batchUpdateStates'
    )
    body = {
        'requests': [
            {
                'activatePurchaseOptionRequest': {
                    'packageName': PKG,
                    'productId': SKU,
                    'purchaseOptionId': OPT_ID,
                },
            }
        ]
    }
    print(f'POST {url[:120]}…')
    r = requests.post(url,
        headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'},
        data=json.dumps(body))
    print(f'HTTP {r.status_code}')
    if r.status_code >= 400:
        print(r.text[:2000])
        sys.exit(1)
    print(json.dumps(r.json(), indent=2, ensure_ascii=False)[:1500])


if __name__ == '__main__':
    main()

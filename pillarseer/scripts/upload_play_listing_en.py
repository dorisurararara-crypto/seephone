#!/usr/bin/env python3
"""pillarseer Play Console listing — en-US 추가 (ko-KR 본문은 별도 스크립트로 이미 commit 완료).

같은 이미지 7장 재사용 (글로벌 — Play Console 은 locale 별 이미지 따로 업로드 가능하나
첫 출시는 동일 이미지로 ko + en 둘 다 OK).
"""
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from pathlib import Path
import os, sys

PKG = 'com.seephone.pillarseer'
LANG = 'en-US'
KEY = os.path.expanduser('~/.googleplay/pillarseer-key.json')
ASSETS = Path('/Users/seunghyeon/seephone/pillarseer/.playwright-mcp')
SCOPES = ['https://www.googleapis.com/auth/androidpublisher']

TITLE = 'Pillarseer - K-pop Charts'
SHORT = '203 K-pop idol charts + 66 past-life web-novel episodes'
FULL = """Pillarseer is a K-pop fandom app — original celebrity charts, hand-written fiction, and curated music — built around a Korean cultural framework.

▶ My Favorite's Chart · 203 K-pop Idols
IU, V (BTS), Jennie (BLACKPINK), Karina (aespa), and 199 more. Each idol's publicly known birth date is sourced from Korean Wikipedia and mapped to a traditional Korean day-pillar chart. Read your favorite's personality, compare chemistry with yours, and discover idols who share your pillar.

▶ Past-Life Series · 66 Original Web-Novel Episodes
66 hand-written longform episodes in the format of Korean web fiction. Tied to your day pillar, each episode tells you who you might have been in a past life — like reading a novel, one chapter at a time. 66 Korean episodes + 66 English episodes — 132 original fiction stories.

▶ Music Pharmacy — Personalized Song Prescriptions
Curated K-pop and OST songs matched to your personality profile.

▶ K-pop Compatibility — You vs Your Bias
Compare day pillars with K-pop idols. Where you align, where you differ, chemistry score.

▶ Korean Cultural Framework
A 1,000-year-old Korean personality system (Saju / Four Pillars) explained in plain language — Ten Gods, Five Elements, structure charts — without the kanji wall.

This is not a daily horoscope app. The main surfaces are K-pop celebrity content, original web-novel fiction, music curation, and a Korean cultural framework explainer.

Monetization: one-time premium pack (no subscription). Free tier includes 5 categories + 1 past-life episode; premium unlocks 12 categories + all 66 episodes."""


def main():
    creds = service_account.Credentials.from_service_account_file(KEY, scopes=SCOPES)
    svc = build('androidpublisher', 'v3', credentials=creds, cache_discovery=False)

    eid = svc.edits().insert(packageName=PKG, body={}).execute()['id']
    print(f'edit_id={eid}')

    for t in ('icon', 'featureGraphic', 'phoneScreenshots'):
        svc.edits().images().deleteall(
            packageName=PKG, editId=eid, language=LANG, imageType=t
        ).execute()

    def up(t, p):
        media = MediaFileUpload(str(p), mimetype='image/png', resumable=True)
        svc.edits().images().upload(
            packageName=PKG, editId=eid, language=LANG,
            imageType=t, media_body=media
        ).execute()
        print(f'  ✅ {t} ← {p.name}')

    up('icon', ASSETS / 'pillarseer-icon-512.png')
    up('featureGraphic', ASSETS / 'pillarseer-feature-graphic.png')
    for p in sorted((ASSETS / 'play_screenshots').glob('*.png'))[:8]:
        up('phoneScreenshots', p)

    svc.edits().listings().update(
        packageName=PKG, editId=eid, language=LANG,
        body={'language': LANG, 'title': TITLE, 'shortDescription': SHORT, 'fullDescription': FULL}
    ).execute()
    print(f'  ✅ {LANG} text set')

    result = svc.edits().commit(packageName=PKG, editId=eid).execute()
    print(f'🎉 en-US commit {result["id"]}')


if __name__ == '__main__':
    main()

import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'app.dart';
import 'services/today_event_service.dart';
import 'services/today_v5_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // R87 sprint 3 — 해외 출생지 IANA tz DST 지원. manseryeok_service 가
  // 사주 계산 중 tz.getLocation() 호출하므로 사주 첫 계산 전에 init 보장.
  // notification_service 도 별도 init 하지만 idempotent.
  try {
    tzdata.initializeTimeZones();
  } catch (_) {}
  // Round 77 sprint 2 — today_event_pool.json (90 entries) 1회 로드.
  // 실패해도 silent (TodayEventService 내부 try/catch). home/result 의 ko 본문이
  // pool entry 를 우선 사용, 미스 시 6분기 fallback.
  await TodayEventService.ensurePoolLoaded();
  // Round 106 P2a — 오늘의 사주 v5 fragment pool 1회 로드. 실패해도 silent
  // (TodayV5Service 내부 try/catch + 내장 fallback 카피).
  await TodayV5Service.ensurePoolLoaded();
  runApp(const PillarSeerApp());
}

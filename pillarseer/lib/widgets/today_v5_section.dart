// Pillar Seer — Round 106 (P2a) — 오늘의 사주 v5 섹션 위젯.
//
// design doc §2/§3/§4/§7 — 헤드라인 + 근거 3칩 + 「구조/발동조건/행동」 + 자기검증.
// 화면 mount 시 RecallFeedbackService.recordShown 호출, 자기검증 버튼 tap →
// recordFeedback 호출. 계산 엔진·selector·feedback 코어는 호출만 (수정 0).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/recall_feedback_service.dart';
import '../services/today_v5_service.dart';
import '../theme/app_theme.dart';

/// 오늘의 사주 v5 — home/today 공용 primary 섹션.
class TodayV5Section extends StatefulWidget {
  final TodayV5Reading reading;

  /// 노출·자기검증 기록 기준 날짜. 테스트에서 고정 주입 가능.
  final DateTime date;

  const TodayV5Section({
    super.key,
    required this.reading,
    required this.date,
  });

  @override
  State<TodayV5Section> createState() => _TodayV5SectionState();
}

class _TodayV5SectionState extends State<TodayV5Section> {
  RecallVerdict? _verdict;
  bool _submitting = false;

  // R106 P2a-fix #5 — 자기검증은 *어제 본 풀이* 에 기록한다.
  // mount 시 RecallFeedbackService.lastReading() 으로 직전 노출 풀이를 읽어두고,
  // 그 topic+date 가 오늘보다 이전이면 자기검증 카드를 띄운다. 없으면 카드 숨김.
  ({String topicId, DateTime date})? _recallTarget;
  bool _recallResolved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initRecall());
  }

  /// 어제 풀이 anchor 확정 → 오늘 풀이 노출 기록 순서로 진행.
  /// 순서 중요: recordShown 이 "마지막 노출 풀이" 슬롯을 오늘 값으로 덮어쓰므로,
  /// 반드시 lastReading() 을 먼저 읽은 뒤에 recordShown 을 호출한다.
  Future<void> _initRecall() async {
    final today = _dateOnly(widget.date);
    final last = await RecallFeedbackService.lastReading();
    if (mounted) {
      setState(() {
        // 어제(또는 그 이전) 노출 풀이가 있어야 자기검증 대상이 된다.
        // 오늘 이미 본 풀이(같은 날)는 "어제 풀이" 가 아니므로 제외.
        if (last != null && _dateOnly(last.date).isBefore(today)) {
          _recallTarget = (topicId: last.topic, date: last.date);
        }
        _recallResolved = true;
      });
    }
    // design doc §4-E — 오늘 주제가 화면에 표시되면 노출 기록 (selector freshness
    // 반영). 동시에 "마지막 노출 풀이" 슬롯이 오늘 값으로 갱신돼, 내일 자기검증의
    // 어제 anchor 가 된다.
    final topicId = widget.reading.topicId;
    if (topicId != null) {
      await RecallFeedbackService.recordShown(topicId, widget.date);
    }
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _onVerdict(RecallVerdict v) async {
    final target = _recallTarget;
    if (target == null || _submitting) return;
    setState(() => _submitting = true);
    // design doc §4-D / §7 — 자기검증 응답 → *어제 본 풀이의* 주제 점수에 반영.
    // feedback date 는 어제 노출일 기준 (그 풀이가 노출된 날).
    await RecallFeedbackService.recordFeedback(
      target.topicId,
      v,
      date: target.date,
    );
    if (!mounted) return;
    setState(() {
      _verdict = v;
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reading;
    // R107 today_v5_en — locale 분기. 다른 화면과 동일 패턴.
    final useKo =
        (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'ko';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── section meta + 주제 칩 ──
          Row(
            children: [
              Text(
                useKo ? '오늘의 사주' : TodayV5Service.sectionTitleEn,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.taupe,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 1),
                ),
                child: Text(
                  r.isFallback
                      ? r.topicLabel
                      : (useKo
                          ? '오늘의 주제 · ${r.topicLabel}'
                          : '${TodayV5Service.topicPrefixEn} · ${r.topicLabel}'),
                  style: GoogleFonts.notoSansKr(
                    fontSize: 10,
                    letterSpacing: 0.2,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // ── 헤드라인 ──
          Text(
            r.headline,
            style: GoogleFonts.notoSerifKr(
              fontSize: 21,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
          // ── 근거 3칩 ──
          if (r.evidenceChips.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              useKo ? '왜 이 주제냐면' : TodayV5Service.chipHeaderEn,
              style: GoogleFonts.notoSansKr(
                fontSize: 11,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w500,
                color: AppColors.taupe,
              ),
            ),
            const SizedBox(height: 10),
            ...r.evidenceChips.map(_buildChip),
          ],
          const SizedBox(height: 14),
          Container(width: 36, height: 1, color: AppColors.line),
          const SizedBox(height: 16),
          // ── 본문 「구조 / 발동조건 / 행동」 ──
          _buildBodyBlock(
              useKo ? '흐름' : TodayV5Service.bodyLabelFlowEn, r.structureLine),
          if (r.triggerLine.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildBodyBlock(
                useKo ? '이런 순간이 오면' : TodayV5Service.bodyLabelTriggerEn,
                r.triggerLine),
          ],
          if (r.actionLine.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildBodyBlock(
                useKo ? '오늘 이렇게' : TodayV5Service.bodyLabelActionEn,
                r.actionLine),
          ],
          // ── 자기검증 (design doc §7) — *어제 본 풀이* 가 있을 때만 노출.
          // 어제 기록이 없으면 (첫 실행·하루 건너뜀) 카드 자체를 숨긴다.
          // R106 P2a-fix #5: 오늘 풀이가 아니라 어제 풀이를 체크하는 카드.
          if (_recallResolved && _recallTarget != null) ...[
            const SizedBox(height: 26),
            _buildRecallBlock(useKo),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(TodayV5EvidenceChip chip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 10),
            child: Container(width: 4, height: 4, color: AppColors.accent),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chip.label,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.taupe,
                    height: 1.5,
                  ),
                ),
                Text(
                  chip.text,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: AppColors.inkLight,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyBlock(String label, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w500,
            color: AppColors.taupe,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            color: AppColors.ink,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _buildRecallBlock(bool useKo) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line, width: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            useKo
                ? TodayV5Service.recallTitleKo
                : TodayV5Service.recallTitleEn,
            style: GoogleFonts.notoSansKr(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            useKo ? TodayV5Service.recallDescKo : TodayV5Service.recallDescEn,
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              color: AppColors.inkLight,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          if (_verdict == null)
            Row(
              children: [
                _buildVerdictButton(
                    RecallVerdict.correct,
                    useKo
                        ? TodayV5Service.recallCorrectKo
                        : TodayV5Service.recallCorrectEn),
                const SizedBox(width: 8),
                _buildVerdictButton(
                    RecallVerdict.unsure,
                    useKo
                        ? TodayV5Service.recallUnsureKo
                        : TodayV5Service.recallUnsureEn),
                const SizedBox(width: 8),
                _buildVerdictButton(
                    RecallVerdict.wrong,
                    useKo
                        ? TodayV5Service.recallWrongKo
                        : TodayV5Service.recallWrongEn),
              ],
            )
          else
            Text(
              useKo
                  ? '체크 고마워요. 다음 풀이가 당신 관심사에 더 가까워질 거예요.'
                  : TodayV5Service.recallDoneEn,
              style: GoogleFonts.notoSansKr(
                fontSize: 12.5,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerdictButton(RecallVerdict v, String label) {
    return Expanded(
      child: InkWell(
        onTap: _submitting ? null : () => _onVerdict(v),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line, width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

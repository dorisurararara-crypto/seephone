import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('질문을 적어주세요')),
      );
      return;
    }
    context.push('/scan?q=${Uri.encodeComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '동공 지진\n탐지기',
                style: GoogleFonts.notoSansKr(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -1.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '카메라로 친구 눈동자 떨림을 측정. 거짓말이면 진도 폭발.',
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: Colors.white60,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                'QUESTION',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 2,
                style: GoogleFonts.notoSansKr(fontSize: 17, color: Colors.white),
                decoration: InputDecoration(
                  hintText: '예: 너 어제 몰래 치킨 먹었지?',
                  hintStyle: GoogleFonts.notoSansKr(color: Colors.white38),
                  border: const UnderlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _start,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: const Color(0xFFFF3D5A),
                ),
                child: Text(
                  '카메라 켜고 스캔 시작',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '※ 친구 얼굴이 화면 중앙에 오게 들고, 질문하고, 답할 때 3초 스캔합니다',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansKr(
                  fontSize: 11,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

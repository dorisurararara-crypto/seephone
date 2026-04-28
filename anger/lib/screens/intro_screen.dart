import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '분노',
                style: GoogleFonts.blackHanSans(
                  fontSize: 96,
                  color: const Color(0xFFFFB800),
                  height: 0.95,
                  letterSpacing: -3,
                ),
              ),
              Text(
                '발전소',
                style: GoogleFonts.blackHanSans(
                  fontSize: 96,
                  color: Colors.white,
                  height: 0.95,
                  letterSpacing: -3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '폰을 미친 듯이 흔들고 화면을 두드려라.\n10초간 측정해서 빡침을 W(와트)로 환산.',
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: Colors.white60,
                  height: 1.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.amber, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '폰을 꽉 잡으세요. 떨어트리면 본인 책임.\n가능하면 손목 스트랩 권장.',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 12,
                          color: Colors.amber.shade100,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push('/measure'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                ),
                child: Text(
                  '10초 분노 방출',
                  style: GoogleFonts.blackHanSans(fontSize: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

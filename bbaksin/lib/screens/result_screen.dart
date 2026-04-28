import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/message_repo.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final String question;
  const ResultScreen({super.key, required this.question});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late final Message _message;

  @override
  void initState() {
    super.initState();
    _message = ref.read(messageRepoProvider).pickFor(widget.question);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: 디자인 변종 선택 후 부적 위젯 styling 입힘.
    // TODO: screenshot 패키지로 부적 영역만 캡처 → gal로 갤러리 저장 → share_plus로 공유.
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8102E),
                    border: Border.all(color: const Color(0xFFF4D35E), width: 8),
                  ),
                  child: Center(
                    child: Text(
                      _message.text,
                      style: const TextStyle(
                        color: Color(0xFFF4E4BC),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: gal.putImage()
                      },
                      child: const Text('저장'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        // TODO: SharePlus.instance.share()
                      },
                      child: const Text('공유'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('처음으로'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

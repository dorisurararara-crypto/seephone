import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToRitual() {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    context.push('/ritual?q=${Uri.encodeComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    // TODO: 디자인 변종 선택 후 styling 입힘.
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('빡神',
                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('디지털 점집 · 매운맛 부적',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              const Spacer(),
              const Text('— 고민을 적으시오 —',
                  style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '예: 전 남친한테 카톡할까?',
                  border: OutlineInputBorder(),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _goToRitual,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text('폰을 흔들어 점치기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              const Text('위아래로 3번 흔드시오',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

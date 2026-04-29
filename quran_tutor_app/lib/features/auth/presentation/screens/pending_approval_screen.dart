import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_tutor_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:quran_tutor_app/features/auth/presentation/bloc/auth_event.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  Timer? _refreshTimer;
  DateTime _lastChecked = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Auto-refresh user status every 30 seconds.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshNow(),
    );
  }

  void _refreshNow() {
    if (!mounted) return;
    context.read<AuthBloc>().add(const RefreshUserRequested());
    setState(() => _lastChecked = DateTime.now());
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                'طلبك قيد المراجعة',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Text('سيتم إشعارك عند الموافقة على طلبك'),
              const SizedBox(height: 8),
              Text(
                'آخر تحقق: ${_formatTime(_lastChecked)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _refreshNow,
                icon: const Icon(Icons.refresh),
                label: const Text('تحقق الآن'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const SignOutRequested());
                },
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

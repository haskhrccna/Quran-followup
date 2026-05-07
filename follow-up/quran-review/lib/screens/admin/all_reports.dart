import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../services/report_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common_widgets.dart';

class AllReports extends ConsumerWidget {
  const AllReports({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reportService = ReportService(ref.read(supabaseProvider));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allReports),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
      ),
      body: FutureBuilder(
        future: reportService.getAllReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const AppLoading();
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) return AppEmptyState(icon: Icons.description_outlined, title: l10n.noReports);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return AppCard(
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.picture_as_pdf, color: Colors.red)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(report.title, style: Theme.of(context).textTheme.titleSmall),
                          Text('${report.teacher?.fullName ?? ''} - ${report.student?.fullName ?? ''}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text('${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
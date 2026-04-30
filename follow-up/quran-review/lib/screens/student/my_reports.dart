import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../providers/auth_provider.dart';
import '../../services/report_service.dart';
import '../../widgets/common/common_widgets.dart';

class MyReports extends ConsumerWidget {
  const MyReports({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);

    if (user == null) return const Scaffold(body: AppLoading());

    final reportService = ReportService(ref.read(supabaseProvider));
    final reportsAsync = ref.watch(_reportsProvider(reportService, user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reports),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/student/dashboard')),
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return AppEmptyState(
              icon: Icons.description_outlined,
              title: l10n.noReports,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return AppCard(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: SfPdfViewer.network(report.pdfUrl),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(report.title, style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(
                              '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.visibility),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

final _reportsProvider = FutureProvider.family(List, ReportService) async {
  return [];
};
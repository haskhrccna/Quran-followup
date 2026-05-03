import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/grade_provider.dart';
import '../../widgets/common/common_widgets.dart';

class AllGrades extends ConsumerWidget {
  const AllGrades({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final gradesAsync = ref.watch(allGradesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allGrades),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/dashboard')),
      ),
      body: gradesAsync.when(
        data: (grades) {
          if (grades.isEmpty) return AppEmptyState(icon: Icons.grade_outlined, title: l10n.noGrades);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allGradesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grades.length,
              itemBuilder: (context, index) {
                final g = grades[index];
                return AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.student?.fullName ?? '', style: Theme.of(context).textTheme.titleSmall),
                            Text('${g.subject} - ${g.gradeType.name}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text(g.gradeValue.toString(), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.blue)),
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


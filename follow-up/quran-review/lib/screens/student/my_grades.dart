import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grade_provider.dart';
import '../../widgets/common/common_widgets.dart';
import '../../config/app_config.dart';

class MyGrades extends ConsumerWidget {
  const MyGrades({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);

    if (user == null) return const Scaffold(body: AppLoading());

    final gradesAsync = ref.watch(studentGradesProvider(user.id));
    final averageAsync = ref.watch(studentAverageGradeProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myGrades),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/student/dashboard')),
      ),
      body: Column(
        children: [
          averageAsync.when(
            data: (avg) => avg > 0
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: AppTheme.primaryColor,
                    child: Column(
                      children: [
                        Text(l10n.averageGrade, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(
                          avg.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: gradesAsync.when(
              data: (grades) {
                if (grades.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.grade_outlined,
                    title: l10n.noGrades,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(studentGradesProvider(user.id)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: grades.length,
                    itemBuilder: (context, index) {
                      final grade = grades[index];
                      return AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(grade.subject, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getGradeTypeText(grade.gradeType, l10n),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _getGradeColor(grade.gradeValue).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                grade.gradeValue.toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _getGradeColor(grade.gradeValue),
                                ),
                              ),
                            ),
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
          ),
        ],
      ),
    );
  }

  String _getGradeTypeText(dynamic type, AppLocalizations l10n) {
    final typeName = type.toString().split('.').last;
    switch (typeName) {
      case 'exam':
        return l10n.exam;
      case 'quiz':
        return l10n.quiz;
      case 'assignment':
        return l10n.assignment;
      case 'project':
        return l10n.project;
      case 'finalExam':
        return l10n.final;
      default:
        return typeName;
    }
  }

  Color _getGradeColor(double value) {
    if (value >= 90) return AppTheme.successColor;
    if (value >= 75) return AppTheme.primaryColor;
    if (value >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
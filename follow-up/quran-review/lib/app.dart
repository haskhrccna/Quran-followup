import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'config/app_config.dart';

class MyApp extends ConsumerWidget {
  final Locale locale;

  const MyApp({super.key, required this.locale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Quran Review',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final authState = ref.read(authStateProvider);
    authState.whenData((user) {
      ref.read(currentUserProvider.notifier).state = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(currentUserProvider.notifier).state = user;
          });
        }
        return AuthGate(user: user);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const LoginFallback(),
    );
  }
}

class AuthGate extends StatelessWidget {
  final dynamic user;

  const AuthGate({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const LoginPlaceholder();
    }
    return MainNavigator(user: user);
  }
}

class LoginPlaceholder extends StatelessWidget {
  const LoginPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class LoginFallback extends StatelessWidget {
  const LoginFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Error loading app')));
  }
}

class MainNavigator extends StatelessWidget {
  final dynamic user;

  const MainNavigator({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
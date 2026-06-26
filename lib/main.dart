import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'models/word.dart';
import 'services/progress_service.dart';
import 'services/word_service.dart';

void main() {
  runApp(const YokdilQuestApp());
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/quiz/:dept',
      builder: (_, state) {
        final dept = Department.values.firstWhere(
          (d) => d.name == state.pathParameters['dept'],
        );
        return QuizScreen(department: dept);
      },
    ),
    GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
  ],
);

class YokdilQuestApp extends StatelessWidget {
  const YokdilQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ProgressService()),
        Provider(create: (_) => WordService()),
      ],
      child: MaterialApp.router(
        title: 'YÖKDİL Quest',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A237E),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}

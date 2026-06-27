import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'models/models.dart';
import 'models/game_models.dart';
import 'screens/home_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/result_progress_screens.dart';
import 'screens/game/splash_screen.dart';
import 'screens/game/map_screen.dart';
import 'screens/game/boss_screen.dart';
import 'screens/game/chest_screen.dart';
import 'services/word_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const GameOfYokdilApp());
}

class GameOfYokdilApp extends StatelessWidget {
  const GameOfYokdilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game of YÖKDİL',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const AppNavigator(),
    );
  }
}

enum AppPage { splash, onboarding, home, map, quiz, boss, chest, result, progress }

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  AppPage _page = AppPage.splash;

  // Oyun durumu
  Department _dept = Department.fen;
  final Map<Department, TreasureMap> _maps = {};
  BossBattle? _boss;
  ChestRewards? _chestRewards;
  SessionResult? _lastResult;
  int _gold = 0;
  int _streak = 0;

  // Kelime verisi
  final _wordService = WordService();
  Map<Department, List<Word>> _allWords = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final results = await Future.wait([
      _wordService.getWords(Department.fen),
      _wordService.getWords(Department.saglik),
      _wordService.getWords(Department.sosyal),
    ]);
    setState(() {
      _allWords = {
        Department.fen:    results[0],
        Department.saglik: results[1],
        Department.sosyal: results[2],
      };
      _loading = false;
    });
  }

  Map<Department, int> get _wordCounts =>
      _allWords.map((k, v) => MapEntry(k, v.length));

  TreasureMap _mapFor(Department d) {
    return _maps.putIfAbsent(d, () => TreasureMap.generate(d.name, d.label));
  }

  List<Question> _buildQuestions([int count = 10]) {
    final words = _allWords[_dept] ?? [];
    return _wordService.buildQuestions(words, count: count);
  }

  void _go(AppPage p) => setState(() => _page = p);

  @override
  Widget build(BuildContext context) {
    if (_loading && _page != AppPage.splash && _page != AppPage.onboarding) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.fen)),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: _buildPage(),
    );
  }

  Widget _buildPage() {
    switch (_page) {
      case AppPage.splash:
        return SplashScreen(
          key: const ValueKey('splash'),
          onComplete: () => _go(AppPage.onboarding),
        );

      case AppPage.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'),
          onSelect: (d) {
            setState(() {
              _dept = d;
              _maps.remove(d);
            });
            _go(AppPage.home);
          },
        );

      case AppPage.home:
        return HomeScreen(
          key: const ValueKey('home'),
          onSelectDept: (d) {
            setState(() {
              _dept = d;
              if (!_maps.containsKey(d)) _mapFor(d);
            });
            _go(AppPage.map);
          },
          wordCounts: _wordCounts,
        );

      case AppPage.map:
        return MapScreen(
          key: ValueKey('map_${_dept.name}'),
          map: _mapFor(_dept),
          department: _dept,
          gold: _gold,
          streak: _streak,
          onStartQuiz: () => _go(AppPage.quiz),
          onBossReady: () {
            setState(() => _boss = BossBattle.forDepartment(_dept));
            _go(AppPage.boss);
          },
          onTreasure: (idx) {
            setState(() {
              _chestRewards = ChestRewards.treasure();
              _gold += 25;
              
            });
            _go(AppPage.chest);
          },
        );

      case AppPage.quiz:
        return QuizScreen(
          key: const ValueKey('quiz'),
          questions: _buildQuestions(10),
          department: _dept,
          theme: _dept.label,
          onComplete: (result) {
            setState(() {
              _lastResult = result;
              
              _mapFor(_dept).unlockNext();
            });
            _go(AppPage.result);
          },
          onBack: () => _go(AppPage.map),
        );

      case AppPage.boss:
        return BossScreen(
          key: const ValueKey('boss'),
          boss: _boss!,
          questions: _buildQuestions(20),
          department: _dept,
          onVictory: (rewards) {
            setState(() {
              _chestRewards = rewards;
              _mapFor(_dept).bossDefeated = true;
              _gold += 80;
              
              _streak++;
            });
            _go(AppPage.chest);
          },
          onDefeat: () => _go(AppPage.map),
        );

      case AppPage.chest:
        return ChestScreen(
          key: const ValueKey('chest'),
          rewards: _chestRewards!,
          onContinue: () {
            if (_mapFor(_dept).bossDefeated) {
              setState(() => _maps.remove(_dept));
            }
            _go(AppPage.map);
          },
        );

      case AppPage.result:
        return ResultScreen(
          key: const ValueKey('result'),
          result: _lastResult!,
          onHome: () => _go(AppPage.map),
          onReplay: () => _go(AppPage.quiz),
        );

      case AppPage.progress:
        return ProgressScreen(
          key: const ValueKey('progress'),
          wordCounts: _wordCounts,
        );
    }
  }
}

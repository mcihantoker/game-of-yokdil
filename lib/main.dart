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
import 'screens/profile_screen.dart';
import 'services/word_service.dart';
import 'services/progress_service.dart';

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

enum AppPage { splash, onboarding, home, map, quiz, boss, chest, result, progress, leaderboard, badges, profile }

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
  final _progress = ProgressService();
  Map<Department, List<Word>> _allWords = {};
  Map<String, WordProgress> _wordProgress = {};
  bool _loading = true;
  bool _deptSaved = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      _wordService.getWords(Department.fen),
      _wordService.getWords(Department.saglik),
      _wordService.getWords(Department.sosyal),
      _progress.loadGameState(),
      _progress.loadSelectedDept(),
      _progress.load(),
    ]);

    final fen        = results[0] as List<Word>;
    final saglik     = results[1] as List<Word>;
    final sosyal     = results[2] as List<Word>;
    final gs         = results[3] as ({int gold, int streak});
    final savedDept  = results[4] as String?;
    final wordProg   = results[5] as Map<String, WordProgress>;

    // Kayıtlı haritaları yükle
    final savedFen    = await _progress.loadMap(Department.fen.name, Department.fen.label);
    final savedSaglik = await _progress.loadMap(Department.saglik.name, Department.saglik.label);
    final savedSosyal = await _progress.loadMap(Department.sosyal.name, Department.sosyal.label);

    Department dept = Department.fen;
    if (savedDept != null) {
      dept = Department.values.firstWhere((d) => d.name == savedDept, orElse: () => Department.fen);
    }

    setState(() {
      _allWords = {
        Department.fen:    fen,
        Department.saglik: saglik,
        Department.sosyal: sosyal,
      };
      _wordProgress = wordProg;
      _gold   = gs.gold;
      _streak = gs.streak;
      _dept   = dept;
      _deptSaved = savedDept != null;
      if (savedFen    != null) _maps[Department.fen]    = savedFen;
      if (savedSaglik != null) _maps[Department.saglik] = savedSaglik;
      if (savedSosyal != null) _maps[Department.sosyal] = savedSosyal;
      _loading = false;
    });
  }

  Map<Department, int> get _learnedCounts {
    return _allWords.map((dept, words) => MapEntry(
      dept,
      words.where((w) => (_wordProgress[w.id]?.correctCount ?? 0) >= 2).length,
    ));
  }

  Map<Department, int> get _mapOpenCounts {
    return {for (final d in Department.values) d: _maps[d]?.openCount ?? 0};
  }

  Map<Department, int> get _wordCounts =>
      _allWords.map((k, v) => MapEntry(k, v.length));

  TreasureMap _mapFor(Department d) =>
      _maps.putIfAbsent(d, () => TreasureMap.generate(d.name, d.label));

  List<Question> _buildQuestions([int count = 10]) {
    final words = _allWords[_dept] ?? [];
    return _wordService.buildQuestions(words, count: count);
  }

  void _go(AppPage p) => setState(() => _page = p);

  void _onTabSelect(int idx) {
    switch (idx) {
      case 0: _go(AppPage.home);
      case 1: _go(AppPage.progress);
      case 2: _go(AppPage.leaderboard);
      case 3: _go(AppPage.badges);
      case 4: _go(AppPage.profile);
    }
  }

  Future<void> _saveMap(Department d) => _progress.saveMap(_mapFor(d));

  Future<void> _saveGameState() =>
      _progress.saveGameState(gold: _gold, streak: _streak);

  @override
  Widget build(BuildContext context) {
    if (_loading && _page != AppPage.splash) {
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
          onComplete: () {
            if (_loading) {
              // Henüz yüklenmediyse yükleme bitmesini bekle
              Future.doWhile(() async {
                await Future.delayed(const Duration(milliseconds: 100));
                return _loading;
              }).then((_) {
                _go(_deptSaved ? AppPage.home : AppPage.onboarding);
              });
            } else {
              _go(_deptSaved ? AppPage.home : AppPage.onboarding);
            }
          },
        );

      case AppPage.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'),
          onSelect: (d) {
            setState(() {
              _dept = d;
              _maps.remove(d);
            });
            _progress.saveSelectedDept(d.name);
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
          learnedCounts: _learnedCounts,
          mapOpenCounts: _mapOpenCounts,
          gold: _gold,
          streak: _streak,
          onTabSelect: _onTabSelect,
        );

      case AppPage.map:
        return MapScreen(
          key: ValueKey('map_${_dept.name}'),
          map: _mapFor(_dept),
          department: _dept,
          gold: _gold,
          streak: _streak,
          onBack: () => _go(AppPage.home),
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
            _saveGameState();
            _saveMap(_dept);
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
            _saveMap(_dept);
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
            _saveGameState();
            _saveMap(_dept);
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
              _progress.saveSelectedDept(_dept.name);
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
          learnedCounts: _learnedCounts,
          onTabSelect: _onTabSelect,
        );

      case AppPage.leaderboard:
        return LeaderboardScreen(
          key: const ValueKey('leaderboard'),
          onTabSelect: _onTabSelect,
        );

      case AppPage.badges:
        return BadgesScreen(
          key: const ValueKey('badges'),
          onTabSelect: _onTabSelect,
        );

      case AppPage.profile:
        return ProfileScreen(
          key: const ValueKey('profile'),
          learnedCounts: _learnedCounts,
          gold: _gold,
          streak: _streak,
          onTabSelect: _onTabSelect,
        );
    }
  }
}

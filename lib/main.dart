import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'models/models.dart';
import 'screens/home_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/result_progress_screens.dart';
import 'services/word_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const YokdilQuestApp());
}

class YokdilQuestApp extends StatelessWidget {
  const YokdilQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YÖKDİL Quest',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      home: const AppNavigator(),
    );
  }
}

// ─── Uygulama durumu ─────────────────────────────────────────────────────────
enum AppPage { home, quiz, result, progress }

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  AppPage _page = AppPage.home;
  SessionResult? _lastResult;
  Department _selectedDept = Department.fen;

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

  Map<Department, int> get _wordCounts => _allWords.map((k, v) => MapEntry(k, v.length));

  List<Question> _buildQuestions(Department dept) {
    final words = _allWords[dept] ?? [];
    return _wordService.buildQuestions(words, count: 10);
  }

  void _goQuiz([Department? dept]) {
    setState(() {
      if (dept != null) _selectedDept = dept;
      _page = AppPage.quiz;
    });
  }

  void _goHome() => setState(() => _page = AppPage.home);

  void _onQuizComplete(SessionResult result) {
    setState(() {
      _lastResult = result;
      _page = AppPage.result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.fen),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: switch (_page) {
        AppPage.home => HomeScreen(
            key: const ValueKey('home'),
            onStartQuiz: _goQuiz,
            onSelectDept: _goQuiz,
            wordCounts: _wordCounts,
          ),
        AppPage.quiz => QuizScreen(
            key: const ValueKey('quiz'),
            questions: _buildQuestions(_selectedDept),
            department: _selectedDept,
            theme: _selectedDept.label,
            onComplete: _onQuizComplete,
            onBack: _goHome,
          ),
        AppPage.result => ResultScreen(
            key: const ValueKey('result'),
            result: _lastResult!,
            onHome: _goHome,
            onReplay: () => _goQuiz(),
          ),
        AppPage.progress => ProgressScreen(
            key: const ValueKey('progress'),
            wordCounts: _wordCounts,
          ),
      },
    );
  }
}

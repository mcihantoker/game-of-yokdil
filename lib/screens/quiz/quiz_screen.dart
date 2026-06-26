import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/word.dart';
import '../../models/user_progress.dart';
import '../../services/word_service.dart';
import '../../services/progress_service.dart';

class QuizScreen extends StatefulWidget {
  final Department department;
  const QuizScreen({super.key, required this.department});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Word> _words = [];
  Map<String, UserProgress> _progress = {};
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _answered = false;
  int _sessionScore = 0;
  int _sessionTotal = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final wordService = context.read<WordService>();
    final progressService = context.read<ProgressService>();
    final allWords = await wordService.getWords(widget.department);
    final progress = await progressService.loadProgress();
    final dueIds = progressService.getDueWordIds(
        progress, widget.department, allWords.map((w) => w.id).toList());

    setState(() {
      _words = dueIds.isEmpty ? allWords : allWords.where((w) => dueIds.contains(w.id)).toList();
      _words.shuffle();
      if (_words.length > 10) _words = _words.sublist(0, 10);
      _progress = progress;
      _loading = false;
    });
  }

  Word get _current => _words[_currentIndex];

  List<String> get _options {
    final wordService = context.read<WordService>();
    final wrong = wordService.buildWrongOptions(_current.trMeaning, _words);
    final options = [_current.trMeaning, ...wrong]..shuffle();
    return options;
  }

  void _answer(String option) {
    if (_answered) return;
    final correct = option == _current.trMeaning;
    setState(() {
      _selectedAnswer = option;
      _answered = true;
      if (correct) _sessionScore++;
      _sessionTotal++;
    });

    context.read<ProgressService>().recordAnswer(
          wordId: _current.id,
          correct: correct,
          allProgress: _progress,
        );
  }

  void _next() {
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Oturum Tamamlandı!'),
        content: Text('$_sessionTotal sorudan $_sessionScore doğru yapıldı.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Ana Sayfa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('Bugünlük tüm kelimeler tamamlandı!')),
      );
    }

    final options = _options;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${_words.length}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _words.length,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    Text(
                      _current.word,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _current.phonetic,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ne anlama gelir?',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...options.map((opt) => _OptionButton(
                  label: opt,
                  selected: _selectedAnswer == opt,
                  correct: _answered ? opt == _current.trMeaning : null,
                  onTap: () => _answer(opt),
                )),
            const Spacer(),
            if (_answered)
              Column(
                children: [
                  if (_answered)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _current.exampleSentence,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    child: Text(_currentIndex < _words.length - 1
                        ? 'Devam'
                        : 'Sonuçlar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool? correct;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.selected,
    required this.correct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    if (selected && correct == true) bgColor = Colors.green[100];
    if (selected && correct == false) bgColor = Colors.red[100];
    if (!selected && correct == true) bgColor = Colors.green[50];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.transparent : Colors.grey[300]!,
            ),
          ),
          child: Text(label,
              style: const TextStyle(fontSize: 15),
              textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

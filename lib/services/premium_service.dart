import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_event.dart';

class PremiumService extends ChangeNotifier {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  static const int freeQuizLimit = 3;

  static const Set<EventType> freeEventTypes = {
    EventType.bonusChest,
    EventType.goldenHour,
    EventType.wordFlash,
    EventType.comboFrenzy,
    EventType.blitz,
  };

  bool _isPremium = false;
  int  _todayQuizCount = 0;

  bool get isPremium        => _isPremium;
  int  get todayQuizCount   => _todayQuizCount;
  int  get remainingQuizzes => _isPremium ? 999 : (freeQuizLimit - _todayQuizCount).clamp(0, freeQuizLimit);
  bool get canStartQuiz     => _isPremium || _todayQuizCount < freeQuizLimit;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('is_premium') ?? false;
    final today     = _todayKey();
    final savedDate = prefs.getString('quiz_date') ?? '';
    if (savedDate != today) {
      _todayQuizCount = 0;
      await prefs.setString('quiz_date', today);
      await prefs.setInt('quiz_count', 0);
    } else {
      _todayQuizCount = prefs.getInt('quiz_count') ?? 0;
    }
    notifyListeners();
  }

  Future<void> recordQuiz() async {
    if (_isPremium) return;
    _todayQuizCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quiz_count', _todayQuizCount);
    notifyListeners();
  }

  Future<void> activate() async {
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', true);
    notifyListeners();
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}

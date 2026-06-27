import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_event.dart';
import 'premium_service.dart';

// ─── Olay Servisi ─────────────────────────────────────────────────────────────
// Kullanım: EventService.instance ile singleton'a eriş
// ChangeNotifier ile provider entegrasyonu hazır

class EventService extends ChangeNotifier {
  EventService._();
  static final EventService instance = EventService._();

  DailyEvent? _todaysEvent;
  bool _eventSeen = false;         // kullanıcı kartı gördü mü
  bool _bonusChestClaimed = false; // bonus sandık bu gün alındı mı
  bool _ironWillFailed = false;    // demir irade bugün başarısız mı
  bool _ironWillCompleted = false; // demir irade bugün tamamlandı mı
  DateTime? _lastLoadDate;

  DailyEvent get todaysEvent {
    _ensureLoaded();
    final event = _todaysEvent!;
    if (!PremiumService.instance.isPremium &&
        !PremiumService.freeEventTypes.contains(event.type)) {
      return DailyEvents.all.firstWhere(
        (e) => e.type == EventType.bonusChest,
        orElse: () => event,
      );
    }
    return event;
  }

  bool get eventSeen        => _eventSeen;
  bool get bonusChestClaimed => _bonusChestClaimed;
  bool get ironWillFailed   => _ironWillFailed;
  bool get ironWillCompleted => _ironWillCompleted;

  /// Efekti şu an aktif mi (altın saat gibi zaman bağımlı olaylar için canlı kontrol)
  bool get isEffectActive {
    final e = todaysEvent;
    if (e.effect.goldenHourActive) {
      return DailyEvents.isGoldenHourNow(e);
    }
    return true; // diğer olaylar her zaman aktif
  }

  /// Aktif XP çarpanı
  double get xpMultiplier => DailyEvents.activeXpMultiplier(todaysEvent);

  /// Bugünkü gerçek süre çarpanı
  double get timerMultiplier => todaysEvent.effect.timerMultiplier;

  // ─── Yükleme ───────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey();

    // Yeni gün mü kontrol et
    final savedDate = prefs.getString('event_date');
    if (savedDate != today) {
      // Yeni gün: her şeyi sıfırla
      await prefs.setString('event_date', today);
      await prefs.setBool('event_seen', false);
      await prefs.setBool('bonus_chest_claimed', false);
      await prefs.setBool('iron_will_failed', false);
      await prefs.setBool('iron_will_completed', false);
    }

    _eventSeen          = prefs.getBool('event_seen') ?? false;
    _bonusChestClaimed  = prefs.getBool('bonus_chest_claimed') ?? false;
    _ironWillFailed     = prefs.getBool('iron_will_failed') ?? false;
    _ironWillCompleted  = prefs.getBool('iron_will_completed') ?? false;
    _todaysEvent        = DailyEvents.todaysEvent();
    _lastLoadDate       = DateTime.now();

    notifyListeners();
  }

  void _ensureLoaded() {
    if (_todaysEvent == null) {
      _todaysEvent = DailyEvents.todaysEvent();
    }
    // Gün değiştiyse yenile (uygulama gece yarısı açık kalabilir)
    final now = DateTime.now();
    if (_lastLoadDate != null && _lastLoadDate!.day != now.day) {
      init(); // async ama UI zaten güncellenecek
    }
  }

  // ─── Durum güncellemeleri ──────────────────────────────────────────────────
  Future<void> markEventSeen() async {
    _eventSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('event_seen', true);
    notifyListeners();
  }

  Future<void> claimBonusChest() async {
    _bonusChestClaimed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bonus_chest_claimed', true);
    notifyListeners();
  }

  Future<void> markIronWillFailed() async {
    _ironWillFailed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('iron_will_failed', true);
    notifyListeners();
  }

  Future<void> markIronWillCompleted() async {
    _ironWillCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('iron_will_completed', true);
    notifyListeners();
  }

  // ─── XP hesabı (olay etkisi dahil) ────────────────────────────────────────
  /// Doğru cevap için kazanılacak XP
  int calculateXP({
    required int baseXP,
    required bool isCorrect,
    required int combo,
  }) {
    final effect = todaysEvent.effect;

    if (!isCorrect) {
      // Çift ya da çift değil: yanlışta 0
      if (effect.doubleOrNothing) return 0;
      return 0; // zaten yanlış cevap XP vermiyor
    }

    double xp = baseXP.toDouble();

    // Aktif çarpan (golden hour dahil)
    xp *= xpMultiplier;

    // Çift ya da çift değil bonus (zaten xpMultiplier'da 2x var, ek değil)
    // doubleOrNothing yanlış cevabı 0'lar, doğru cevabı 2x'ler — yukarıda halledildi

    return xp.round();
  }

  /// Combo artışı (olay etkisi dahil)
  int comboIncrement() => 1 + todaysEvent.effect.comboBonus;

  // ─── Seçenek sırası (Lanetli Tuşlar) ─────────────────────────────────────
  /// Seçenek listesini olaya göre yeniden sıralar
  List<T> applyOptionOrder<T>(List<T> options) {
    final effect = todaysEvent.effect;
    if (effect.shuffleOptionsReverse) {
      return options.reversed.toList();
    }
    if (effect.swapAC_BD && options.length == 4) {
      // A(0)↔C(2), B(1)↔D(3)
      return [options[2], options[3], options[0], options[1]];
    }
    return options;
  }

  /// Orijinal indexten görüntülenen indexe (Lanetli Tuşlar için doğru cevap index'i)
  int mapCorrectIndex(int originalIndex, int optionCount) {
    final effect = todaysEvent.effect;
    if (effect.swapAC_BD && optionCount == 4) {
      const mapping = [2, 3, 0, 1]; // 0→2, 1→3, 2→0, 3→1
      return mapping[originalIndex];
    }
    if (effect.shuffleOptionsReverse) {
      return (optionCount - 1) - originalIndex;
    }
    return originalIndex;
  }

  // ─── Can sistemi (Demir İrade) ─────────────────────────────────────────────
  /// Bu tur için başlangıç can sayısı
  int startingLives(int defaultLives) {
    if (todaysEvent.effect.singleLife) return 1;
    return defaultLives;
  }

  /// Yanlış cevapta can düşmeli mi
  bool shouldTakeDamage() {
    return !todaysEvent.effect.noDamageOnWrong;
  }

  // ─── Yardımcılar ──────────────────────────────────────────────────────────
  String _dateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Test için olayı geçersiz kıl (sadece debug modunda kullanılır)
  void debugOverrideEvent(DailyEvent event) {
    assert(kDebugMode, 'Bu metot sadece debug modunda kullanılabilir');
    _todaysEvent = event;
    notifyListeners();
  }
}

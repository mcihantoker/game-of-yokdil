import 'dart:math';

// ─── Olay Tipi ────────────────────────────────────────────────────────────────
enum EventType {
  fogDay,         // Sis Günü: kelime 1sn görünür, kaybolur
  doubleOrNothing,// Çift ya da çift değil: doğru=XP×2, yanlış=0
  silentBoss,     // Sessiz Boss: telaffuz yok, sadece fonetik
  goldenHour,     // Altın Saat: belirli saatte ×3 XP
  mirrorMode,     // Ayna Modu: seçenekler ters alfabetik sırada
  blitz,          // Şimşek Turu: süre yarıya iner ama XP ×2
  ironWill,       // Demir İrade: can yok, tek şans, hepsi doğruysa büyük ödül
  wordFlash,      // Kelime Flaşı: kelime 2sn görünür, cevap normal sürede
  bonusChest,     // Bonus Sandık: bu gün ilk doğru cevapla ekstra sandık
  cursedKeys,     // Lanetli Tuşlar: A↔C ve B↔D seçenekleri yer değiştirir
  comboFrenzy,    // Combo Çılgınlığı: her doğru cevap comboya +2 ekler
  soulBind,       // Ruh Bağı: yanlış cevap XP çalmaz ama combo sıfırlar
}

// ─── Olay Modeli ─────────────────────────────────────────────────────────────
class DailyEvent {
  final EventType type;
  final String title;
  final String description;    // kısa açıklama (kart)
  final String fullDescription;// detaylı açıklama (modal)
  final String emoji;
  final String rarity;         // 'common' | 'rare' | 'legendary'
  final EventEffect effect;

  const DailyEvent({
    required this.type,
    required this.title,
    required this.description,
    required this.fullDescription,
    required this.emoji,
    required this.rarity,
    required this.effect,
  });
}

// ─── Olay Efekti (Quiz/Boss mekaniklerine inject edilir) ──────────────────────
class EventEffect {
  // Süre
  final double timerMultiplier;  // 1.0 = normal, 0.5 = yarı süre
  final bool hideWordAfterMs;    // true ise wordHideMs sonra kelime kaybolur
  final int wordHideMs;          // kelime kaç ms sonra kaybolur

  // XP
  final double xpMultiplier;     // 1.0 = normal, 2.0 = iki kat
  final bool doubleOrNothing;    // doğru=xp*2, yanlış=0
  final bool goldenHourActive;   // aktif saatte xpMultiplier uygulanır
  final int goldenHourStart;     // başlangıç saati (0–23)
  final int goldenHourEnd;       // bitiş saati (0–23)

  // Görsel/UI
  final bool hidePhonetic;       // telaffuz yazısını gizle
  final bool shuffleOptionsReverse; // seçenekleri ters sırala
  final bool swapAC_BD;          // A↔C ve B↔D yerini değiştir

  // Combo
  final int comboBonus;          // her doğru cevapta comboya eklenir
  final bool resetComboOnWrong;  // yanlışta combo sıfırlanır mı

  // Can
  final bool noDamageOnWrong;    // yanlışta can düşmez
  final bool singleLife;         // tek can, ilk yanlışta biter

  // Bonus
  final bool bonusChestOnFirst;  // ilk doğru cevapla sandık kazanılır

  const EventEffect({
    this.timerMultiplier     = 1.0,
    this.hideWordAfterMs     = false,
    this.wordHideMs          = 1000,
    this.xpMultiplier        = 1.0,
    this.doubleOrNothing     = false,
    this.goldenHourActive    = false,
    this.goldenHourStart     = 20,
    this.goldenHourEnd       = 21,
    this.hidePhonetic        = false,
    this.shuffleOptionsReverse = false,
    this.swapAC_BD           = false,
    this.comboBonus          = 0,
    this.resetComboOnWrong   = true,
    this.noDamageOnWrong     = false,
    this.singleLife          = false,
    this.bonusChestOnFirst   = false,
  });
}

// ─── Tüm Olaylar ──────────────────────────────────────────────────────────────
class DailyEvents {
  static const List<DailyEvent> all = [

    DailyEvent(
      type: EventType.fogDay,
      title: 'Sis Günü',
      description: 'Kelime 1 saniye görünür, sonra kaybolur.',
      fullDescription:
          'Bugün sis orduyu sardı. Her kelime ekranda yalnızca 1 saniye belirecek — '
          'sonra karanlığa gömülecek. Hafıza ve dikkat en büyük silahın.',
      emoji: '🌫️',
      rarity: 'rare',
      effect: EventEffect(
        hideWordAfterMs: true,
        wordHideMs: 1000,
      ),
    ),

    DailyEvent(
      type: EventType.doubleOrNothing,
      title: 'Çift ya da Çift Değil',
      description: 'Doğru → XP×2. Yanlış → 0 XP.',
      fullDescription:
          'Büyük kumarbaz günü. Her doğru cevap XP\'ni ikiye katlar, '
          'ama yanlış cevap tüm tur XP\'ni sıfırlar. Emin olduğunda hamle yap.',
      emoji: '🎲',
      rarity: 'rare',
      effect: EventEffect(
        doubleOrNothing: true,
        xpMultiplier: 2.0,
      ),
    ),

    DailyEvent(
      type: EventType.silentBoss,
      title: 'Sessiz Boss',
      description: 'Telaffuz ipucu yok, sadece fonetik yazı.',
      fullDescription:
          'Boss bugün sessizliğe büründü. Kelimelerin sesli telaffuzu görünmeyecek — '
          'sadece fonetik semboller kalacak. Gerçek bilgi sınavı.',
      emoji: '🤐',
      rarity: 'common',
      effect: EventEffect(
        hidePhonetic: false, // fonetik görünür ama ses ipucu yok (UI katmanı)
        // Not: ses oynatma özelliği eklendiğinde hideAudio: true kullanılacak
      ),
    ),

    DailyEvent(
      type: EventType.goldenHour,
      title: 'Altın Saat',
      description: '20:00–21:00 arası oyna → ×3 XP kazan.',
      fullDescription:
          'Savaş alanı bir saatliğine altınla kaplandı. Saat 20:00–21:00 arasında '
          'verilen her doğru cevap üç kat XP kazandırır. '
          'Bu pencereyi kaçırma.',
      emoji: '⏰',
      rarity: 'common',
      effect: EventEffect(
        goldenHourActive: true,
        goldenHourStart: 20,
        goldenHourEnd: 21,
        xpMultiplier: 3.0,
      ),
    ),

    DailyEvent(
      type: EventType.blitz,
      title: 'Şimşek Turu',
      description: 'Süre yarıya indi — ama XP ×2.',
      fullDescription:
          'Şimşek gündür. Cevap vermek için normal sürenin yarısı var, '
          'ama her doğru cevap iki kat XP getiriyor. Hızlı düşün, hızlı vur.',
      emoji: '⚡',
      rarity: 'rare',
      effect: EventEffect(
        timerMultiplier: 0.5,
        xpMultiplier: 2.0,
      ),
    ),

    DailyEvent(
      type: EventType.ironWill,
      title: 'Demir İrade',
      description: 'Tek can. Hepsini doğru yap → efsanevi ödül.',
      fullDescription:
          'Bugün yalnız savaşıyorsun. Yedek canın yok — ilk yanlış cevap turu bitirir. '
          'Ama tüm soruları doğru yanıtlarsan efsanevi bir sandık seni bekliyor.',
      emoji: '🗡️',
      rarity: 'legendary',
      effect: EventEffect(
        singleLife: true,
        xpMultiplier: 1.0,
        bonusChestOnFirst: false,
      ),
    ),

    DailyEvent(
      type: EventType.wordFlash,
      title: 'Kelime Flaşı',
      description: 'Kelime 2sn görünür, seçenekler kalır.',
      fullDescription:
          'Kelime şimşek gibi geçer — 2 saniye içinde oku, sonra seçeneklere bak. '
          'Cevaplamak için normal süren var, ama kelime artık görünmüyor.',
      emoji: '💡',
      rarity: 'common',
      effect: EventEffect(
        hideWordAfterMs: true,
        wordHideMs: 2000,
      ),
    ),

    DailyEvent(
      type: EventType.bonusChest,
      title: 'Bonus Sandık',
      description: 'İlk doğru cevabında ekstra sandık kazanırsın.',
      fullDescription:
          'Bugün savaş alanında gizli bir hazine var. '
          'Bu günün ilk doğru cevabı sana ekstra bir sandık açma hakkı verir.',
      emoji: '📦',
      rarity: 'common',
      effect: EventEffect(
        bonusChestOnFirst: true,
      ),
    ),

    DailyEvent(
      type: EventType.cursedKeys,
      title: 'Lanetli Tuşlar',
      description: 'A↔C ve B↔D seçenekleri yer değiştirdi.',
      fullDescription:
          'Cadı büyüsü klavyeyi lanetledi. A ve C seçenekleri, B ve D seçenekleri '
          'birbirleriyle yer değiştirdi. Gördüğün ilk harfe tıklama — oku, düşün.',
      emoji: '🔮',
      rarity: 'rare',
      effect: EventEffect(
        swapAC_BD: true,
      ),
    ),

    DailyEvent(
      type: EventType.comboFrenzy,
      title: 'Combo Çılgınlığı',
      description: 'Her doğru cevap comboya +2 ekler.',
      fullDescription:
          'Bugün combo makinesi çıldırdı. Her doğru cevap normal +1 yerine '
          '+2 combo ekler. Maksimum combo bonusuna tek elde ulaşabilirsin.',
      emoji: '🔥',
      rarity: 'rare',
      effect: EventEffect(
        comboBonus: 2,
      ),
    ),

    DailyEvent(
      type: EventType.soulBind,
      title: 'Ruh Bağı',
      description: 'Yanlış cevap XP çalmaz, sadece combo sıfırlar.',
      fullDescription:
          'Bugün koruyucu bir büyü seni sarıyor. Yanlış cevapların canını veya '
          'XP\'ni götürmez — sadece combo zincirini kırar. Rahatça dene.',
      emoji: '🛡️',
      rarity: 'common',
      effect: EventEffect(
        noDamageOnWrong: true,
        resetComboOnWrong: true,
        xpMultiplier: 0.8, // telafi: XP biraz düşük ama risksiz
      ),
    ),

  ];

  // Rarity ağırlıkları: common=60%, rare=30%, legendary=10%
  static const Map<String, int> _weights = {
    'common': 60,
    'rare': 30,
    'legendary': 10,
  };

  /// Bugünün olayını belirler — tarih seed'i kullanır (aynı gün herkese aynı olay)
  static DailyEvent todaysEvent() {
    final now = DateTime.now();
    // Seed: yılın kaçıncı günü — bu sayede aynı gün herkes aynı olayı görür
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final rng = Random(dayOfYear * 31 + now.year);

    // Önce rarity belirle
    final roll = rng.nextInt(100);
    String rarity;
    if (roll < 60) {
      rarity = 'common';
    } else if (roll < 90) {
      rarity = 'rare';
    } else {
      rarity = 'legendary';
    }

    // O rarity'deki olayları filtrele
    final pool = all.where((e) => e.rarity == rarity).toList();
    if (pool.isEmpty) return all.first;

    return pool[rng.nextInt(pool.length)];
  }

  /// Altın saat şu an aktif mi?
  static bool isGoldenHourNow(DailyEvent event) {
    if (!event.effect.goldenHourActive) return false;
    final now = DateTime.now();
    return now.hour >= event.effect.goldenHourStart &&
        now.hour < event.effect.goldenHourEnd;
  }

  /// Aktif XP çarpanını hesapla (altın saat dahil)
  static double activeXpMultiplier(DailyEvent event) {
    if (event.effect.goldenHourActive) {
      return isGoldenHourNow(event) ? event.effect.xpMultiplier : 1.0;
    }
    return event.effect.xpMultiplier;
  }

  /// Rarity rengi
  static ({String label, int colorHex}) rarityStyle(String rarity) {
    switch (rarity) {
      case 'legendary': return (label: 'Efsanevi', colorHex: 0xFFF5A623);
      case 'rare':      return (label: 'Nadir',    colorHex: 0xFF7F77DD);
      default:          return (label: 'Yaygın',   colorHex: 0xFF4DD0A6);
    }
  }
}

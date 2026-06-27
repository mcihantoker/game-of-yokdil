import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'app_assets.dart';

// ─── Rozet Tanımı ─────────────────────────────────────────────────────────────
class Badge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final String assetPath;
  final Department? dept; // null = tüm bölümler
  final BadgeRarity rarity;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.assetPath,
    this.dept,
    this.rarity = BadgeRarity.common,
  });
}

enum BadgeRarity { common, rare, legendary }

extension BadgeRarityExt on BadgeRarity {
  String get label => switch (this) {
    BadgeRarity.common    => 'Yaygın',
    BadgeRarity.rare      => 'Nadir',
    BadgeRarity.legendary => 'Efsanevi',
  };
  int get colorHex => switch (this) {
    BadgeRarity.common    => 0xFF4DD0A6,
    BadgeRarity.rare      => 0xFF7F77DD,
    BadgeRarity.legendary => 0xFFF5A623,
  };
}

// ─── Tüm Rozetler ─────────────────────────────────────────────────────────────
class BadgeDefinitions {
  static const List<Badge> all = [
    Badge(
      id: 'first_word',
      title: 'İlk Adım',
      description: 'İlk kelimeni öğrendin.',
      emoji: '🌱',
      assetPath: AppAssets.badgeFirstWord,
      rarity: BadgeRarity.common,
    ),
    Badge(
      id: 'words_50',
      title: '50 Kelime',
      description: '50 kelimeyi tamamladın.',
      emoji: '📚',
      assetPath: AppAssets.badgeFirst50,
      rarity: BadgeRarity.rare,
    ),
    Badge(
      id: 'words_100',
      title: '100 Kelime',
      description: '100 kelimeyi tamamladın.',
      emoji: '🏛️',
      assetPath: AppAssets.badgeFirst100,
      rarity: BadgeRarity.legendary,
    ),
    Badge(
      id: 'boss_fen',
      title: 'Fen Fatihi',
      description: 'Fen Bilimleri canavarını yendin.',
      emoji: '⚗️',
      assetPath: AppAssets.badgeBossFen,
      dept: Department.fen,
      rarity: BadgeRarity.rare,
    ),
    Badge(
      id: 'boss_saglik',
      title: 'Şifacı',
      description: 'Sağlık Bilimleri ejderhasını yendin.',
      emoji: '💉',
      assetPath: AppAssets.badgeBossSaglik,
      dept: Department.saglik,
      rarity: BadgeRarity.rare,
    ),
    Badge(
      id: 'boss_sosyal',
      title: 'Bilge',
      description: 'Sosyal Bilimler kâbusunu yendin.',
      emoji: '🎓',
      assetPath: AppAssets.badgeBossSosyal,
      dept: Department.sosyal,
      rarity: BadgeRarity.rare,
    ),
    Badge(
      id: 'streak_7',
      title: '7 Gün Serisi',
      description: '7 gün art arda oynadın.',
      emoji: '🔥',
      assetPath: AppAssets.badgeStreak7,
      rarity: BadgeRarity.common,
    ),
    Badge(
      id: 'streak_30',
      title: '30 Gün Serisi',
      description: '30 gün art arda oynadın.',
      emoji: '⚡',
      assetPath: AppAssets.badgeStreak30,
      rarity: BadgeRarity.rare,
    ),
    Badge(
      id: 'streak_100',
      title: 'Efsane',
      description: '100 gün art arda oynadın.',
      emoji: '👑',
      assetPath: AppAssets.badgeStreak100,
      rarity: BadgeRarity.legendary,
    ),
    Badge(
      id: 'perfect_quiz',
      title: 'Mükemmel',
      description: 'Bir turda tüm soruları doğru yanıtladın.',
      emoji: '⭐',
      assetPath: AppAssets.badgePerfectQuiz,
      rarity: BadgeRarity.rare,
    ),
    Badge(
      id: 'sentence_master',
      title: 'Cümle Ustası',
      description: 'Cümle İnşa Modunu tamamladın.',
      emoji: '📝',
      assetPath: AppAssets.badgeSentenceMaster,
      rarity: BadgeRarity.rare,
    ),
    Badge(
      id: 'iron_will',
      title: 'Demir İrade',
      description: 'Demir İrade olayını tam doğrulukla tamamladın.',
      emoji: '🗡️',
      assetPath: AppAssets.badgeIronWill,
      rarity: BadgeRarity.legendary,
    ),
  ];

  static Badge? byId(String id) {
    try { return all.firstWhere((b) => b.id == id); }
    catch (_) { return null; }
  }
}

// ─── Rozet Servisi ────────────────────────────────────────────────────────────
class BadgeService extends ChangeNotifier {
  BadgeService._();
  static final BadgeService instance = BadgeService._();

  Set<String> _earned = {};
  List<Badge> _pendingNotifications = [];

  Set<String>   get earned             => _earned;
  List<Badge>   get pendingNotifications => _pendingNotifications;
  bool isEarned(String id) => _earned.contains(id);

  // ─── Yükleme ──────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('earned_badges') ?? [];
    _earned = saved.toSet();
    notifyListeners();
  }

  // ─── Rozet kazanma ────────────────────────────────────────────────────────
  Future<void> earn(String id) async {
    if (_earned.contains(id)) return;
    final badge = BadgeDefinitions.byId(id);
    if (badge == null) return;

    _earned.add(id);
    _pendingNotifications.add(badge);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('earned_badges', _earned.toList());
    notifyListeners();
  }

  void clearNotification() {
    if (_pendingNotifications.isNotEmpty) {
      _pendingNotifications.removeAt(0);
      notifyListeners();
    }
  }

  // ─── Oyun olaylarından rozet kontrolü ────────────────────────────────────
  Future<void> checkAfterQuiz({
    required int correctAnswers,
    required int totalWords,
    required bool isPerfect,
    required int streak,
    required Department dept,
  }) async {
    if (totalWords == 1)    await earn('first_word');
    if (totalWords >= 50)   await earn('words_50');
    if (totalWords >= 100)  await earn('words_100');
    if (isPerfect)          await earn('perfect_quiz');
    if (streak >= 7)        await earn('streak_7');
    if (streak >= 30)       await earn('streak_30');
    if (streak >= 100)      await earn('streak_100');
  }

  Future<void> checkAfterBoss(Department dept) async {
    await earn('boss_${dept.name}');
  }

  Future<void> checkAfterSentenceMode() async {
    await earn('sentence_master');
  }

  Future<void> checkIronWill() async {
    await earn('iron_will');
  }
}

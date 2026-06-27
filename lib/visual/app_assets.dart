import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';

// ─── Varlık Yolları ───────────────────────────────────────────────────────────
class AppAssets {

  // ── Lottie animasyonları ──────────────────────────────────────────────────
  static const String lottieChestOpen   = 'assets/lottie/chest_open.json';
  static const String lottieCorrect     = 'assets/lottie/correct_burst.json';
  static const String lottieComboFire   = 'assets/lottie/combo_fire.json';
  static const String lottieCellUnlock  = 'assets/lottie/cell_unlock.json';
  static const String lottieSplashGlow  = 'assets/lottie/splash_glow.json';

  // ── Harita hücre ikonları ─────────────────────────────────────────────────
  static const String iconCellLocked   = 'assets/icons/cell_locked.png';
  static const String iconCellOpen     = 'assets/icons/cell_open.png';
  static const String iconCellTreasure = 'assets/icons/cell_treasure.png';
  static const String iconCellBoss     = 'assets/icons/cell_boss.png';
  static const String iconCellCurrent  = 'assets/icons/cell_current.png';

  // ── Boss karakterleri ─────────────────────────────────────────────────────
  static const String bossFen    = 'assets/bosses/boss_fen.png';
  static const String bossSaglik = 'assets/bosses/boss_saglik.png';
  static const String bossSosyal = 'assets/bosses/boss_sosyal.png';

  // ── Rozetler ─────────────────────────────────────────────────────────────
  static const String badgeFirstWord      = 'assets/badges/badge_first_word.png';
  static const String badgeFirst50        = 'assets/badges/badge_first50.png';
  static const String badgeFirst100       = 'assets/badges/badge_first100.png';
  static const String badgeBossFen        = 'assets/badges/badge_boss_fen.png';
  static const String badgeBossSaglik     = 'assets/badges/badge_boss_saglik.png';
  static const String badgeBossSosyal     = 'assets/badges/badge_boss_sosyal.png';
  static const String badgeStreak7        = 'assets/badges/badge_streak7.png';
  static const String badgeStreak30       = 'assets/badges/badge_streak30.png';
  static const String badgeStreak100      = 'assets/badges/badge_streak100.png';
  static const String badgePerfectQuiz    = 'assets/badges/badge_perfect_quiz.png';
  static const String badgeSentenceMaster = 'assets/badges/badge_sentence_master.png';
  static const String badgeIronWill       = 'assets/badges/badge_iron_will.png';

  // ── Arka planlar ─────────────────────────────────────────────────────────
  static const String bgMapTexture   = 'assets/backgrounds/map_texture.png';
  static const String bgDeptFen      = 'assets/backgrounds/dept_bg_fen.png';
  static const String bgDeptSaglik   = 'assets/backgrounds/dept_bg_saglik.png';
  static const String bgDeptSosyal   = 'assets/backgrounds/dept_bg_sosyal.png';
  static const String bgDefeatScene  = 'assets/backgrounds/defeat_scene.png';

  // ── Logo ─────────────────────────────────────────────────────────────────
  static const String logo = 'assets/logo.png';

  // ─── Yardımcı erişimciler ────────────────────────────────────────────────

  static String bossImage(Department dept) => switch (dept) {
    Department.fen    => bossFen,
    Department.saglik => bossSaglik,
    Department.sosyal => bossSosyal,
  };

  static String deptBackground(Department dept) => switch (dept) {
    Department.fen    => bgDeptFen,
    Department.saglik => bgDeptSaglik,
    Department.sosyal => bgDeptSosyal,
  };

  static String cellIcon(CellType type) => switch (type) {
    CellType.locked   => iconCellLocked,
    CellType.open     => iconCellOpen,
    CellType.treasure => iconCellTreasure,
    CellType.boss     => iconCellBoss,
    CellType.current  => iconCellCurrent,
  };

  // ─── Varlık var mı kontrolü (async) ─────────────────────────────────────
  // Görsel dosya henüz eklenmemişse fallback'e geç
  static Future<bool> exists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ─── Akıllı Görsel Widget — fallback sistemi ─────────────────────────────────
// Görsel dosya yoksa emoji/icon fallback'i gösterir.
// Dosya eklendikten sonra otomatik olarak görsel gösterilir.

class SmartImage extends StatelessWidget {
  final String assetPath;
  final double width;
  final double height;
  final Widget fallback;
  final BoxFit fit;
  final double? opacity;

  const SmartImage({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AppAssets.exists(assetPath),
      builder: (ctx, snap) {
        if (snap.data == true) {
          final img = Image.asset(
            assetPath,
            width: width,
            height: height,
            fit: fit,
            filterQuality: FilterQuality.high,
          );
          if (opacity != null) {
            return Opacity(opacity: opacity!, child: img);
          }
          return img;
        }
        return SizedBox(width: width, height: height, child: fallback);
      },
    );
  }
}

// ─── Boss Karakter Widget ─────────────────────────────────────────────────────
class BossCharacterImage extends StatelessWidget {
  final Department department;
  final String fallbackEmoji;
  final double size;

  const BossCharacterImage({
    super.key,
    required this.department,
    required this.fallbackEmoji,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SmartImage(
      assetPath: AppAssets.bossImage(department),
      width: size,
      height: size,
      fallback: Center(
        child: Text(fallbackEmoji, style: TextStyle(fontSize: size * 0.55)),
      ),
    );
  }
}

// ─── Harita Hücre İkon Widget ────────────────────────────────────────────────
class CellIconImage extends StatelessWidget {
  final CellType type;
  final double size;
  final Widget Function(CellType) fallbackBuilder;

  const CellIconImage({
    super.key,
    required this.type,
    required this.fallbackBuilder,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SmartImage(
      assetPath: AppAssets.cellIcon(type),
      width: size,
      height: size,
      fallback: fallbackBuilder(type),
    );
  }
}

// ─── Bölüm Arka Plan Widget ───────────────────────────────────────────────────
class DeptBackgroundImage extends StatelessWidget {
  final Department department;
  final double width;
  final double height;

  const DeptBackgroundImage({
    super.key,
    required this.department,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SmartImage(
      assetPath: AppAssets.deptBackground(department),
      width: width,
      height: height,
      opacity: 0.13,
      fit: BoxFit.cover,
      // Görsel yoksa hiçbir şey gösterme
      fallback: const SizedBox.shrink(),
    );
  }
}

// ─── Rozet Widget ────────────────────────────────────────────────────────────
class BadgeImage extends StatelessWidget {
  final String assetPath;
  final double size;
  final String fallbackEmoji;
  final bool isEarned;

  const BadgeImage({
    super.key,
    required this.assetPath,
    required this.fallbackEmoji,
    this.size = 52,
    this.isEarned = true,
  });

  @override
  Widget build(BuildContext context) {
    final widget = SmartImage(
      assetPath: assetPath,
      width: size,
      height: size,
      fallback: Center(
        child: Text(fallbackEmoji, style: TextStyle(fontSize: size * 0.55)),
      ),
    );

    if (!isEarned) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      0.4, 0,
        ]),
        child: widget,
      );
    }
    return widget;
  }
}

// ─── Harita Doku Widget ───────────────────────────────────────────────────────
class MapTextureBackground extends StatelessWidget {
  final Widget child;

  const MapTextureBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AppAssets.exists(AppAssets.bgMapTexture),
      builder: (ctx, snap) {
        if (snap.data != true) return child;
        return Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.07,
                child: Image.asset(
                  AppAssets.bgMapTexture,
                  repeat: ImageRepeat.repeat,
                  filterQuality: FilterQuality.low,
                ),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}

// ─── Lottie Akıllı Widget ────────────────────────────────────────────────────
// Lottie paketi zaten var. Dosya yoksa AnimatedWidget fallback gösterir.
class SmartLottie extends StatelessWidget {
  final String assetPath;
  final double size;
  final bool repeat;
  final VoidCallback? onLoaded;
  // Lottie olmadığında gösterilecek fallback animasyonu
  final Widget fallback;

  const SmartLottie({
    super.key,
    required this.assetPath,
    required this.size,
    required this.fallback,
    this.repeat = false,
    this.onLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AppAssets.exists(assetPath),
      builder: (ctx, snap) {
        if (snap.data != true) {
          return SizedBox(width: size, height: size, child: fallback);
        }
        // Lottie paketi yüklü — gerçek animasyon
        // import 'package:lottie/lottie.dart'; dosyanın başına ekleyin
        // return Lottie.asset(assetPath, width: size, height: size, repeat: repeat);
        //
        // Şimdilik fallback göster (import gerektirmiyor)
        return SizedBox(width: size, height: size, child: fallback);
      },
    );
  }
}

// ─── Yenilgi Sahnesi Arka Planı ──────────────────────────────────────────────
class DefeatSceneBackground extends StatelessWidget {
  final Widget child;

  const DefeatSceneBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AppAssets.exists(AppAssets.bgDefeatScene),
      builder: (ctx, snap) {
        if (snap.data != true) return child;
        return Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(
                  AppAssets.bgDefeatScene,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}

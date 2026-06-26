import 'word.dart';

class UserStats {
  final String userId;
  int xp;
  int streak;
  DateTime? lastPlayedDate;
  int streakSavesRemaining;
  Map<Department, int> wordsLearnedByDept;
  List<String> earnedBadges;

  UserStats({
    required this.userId,
    this.xp = 0,
    this.streak = 0,
    this.lastPlayedDate,
    this.streakSavesRemaining = 0,
    Map<Department, int>? wordsLearnedByDept,
    List<String>? earnedBadges,
  })  : wordsLearnedByDept = wordsLearnedByDept ?? {},
        earnedBadges = earnedBadges ?? [];

  int get level => (xp / 500).floor() + 1;
  int get xpToNextLevel => 500 - (xp % 500);

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        userId: json['user_id'] as String,
        xp: json['xp'] as int,
        streak: json['streak'] as int,
        lastPlayedDate: json['last_played_date'] != null
            ? DateTime.parse(json['last_played_date'] as String)
            : null,
        streakSavesRemaining: json['streak_saves_remaining'] as int,
        wordsLearnedByDept: (json['words_learned_by_dept'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(
                  Department.values.firstWhere((d) => d.name == k),
                  v as int,
                )),
        earnedBadges: List<String>.from(json['earned_badges'] as List),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'xp': xp,
        'streak': streak,
        'last_played_date': lastPlayedDate?.toIso8601String(),
        'streak_saves_remaining': streakSavesRemaining,
        'words_learned_by_dept':
            wordsLearnedByDept.map((k, v) => MapEntry(k.name, v)),
        'earned_badges': earnedBadges,
      };
}

class UserProgress {
  final String wordId;
  int correctCount;
  int wrongCount;
  DateTime nextReviewAt;
  double easeFactor;
  int interval; // gün cinsinden

  UserProgress({
    required this.wordId,
    this.correctCount = 0,
    this.wrongCount = 0,
    DateTime? nextReviewAt,
    this.easeFactor = 2.5,
    this.interval = 1,
  }) : nextReviewAt = nextReviewAt ?? DateTime.now();

  bool get isDueForReview => DateTime.now().isAfter(nextReviewAt);

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        wordId: json['word_id'] as String,
        correctCount: json['correct_count'] as int,
        wrongCount: json['wrong_count'] as int,
        nextReviewAt: DateTime.parse(json['next_review_at'] as String),
        easeFactor: (json['ease_factor'] as num).toDouble(),
        interval: json['interval'] as int,
      );

  Map<String, dynamic> toJson() => {
        'word_id': wordId,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'next_review_at': nextReviewAt.toIso8601String(),
        'ease_factor': easeFactor,
        'interval': interval,
      };
}

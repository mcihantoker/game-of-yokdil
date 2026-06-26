import '../models/user_progress.dart';

class Sm2Service {
  // quality: 0-5 (0-2 yanlış, 3-5 doğru)
  static UserProgress update(UserProgress progress, int quality) {
    if (quality < 3) {
      progress.interval = 1;
      progress.wrongCount++;
    } else {
      if (progress.correctCount == 0) {
        progress.interval = 1;
      } else if (progress.correctCount == 1) {
        progress.interval = 6;
      } else {
        progress.interval = (progress.interval * progress.easeFactor).round();
      }
      progress.correctCount++;

      final newEF =
          progress.easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      progress.easeFactor = newEF < 1.3 ? 1.3 : newEF;
    }

    progress.nextReviewAt =
        DateTime.now().add(Duration(days: progress.interval));
    return progress;
  }
}

enum Department { fen, saglik, sosyal }

class Word {
  final String id;
  final String word;
  final String phonetic;
  final String trMeaning;
  final String exampleSentence;
  final Department department;
  final String theme;
  final List<int> examYears;

  const Word({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.trMeaning,
    required this.exampleSentence,
    required this.department,
    required this.theme,
    required this.examYears,
  });

  factory Word.fromJson(Map<String, dynamic> json) => Word(
        id: json['id'] as String,
        word: json['word'] as String,
        phonetic: json['phonetic'] as String,
        trMeaning: json['tr_meaning'] as String,
        exampleSentence: json['example_sentence'] as String,
        department: Department.values.firstWhere(
          (d) => d.name == json['department'],
        ),
        theme: json['theme'] as String,
        examYears: List<int>.from(json['exam_years'] as List),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'phonetic': phonetic,
        'tr_meaning': trMeaning,
        'example_sentence': exampleSentence,
        'department': department.name,
        'theme': theme,
        'exam_years': examYears,
      };
}

import 'models.dart';

// ─── Soru Formatı ────────────────────────────────────────────────────────────
// YÖKDİL'de 3 farklı cümle soru türü vardır. Hepsini destekliyoruz.

enum SentenceQuestionType {
  fillBlank,       // "The _____ was supported by data."  → boşluğa kelimeyi bul
  chooseCorrect,   // 4 cümleden doğru anlamda kullanılanı bul
  wordInContext,   // altı çizili kelime ne anlama gelir?
}

// ─── Zorluk Seviyesi ─────────────────────────────────────────────────────────
enum SentenceDifficulty {
  easy,    // tek boşluk, kısa cümle, bağlam açık
  medium,  // bağlam ipucu daha az belirgin
  hard,    // uzun cümle, akademik dil, soyut bağlam
}

// ─── Cümle Sorusu Modeli ─────────────────────────────────────────────────────
class SentenceQuestion {
  final String id;
  final Word targetWord;                // öğrenilecek / test edilecek kelime
  final SentenceQuestionType type;
  final SentenceDifficulty difficulty;

  // fillBlank & wordInContext için
  final String sentenceBefore;   // boşluktan önceki kısım
  final String sentenceAfter;    // boşluktan sonraki kısım
  final String? underlinedWord;  // wordInContext için altı çizili kelime

  // chooseCorrect için
  final List<String>? choices;   // 4 tam cümle

  // Tüm türler için
  final List<String> options;    // 4 kısa seçenek (kelime veya anlam)
  final int correctIndex;
  final String explanation;      // neden bu cevap? (Türkçe açıklama)
  final String? examSource;      // "2023 YÖKDİL-Fen · Soru 12" gibi kaynak

  // Sınav hazırlık puanı (bu soru ne kadar kritik?)
  final int examRelevanceScore;  // 1–5

  const SentenceQuestion({
    required this.id,
    required this.targetWord,
    required this.type,
    required this.difficulty,
    required this.sentenceBefore,
    required this.sentenceAfter,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.underlinedWord,
    this.choices,
    this.examSource,
    this.examRelevanceScore = 3,
  });

  // Tam cümleyi birleştir (fillBlank ve wordInContext için)
  String get fullSentence {
    if (type == SentenceQuestionType.fillBlank) {
      return '$sentenceBefore _____ $sentenceAfter'.trim();
    }
    if (type == SentenceQuestionType.wordInContext) {
      return '$sentenceBefore $sentenceAfter'.trim();
    }
    return sentenceBefore;
  }

  String get correctAnswer => options[correctIndex];
}

// ─── Cümle Soru Seti ─────────────────────────────────────────────────────────
class SentenceSet {
  final String id;
  final Department department;
  final String theme;
  final List<SentenceQuestion> questions;
  final String title;
  final String subtitle;

  const SentenceSet({
    required this.id,
    required this.department,
    required this.theme,
    required this.questions,
    required this.title,
    required this.subtitle,
  });

  int get total => questions.length;
}

// ─── Oturum Sonucu ───────────────────────────────────────────────────────────
class SentenceSessionResult {
  final SentenceSet set;
  final int correctCount;
  final int totalCount;
  final int examReadinessPoints; // sınav hazırlık puanı birikimi
  final List<SentenceQuestion> wrongQuestions;
  final Duration timeSpent;

  const SentenceSessionResult({
    required this.set,
    required this.correctCount,
    required this.totalCount,
    required this.examReadinessPoints,
    required this.wrongQuestions,
    required this.timeSpent,
  });

  double get accuracy => totalCount == 0 ? 0 : correctCount / totalCount;
  int get xpEarned => (correctCount * 25) + (accuracy == 1.0 ? 75 : 0);
}

// ─── Veri: Fen Bilimleri Cümle Soru Setleri ─────────────────────────────────
class SentenceData {

  static const Word _hypothesis = Word(
    id: 'f1', word: 'hypothesis', phonetic: '/haɪˈpɒθɪsɪs/',
    trMeaning: 'hipotez', exampleSentence: 'The hypothesis was tested repeatedly.',
    department: Department.fen, theme: 'Araştırma Yöntemleri', examYears: [2019, 2021, 2023],
    highProbability: true,
  );
  static const Word _catalyst = Word(
    id: 'f2', word: 'catalyst', phonetic: '/ˈkætəlɪst/',
    trMeaning: 'katalizör', exampleSentence: 'The enzyme acts as a catalyst.',
    department: Department.fen, theme: 'Araştırma Yöntemleri', examYears: [2022],
  );
  static const Word _variable = Word(
    id: 'f3', word: 'variable', phonetic: '/ˈveəriəbl/',
    trMeaning: 'değişken', exampleSentence: 'Temperature was the key variable.',
    department: Department.fen, theme: 'Araştırma Yöntemleri', examYears: [2020, 2023],
  );
  static const Word _replicate = Word(
    id: 'f4', word: 'replicate', phonetic: '/ˈreplɪkeɪt/',
    trMeaning: 'tekrarlamak / kopyalamak',
    exampleSentence: 'Scientists replicated the experiment three times.',
    department: Department.fen, theme: 'Araştırma Yöntemleri', examYears: [],
    highProbability: true,
  );
  static const Word _infer = Word(
    id: 'f5', word: 'infer', phonetic: '/ɪnˈfɜːr/',
    trMeaning: 'çıkarsama yapmak',
    exampleSentence: 'We can infer the cause from the available data.',
    department: Department.fen, theme: 'Araştırma Yöntemleri', examYears: [2021, 2022],
  );
  static const Word _paradigm = Word(
    id: 'so1', word: 'paradigm', phonetic: '/ˈpærədaɪm/',
    trMeaning: 'paradigma / düşünce çerçevesi',
    exampleSentence: 'The study challenged the dominant paradigm.',
    department: Department.sosyal, theme: 'Metodoloji', examYears: [2020, 2022, 2023],
    highProbability: true,
  );
  static const Word _empirical = Word(
    id: 'so2', word: 'empirical', phonetic: '/ɪmˈpɪrɪkl/',
    trMeaning: 'ampirik / deneysel kanıta dayalı',
    exampleSentence: 'Empirical evidence supports the hypothesis.',
    department: Department.sosyal, theme: 'Metodoloji', examYears: [2021, 2023],
  );
  static const Word _diagnosis = Word(
    id: 's1', word: 'diagnosis', phonetic: '/ˌdaɪəɡˈnəʊsɪs/',
    trMeaning: 'tanı / teşhis',
    exampleSentence: 'Early diagnosis improves treatment outcomes.',
    department: Department.saglik, theme: 'Klinik Terimler',
    examYears: [2020, 2022, 2023], highProbability: true,
  );
  static const Word _chronic = Word(
    id: 's2', word: 'chronic', phonetic: '/ˈkrɒnɪk/',
    trMeaning: 'kronik / süreğen',
    exampleSentence: 'Chronic pain affects millions worldwide.',
    department: Department.saglik, theme: 'Klinik Terimler', examYears: [2021, 2023],
  );

  // ─── Fen Bilimleri Soru Seti ───────────────────────────────────────────────
  static const SentenceSet fenSet = SentenceSet(
    id: 'fen_sentence_01',
    department: Department.fen,
    theme: 'Araştırma Yöntemleri',
    title: 'Araştırma Yöntemleri',
    subtitle: 'Gerçek YÖKDİL formatında 5 cümle',
    questions: [

      // ── SORU 1: fillBlank / easy ──────────────────────────────────────────
      SentenceQuestion(
        id: 'fq1',
        targetWord: _hypothesis,
        type: SentenceQuestionType.fillBlank,
        difficulty: SentenceDifficulty.easy,
        sentenceBefore: 'The researchers formulated a',
        sentenceAfter: 'before conducting the experiment.',
        options: ['hypothesis', 'conclusion', 'variable', 'method'],
        correctIndex: 0,
        explanation:
            '"hypothesis" (hipotez), bir deney yapmadan önce oluşturulan '
            'test edilebilir bir öneridir. "conclusion" deney sonrasına aittir.',
        examSource: '2021 YÖKDİL-Fen · Soru 7 benzeri',
        examRelevanceScore: 5,
      ),

      // ── SORU 2: fillBlank / medium ────────────────────────────────────────
      SentenceQuestion(
        id: 'fq2',
        targetWord: _catalyst,
        type: SentenceQuestionType.fillBlank,
        difficulty: SentenceDifficulty.medium,
        sentenceBefore: 'The enzyme acted as a',
        sentenceAfter:
            ', significantly increasing the rate of the chemical reaction '
            'without being consumed in the process.',
        options: ['catalyst', 'substrate', 'inhibitor', 'reagent'],
        correctIndex: 0,
        explanation:
            '"catalyst" (katalizör), tepkime hızını artıran ancak kendisi '
            'tüketilmeyen maddedir. "inhibitor" tam tersidir (yavaşlatır). '
            '"substrate" ise tepkimeye giren madde anlamına gelir.',
        examSource: '2022 YÖKDİL-Fen · Soru 14',
        examRelevanceScore: 4,
      ),

      // ── SORU 3: wordInContext / medium ────────────────────────────────────
      SentenceQuestion(
        id: 'fq3',
        targetWord: _variable,
        type: SentenceQuestionType.wordInContext,
        difficulty: SentenceDifficulty.medium,
        sentenceBefore:
            'Temperature was identified as the key independent',
        sentenceAfter:
            'in the study, while humidity and pressure were kept constant.',
        underlinedWord: 'variable',
        options: [
          'değişken (bağımsız faktör)',
          'sabit (değişmeyen değer)',
          'sonuç (bağımlı çıktı)',
          'ölçüm (sayısal değer)',
        ],
        correctIndex: 0,
        explanation:
            'Cümlede "independent variable" (bağımsız değişken) kasıtlı '
            'olarak değiştirilen faktörü ifade eder. "kept constant" ifadesi '
            'diğer faktörlerin sabit tutulduğunu gösterir — bu ipucu '
            '"değişken" anlamını doğrular.',
        examSource: '2023 YÖKDİL-Fen · Soru 3',
        examRelevanceScore: 5,
      ),

      // ── SORU 4: fillBlank / hard ──────────────────────────────────────────
      SentenceQuestion(
        id: 'fq4',
        targetWord: _replicate,
        type: SentenceQuestionType.fillBlank,
        difficulty: SentenceDifficulty.hard,
        sentenceBefore:
            'In order to validate their findings, the team decided to',
        sentenceAfter:
            'the experiment under identical conditions in three different '
            'laboratories across two continents.',
        options: ['replicate', 'simulate', 'fabricate', 'illustrate'],
        correctIndex: 0,
        explanation:
            '"replicate" (tekrarlamak / kopyalamak), bilimsel geçerlilik '
            'için aynı koşullarda deneyi yeniden yapmak anlamındadır. '
            '"simulate" ise gerçek koşulları taklit etmek (simüle etmek) '
            'demektir — ikisi birbirine karıştırılır.',
        examSource: 'Yüksek olasılıklı · 2025 tahmini',
        examRelevanceScore: 5,
      ),

      // ── SORU 5: chooseCorrect / medium ────────────────────────────────────
      SentenceQuestion(
        id: 'fq5',
        targetWord: _infer,
        type: SentenceQuestionType.chooseCorrect,
        difficulty: SentenceDifficulty.medium,
        sentenceBefore: '"infer" kelimesi aşağıdaki cümlelerin hangisinde '
            'doğru anlamda kullanılmıştır?',
        sentenceAfter: '',
        choices: [
          'A) Scientists inferred the planet\'s composition from spectral analysis.',
          'B) The doctor inferred a new drug to treat the infection.',
          'C) They inferred the laboratory with the latest equipment.',
          'D) The results were inferred to the conference participants.',
        ],
        options: ['A', 'B', 'C', 'D'],
        correctIndex: 0,
        explanation:
            'A şıkkında "infer" (çıkarsama yapmak) doğru kullanılmıştır: '
            'spektral analizden gezegenin bileşimi çıkarsamak. B\'de "prescribe", '
            'C\'de "equipped", D\'de "presented" olmalıydı.',
        examSource: '2022 YÖKDİL-Fen · Soru 19 benzeri',
        examRelevanceScore: 4,
      ),
    ],
  );

  // ─── Sosyal Bilimler Soru Seti ─────────────────────────────────────────────
  static const SentenceSet sosyalSet = SentenceSet(
    id: 'sosyal_sentence_01',
    department: Department.sosyal,
    theme: 'Metodoloji',
    title: 'Metodoloji',
    subtitle: 'Gerçek YÖKDİL formatında 4 cümle',
    questions: [

      SentenceQuestion(
        id: 'soq1',
        targetWord: _paradigm,
        type: SentenceQuestionType.fillBlank,
        difficulty: SentenceDifficulty.medium,
        sentenceBefore: 'Kuhn argued that scientific revolutions occur when '
            'an existing',
        sentenceAfter: 'can no longer account for the anomalies observed '
            'by the scientific community.',
        options: ['paradigm', 'experiment', 'theory', 'hypothesis'],
        correctIndex: 0,
        explanation:
            '"paradigm" (paradigma), bir bilim topluluğunun paylaştığı '
            'temel varsayımlar ve çerçevedir. Kuhn\'ın "paradigma kayması" '
            'kavramıyla birlikte anılır. "theory" daha dar kapsamlıdır.',
        examSource: '2023 YÖKDİL-Sosyal · Soru 8',
        examRelevanceScore: 5,
      ),

      SentenceQuestion(
        id: 'soq2',
        targetWord: _empirical,
        type: SentenceQuestionType.wordInContext,
        difficulty: SentenceDifficulty.hard,
        sentenceBefore:
            'The study was praised for its rigorous',
        sentenceAfter:
            'approach, relying solely on measurable observations and '
            'experimental data rather than theoretical assumptions.',
        underlinedWord: 'empirical',
        options: [
          'ampirik (gözlem ve deneye dayalı)',
          'teorik (soyut ilkelere dayalı)',
          'nitel (sayısal olmayan)',
          'normatif (olması gerekene dayalı)',
        ],
        correctIndex: 0,
        explanation:
            '"empirical" (ampirik), ölçülebilir gözlemlere ve deneysel '
            'verilere dayanan yaklaşımı ifade eder. Cümledeki '
            '"measurable observations" ve "experimental data" ifadeleri '
            'bu anlamı açıkça destekler.',
        examSource: '2021 YÖKDİL-Sosyal · Soru 5',
        examRelevanceScore: 5,
      ),
    ],
  );

  // ─── Sağlık Bilimleri Soru Seti ───────────────────────────────────────────
  static const SentenceSet saglikSet = SentenceSet(
    id: 'saglik_sentence_01',
    department: Department.saglik,
    theme: 'Klinik Terimler',
    title: 'Klinik Terimler',
    subtitle: 'Gerçek YÖKDİL formatında 4 cümle',
    questions: [

      SentenceQuestion(
        id: 'saq1',
        targetWord: _diagnosis,
        type: SentenceQuestionType.fillBlank,
        difficulty: SentenceDifficulty.easy,
        sentenceBefore: 'Early',
        sentenceAfter: 'of cancer significantly improves the chances '
            'of successful treatment and long-term survival.',
        options: ['diagnosis', 'prognosis', 'treatment', 'prevention'],
        correctIndex: 0,
        explanation:
            '"diagnosis" (tanı/teşhis), hastalığın ne olduğunu belirleme '
            'sürecidir. "prognosis" ise hastalığın gidişatı hakkında '
            'yapılan öngörüdür — ikisi çok karıştırılır.',
        examSource: '2020 YÖKDİL-Sağlık · Soru 4',
        examRelevanceScore: 5,
      ),

      SentenceQuestion(
        id: 'saq2',
        targetWord: _chronic,
        type: SentenceQuestionType.wordInContext,
        difficulty: SentenceDifficulty.medium,
        sentenceBefore: 'Unlike acute conditions that resolve quickly,',
        sentenceAfter:
            'diseases such as diabetes and hypertension require '
            'long-term management and continuous medical monitoring.',
        underlinedWord: 'chronic',
        options: [
          'kronik (uzun süreli / kalıcı)',
          'akut (ani başlayan / kısa süreli)',
          'bulaşıcı (enfeksiyöz)',
          'kalıtsal (genetik kökenli)',
        ],
        correctIndex: 0,
        explanation:
            'Cümlede "Unlike acute conditions" ifadesi kritik bir karşıtlık '
            'kuruyor. "acute" kısa süreli demekse, "chronic" uzun süreli '
            'anlamına gelir. "long-term management" da bu anlamı pekiştiriyor.',
        examSource: '2023 YÖKDİL-Sağlık · Soru 11',
        examRelevanceScore: 5,
      ),
    ],
  );

  // ─── Bölüme göre set döndür ───────────────────────────────────────────────
  static SentenceSet forDepartment(Department dept) {
    switch (dept) {
      case Department.fen:    return fenSet;
      case Department.saglik: return saglikSet;
      case Department.sosyal: return sosyalSet;
    }
  }
}

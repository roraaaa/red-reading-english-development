import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:red/data/services/pdf_service.dart';
import 'package:red/domain/models/attempt.dart';
import 'package:red/domain/models/passage.dart';
import 'package:red/domain/models/reading_result.dart';
import 'package:red/domain/use_cases/reading_evaluator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final json = jsonDecode(File('assets/content/materials/pink.json').readAsStringSync()) as Map<String, dynamic>;
  // José Rizal has accented letters, which must survive the font fallback.
  final passage = (json['passages'] as List)
      .map((p) => Passage.fromJson(p as Map<String, dynamic>))
      .firstWhere((p) => p.id == 'jose-rizal');

  bool isPdf(List<int> bytes) => bytes.length > 1000 && ascii.decode(bytes.sublist(0, 5)) == '%PDF-';

  test('builds a printable worksheet for a story', () async {
    final bytes = await PdfService().buildPassageWorksheet(passage, levelLabel: 'Level 5 Pink');
    expect(isPdf(bytes), isTrue);
  });

  test('builds a results report', () async {
    final correctById = {for (final q in passage.questions) q.id: q.id != 'q2'};
    final result = ReadingResult(
      kind: AttemptKind.assessment,
      passage: passage,
      responses: {for (final q in passage.questions) q.id: 'an answer'},
      correctById: correctById,
      correct: 4,
      total: 5,
      stars: 2,
      skillBreakdown: ReadingEvaluator.skillBreakdown(passage.questions, correctById),
      skillsToPractice: ReadingEvaluator.skillsToPractice(passage.questions, correctById),
      completedAt: DateTime(2026, 9, 15, 14, 30),
      readingTime: const Duration(seconds: 95),
      wordsPerMinute: 180,
      speed: ReadingSpeed.fast,
      verdict: ReadingEvaluator.verdict(ReadingSpeed.fast, 4, 5),
    );
    final bytes = await PdfService().buildResultReport(result, readerName: 'Test Reader');
    expect(isPdf(bytes), isTrue);
  });
}

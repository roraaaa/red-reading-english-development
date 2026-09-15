import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/models/passage.dart';
import '../../domain/models/question.dart';
import '../../domain/models/reading_result.dart';

/// Builds printable PDFs of reading cards and result reports, and hands them
/// to the platform print / share sheet.
class PdfService {
  static const _red = PdfColor.fromInt(0xFFCC3F28);
  static const _ink = PdfColor.fromInt(0xFF2A2340);
  static const _soft = PdfColor.fromInt(0xFF625B75);
  static const _tint = PdfColor.fromInt(0xFFFFF1E8);
  static const _green = PdfColor.fromInt(0xFF17804F);

  pw.ThemeData? _theme;

  Future<pw.ThemeData> _loadTheme() async {
    if (_theme != null) return _theme!;
    try {
      _theme = pw.ThemeData.withFont(
        base: await PdfGoogleFonts.lexendRegular(),
        bold: await PdfGoogleFonts.lexendSemiBold(),
      );
    } catch (e) {
      // Offline: fall back to the built-in PDF font.
      debugPrint('PDF fonts unavailable, using Helvetica: $e');
      _theme = pw.ThemeData.base();
    }
    return _theme!;
  }

  /// A worksheet: the story followed by its questions with space to write.
  Future<Uint8List> buildPassageWorksheet(Passage passage, {String? levelLabel}) async {
    final doc = pw.Document(title: passage.title, author: 'RED - Reading English Development');
    doc.addPage(
      pw.MultiPage(
        theme: await _loadTheme(),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: _footer,
        build: (context) => [
          _header(passage.title, [passage.topic, ?levelLabel].join('  |  ')),
          pw.SizedBox(height: 16),
          for (final paragraph in passage.paragraphs)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Text(paragraph, style: const pw.TextStyle(fontSize: 12.5, lineSpacing: 4, color: _ink)),
            ),
          pw.SizedBox(height: 12),
          _sectionTitle('Questions'),
          pw.Text('Name: ______________________    Date: ____________',
              style: const pw.TextStyle(fontSize: 11, color: _soft)),
          pw.SizedBox(height: 12),
          for (final (i, q) in passage.questions.indexed) _worksheetQuestion(i + 1, q),
        ],
      ),
    );
    return doc.save();
  }

  /// A report of a finished Assess or Materials session.
  Future<Uint8List> buildResultReport(ReadingResult result, {required String readerName}) async {
    final doc = pw.Document(title: '${result.passage.title} results', author: 'RED - Reading English Development');
    final date = DateFormat.yMMMMd().add_jm().format(result.completedAt);
    doc.addPage(
      pw.MultiPage(
        theme: await _loadTheme(),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: _footer,
        build: (context) => [
          _header(
            result.isAssessment ? 'Reading Assessment Results' : 'Reading Practice Results',
            '$readerName  |  ${result.passage.title}  |  $date',
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(color: _tint, borderRadius: pw.BorderRadius.circular(10)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _stat('Score', '${result.correct} / ${result.total}'),
                _stat('Stars', '${result.stars} of 3'),
                if (result.readingTime != null)
                  _stat('Reading time', '${(result.readingTime!.inMilliseconds / 1000).toStringAsFixed(1)} s'),
                if (result.wordsPerMinute != null) _stat('Speed', '${result.wordsPerMinute} words/min'),
              ],
            ),
          ),
          if (result.verdict != null) ...[
            pw.SizedBox(height: 10),
            pw.Text(result.verdict!, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _ink)),
          ],
          pw.SizedBox(height: 16),
          _sectionTitle('Answers'),
          for (final (i, q) in result.passage.questions.indexed) _answerRow(i + 1, q, result),
          if (result.skillsToPractice.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _sectionTitle('Advice'),
            for (final skill in result.skillsToPractice)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(skill.adviceTitle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _ink)),
                    pw.Text(skill.advice, style: const pw.TextStyle(fontSize: 11, color: _soft, lineSpacing: 2)),
                  ],
                ),
              ),
          ],
          pw.SizedBox(height: 12),
          _sectionTitle('Skills'),
          for (final s in result.skillBreakdown)
            pw.Text('${s.skill.label}: ${s.correct} of ${s.total} correct',
                style: const pw.TextStyle(fontSize: 11, color: _ink)),
        ],
      ),
    );
    return doc.save();
  }

  /// Opens the system print dialog (which also offers "Save as PDF").
  Future<void> printPdf(Uint8List bytes, String name) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: name);

  /// Saves or shares the PDF file (downloads it on the web).
  Future<void> savePdf(Uint8List bytes, String fileName) =>
      Printing.sharePdf(bytes: bytes, filename: fileName);

  static String fileNameFor(String title, {String suffix = ''}) {
    final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    return 'RED-$slug$suffix.pdf';
  }

  pw.Widget _header(String title, String subtitle) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('RED  -  Reading English Development',
          style: pw.TextStyle(fontSize: 10, color: _red, fontWeight: pw.FontWeight.bold, letterSpacing: 1)),
      pw.SizedBox(height: 6),
      pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: _ink)),
      pw.SizedBox(height: 4),
      pw.Text(subtitle, style: const pw.TextStyle(fontSize: 11, color: _soft)),
      pw.SizedBox(height: 10),
      pw.Container(height: 3, width: 60, color: _red),
    ],
  );

  pw.Widget _sectionTitle(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(text, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _red)),
  );

  pw.Widget _stat(String label, String value) => pw.Column(
    children: [
      pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _ink)),
      pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _soft)),
    ],
  );

  pw.Widget _worksheetQuestion(int number, Question q) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 14),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$number. ${q.prompt}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _ink)),
        pw.SizedBox(height: 6),
        if (q.type == QuestionType.choice)
          for (final (i, option) in q.options.indexed)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 12, bottom: 3),
              child: pw.Text('( ${String.fromCharCode(65 + i)} )  $option', style: const pw.TextStyle(color: _ink)),
            )
        else
          for (var line = 0; line < 2; line++)
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 16, left: 12),
              height: 1,
              color: PdfColors.grey400,
            ),
      ],
    ),
  );

  pw.Widget _answerRow(int number, Question q, ReadingResult result) {
    final correct = result.correctById[q.id] ?? false;
    final response = result.responses[q.id]?.trim() ?? '';
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$number. ${q.prompt}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _ink)),
          pw.Text(
            '${correct ? 'Correct' : 'Not quite'}  -  Your answer: ${response.isEmpty ? '(no answer)' : response}',
            style: pw.TextStyle(fontSize: 11, color: correct ? _green : _red),
          ),
          if (!correct)
            pw.Text('Correct answer: ${q.correctAnswerLabel}', style: const pw.TextStyle(fontSize: 11, color: _soft)),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context) => pw.Container(
    alignment: pw.Alignment.centerRight,
    margin: const pw.EdgeInsets.only(top: 12),
    child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: _soft)),
  );
}

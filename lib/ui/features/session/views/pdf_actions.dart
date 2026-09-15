import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/pdf_service.dart';
import '../../../../domain/models/passage.dart';
import '../../../../domain/models/reading_result.dart';

/// UI glue between the screens and [PdfService]: builds the PDF, opens the
/// print or save sheet and reports problems kindly.
abstract final class PdfActions {
  static Future<void> printPassage(BuildContext context, Passage passage, {String? levelLabel}) =>
      _run(context, () async {
        final pdf = context.read<PdfService>();
        final bytes = await pdf.buildPassageWorksheet(passage, levelLabel: levelLabel);
        await pdf.printPdf(bytes, passage.title);
      });

  static Future<void> savePassage(BuildContext context, Passage passage, {String? levelLabel}) =>
      _run(context, () async {
        final pdf = context.read<PdfService>();
        final bytes = await pdf.buildPassageWorksheet(passage, levelLabel: levelLabel);
        await pdf.savePdf(bytes, PdfService.fileNameFor(passage.title));
      }, successMessage: 'Your story PDF is ready!');

  static Future<void> saveResult(BuildContext context, ReadingResult result) =>
      _run(context, () async {
        final pdf = context.read<PdfService>();
        final name = context.read<AuthRepository>().currentUser?.displayName ?? 'Reader';
        final bytes = await pdf.buildResultReport(result, readerName: name);
        await pdf.savePdf(bytes, PdfService.fileNameFor(result.passage.title, suffix: '-results'));
      }, successMessage: 'Your results PDF is ready!');

  static Future<void> _run(BuildContext context, Future<void> Function() action, {String? successMessage}) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Making your PDF...'), duration: Duration(seconds: 2)));
    try {
      await action();
      messenger.hideCurrentSnackBar();
      if (successMessage != null) {
        messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      debugPrint('PDF error: $e');
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Sorry, the PDF could not be made. Please try again.')));
    }
  }
}

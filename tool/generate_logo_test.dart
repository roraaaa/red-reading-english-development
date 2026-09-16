// Renders the drawn RED mascot to PNG files.
//
// Not part of the normal test suite (that only scans test/). Run it with:
//   flutter test tool/generate_logo_test.dart
//
// It writes:
//   assets/images/red_panda.png            transparent, used all over the app
//   assets/images/app_icon.png             on cream, used for the launcher icon
//   assets/images/app_icon_foreground.png  transparent with Android's safe-zone
//                                          padding, for the adaptive icon
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red/ui/core/widgets/red_panda_logo.dart';
import 'package:red/ui/core/theme/app_colors.dart';

/// [pandaFraction] is how much of the square the mascot fills. Android only
/// guarantees the middle ~66% of an adaptive icon is visible, so the
/// foreground layer keeps the mascot well inside that.
Future<void> render(String path, {required double pandaFraction, Color? background, int size = 1024}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final square = size.toDouble();

  if (background != null) {
    canvas.drawRect(Rect.fromLTWH(0, 0, square, square), Paint()..color = background);
  }

  final panda = square * pandaFraction;
  final offset = (square - panda) / 2;
  canvas.translate(offset, offset);
  RedPandaPainter().paint(canvas, Size(panda, panda));

  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
  debugPrint('wrote $path (${(file.lengthSync() / 1024).round()} KB)');
}

void main() {
  testWidgets('render the mascot to PNG files', (tester) async {
    await tester.runAsync(() async {
      await render('assets/images/red_panda.png', pandaFraction: 0.94);
      await render('assets/images/app_icon.png', pandaFraction: 0.78, background: AppColors.background);
      await render('assets/images/app_icon_foreground.png', pandaFraction: 0.58);
    });

    for (final name in ['red_panda.png', 'app_icon.png', 'app_icon_foreground.png']) {
      expect(File('assets/images/$name').existsSync(), isTrue, reason: name);
    }
  });
}

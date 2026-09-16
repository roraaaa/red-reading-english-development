import 'package:flutter/material.dart';

import '../../../domain/models/passage.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';
import 'surfaces.dart';

/// The picture for a reading card. Shows the story's photo when it has one,
/// and falls back to the colourful icon cover if there is no photo or it
/// cannot be loaded (for example, an online photo while offline).
class StoryCover extends StatelessWidget {
  const StoryCover({
    super.key,
    required this.passage,
    required this.color,
    this.height = 160,
    this.radius = 28,
    this.iconSize,
  });

  final Passage passage;
  final Color color;
  final double height;
  final double radius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final fallback = TopicCover(
      icon: passage.icon,
      color: color,
      height: height,
      radius: radius,
      iconSize: iconSize,
    );
    final image = passage.image;
    if (image == null) return fallback;

    Widget errorFallback(BuildContext context, Object error, StackTrace? stack) => fallback;
    final picture = image.startsWith('https://')
        ? Image.network(
            image,
            fit: BoxFit.cover,
            errorBuilder: errorFallback,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : ColoredBox(color: color.tint),
          )
        : Image.asset(image, fit: BoxFit.cover, errorBuilder: errorFallback);

    // Decorative: the title is always shown next to the picture.
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(height: height, width: double.infinity, child: picture),
      ),
    );
  }
}

/// A small "Photo: author (licence)" line. Tapping it shows where the photo
/// came from, as open licences ask.
class PhotoCredit extends StatelessWidget {
  const PhotoCredit({super.key, required this.credit});

  final ImageCredit credit;

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Photo credit', style: AppTheme.display(size: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By ${credit.author}', style: AppTheme.body()),
            const SizedBox(height: 4),
            Text('Licence: ${credit.license}', style: AppTheme.body()),
            const SizedBox(height: 12),
            Text('Source', style: AppTheme.body(size: 13, color: AppColors.inkSoft)),
            SelectableText(credit.source, style: AppTheme.body(size: 13)),
            if (credit.licenseUrl case final url? when url.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Licence details', style: AppTheme.body(size: 13, color: AppColors.inkSoft)),
              SelectableText(url, style: AppTheme.body(size: 13)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => _showDetails(context),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.inkSoft,
          minimumSize: const Size(48, 36),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: Text(
          credit.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.body(size: 11, color: AppColors.inkSoft),
        ),
      ),
    );
  }
}

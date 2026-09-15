import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum ChunkyVariant { primary, secondary, soft }

/// A big, friendly "3D" button: it has a darker bottom edge and sinks when
/// pressed. At least 56px tall so small fingers can hit it easily.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = ChunkyVariant.primary,
    this.color,
    this.edgeColor,
    this.foregroundColor,
    this.expand = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ChunkyVariant variant;
  final Color? color;
  final Color? edgeColor;
  final Color? foregroundColor;
  final bool expand;
  final bool isLoading;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  static const _edge = 5.0;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final (face, edge, foreground) = switch (widget.variant) {
      ChunkyVariant.primary => (AppColors.primary, AppColors.primaryDeep, Colors.white),
      ChunkyVariant.secondary => (AppColors.surface, AppColors.outline, AppColors.ink),
      ChunkyVariant.soft => (AppColors.primaryTint, const Color(0xFFF2BFAE), AppColors.primaryDeep),
    };
    final faceColor = _enabled ? (widget.color ?? face) : const Color(0xFFEDE5DC);
    final edgeColor = _enabled ? (widget.edgeColor ?? edge) : const Color(0xFFDCD2C7);
    final fg = _enabled ? (widget.foregroundColor ?? foreground) : AppColors.inkSoft;
    final sink = _pressed ? _edge - 1 : 0.0;

    final content = widget.isLoading
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 3, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: 24),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: AppTheme.display(size: 19, color: fg, weight: FontWeight.w600),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.isLoading ? '${widget.label}, loading' : null,
      child: Padding(
        padding: EdgeInsets.only(top: sink),
        child: Container(
          width: widget.expand ? double.infinity : null,
          decoration: BoxDecoration(
            color: edgeColor,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.only(bottom: _edge - sink),
          child: Material(
            color: faceColor,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _enabled ? widget.onPressed : null,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  child: Center(widthFactor: 1, child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

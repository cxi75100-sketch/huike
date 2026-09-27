import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'glass_dialog.dart';
import 'glass_metrics.dart';
import 'glass_motion.dart';
import 'glass_surface.dart';

/// Native TextField input behavior inside a shared glass control surface.
class GlassTextField extends StatefulWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    required this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autofocus = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    final focused = _focused || widget.focusNode?.hasFocus == true;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final radius = BorderRadius.circular(GlassMetrics.controlRadius);

    return AnimatedContainer(
      duration: reducedMotion ? Duration.zero : GlassMotion.fast,
      curve: GlassMotion.enter,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: focused ? palette.accent : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: GlassSurface(
        radius: GlassMetrics.controlRadius,
        intensity: GlassIntensity.subtle,
        blurSigma: 0,
        showEdge: !focused,
        tint: focused ? palette.accent.withValues(alpha: 0.1) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Focus(
          onFocusChange: (value) {
            if (_focused != value) setState(() => _focused = value);
          },
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            autofillHints: widget.autofillHints,
            inputFormatters: widget.inputFormatters,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            decoration: widget.decoration.copyWith(
              filled: false,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
    );
  }
}

/// A glass choice row that exposes radio-group semantics without a Material
/// RadioListTile surface.
class GlassSelectionRow extends StatelessWidget {
  const GlassSelectionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Semantics(
      container: true,
      label: label,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      onTap: onSelected,
      child: ExcludeSemantics(
        child: GlassSurface(
          interactive: true,
          onTap: onSelected,
          blurSigma: 0,
          radius: 12,
          depth: 0.15,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 10)],
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: selected ? palette.accent : palette.ink,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 20,
                  color: selected ? palette.accent : palette.inkTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A glass checkbox row for confirmations and optional import settings.
class GlassToggleRow extends StatelessWidget {
  const GlassToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    void toggle() => onChanged(!value);
    return Semantics(
      container: true,
      label: label,
      value: value ? '已选中' : '未选中',
      checked: value,
      onTap: toggle,
      child: ExcludeSemantics(
        child: GlassSurface(
          interactive: true,
          onTap: toggle,
          blurSigma: 0,
          radius: 12,
          depth: 0.15,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Icon(
                  value
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: value ? palette.accent : palette.inkTertiary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(fontSize: 14, color: palette.ink),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: palette.inkSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Labeled picker that opens a shared glass selection dialog.
class GlassPickerRow<T> extends StatelessWidget {
  const GlassPickerRow({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    var selectedLabel = '';
    for (final option in options) {
      if (option.$1 == value) {
        selectedLabel = option.$2;
        break;
      }
    }

    return Semantics(
      container: true,
      label: label,
      value: selectedLabel,
      button: true,
      onTap: () => _open(context),
      child: ExcludeSemantics(
        child: GlassSurface(
          interactive: true,
          onTap: () => _open(context),
          blurSigma: 0,
          radius: GlassMetrics.controlRadius,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 13, color: palette.inkSecondary),
                  ),
                ),
                Text(
                  selectedLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: palette.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more_rounded, color: palette.inkTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final selected = await showGlassDialog<T>(
      context: context,
      builder: (dialogContext) => GlassDialog(
        title: Text(label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < options.length; index++) ...[
              if (index > 0) const SizedBox(height: 6),
              GlassSelectionRow(
                label: options[index].$2,
                selected: options[index].$1 == value,
                onSelected: () =>
                    Navigator.of(dialogContext).pop(options[index].$1),
              ),
            ],
          ],
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }
}

/// Compact glass option used for short mutually exclusive choices such as
/// weekdays. It keeps the selected state available to assistive technology.
class GlassChoiceChip extends StatelessWidget {
  const GlassChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Semantics(
      container: true,
      label: label,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      onTap: onSelected,
      child: ExcludeSemantics(
        child: GlassSurface(
          interactive: true,
          onTap: onSelected,
          blurSigma: 0,
          radius: 18,
          depth: 0.15,
          tint: selected ? palette.accent.withValues(alpha: 0.13) : null,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 28),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: selected ? palette.accent : palette.inkSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

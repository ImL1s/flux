import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/flux_theme.dart';

enum FluxInputType {
  text,
  password,
  email,
  number,
  search,
  multiline,
}

/// A form input component for FluxUI.
///
/// Features:
/// - Validation logic support
/// - Types: text, password, email, number, search, multiline
/// - Prefix/Suffix icons
/// - Clear button (optional)
/// - Error state styling
class FluxInput extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final FluxInputType type;
  final bool enabled;
  final bool autofocus;
  final bool showClearButton;
  final TextEditingController? controller;

  const FluxInput({
    super.key,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.type = FluxInputType.text,
    this.enabled = true,
    this.autofocus = false,
    this.showClearButton = false,
    this.controller,
  });

  @override
  State<FluxInput> createState() => _FluxInputState();
}

class _FluxInputState extends State<FluxInput> {
  late TextEditingController _controller;
  bool _obscureText = false;
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _obscureText = widget.type == FluxInputType.password;
    _hasValue = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasValue = _controller.text.isNotEmpty;
    if (_hasValue != hasValue) {
      setState(() {
        _hasValue = hasValue;
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _toggleObscure() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  TextInputType _getKeyboardType() {
    switch (widget.type) {
      case FluxInputType.email:
        return TextInputType.emailAddress;
      case FluxInputType.number:
        return TextInputType.number;
      case FluxInputType.multiline:
        return TextInputType.multiline;
      case FluxInputType.search:
        return TextInputType.text; // handled by action
      default:
        return TextInputType.text;
    }
  }

  TextInputAction _getInputAction() {
    switch (widget.type) {
      case FluxInputType.search:
        return TextInputAction.search;
      case FluxInputType.multiline:
        return TextInputAction.newline;
      default:
        return TextInputAction.done;
    }
  }

  List<TextInputFormatter>? _getFormatters() {
    if (widget.type == FluxInputType.number) {
      return [FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]'))];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluxTheme.of(context);
    final colors = theme.colorScheme;
    final typography = theme.typography;

    Widget? suffix;
    if (widget.type == FluxInputType.password) {
      suffix = IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: colors.onSurfaceVariant,
        ),
        onPressed: _toggleObscure,
      );
    } else if (widget.showClearButton && _hasValue) {
      suffix = IconButton(
        icon: Icon(Icons.close, color: colors.onSurfaceVariant),
        onPressed: _clear,
      );
    } else if (widget.suffixIcon != null) {
      suffix = Icon(widget.suffixIcon, color: colors.onSurfaceVariant);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: typography.labelMedium.copyWith(
              color: widget.enabled
                  ? colors.onSurface
                  : colors.onSurface.withValues(alpha: 0.38),
            ),
          ),
          const SizedBox(height: FluxSpacing.xs),
        ],
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          obscureText: _obscureText,
          keyboardType: _getKeyboardType(),
          textInputAction: _getInputAction(),
          inputFormatters: _getFormatters(),
          maxLines: widget.type == FluxInputType.multiline ? null : 1,
          autofocus: widget.autofocus,
          style: typography.bodyLarge.copyWith(
            color: widget.enabled
                ? colors.onSurface
                : colors.onSurface.withValues(alpha: 0.38),
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: typography.bodyLarge.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: colors.onSurfaceVariant)
                : null,
            suffixIcon: suffix,
            filled: true,
            fillColor: widget.enabled
                ? colors.surfaceVariant.withValues(alpha: 0.3)
                : colors.onSurface
                    .withValues(alpha: 0.04), // lighter for disabled
            contentPadding: const EdgeInsets.symmetric(
                horizontal: FluxSpacing.md, vertical: FluxSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FluxRadius.sm),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FluxRadius.sm),
              borderSide:
                  BorderSide(color: colors.outline.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FluxRadius.sm),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FluxRadius.sm),
              borderSide: BorderSide(color: colors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(FluxRadius.sm),
              borderSide: BorderSide(color: colors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

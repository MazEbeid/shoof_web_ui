import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';

/// A styled text field widget for admin/web applications.
class AdminTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool filled;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;

  const AdminTextField({
    super.key,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.prefix,
    this.suffix,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.filled = true,
    this.fillColor,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AdminTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AdminSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          validator: validator,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          style: AdminTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AdminTextStyles.bodyMedium.copyWith(
              color: AdminColors.textMuted,
            ),
            helperText: helperText,
            helperStyle: AdminTextStyles.labelSmall.copyWith(
              color: AdminColors.textMuted,
            ),
            errorText: errorText,
            errorStyle: AdminTextStyles.labelSmall.copyWith(
              color: AdminColors.error,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: AdminColors.textSecondary)
                : prefix,
            suffix: suffix,
            suffixIcon: suffixIcon,
            filled: filled,
            fillColor: fillColor ?? AdminColors.backgroundHover,
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: AdminSpacing.md,
                  vertical: AdminSpacing.sm,
                ),
            border: OutlineInputBorder(
              borderRadius: AdminRadius.smAll,
              borderSide: const BorderSide(color: AdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AdminRadius.smAll,
              borderSide: BorderSide(color: AdminColors.border.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AdminRadius.smAll,
              borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AdminRadius.smAll,
              borderSide: const BorderSide(color: AdminColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AdminRadius.smAll,
              borderSide: const BorderSide(color: AdminColors.error, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AdminRadius.smAll,
              borderSide: BorderSide(color: AdminColors.border.withOpacity(0.3)),
            ),
          ),
        ),
      ],
    );
  }
}

/// A password field with visibility toggle
class AdminPasswordField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;

  const AdminPasswordField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.textInputAction,
  });

  @override
  State<AdminPasswordField> createState() => _AdminPasswordFieldState();
}

class _AdminPasswordFieldState extends State<AdminPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AdminTextField(
      label: widget.label,
      hintText: widget.hintText ?? 'Enter password',
      controller: widget.controller,
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      prefixIcon: Icons.lock_outlined,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: AdminColors.textSecondary,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      ),
    );
  }
}

/// A search field with search icon
class AdminSearchField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final double? width;

  const AdminSearchField({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AdminTextField(
        hintText: hintText ?? 'Search...',
        controller: controller,
        prefixIcon: Icons.search,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        suffix: controller != null && controller!.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
      ),
    );
  }
}

/// A dropdown field styled to match AdminTextField
class AdminDropdownField<T> extends StatelessWidget {
  final String? label;
  final String? hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  const AdminDropdownField({
    super.key,
    this.label,
    this.hintText,
    this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AdminTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AdminSpacing.xs),
        ],
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AdminColors.backgroundHover,
            borderRadius: AdminRadius.smAll,
            border: Border.all(color: AdminColors.border.withOpacity(0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: enabled ? onChanged : null,
              hint: hintText != null
                  ? Text(
                      hintText!,
                      style: AdminTextStyles.bodyMedium.copyWith(
                        color: AdminColors.textMuted,
                      ),
                    )
                  : null,
              isExpanded: true,
              style: AdminTextStyles.bodyMedium,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              dropdownColor: AdminColors.surface,
              borderRadius: AdminRadius.smAll,
            ),
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';

// Extension để thay thế withValues bằng withOpacity
extension ColorExtension on Color {
  Color withAlpha(double alpha) {
    return withOpacity(alpha);
  }
}

// Wrapper cho DropdownButtonFormField để xử lý initialValue -> value
class CompatDropdownButtonFormField<T> extends DropdownButtonFormField<T> {
  CompatDropdownButtonFormField({
    super.key,
    super.decoration,
    super.onSaved,
    super.validator,
    super.autovalidateMode,
    T? value,
    T? initialValue, // Deprecated parameter
    required super.items,
    super.onChanged,
    super.focusNode,
    super.autofocus = false,
    super.dropdownColor,
    super.elevation,
    super.style,
    super.icon,
    super.iconDisabledColor,
    super.iconEnabledColor,
    super.iconSize,
    super.isDense,
    super.isExpanded,
    super.itemHeight,
    super.hint,
    super.disabledHint,
    super.selectedItemBuilder,
  }) : super(
    initialValue: value ?? initialValue,
  );
}

// Wrapper cho Switch để xử lý activeThumbColor -> thumbColor
class CompatSwitch extends Switch {
  const CompatSwitch({super.key});

} 
  const CompatSwitch({
    super.key,
    required super.value,
    required super.onChanged,
    Color? activeThumbColor, // Deprecated parameter
    super.thumbColor,
    super.trackColor,
    super.thumbIcon,
    super.materialTapTargetSize,
    super.dragStartBehavior,
    super.mouseCursor,
    super.focusColor,
    super.hoverColor,
    super.overlayColor,
    super.splashRadius,
    super.focusNode,
    super.autofocus,
    super.onFocusChange,
  }) : super(
    thumbColor: thumbColor ?? (activeThumbColor != null 
        ? WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return activeThumbColor;
            }
            return null;
          })
        : null),
  );
}
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

/// Internal composition scope matching the Web chat icon and action roles.
class KChatAppearance extends StatefulWidget {
  const KChatAppearance({required this.child, super.key});
  final Widget child;

  @override
  State<KChatAppearance> createState() => _KChatAppearanceState();
}

class _KChatAppearanceState extends State<KChatAppearance> {
  ThemeData? _sourceTheme;
  late ThemeData _chatTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.extension<KDesignTokens>()!;
    if (!identical(theme, _sourceTheme)) {
      _sourceTheme = theme;
      _chatTheme = theme.copyWith(
        extensions: [
          ...theme.extensions.values.where((value) => value is! KDesignTokens),
          t.copyWith(
            sizeIconStroke: t.componentChatIconStroke,
            fontControlWeight: t.fontLabelWeight,
          ),
        ],
      );
    }
    return Theme(
      data: _chatTheme,
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontFamily: t.fontFamily,
          color: t.colorTextPrimary,
          fontSize: t.fontBodySmallSize,
          fontWeight: t.fontBodyWeight,
          height: t.fontBodySmallLineHeight / t.fontBodySmallSize,
        ),
        child: widget.child,
      ),
    );
  }
}

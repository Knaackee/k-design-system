import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

/// The consumer chooses the presentation; available width never changes it.
enum KDataTableDisplayMode { multiColumn, singleColumn }

/// A read-only row projection with consumer-owned content and action.
class KDataTableSingleColumn<T> {
  const KDataTableSingleColumn({
    required this.title,
    required this.onActivate,
    required this.semanticsLabel,
    required this.columnLabel,
    this.leading,
    this.trailing,
  });

  final Widget Function(T row) title;
  final Widget Function(T row)? leading;
  final Widget Function(T row)? trailing;
  final void Function(T row) onActivate;
  final String Function(T row) semanticsLabel;
  final String columnLabel;
}

class KDataTableSingleRow<T> extends StatelessWidget {
  const KDataTableSingleRow({
    required this.content,
    required this.row,
    super.key,
  });
  final KDataTableSingleColumn<T> content;
  final T row;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    return Semantics(
      label: content.semanticsLabel(row),
      button: true,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => content.onActivate(row),
        borderRadius: BorderRadius.circular(tokens.radiusControl),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: tokens.sizeHitTarget),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceControlInsetInline,
              vertical: tokens.spaceControlGap,
            ),
            child: Row(
              children: [
                if (content.leading != null) ...[
                  content.leading!(row),
                  SizedBox(width: tokens.spaceControlGap * 2 + 4),
                ],
                // From 1.3x the trailing value moves under the title so the
                // title keeps the row (Decision 0010).
                if (large && content.trailing != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: tokens.spaceMicro,
                      children: [content.title(row), content.trailing!(row)],
                    ),
                  )
                else ...[
                  Expanded(child: content.title(row)),
                  if (content.trailing != null) ...[
                    SizedBox(width: tokens.spaceControlGap),
                    content.trailing!(row),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

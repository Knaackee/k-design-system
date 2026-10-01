import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_icon.dart';
import 'k_select.dart';

class KOptionMedia extends StatelessWidget {
  const KOptionMedia(this.option, {super.key});
  final KSelectOption option;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final fallback = KIcon(option.icon ?? KIconName.user);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: t.sizeContent,
        child:
            option.leading ??
            (option.imageSrc == null
                ? fallback
                : ClipOval(
                    child: Image.network(
                      option.imageSrc!,
                      width: t.sizeContent,
                      height: t.sizeContent,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => fallback,
                    ),
                  )),
      ),
    );
  }
}

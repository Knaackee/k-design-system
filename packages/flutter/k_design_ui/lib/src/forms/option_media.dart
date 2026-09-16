import 'package:flutter/material.dart';
import '../primitives/k_icon.dart';
import 'k_select.dart';

class KOptionMedia extends StatelessWidget {
  const KOptionMedia(this.option, {super.key});
  final KSelectOption option;
  @override
  Widget build(BuildContext context) {
    final fallback = KIcon(option.icon ?? KIconName.user);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 16,
        child: option.imageSrc == null
            ? fallback
            : ClipOval(
                child: Image.network(
                  option.imageSrc!,
                  width: 16,
                  height: 16,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => fallback,
                ),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../primitives/k_icon.dart';
import 'k_menu_button.dart';

class KLanguageOption {
  const KLanguageOption({required this.value, required this.label, this.flag});
  final String value;
  final String label;
  final Widget? flag;
}

/// The host applies translations and persists the selected language.
class KLanguageSwitcher extends StatelessWidget {
  const KLanguageSwitcher({
    required this.value,
    required this.onChanged,
    required this.languages,
    this.label = 'Language',
    this.disabled = false,
    super.key,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final List<KLanguageOption> languages;
  final String label;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final selected = languages.where((item) => item.value == value).firstOrNull;
    return Tooltip(
      message: '$label: ${selected?.label ?? value}',
      excludeFromSemantics: true,
      child: KMenuButton(
        label: '$label: ${selected?.label ?? value}',
        overflow: true,
        alignEnd: true,
        disabled: disabled,
        triggerIcon: KIconName.languages,
        actions: [
          for (final language in languages)
            KMenuAction(
              id: language.value,
              label: language.label,
              iconContent: language.flag,
              checked: language.value == value,
              onSelect: () => onChanged(language.value),
            ),
        ],
      ),
    );
  }
}

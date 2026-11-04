import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'theme/consumer_theme.dart';

class ConsumerExampleApp extends StatelessWidget {
  const ConsumerExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'K Design System consumer',
    debugShowCheckedModeBanner: false,
    theme: consumerTheme(Brightness.light),
    darkTheme: consumerTheme(Brightness.dark),
    themeMode: ThemeMode.system,
    builder: consumerAdaptive,
    home: const ConsumerExamplePage(),
  );
}

class ConsumerExamplePage extends StatefulWidget {
  const ConsumerExamplePage({super.key});

  @override
  State<ConsumerExamplePage> createState() => _ConsumerExamplePageState();
}

class _ConsumerExamplePageState extends State<ConsumerExamplePage> {
  String _notificationLevel = 'important';
  String _workspaceName = '';
  int _savedCount = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceLayoutGutter),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const KText(
                    'Consumer-owned configuration',
                    variant: KTextVariant.heading2,
                  ),
                  SizedBox(height: tokens.spaceTight),
                  const KText(
                    'Components come from the submodule. Branding and state stay in this application.',
                    variant: KTextVariant.bodySmall,
                  ),
                  SizedBox(height: tokens.spaceLayoutSectionGap),
                  KCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const KText(
                          'Workspace settings',
                          variant: KTextVariant.heading4,
                        ),
                        SizedBox(height: tokens.spaceContentActionGap),
                        KInput(
                          label: 'Workspace name',
                          placeholder: 'Product Lab',
                          clearable: true,
                          onChanged: (value) =>
                              setState(() => _workspaceName = value),
                        ),
                        SizedBox(height: tokens.spaceContentActionGap),
                        KRadioGroup<String>(
                          label: 'Notifications',
                          value: _notificationLevel,
                          items: const [
                            KRadioOption(value: 'all', label: 'All updates'),
                            KRadioOption(
                              value: 'important',
                              label: 'Important updates only',
                            ),
                            KRadioOption(value: 'none', label: 'No updates'),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _notificationLevel = value);
                            }
                          },
                        ),
                        SizedBox(height: tokens.spaceContentActionGap),
                        KButton(
                          label: 'Save settings',
                          fullWidth: true,
                          onPressed: () => setState(() => _savedCount += 1),
                        ),
                        SizedBox(height: tokens.spaceTight),
                        KText(
                          _savedCount == 0
                              ? 'No changes saved yet'
                              : 'Saved $_savedCount time${_savedCount == 1 ? '' : 's'}: ${_workspaceName.isEmpty ? 'Product Lab' : _workspaceName}',
                          variant: KTextVariant.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

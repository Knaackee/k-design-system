import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_components.dart';
import '../forms/k_field.dart';
import '../forms/k_input.dart';
import '../forms/k_select.dart';
import '../forms/k_textarea.dart';
import '../overlays/k_adaptive_dialog.dart';
import '../primitives/k_button.dart';
import '../primitives/k_text.dart';
import 'k_integration_admin_catalog.dart';
import 'k_integration_editor_types.dart';
import 'k_integrations.dart';

export 'k_integration_editor_types.dart';

class KIntegrationEditor extends StatefulWidget {
  static const double defaultMaxWidth = 720;
  static const double defaultCompactBreakpoint = 520;

  const KIntegrationEditor({
    required this.onCancel,
    required this.onSave,
    required this.onTest,
    required this.onPublish,
    this.value = const KIntegrationDraft.empty(),
    this.initialStatus = KIntegrationCatalogState.draft,
    this.existingIcon,
    this.onPickIcon,
    this.testControls,
    this.allowedHttpOrigins = const {},
    this.testSuccessMessage = 'Test erfolgreich. Freigabe möglich.',
    this.testFailureMessage =
        'Test fehlgeschlagen. Bitte prüfe die Konfiguration.',
    this.testErrorMessage =
        'Die Aktion konnte nicht abgeschlossen werden. Bitte versuche es erneut.',
    this.maxWidth = defaultMaxWidth,
    super.key,
  });

  final KIntegrationDraft value;
  final KIntegrationCatalogState initialStatus;
  final Widget? existingIcon;
  final VoidCallback onCancel;
  final void Function(KIntegrationDraft draft, KIntegrationCatalogState status)
  onSave;
  final Future<bool> Function(KIntegrationDraft draft) onTest;
  final ValueChanged<KIntegrationDraft> onPublish;
  final Future<KIntegrationIconSelection?> Function()? onPickIcon;
  final Widget? testControls;

  /// Explicit development origins only. The server must independently authorize endpoints.
  final Set<String> allowedHttpOrigins;
  final String testSuccessMessage;
  final String testFailureMessage;
  final String testErrorMessage;
  final double maxWidth;

  @override
  State<KIntegrationEditor> createState() => _KIntegrationEditorState();
}

class _KIntegrationEditorState extends State<KIntegrationEditor> {
  late KIntegrationDraft draft;
  late KIntegrationCatalogState status;
  final controllers = <String, TextEditingController>{};
  Map<String, String> errors = const {};
  String? testMessage;
  bool testing = false;
  bool pickingIcon = false;
  String? iconError;
  int revision = 0;
  int iconPickGeneration = 0;

  @override
  void initState() {
    super.initState();
    draft = widget.value;
    status = widget.initialStatus;
    controllers.addAll({
      'name': TextEditingController(text: draft.name),
      'description': TextEditingController(text: draft.description),
      'category': TextEditingController(text: draft.category),
      'endpoint': TextEditingController(text: draft.endpoint),
      'clientId': TextEditingController(text: draft.clientId),
      'scopes': TextEditingController(text: draft.scopes),
    });
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void update(KIntegrationDraft next, [String? field]) {
    setState(() {
      draft = next;
      revision += 1;
      status = KIntegrationCatalogState.draft;
      testMessage = null;
      if (field != null) errors = {...errors}..remove(field);
    });
  }

  bool validate() {
    final next = validateKIntegrationDraft(
      draft,
      allowedHttpOrigins: widget.allowedHttpOrigins,
    );
    setState(() => errors = next);
    return next.isEmpty;
  }

  Future<void> test() async {
    if (pickingIcon || !validate()) return;
    final testedRevision = revision;
    setState(() => testing = true);
    try {
      final succeeded = await widget.onTest(draft.normalized());
      if (!mounted) return;
      setState(() {
        testing = false;
        if (testedRevision != revision) return;
        status = succeeded
            ? KIntegrationCatalogState.tested
            : KIntegrationCatalogState.draft;
        testMessage = succeeded
            ? widget.testSuccessMessage
            : widget.testFailureMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        testing = false;
        if (testedRevision != revision) return;
        status = KIntegrationCatalogState.draft;
        testMessage = widget.testErrorMessage;
      });
    }
  }

  Future<void> pickIcon() async {
    if (pickingIcon || widget.onPickIcon == null) return;
    final generation = ++iconPickGeneration;
    setState(() {
      pickingIcon = true;
      iconError = null;
    });
    try {
      final selection = await widget.onPickIcon!.call();
      if (!mounted || generation != iconPickGeneration) return;
      if (selection == null) {
        setState(() => pickingIcon = false);
        return;
      }
      const supported = {'image/png', 'image/jpeg', 'image/webp'};
      if (!supported.contains(selection.contentType)) {
        setState(() {
          pickingIcon = false;
          iconError = 'Bitte wähle eine PNG-, JPEG- oder WebP-Datei aus.';
        });
        return;
      }
      if (selection.bytes.lengthInBytes > 2 * 1024 * 1024) {
        setState(() {
          pickingIcon = false;
          iconError = 'Das Icon darf höchstens 2 MB groß sein.';
        });
        return;
      }
      setState(() => pickingIcon = false);
      update(draft.copyWith(icon: selection));
    } catch (_) {
      if (!mounted || generation != iconPickGeneration) return;
      setState(() {
        pickingIcon = false;
        iconError = 'Das Icon konnte nicht gelesen werden.';
      });
    }
  }

  void save() {
    if (pickingIcon || !validate()) return;
    widget.onSave(draft.normalized(), status);
  }

  void publish() {
    if (pickingIcon ||
        status != KIntegrationCatalogState.tested ||
        !validate()) {
      return;
    }
    widget.onPublish(draft.normalized());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final title = widget.value.name.isEmpty
        ? 'Integration hinzufügen'
        : 'Integration bearbeiten';
    final badge = switch (status) {
      KIntegrationCatalogState.draft => (KBadgeVariant.outline, 'Entwurf'),
      KIntegrationCatalogState.tested => (KBadgeVariant.info, 'Getestet'),
      KIntegrationCatalogState.published => (
        KBadgeVariant.success,
        'Veröffentlicht',
      ),
    };
    return KAdaptiveDialog(
      title: Text(title),
      description: const Text(
        'Lege die Katalogangaben und die technische Verbindung fest.',
      ),
      maxWidth: widget.maxWidth,
      onClose: widget.onCancel,
      actions: Wrap(
        alignment: WrapAlignment.end,
        spacing: t.spaceControlGap,
        runSpacing: t.spaceControlGap,
        children: [
          KButton(
            label: 'Abbrechen',
            variant: KButtonVariant.ghost,
            onPressed: widget.onCancel,
          ),
          KButton(
            label: 'Integration speichern',
            onPressed: pickingIcon ? null : save,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: t.spaceControlGap,
            runSpacing: t.spaceControlGap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              KBadge(variant: badge.$1, child: Text(badge.$2)),
              KButton(
                label: 'Verbindung testen',
                loading: testing,
                variant: KButtonVariant.secondary,
                onPressed: testing || pickingIcon ? null : test,
              ),
              KButton(
                label: 'Veröffentlichen',
                onPressed:
                    !pickingIcon && status == KIntegrationCatalogState.tested
                    ? publish
                    : null,
              ),
            ],
          ),
          if (testMessage != null) ...[
            SizedBox(height: t.spaceControlGap),
            Semantics(
              liveRegion: true,
              child: KText(
                testMessage!,
                variant: KTextVariant.bodySmall,
                style: TextStyle(
                  color: status == KIntegrationCatalogState.tested
                      ? t.colorStatusSuccessForeground
                      : t.colorStatusErrorForeground,
                ),
              ),
            ),
          ],
          if (widget.testControls != null) ...[
            SizedBox(height: t.spaceControlGap),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: widget.testControls!,
            ),
          ],
          SizedBox(height: t.spaceContentActionGap),
          _iconField(t),
          SizedBox(height: t.spaceContentActionGap),
          KField(
            label: 'Name',
            required: true,
            errorText: errors['name'],
            child: KInput(
              controller: controllers['name'],
              onChanged: (value) => update(draft.copyWith(name: value), 'name'),
            ),
          ),
          SizedBox(height: t.spaceContentActionGap),
          KField(
            label: 'Beschreibung',
            required: true,
            errorText: errors['description'],
            child: KTextarea(
              controller: controllers['description']!,
              rows: 2,
              onChanged: (value) =>
                  update(draft.copyWith(description: value), 'description'),
            ),
          ),
          SizedBox(height: t.spaceContentActionGap),
          _responsiveFields(t),
          SizedBox(height: t.spaceContentActionGap),
          KField(
            label: 'HTTPS-Endpoint',
            required: true,
            helperText: 'Beispiel: https://api.example.com',
            errorText: errors['endpoint'],
            child: KInput(
              controller: controllers['endpoint'],
              onChanged: (value) =>
                  update(draft.copyWith(endpoint: value), 'endpoint'),
            ),
          ),
          if (draft.authType == KIntegrationAuthType.oauth) ...[
            SizedBox(height: t.spaceContentActionGap),
            _oauthFields(t),
          ],
          SizedBox(height: t.spaceContentActionGap),
          KText(
            'Zugangsdaten und Geheimnisse werden in diesem Entwurf nicht gespeichert.',
            variant: KTextVariant.bodySmall,
            style: TextStyle(color: t.colorTextMuted),
          ),
        ],
      ),
    );
  }

  Widget _iconField(KDesignTokens t) => LayoutBuilder(
    builder: (context, bounds) {
      final hasPreview = draft.icon != null || widget.existingIcon != null;
      final preview = hasPreview
          ? KIntegrationIcon(
              child: draft.icon != null
                  ? Image.memory(draft.icon!.bytes, fit: BoxFit.contain)
                  : widget.existingIcon!,
            )
          : null;
      final field = KField(
        label: 'Icon',
        helperText: 'PNG, JPEG oder WebP, maximal 2 MB',
        errorText: iconError,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: KButton(
            label: hasPreview ? 'Icon ersetzen' : 'Icon hochladen',
            loading: pickingIcon,
            variant: KButtonVariant.secondary,
            onPressed: widget.onPickIcon == null || pickingIcon
                ? null
                : pickIcon,
          ),
        ),
      );
      if (preview == null) return field;
      if (bounds.maxWidth < KIntegrationEditor.defaultCompactBreakpoint) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            preview,
            SizedBox(height: t.spaceControlInsetInline),
            field,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          preview,
          SizedBox(width: t.spaceControlInsetInline),
          Expanded(child: field),
        ],
      );
    },
  );

  Widget _responsiveFields(KDesignTokens t) => LayoutBuilder(
    builder: (context, bounds) {
      final category = KField(
        label: 'Kategorie',
        required: true,
        errorText: errors['category'],
        child: KInput(
          controller: controllers['category'],
          onChanged: (value) =>
              update(draft.copyWith(category: value), 'category'),
        ),
      );
      final auth = KField(
        label: 'Authentifizierung',
        required: true,
        child: KSelect(
          value: draft.authType.name,
          options: const [
            KSelectOption(value: 'oauth', label: 'OAuth 2.0'),
            KSelectOption(value: 'none', label: 'Keine Authentifizierung'),
            KSelectOption(value: 'bearer', label: 'Bearer-Token'),
          ],
          onChanged: (value) => update(
            draft.copyWith(
              authType: KIntegrationAuthType.values.byName(value!),
            ),
          ),
        ),
      );
      return bounds.maxWidth < 520
          ? Column(
              children: [
                category,
                SizedBox(height: t.spaceContentActionGap),
                auth,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: category),
                SizedBox(width: t.spaceControlInsetInline),
                Expanded(child: auth),
              ],
            );
    },
  );

  Widget _oauthFields(KDesignTokens t) => LayoutBuilder(
    builder: (context, bounds) {
      final client = KField(
        label: 'OAuth Client-ID',
        helperText: 'Optional',
        child: KInput(
          controller: controllers['clientId'],
          onChanged: (value) => update(draft.copyWith(clientId: value)),
        ),
      );
      final scopes = KField(
        label: 'OAuth Scopes',
        helperText: 'Optional, durch Leerzeichen getrennt',
        child: KInput(
          controller: controllers['scopes'],
          onChanged: (value) => update(draft.copyWith(scopes: value)),
        ),
      );
      return bounds.maxWidth < 520
          ? Column(
              children: [
                client,
                SizedBox(height: t.spaceContentActionGap),
                scopes,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: client),
                SizedBox(width: t.spaceControlInsetInline),
                Expanded(child: scopes),
              ],
            );
    },
  );
}

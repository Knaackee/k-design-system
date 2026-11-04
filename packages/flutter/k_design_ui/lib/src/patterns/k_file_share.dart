part of 'k_files.dart';

class KFileRecipient {
  const KFileRecipient({
    required this.id,
    required this.name,
    required this.permission,
    this.expires,
  });
  final String id, name, permission;
  final String? expires;
}

class KFileShare extends StatefulWidget {
  const KFileShare({
    required this.recipients,
    this.onInvite,
    this.onRevoke,
    this.onCopyLink,
    this.hasLink = false,
    this.child,
    super.key,
  });
  final List<KFileRecipient> recipients;
  final void Function(String email, String permission)? onInvite;
  final ValueChanged<String>? onRevoke;
  final VoidCallback? onCopyLink;
  final bool hasLink;
  final Widget? child;
  @override
  State<KFileShare> createState() => _KFileShareState();
}

class _KFileShareState extends State<KFileShare> {
  final email = TextEditingController();
  String permission = 'view';
  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    Widget heading(String label) =>
        Text(label, style: TextStyle(fontWeight: FontWeight.w600));
    Widget sectionBreak() => Padding(
      padding: EdgeInsets.symmetric(vertical: t.spaceControlInsetInline),
      child: Divider(height: t.borderWidthDefault, color: t.colorBorderDefault),
    );
    return DefaultTextStyle.merge(
      style: TextStyle(
        fontFamily: t.fontFamily,
        fontSize: t.fontControlSize,
        height: t.componentFilesTextLineHeight,
        color: t.colorTextPrimary,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.onInvite != null) ...[
            heading('Personen einladen'),
            SizedBox(height: t.spaceControlGap),
            KInput(
              controller: email,
              label: 'Personen einladen',
              placeholder: 'E-Mail-Adresse',
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: t.spaceControlGap),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: KSelect(
                    label: 'Berechtigung',
                    value: permission,
                    options: const [
                      KSelectOption(value: 'view', label: 'Kann ansehen'),
                      KSelectOption(value: 'edit', label: 'Kann bearbeiten'),
                    ],
                    onChanged: (value) =>
                        setState(() => permission = value ?? 'view'),
                  ),
                ),
                KButton(
                  label: 'Einladen',
                  onPressed: !email.text.trim().contains('@')
                      ? null
                      : () {
                          if (email.text.trim().contains('@')) {
                            widget.onInvite!(email.text.trim(), permission);
                          }
                        },
                ),
              ],
            ),
            sectionBreak(),
          ],
          heading('Personen mit Zugriff'),
          SizedBox(height: t.spaceControlGap),
          for (final recipient in widget.recipients)
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: t.spaceControlInsetInline,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KLeading(
                    size: 20,
                    textVariant: KTextVariant.body,
                    child: KIcon(
                      KIconName.user,
                      size: 20,
                      color: t.colorTextMuted,
                    ),
                  ),
                  SizedBox(width: t.spaceControlGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipient.name,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          recipient.permission,
                          style: TextStyle(color: t.colorTextMuted),
                        ),
                        if (recipient.expires != null)
                          Text(
                            recipient.expires!,
                            style: TextStyle(color: t.colorTextMuted),
                          ),
                      ],
                    ),
                  ),
                  if (widget.onRevoke != null)
                    KButton(
                      label: 'Entfernen',
                      variant: KButtonVariant.ghost,
                      onPressed: () => widget.onRevoke!(recipient.id),
                    ),
                ],
              ),
            ),
          if (widget.hasLink) ...[
            sectionBreak(),
            heading('Linkzugriff'),
            SizedBox(height: t.spaceControlGap),
            Text(
              'Jeder mit dem Link kann ansehen und herunterladen. Bearbeiten erfordert eine Anmeldung und Freigabe.',
              style: TextStyle(color: t.colorTextMuted),
            ),
            SizedBox(height: t.spaceTight),
            Align(
              alignment: Alignment.centerLeft,
              child: KButton(
                label: 'Link kopieren',
                leading: const KIcon(KIconName.link, size: 16),
                variant: KButtonVariant.secondary,
                onPressed: widget.onCopyLink,
              ),
            ),
          ],
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

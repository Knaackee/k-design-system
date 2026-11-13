part of 'chat_presentation_media.dart';

class KPresentationFile extends StatelessWidget {
  const KPresentationFile({
    required this.name,
    this.meta,
    this.icon = KIconName.file,
    this.onOpen,
    this.onDownload,
    this.onSave,
    this.openLabel = 'Open',
    this.downloadLabel = 'Download',
    this.saveLabel = 'Save to Files',
    super.key,
  });
  final String name, openLabel, downloadLabel, saveLabel;
  final Widget? meta;
  final KIconName icon;
  final VoidCallback? onOpen, onDownload, onSave;
  @override
  Widget build(BuildContext context) {
    final tokens = _tokens(context);
    return _MediaSurface(
      label: name,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceCardPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KLeading(
                  size: 24,
                  textVariant: KTextVariant.body,
                  child: KIcon(icon, size: 24),
                ),
                SizedBox(width: tokens.spaceControlGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (meta != null)
                        DefaultTextStyle.merge(
                          style: TextStyle(color: tokens.colorTextMuted),
                          child: meta!,
                        ),
                    ],
                  ),
                ),
              ],
            );
            final actions = Wrap(
              alignment: WrapAlignment.end,
              spacing: tokens.spaceControlGap,
              runSpacing: tokens.spaceControlGap,
              children: [
                if (onOpen != null)
                  Semantics(
                    label: '$openLabel: $name',
                    child: KButton(
                      label: openLabel,
                      variant: KButtonVariant.secondary,
                      leading: const KIcon(KIconName.externalLink),
                      onPressed: onOpen,
                    ),
                  ),
                if (onDownload != null)
                  Semantics(
                    label: '$downloadLabel: $name',
                    child: KButton(
                      label: downloadLabel,
                      variant: KButtonVariant.ghost,
                      leading: const KIcon(KIconName.download),
                      onPressed: onDownload,
                    ),
                  ),
                if (onSave != null)
                  Semantics(
                    label: '$saveLabel: $name',
                    child: KButton(
                      label: saveLabel,
                      variant: KButtonVariant.ghost,
                      leading: const KIcon(KIconName.folderInput),
                      onPressed: onSave,
                    ),
                  ),
              ],
            );
            if (constraints.maxWidth >= 520 &&
                (onOpen != null || onDownload != null || onSave != null)) {
              return Row(
                children: [
                  Expanded(child: details),
                  SizedBox(width: tokens.spaceControlGap),
                  Flexible(child: actions),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                if (onOpen != null || onDownload != null || onSave != null)
                  Padding(
                    padding: EdgeInsets.only(top: tokens.spaceControlGap),
                    child: actions,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_text.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_file_icon.dart';
import '../primitives/k_surface.dart';

/// Presentation-only category for the controlled files dashboard.
enum KFilesHomeCategory { all, documents, images, other }

/// Display-ready recent file; timestamps and parent resolution belong to the host.
class KFilesHomeEntry {
  const KFilesHomeEntry({
    required this.id,
    required this.name,
    required this.parentLabel,
    required this.updatedLabel,
    this.category,
  });
  final String id, name, parentLabel, updatedLabel;
  final KFilesHomeCategory? category;
}

/// Controlled dashboard. File access, sorting, dates and mutations belong to the host.
class KFilesHome extends StatelessWidget {
  const KFilesHome({
    required this.files,
    required this.onOpen,
    required this.onCreateFile,
    required this.onCreateFolder,
    required this.onUpload,
    required this.filter,
    required this.onFilterChange,
    this.loading = false,
    this.labels = const KFilesHomeLabels(),
    super.key,
  });
  final List<KFilesHomeEntry> files;
  final bool loading;
  final KFilesHomeLabels labels;
  final KFilesHomeCategory filter;
  final ValueChanged<KFilesHomeCategory> onFilterChange;
  final ValueChanged<String> onOpen;
  final VoidCallback onCreateFile, onCreateFolder, onUpload;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final categories = [
      KFilesHomeCategory.all,
      for (final value in KFilesHomeCategory.values.skip(1))
        if (files.any(
          (file) => (file.category ?? kFilesHomeCategory(file.name)) == value,
        ))
          value,
    ];
    final active = categories.contains(filter)
        ? filter
        : KFilesHomeCategory.all;
    final visible = files
        .where(
          (file) =>
              active == KFilesHomeCategory.all ||
              (file.category ?? kFilesHomeCategory(file.name)) == active,
        )
        .toList();
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth <= 760;
        final phone = box.maxWidth <= 480;
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: t.spaceHairline * 960),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact
                      ? t.spaceLayoutGutter
                      : t.spaceLayoutSectionGap,
                  vertical: t.spaceLayoutSectionGap,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KText(
                      labels.title,
                      variant: KTextVariant.heading2,
                      style: TextStyle(
                        fontSize: phone ? 23 : 26,
                        height: t.fontTightHeight * 1.25,
                        fontWeight: FontWeight.w500,
                        fontVariations: const [FontVariation.weight(550)],
                        letterSpacing: phone ? -.575 : -.65,
                      ),
                    ),
                    SizedBox(height: t.spaceHairline * 10),
                    KText(
                      labels.description,
                      style: TextStyle(
                        color: t.colorTextMuted,
                        fontSize: t.fontControlSize,
                        height: t.fontTightHeight * 1.6,
                      ),
                    ),
                    SizedBox(height: phone ? 24 : 30),
                    _actions(context, phone, compact),
                    SizedBox(height: phone ? 32 : 46),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        KText(
                          labels.recent,
                          variant: KTextVariant.heading5,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (!compact) ...[
                          const Spacer(),
                          Flexible(
                            child: KText(
                              labels.recentHint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              variant: KTextVariant.caption,
                              style: TextStyle(color: t.colorTextMuted),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: t.spaceHairline * 18),
                    if (files.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final value in categories)
                            KButton(
                              label: labels.categoryLabel(value),
                              variant: active == value
                                  ? KButtonVariant.secondary
                                  : KButtonVariant.ghost,
                              onPressed: () => onFilterChange(value),
                            ),
                        ],
                      ),
                      SizedBox(height: t.spaceHairline * 16),
                    ],
                    if (loading && files.isEmpty)
                      KText(
                        labels.loading,
                        style: TextStyle(
                          color: t.colorTextMuted,
                          fontSize: t.fontControlSize,
                          height: t.fontTightHeight * 1.7,
                        ),
                      )
                    else if (visible.isEmpty)
                      _empty(context)
                    else
                      _recent(context, visible, phone),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actions(BuildContext context, bool phone, bool compact) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final actions = [
      (
        labels.createFile,
        labels.createFileHint,
        KIconName.filePlus,
        onCreateFile,
      ),
      (
        labels.createFolder,
        labels.createFolderHint,
        KIconName.folderPlus,
        onCreateFolder,
      ),
      (labels.upload, labels.uploadHint, KIconName.upload, onUpload),
    ];
    final cards = [
      for (final action in actions) _action(context, action, phone, compact),
    ];
    if (phone) {
      return IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < 2) SizedBox(height: t.spaceHairline * 8),
            ],
          ],
        ),
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < 2) SizedBox(width: compact ? 8 : 12),
          ],
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context,
    (String, String, KIconName, VoidCallback) action,
    bool phone,
    bool compact,
  ) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final details = Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KText(action.$1, variant: KTextVariant.label),
          SizedBox(height: t.spaceHairline * 5),
          KText(
            action.$2,
            variant: KTextVariant.caption,
            style: TextStyle(
              color: t.colorTextMuted,
              height: t.fontTightHeight * 1.4,
            ),
          ),
        ],
      ),
    );
    final icon = KIcon(action.$3, size: 24, color: t.colorTextMuted);
    final arrow = KIcon(KIconName.arrowUpRight, color: t.colorTextMuted);
    final content = phone
        ? Row(
            children: [
              icon,
              SizedBox(width: t.spaceHairline * 12),
              details,
              SizedBox(width: t.spaceHairline * 12),
              arrow,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              SizedBox(height: t.spaceHairline * 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  details,
                  SizedBox(width: t.spaceHairline * 14),
                  arrow,
                ],
              ),
            ],
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(t.radiusControl),
      child: KSurface(
        tone: KSurfaceTone.raised,
        border: KSurfaceBorder.standard,
        radius: KSurfaceRadius.medium,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: action.$4,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: phone ? 70 : 114),
              child: Padding(
                padding: EdgeInsets.all(
                  compact ? t.spaceControlInsetInline : t.spaceCardPadding,
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _recent(
    BuildContext context,
    List<KFilesHomeEntry> files,
    bool phone,
  ) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Column(
      children: [
        for (var i = 0; i < files.length; i++) ...[
          if (i > 0)
            Divider(
              height: t.spaceHairline * 1,
              thickness: 1,
              color: t.colorBorderDefault,
            ),
          _row(context, files[i], files[i].parentLabel, phone),
        ],
      ],
    );
  }

  Widget _row(
    BuildContext context,
    KFilesHomeEntry file,
    String parent,
    bool phone,
  ) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onOpen(file.id),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: t.spaceHairline * 72),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: t.spaceHairline * 8,
              vertical: t.spaceHairline * 12,
            ),
            child: Row(
              children: [
                Container(
                  width: t.spaceHairline * 36,
                  height: t.spaceHairline * 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.colorSurfaceSubtle,
                    borderRadius: BorderRadius.circular(t.radiusControl),
                  ),
                  child: KFileIcon(name: file.name),
                ),
                SizedBox(width: t.spaceHairline * 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KText(
                        file.name,
                        variant: KTextVariant.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: t.spaceHairline * 5),
                      KText(
                        parent,
                        variant: KTextVariant.caption,
                        style: TextStyle(
                          color: t.colorTextMuted,
                          height: t.fontTightHeight * 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!phone) ...[
                  SizedBox(width: t.spaceHairline * 16),
                  KText(
                    file.updatedLabel,
                    variant: KTextVariant.caption,
                    style: TextStyle(color: t.colorTextMuted),
                  ),
                ],
                SizedBox(width: t.spaceHairline * 16),
                KIcon(KIconName.arrowUpRight, color: t.colorTextMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return CustomPaint(
      painter: _DashedBorder(
        t.colorBorderDefault,
        t.radiusControl,
        t.spaceHairline,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: t.spaceHairline * 16,
          vertical: t.spaceHairline * 46,
        ),
        child: Column(
          children: [
            KIcon(KIconName.files, size: 32, color: t.colorTextMuted),
            SizedBox(height: t.spaceHairline * 24),
            KText(
              labels.emptyTitle,
              variant: KTextVariant.heading5,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: t.spaceHairline * 10),
            KText(
              labels.emptyDescription,
              align: TextAlign.center,
              style: TextStyle(
                color: t.colorTextMuted,
                fontSize: t.fontControlSize,
                height: t.fontTightHeight * 1.7,
              ),
            ),
            SizedBox(height: t.spaceHairline * 20),
            KButton(
              label: labels.emptyAction,
              variant: KButtonVariant.secondary,
              onPressed: onCreateFile,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder(this.color, this.radius, this.strokeWidth);
  final Color color;
  final double radius, strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in path.computeMetrics()) {
      for (double at = 0; at < metric.length; at += 7) {
        canvas.drawPath(
          metric.extractPath(at, (at + 4).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

KFilesHomeCategory kFilesHomeCategory(String name) {
  final extension = name.contains('.')
      ? name.split('.').last.toLowerCase()
      : '';
  if (const {
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'svg',
    'avif',
    'heic',
  }.contains(extension)) {
    return KFilesHomeCategory.images;
  }
  if (const {
    'md',
    'txt',
    'pdf',
    'doc',
    'docx',
    'odt',
    'rtf',
    'csv',
    'xlsx',
    'xls',
    'pptx',
  }.contains(extension)) {
    return KFilesHomeCategory.documents;
  }
  return KFilesHomeCategory.other;
}

/// Configurable copy for the files dashboard.
class KFilesHomeLabels {
  const KFilesHomeLabels({
    this.title = 'Dein Platz für Ideen.',
    this.description =
        'Alles, was du festhältst. Alles, was dein Assistent für dich erstellt.',
    this.recent = 'Zuletzt geändert',
    this.recentHint = 'Deine letzten 50 Dateien · auch aus Unterordnern',
    this.loading = 'Deine Dateien werden geladen …',
    this.createFile = 'Neue Datei',
    this.createFileHint = 'Gedanken festhalten',
    this.createFolder = 'Neuer Ordner',
    this.createFolderHint = 'Platz für ein neues Thema',
    this.upload = 'Hochladen',
    this.uploadHint = 'Dateien von deinem Gerät',
    this.emptyTitle = 'Hier beginnt deine Sammlung.',
    this.emptyDescription =
        'Erstelle deine erste Datei oder lade etwas hoch.\nAuch die Dateien deines Assistenten findest du hier.',
    this.emptyAction = 'Erste Datei erstellen',
    this.all = 'Alle',
    this.documents = 'Dokumente',
    this.images = 'Bilder',
    this.other = 'Weitere',
  });
  final String title;
  final String description;
  final String recent;
  final String recentHint;
  final String loading;
  final String createFile;
  final String createFileHint;
  final String createFolder;
  final String createFolderHint;
  final String upload;
  final String uploadHint;
  final String emptyTitle;
  final String emptyDescription;
  final String emptyAction;
  final String all, documents, images, other;
  String categoryLabel(KFilesHomeCategory value) => switch (value) {
    KFilesHomeCategory.all => all,
    KFilesHomeCategory.documents => documents,
    KFilesHomeCategory.images => images,
    KFilesHomeCategory.other => other,
  };
}

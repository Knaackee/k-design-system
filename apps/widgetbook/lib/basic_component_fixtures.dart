import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class BasicComponentFixture extends StatefulWidget {
  const BasicComponentFixture({required this.kind, super.key});
  final String kind;

  @override
  State<BasicComponentFixture> createState() => _BasicComponentFixtureState();
}

class _BasicComponentFixtureState extends State<BasicComponentFixture> {
  String status = 'No action';

  @override
  Widget build(BuildContext context) {
    final child = switch (widget.kind) {
      'alert' => _alerts(),
      'alert-dialog' => _alertDialog(),
      'attachment' => _attachments(),
      'avatar' => _avatars(),
      'badge' => _badges(),
      'breadcrumb' => _breadcrumb(),
      'carousel' => _carousel(),
      _ => const SizedBox.shrink(),
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: child,
        ),
      ),
    );
  }

  Widget _alerts() => Column(
    children: [
      KAlert(
        icon: KIconName.info,
        tone: KStatusTone.info,
        title: const Text('Scheduled maintenance'),
        description: const Text(
          'The workspace will be unavailable tonight from 22:00 to 22:15.',
        ),
        action: KButton(
          label: 'Details',
          variant: KButtonVariant.ghost,
          onPressed: () {},
        ),
      ),
      const SizedBox(height: 16),
      const KAlert(
        icon: KIconName.triangleAlert,
        tone: KStatusTone.error,
        title: Text('Upload failed'),
        description: Text('Check the file and try again.'),
      ),
    ],
  );

  Widget _alertDialog() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      KButton(
        label: 'Delete project',
        variant: KButtonVariant.secondary,
        onPressed: () async {
          final confirmed = await KAlertDialog.show(
            context: context,
            title: const Text('Delete project?'),
            description: const Text(
              'This action cannot be undone. All project data will be removed.',
            ),
            media: const KIcon(KIconName.trash, size: 22),
            cancelLabel: 'Cancel',
            actionLabel: 'Delete project',
            destructive: true,
          );
          if (confirmed == true && mounted) {
            setState(() => status = 'Project deleted');
          }
        },
      ),
      const SizedBox(height: 16),
      Text(status),
    ],
  );

  Widget _attachments() => Column(
    children: [
      KAttachment(
        title: const Text('Product brief.pdf'),
        description: const Text('2.4 MB · PDF'),
        media: const KIcon(KIconName.fileText),
        activateLabel: 'Open Product brief.pdf',
        onActivate: () {},
        actions: KIconButton(
          icon: KIconName.download,
          label: 'Download',
          onPressed: () {},
        ),
      ),
      const SizedBox(height: 16),
      KAttachment(
        title: const Text('Brand assets.zip'),
        description: const Text('Uploading · 68%'),
        state: KAttachmentState.uploading,
        progress: .68,
        showLoadingIndicator: true,
        media: const KIcon(KIconName.upload),
        actions: KIconButton(
          icon: KIconName.x,
          label: 'Cancel upload',
          onPressed: () {},
        ),
      ),
    ],
  );

  Widget _avatars() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Row(
        children: [
          KAvatar(
            size: KAvatarSize.small,
            alt: 'Mia Chen',
            fallback: Text('MC'),
          ),
          SizedBox(width: 16),
          KAvatar(
            alt: 'Noah Williams',
            fallback: Text('NW'),
            badge: SizedBox.shrink(),
          ),
          SizedBox(width: 16),
          KAvatar(
            size: KAvatarSize.large,
            alt: 'Ava Singh',
            fallback: Text('AS'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const KAvatarGroup(
        children: [
          KAvatar(alt: 'Mia Chen', fallback: Text('MC')),
          KAvatar(alt: 'Noah Williams', fallback: Text('NW')),
          KAvatar(alt: 'Ava Singh', fallback: Text('AS')),
          KAvatar(alt: 'Three more members', fallback: Text('+3')),
        ],
      ),
    ],
  );

  Widget _badges() => const Wrap(
    spacing: 16,
    runSpacing: 16,
    children: [
      KBadge(
        variant: KBadgeVariant.success,
        leading: KIcon(KIconName.check),
        child: Text('Active'),
      ),
      KBadge(variant: KBadgeVariant.secondary, child: Text('Draft')),
      KBadge(variant: KBadgeVariant.outline, child: Text('In review')),
      KBadge(variant: KBadgeVariant.ghost, child: Text('Archived')),
      KBadge(
        variant: KBadgeVariant.destructive,
        leading: KIcon(KIconName.circleAlert),
        child: Text('Blocked'),
      ),
    ],
  );

  Widget _breadcrumb() => KBreadcrumb(
    items: [
      KBreadcrumbItem(id: 'home', label: 'Home', onSelect: () {}),
      KBreadcrumbItem(id: 'projects', label: 'Projects', onSelect: () {}),
      const KBreadcrumbItem(id: 'orbit', label: 'Orbit redesign'),
    ],
  );

  Widget _carousel() => KCarousel(
    label: 'Featured projects',
    children: const [
      _CarouselCard(
        title: 'Orbit workspace',
        body: 'Coordinate product work across every platform.',
      ),
      _CarouselCard(
        title: 'Design review',
        body: 'Keep decisions, files and feedback together.',
      ),
      _CarouselCard(
        title: 'Release planning',
        body: 'Move confidently from scope to delivery.',
      ),
    ],
  );
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.colorSurfaceRaised,
        border: Border.all(color: t.colorBorderDefault),
        borderRadius: BorderRadius.circular(t.radiusCard),
      ),
      alignment: AlignmentDirectional.bottomStart,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KText(title, variant: KTextVariant.heading4),
          KText(body),
        ],
      ),
    );
  }
}

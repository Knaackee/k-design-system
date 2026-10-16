import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class ExtendedComponentFixture extends StatefulWidget {
  const ExtendedComponentFixture({required this.kind, super.key});
  final String kind;
  @override
  State<ExtendedComponentFixture> createState() =>
      _ExtendedComponentFixtureState();
}

class _ExtendedComponentFixtureState extends State<ExtendedComponentFixture> {
  String otp = '123';
  int page = 4;
  double slider = 38;
  bool enabled = true;
  String tab = 'overview';
  int step = 0;
  bool done = false;
  bool componentLibrary = true;
  bool decisions = true;
  bool startNow = true;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _content(context),
      ),
    ),
  );
  Widget _content(BuildContext context) => switch (widget.kind) {
    'drawer' => KButton(
      label: 'Open workspace',
      variant: KButtonVariant.secondary,
      onPressed: () => KResponsiveDrawer.show(
        context: context,
        title: const Text('Workspace settings'),
        description: const Text(
          'Sidebar on larger screens, bottom sheet on compact screens.',
        ),
        actions: KButton(
          label: 'Save changes',
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).maybePop(),
        ),
        child: const Text('Any consumer content can live here.'),
      ),
    ),
    'otp' => KInputOtp(
      value: otp,
      onChanged: (value) => setState(() => otp = value),
      label: 'Verification code',
    ),
    'kbd' => const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Open commands with '),
        KKbdGroup(
          children: [
            KKbd(child: Text('Ctrl')),
            Text('+'),
            KKbd(child: Text('K')),
          ],
        ),
      ],
    ),
    'navigation-menu' => KNavigationMenu(
      items: [
        KNavigationMenuItem(
          id: 'products',
          label: const Text('Products'),
          content: const SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Design system',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text('Reusable components for every platform.'),
              ],
            ),
          ),
        ),
        KNavigationMenuItem(
          id: 'docs',
          label: const Text('Documentation'),
          onPressed: () {},
        ),
        KNavigationMenuItem(
          id: 'components',
          label: const Text('Components'),
          onPressed: () {},
        ),
        KNavigationMenuItem(
          id: 'resources',
          label: const Text('Resources'),
          onPressed: () {},
        ),
        KNavigationMenuItem(
          id: 'changelog',
          label: const Text('Changelog'),
          onPressed: () {},
        ),
        KNavigationMenuItem(
          id: 'about',
          label: const Text('About'),
          onPressed: () {},
        ),
      ],
    ),
    'pagination' => KPagination(
      page: page,
      pageCount: 12,
      onPageChanged: (value) => setState(() => page = value),
    ),
    'popover' => KPopover(
      label: 'Project details',
      trigger: const KButton(
        label: 'Open popover',
        variant: KButtonVariant.secondary,
        onPressed: null,
      ),
      content: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Project details',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text('Rich, consumer-defined content.'),
          ],
        ),
      ),
    ),
    'progress' => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const KProgress(value: 68, label: Text('Upload progress')),
        const SizedBox(height: 20),
        const KProgress(label: Text('Preparing workspace')),
      ],
    ),
    'questionnaire' =>
      done
          ? const Text('Plan saved.')
          : KQuestionnaire(
              step: step,
              onStepChanged: (value) => setState(() => step = value),
              onComplete: () => setState(() => done = true),
              steps: [
                KQuestionnaireStep(
                  id: 'direction',
                  title: const Text('What should we build next?'),
                  description: const Text('Choose a direction.'),
                  content: KCheckbox(
                    label: 'Component library',
                    value: componentLibrary,
                    onChanged: (value) =>
                        setState(() => componentLibrary = value ?? false),
                  ),
                ),
                KQuestionnaireStep(
                  id: 'updates',
                  title: const Text('What should updates include?'),
                  description: const Text('Select all that apply.'),
                  optional: true,
                  content: KCheckbox(
                    label: 'Decisions and risks',
                    value: decisions,
                    onChanged: (value) =>
                        setState(() => decisions = value ?? false),
                  ),
                ),
                KQuestionnaireStep(
                  id: 'start',
                  title: const Text('When should work begin?'),
                  content: KCheckbox(
                    label: 'Start now',
                    value: startNow,
                    onChanged: (value) =>
                        setState(() => startNow = value ?? false),
                  ),
                ),
              ],
            ),
    'skeleton' => const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KSkeleton(width: 48, height: 48, circle: true),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              KSkeleton(width: 140),
              SizedBox(height: 8),
              KSkeleton(),
              SizedBox(height: 8),
              KSkeleton(width: 220),
            ],
          ),
        ),
      ],
    ),
    'slider' => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KSlider(
          value: slider,
          onChanged: (value) => setState(() => slider = value),
          label: 'Volume',
          valueLabel: (value) => '${value.round()}%',
        ),
        Text('${slider.round()}%'),
      ],
    ),
    'spinner' => const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KSpinner(label: 'Processing'),
        SizedBox(width: 10),
        Text('Processing payment…'),
      ],
    ),
    'switch' => KSwitch(
      value: enabled,
      onChanged: (value) => setState(() => enabled = value),
      label: 'Share across devices',
    ),
    'tabs' => KTabs(
      value: tab,
      onChanged: (value) => setState(() => tab = value),
      items: const [
        KTabItem(
          id: 'overview',
          label: Text('Overview'),
          icon: KIconName.folder,
          content: Text('Key metrics and recent activity.'),
        ),
        KTabItem(
          id: 'analytics',
          label: Text('Analytics'),
          icon: KIconName.info,
          content: Text('Analytics content.'),
        ),
        KTabItem(
          id: 'activity',
          label: Text('Activity'),
          icon: KIconName.calendar,
          content: Text('Recent workspace activity.'),
        ),
        KTabItem(
          id: 'members',
          label: Text('Members'),
          icon: KIconName.users,
          content: Text('Workspace members.'),
        ),
        KTabItem(
          id: 'integrations',
          label: Text('Integrations'),
          icon: KIconName.link,
          content: Text('Connected integrations.'),
        ),
        KTabItem(
          id: 'settings',
          label: Text('Settings'),
          icon: KIconName.settings,
          content: Text('Settings content.'),
        ),
      ],
    ),
    'toast' => KButton(
      label: 'Show toast',
      variant: KButtonVariant.secondary,
      onPressed: () => KToast.show(
        context: context,
        tone: KToastTone.success,
        icon: const KIcon(KIconName.circleCheck),
        title: const Text('Event created'),
        description: const Text('Today at 09:00'),
        action: KButton(
          label: 'View',
          variant: KButtonVariant.secondary,
          onPressed: () {},
        ),
      ),
    ),
    _ => const SizedBox.shrink(),
  };
}

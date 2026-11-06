import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../data_display/k_progress_dots.dart';
import '../localization/k_localization.dart';
import '../primitives/k_button.dart';

/// A step-by-step introduction or setup (Decision 0015).
///
/// The footer is fixed at the bottom on every step: Back at the start
/// (hidden on the first step, its space kept so nothing moves), the
/// progress in the middle and Next — Done on the last step — at the end.
/// Only the step content changes, with the style's page motion; swiping
/// moves between steps too. The footer stays above the keyboard and the
/// home indicator.
///
/// Use it for every onboarding or multi-step setup; never place progress
/// dots or step buttons by hand (`check-consumer-ui` › hand-built-steps).
class KOnboarding extends StatefulWidget {
  const KOnboarding({
    required this.steps,
    required this.onDone,
    this.onStepChanged,
    this.canContinue = true,
    this.initialStep = 0,
    this.nextLabel,
    this.doneLabel,
    super.key,
  });

  /// One widget per step; each scrolls on its own when it is taller.
  final List<Widget> steps;
  final VoidCallback onDone;
  final ValueChanged<int>? onStepChanged;

  /// Whether the current step allows Next (a required answer is given).
  final bool canContinue;
  final int initialStep;

  /// Overrides the localized "Next" and "Done".
  final String? nextLabel;
  final String? doneLabel;

  @override
  State<KOnboarding> createState() => _KOnboardingState();
}

class _KOnboardingState extends State<KOnboarding> {
  late final PageController _pages = PageController(
    initialPage: widget.initialStep,
  );
  late int _step = widget.initialStep;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int step) {
    final motion = Theme.of(
      context,
    ).extension<KDesignTokens>()!.motion(KMotionRole.page);
    _pages.animateToPage(step, duration: motion.duration, curve: motion.curve);
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.steps.isNotEmpty, 'KOnboarding needs at least one step.');
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final l10n = KLocalization.of(context);
    final media = MediaQuery.of(context);
    final last = _step == widget.steps.length - 1;
    final gutter = t.spaceLayoutGutter;
    final footer = Padding(
      padding: EdgeInsets.fromLTRB(
        gutter + media.padding.left,
        t.spaceControlGap,
        gutter + media.padding.right,
        gutter + media.padding.bottom,
      ),
      child: Row(
        children: [
          // Back keeps its space on the first step, so Next never moves.
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Visibility(
                visible: _step > 0,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: KButton(
                  label: l10n.text('onboardingBack'),
                  variant: KButtonVariant.ghost,
                  onPressed: _step > 0 ? () => _go(_step - 1) : null,
                ),
              ),
            ),
          ),
          KProgressDots(
            count: widget.steps.length,
            activeIndex: _step,
            label: l10n
                .text('onboardingStep')
                .replaceAll('{current}', '${_step + 1}')
                .replaceAll('{total}', '${widget.steps.length}'),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: KButton(
                label: last
                    ? widget.doneLabel ?? l10n.text('onboardingDone')
                    : widget.nextLabel ?? l10n.text('onboardingNext'),
                onPressed: !widget.canContinue
                    ? null
                    : last
                    ? widget.onDone
                    : () => _go(_step + 1),
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: PageView(
              controller: _pages,
              // Swiping forward needs the same permission as Next.
              physics: widget.canContinue
                  ? const PageScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              onPageChanged: (step) {
                setState(() => _step = step);
                widget.onStepChanged?.call(step);
              },
              children: widget.steps,
            ),
          ),
        ),
        // Above the keyboard when it is open.
        Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: footer,
        ),
      ],
    );
  }
}

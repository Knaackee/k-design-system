import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class NotificationFixture extends StatefulWidget {
  const NotificationFixture({this.snackbar = false, super.key});
  final bool snackbar;
  @override
  State<NotificationFixture> createState() => _NotificationFixtureState();
}

class _NotificationFixtureState extends State<NotificationFixture> {
  KToastController? _controller;
  String _status = '';
  static const _long =
      'Your changes were saved. Everyone in the workspace will see the updated settings the next time they open the page.';
  @override
  void dispose() {
    _controller?.dismiss();
    super.dispose();
  }

  void _show(bool long) {
    _controller?.dismiss();
    setState(() => _status = '');
    final action = KButton(
      label: widget.snackbar ? 'Undo' : 'View',
      variant: KButtonVariant.ghost,
      onPressed: () {
        _controller?.dismiss();
        setState(
          () =>
              _status = widget.snackbar ? 'Message restored' : 'Changes opened',
        );
      },
    );
    if (widget.snackbar) {
      _controller = KSnackbar.show(
        context: context,
        message: Text(long ? _long : 'Message archived'),
        action: action,
        duration: const Duration(seconds: 6),
      );
    } else {
      _controller = KToast.show(
        context: context,
        title: const Text('Changes saved'),
        description: Text(
          long ? _long : 'Your workspace settings are up to date.',
        ),
        icon: const KIcon(KIconName.circleCheck),
        action: action,
        tone: KToastTone.success,
        duration: const Duration(seconds: 6),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(t.spaceCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KButton(
              label: widget.snackbar ? 'Show snackbar' : 'Show toast',
              onPressed: () => _show(false),
            ),
            SizedBox(height: t.spaceControlGap),
            KButton(
              label: 'Show long message',
              variant: KButtonVariant.secondary,
              onPressed: () => _show(true),
            ),
            if (_status.isNotEmpty) ...[
              SizedBox(height: t.spaceControlGap),
              KText(_status),
            ],
          ],
        ),
      ),
    );
  }
}

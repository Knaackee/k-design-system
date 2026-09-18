import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_ui/k_design_ui.dart';

class ProjectTitleCell extends StatefulWidget {
  const ProjectTitleCell({
    required this.id,
    required this.title,
    required this.onFinish,
    this.startEditing = false,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    super.key,
  });
  final String id;
  final String title;
  final void Function(String value, bool commit) onFinish;
  final bool startEditing;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final bool enabled;
  @override
  State<ProjectTitleCell> createState() => ProjectTitleCellState();
}

class ProjectTitleCellState extends State<ProjectTitleCell> {
  final _draft = TextEditingController();
  final _focus = FocusNode();
  bool _editing = false;
  @override
  void initState() {
    super.initState();
    _draft.text = widget.title;
    _editing = widget.startEditing;
    if (_editing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _editing) {
          _focus.requestFocus();
          Scrollable.ensureVisible(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _draft.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _finish(bool commit) {
    if (!mounted || !_editing) return;
    setState(() => _editing = false);
    widget.onFinish(_draft.text, commit);
  }

  @override
  Widget build(BuildContext context) => KEditableCell(
    label: 'Edit title for ${widget.id}',
    paddingInline: 4,
    editing: _editing,
    onEdit: !widget.enabled
        ? null
        : () => setState(() {
            _draft.text = widget.title;
            _editing = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _editing) _focus.requestFocus();
            });
          }),
    display: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    editor: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => _finish(false),
      },
      child: Focus(
        onFocusChange: (focused) {
          if (!focused) _finish(true);
        },
        child: KInput(
          label: 'Title for ${widget.id}',
          autofocus: true,
          focusNode: _focus,
          controller: _draft,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          onSubmitted: (_) {
            _finish(true);
            widget.onSubmitted?.call();
          },
        ),
      ),
    ),
  );
}

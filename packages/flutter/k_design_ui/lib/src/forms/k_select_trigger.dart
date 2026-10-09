part of 'k_select.dart';

// Select display remains separate from popup/search state. Editable comboboxes
// keep their real text field; compact read-only selects can truncate visually.
extension _KSelectTrigger on _KSelectState {
  Widget _buildTrigger(BuildContext context, InputDecoration appearance) {
    final t = formTokens(context);
    if (widget.truncateLabel && !widget.editable) {
      final label = _text.text.isEmpty
          ? widget.placeholder ?? KLocalization.of(context).text('choose')
          : _text.text;
      return Focus(
        focusNode: _focus,
        canRequestFocus: widget.enabled,
        child: TextFieldTapRegion(
          onTapOutside: (_) {
            if (_open) _close();
            _focus.unfocus();
          },
          child: MouseRegion(
            cursor: widget.enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: !widget.enabled
                  ? null
                  : () {
                      if (_open) {
                        _close();
                      } else {
                        _show();
                      }
                    },
              child: InputDecorator(
                decoration: appearance.copyWith(hint: const SizedBox.shrink()),
                isFocused: _focus.hasFocus,
                child: Text(
                  label,
                  textAlign: widget.textAlign,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: formTextStyle(
                    context,
                    color: _text.text.isEmpty
                        ? t.colorTextMuted
                        : t.colorTextPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return TextField(
      textAlign: widget.textAlign,
      controller: _text,
      focusNode: _focus,
      enabled: widget.enabled,
      readOnly: !widget.editable,
      enableInteractiveSelection: widget.editable,
      showCursor: widget.editable,
      mouseCursor: !widget.enabled
          ? SystemMouseCursors.basic
          : widget.editable
          ? SystemMouseCursors.text
          : SystemMouseCursors.click,
      textAlignVertical: formInputAlignment(appearance),
      style: formTextStyle(context),
      cursorColor: t.colorBorderFocus,
      onTapAlwaysCalled: true,
      onTapOutside: (_) {
        if (_open) _close();
        _focus.unfocus();
      },
      onTap: () {
        if (_open && !widget.editable) {
          _close();
        } else if (!_open) {
          _show();
        }
      },
      onChanged: _updateQuery,
      decoration: appearance,
    );
  }
}

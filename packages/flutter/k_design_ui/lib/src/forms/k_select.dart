import '../localization/k_localization.dart';
import 'dart:ui' show SemanticsValidationResult;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../primitives/k_icon.dart';
import 'form_style.dart';
import 'k_field.dart';
import 'selection_popup.dart';
import 'form_clear.dart';
import 'option_media.dart';

class KSelectOption {
  const KSelectOption({
    required this.value,
    required this.label,
    this.disabled = false,
    this.icon,
    this.imageSrc,
  });
  final String value;
  final String label;
  final bool disabled;
  final KIconName? icon;
  final String? imageSrc;
  bool get hasMedia => icon != null || imageSrc != null;
}

enum KSelectPresentation { standard, inline }

class KSelect extends StatefulWidget {
  const KSelect({
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.placeholder,
    this.clearable = false,
    this.clearLabel,
    this.optionsLabel,
    this.noResultsLabel,
    this.presentation = KSelectPresentation.standard,
    super.key,
  });
  final KSelectPresentation presentation;
  final List<KSelectOption> options;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String? label;
  final String? placeholder;
  final bool clearable;
  final String? clearLabel;
  final String? optionsLabel, noResultsLabel;
  bool get editable => false;
  @override
  State<KSelect> createState() => _KSelectState();
}

class KCombobox extends KSelect {
  const KCombobox({
    required super.options,
    required super.value,
    required super.onChanged,
    super.label,
    super.presentation,
    super.placeholder,
    super.clearable,
    super.clearLabel,
    super.optionsLabel,
    super.noResultsLabel,
    super.key,
  });
  @override
  bool get editable => true;
}

class _KSelectState extends State<KSelect> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _portal = OverlayPortalController();
  final _anchor = GlobalKey();
  final _optionKeys = <String, GlobalKey>{};
  ScrollPosition? _ancestorScroll;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _ancestorScroll) {
      _ancestorScroll?.removeListener(_parentScrolled);
      _ancestorScroll = position;
      _ancestorScroll?.addListener(_parentScrolled);
    }
  }

  void _parentScrolled() {
    if (_open) _close();
  }

  String _prefix = '';
  DateTime? _prefixAt;
  void _revealActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_open || _active < 0 || _active >= _visible.length) {
        return;
      }
      final target = _optionKeys[_visible[_active].value]?.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  String _query = '';
  int _active = -1;
  bool get _open => _portal.isShowing;
  String get _committed =>
      widget.options.where((o) => o.value == widget.value).firstOrNull?.label ??
      '';
  List<KSelectOption> get _visible => widget.options
      .where(
        (o) =>
            !widget.editable ||
            o.label.toLowerCase().contains(_query.toLowerCase()),
      )
      .toList();
  @override
  void initState() {
    super.initState();
    _text.text = _committed;
  }

  @override
  void didUpdateWidget(covariant KSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || !_open) _text.text = _committed;
    if (widget.onChanged == null && _open) _close();
  }

  @override
  void dispose() {
    _ancestorScroll?.removeListener(_parentScrolled);

    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _show() {
    if (widget.onChanged == null) return;
    setState(() {
      _query = '';
      if (widget.editable) _text.clear();
      _active = _visible.indexWhere(
        (o) => o.value == widget.value && !o.disabled,
      );
      if (_active < 0) _active = _visible.indexWhere((o) => !o.disabled);
    });
    _portal.show();
    _focus.requestFocus();
    _revealActive();
  }

  void _close() {
    _portal.hide();
    setState(() {
      _query = '';
      _text.text = _committed;
    });
  }

  void _clear() {
    _portal.hide();
    setState(() {
      _query = '';
      _active = -1;
      _text.clear();
    });
    widget.onChanged?.call(null);
    restoreFormFocus(_focus, () => mounted);
  }

  void _choose(KSelectOption option) {
    if (option.disabled) return;
    _portal.hide();
    _query = '';
    _text.text = option.label;
    widget.onChanged?.call(option.value);
    _focus.requestFocus();
    _revealActive();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_focus.hasFocus) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape && _open) {
      _close();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      if (!_open) {
        _show();
        return KeyEventResult.handled;
      }
      final options = _visible;
      final step = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      for (var n = 1; n <= options.length; n++) {
        final next = (_active + step * n) % options.length;
        if (!options[next].disabled) {
          setState(() => _active = next);
          _revealActive();
          break;
        }
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        (!widget.editable && key == LogicalKeyboardKey.space)) {
      if (!_open) {
        _show();
      } else if (_active >= 0 && _active < _visible.length) {
        _choose(_visible[_active]);
      }
      return KeyEventResult.handled;
    }
    if (!widget.editable &&
        (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.end)) {
      if (!_open) _show();
      final candidates = _visible;
      setState(
        () => _active = key == LogicalKeyboardKey.home
            ? candidates.indexWhere((o) => !o.disabled)
            : candidates.lastIndexWhere((o) => !o.disabled),
      );
      _revealActive();
      return KeyEventResult.handled;
    }
    final character = event.character;
    if (!widget.editable &&
        character != null &&
        character.length == 1 &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isMetaPressed) {
      if (!_open) _show();
      final now = DateTime.now();
      _prefix =
          _prefixAt == null || now.difference(_prefixAt!).inMilliseconds > 700
          ? character
          : '$_prefix$character';
      _prefixAt = now;
      final next = _visible.indexWhere(
        (o) =>
            !o.disabled &&
            o.label.toLowerCase().startsWith(_prefix.toLowerCase()),
      );
      if (next >= 0) setState(() => _active = next);
      _revealActive();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    final field = KFieldScope.of(context);
    final canClear =
        widget.clearable &&
        widget.onChanged != null &&
        (widget.value != null || _query.isNotEmpty);
    final selected = widget.options
        .where((o) => o.value == widget.value)
        .firstOrNull;
    final inlineResting =
        widget.presentation == KSelectPresentation.inline &&
        !_focus.hasFocus &&
        !_open;
    var appearance = formDecoration(
      context,
      placeholder:
          widget.placeholder ?? KLocalization.of(context).text('choose'),
      invalid: field?.invalid ?? false,
      prefix: selected?.hasMedia == true && (!widget.editable || !_open)
          ? Padding(
              padding: EdgeInsets.only(
                left: t.spaceControlInsetInline + 1,
                right: t.spaceControlGap - 4,
              ),
              child: KOptionMedia(selected!),
            )
          : null,
      suffix: Padding(
        padding: EdgeInsets.only(
          left: t.spaceControlGap - 4,
          right: t.spaceControlInsetInline + 1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canClear) ...[
              SizedBox(width: math.max(24, t.sizeHitTarget), height: 16),
              SizedBox(width: t.spaceControlGap),
            ],
            Opacity(
              opacity: inlineResting ? 0 : 1,
              child: KIcon(KIconName.chevronDown, color: t.colorTextMuted),
            ),
          ],
        ),
      ),
    );
    if (inlineResting) {
      final hiddenBorder = OutlineInputBorder(
        gapPadding: 0,
        borderRadius: BorderRadius.circular(t.radiusControl),
        borderSide: const BorderSide(color: Colors.transparent),
      );
      appearance = appearance.copyWith(
        fillColor: Colors.transparent,
        enabledBorder: hiddenBorder,
        disabledBorder: hiddenBorder,
      );
    }
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _popup,
      child: Focus(
        onKeyEvent: _key,
        onFocusChange: (focused) {
          if (!focused && _open) _close();
          setState(() {});
        },
        child: KFormClearOverlay(
          label: widget.clearLabel ?? KLocalization.of(context).text('clear'),
          onPressed: canClear ? _clear : null,
          right: t.spaceControlInsetInline + 1 + 16 + t.spaceControlGap,
          child: Semantics(
            expanded: _open,
            label: widget.label ?? field?.label,
            hint: field?.helperText,
            isRequired: field?.required,
            validationResult: field?.invalid == true
                ? SemanticsValidationResult.invalid
                : SemanticsValidationResult.none,
            child: Opacity(
              opacity: widget.onChanged == null ? .48 : 1,
              child: ConstrainedBox(
                key: _anchor,
                constraints: BoxConstraints(
                  minHeight: math.max(t.sizeControl, t.sizeHitTarget),
                ),
                child: Center(
                  heightFactor: 1,
                  child: TextField(
                    controller: _text,
                    focusNode: _focus,
                    enabled: widget.onChanged != null,
                    readOnly: !widget.editable,
                    enableInteractiveSelection: widget.editable,
                    showCursor: widget.editable,
                    mouseCursor: widget.onChanged == null
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
                      if (!_open) _show();
                    },
                    onChanged: (value) {
                      if (!_open) _portal.show();
                      setState(() {
                        _query = value;
                        _active = _visible.indexWhere((o) => !o.disabled);
                      });
                    },
                    decoration: appearance,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _popup(BuildContext context) {
    final t = formTokens(context);
    final box = _anchor.currentContext!.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(this.context).context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final screen = overlay.size;
    final width = math.min(box.size.width, screen.width - 16.0);
    final left = origin.dx.clamp(8.0, math.max(8.0, screen.width - width - 8));
    final below =
        screen.height - origin.dy - box.size.height - t.spaceControlGap - 8;
    final above = origin.dy - t.spaceControlGap - 8;
    final opensAbove = below < 120 && above > below;
    final maxHeight = math.max(
      0.0,
      math.min(280.0, opensAbove ? above : below),
    );
    final options = _visible;
    return Positioned(
      left: left.toDouble(),
      width: width,
      top: opensAbove ? null : origin.dy + box.size.height + t.spaceControlGap,
      bottom: opensAbove ? screen.height - origin.dy + t.spaceControlGap : null,
      child: KSelectionPopup(
        optionsLabel: widget.optionsLabel,
        noResultsLabel: widget.noResultsLabel,
        options: options,
        active: _active,
        value: widget.value,
        maxHeight: maxHeight,
        optionKeys: _optionKeys,
        onActive: (index) => setState(() => _active = index),
        onSelected: _choose,
      ),
    );
  }
}

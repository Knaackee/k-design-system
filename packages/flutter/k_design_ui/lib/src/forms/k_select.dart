import '../localization/k_localization.dart';
import 'dart:ui' show SemanticsValidationResult;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../primitives/k_icon.dart';
import 'form_style.dart';
import 'k_field.dart';
import 'selection_popup.dart';
import 'selection_popup_layout.dart';
import 'form_clear.dart';
import 'option_media.dart';
part 'k_select_trigger.dart';

class KSelectOption {
  const KSelectOption({
    required this.value,
    required this.label,
    this.description,
    this.disabled = false,
    this.icon,
    this.leading,
    this.imageSrc,
  });
  final String value;
  final String label;
  final String? description;
  final bool disabled;
  final KIconName? icon;

  /// Decorative media; takes precedence over icon and imageSrc.
  final Widget? leading;
  final String? imageSrc;
  bool get hasMedia => leading != null || icon != null || imageSrc != null;
}

enum KSelectPresentation { standard, inline }

class KSelect extends StatefulWidget {
  const KSelect({
    required this.options,
    this.value,
    this.onChanged,
    this.multiple = false,
    this.values = const [],
    this.onValuesChanged,
    this.selectionLabel,
    this.label,
    this.placeholder,
    this.clearable = false,
    this.clearLabel,
    this.optionsLabel,
    this.noResultsLabel,
    this.presentation = KSelectPresentation.standard,
    this.truncateLabel = false,
    this.expandedPopup = false,
    this.showInlineIndicator = false,
    this.textAlign = TextAlign.start,
    super.key,
  });
  final KSelectPresentation presentation;
  final TextAlign textAlign;

  /// Ellipsize read-only labels without changing their full accessible text.
  final bool truncateLabel;

  /// Use the picker width, bounded by the viewport, with concise option labels.
  final bool expandedPopup;

  /// Keep the dropdown indicator visible in an unfocused inline control.
  final bool showInlineIndicator;
  final List<KSelectOption> options;
  final String? value;
  final bool multiple;
  final List<String> values;
  final ValueChanged<List<String>>? onValuesChanged;
  final String? selectionLabel;
  bool get enabled => multiple ? onValuesChanged != null : onChanged != null;
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
    super.value,
    super.onChanged,
    super.multiple,
    super.values,
    super.onValuesChanged,
    super.selectionLabel,
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

class _KSelectState extends State<KSelect> with WidgetsBindingObserver {
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
  bool _selected(String value) =>
      widget.multiple ? widget.values.contains(value) : widget.value == value;
  String get _committed => widget.multiple
      ? (widget.selectionLabel ??
            widget.options
                .where((o) => _selected(o.value))
                .map((o) => o.label)
                .join(', '))
      : widget.options
                .where((o) => o.value == widget.value)
                .firstOrNull
                ?.label ??
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
    WidgetsBinding.instance.addObserver(this);
    _text.text = _committed;
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _open) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant KSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!widget.editable || !_open) || oldWidget.value != widget.value) {
      _text.text = _committed;
    }
    if (!widget.enabled && _open) _close();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ancestorScroll?.removeListener(_parentScrolled);

    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _show() {
    if (!widget.enabled) return;
    setState(() {
      _query = '';
      if (widget.editable) _text.clear();
      _active = _visible.indexWhere((o) => _selected(o.value) && !o.disabled);
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
    if (widget.multiple) {
      widget.onValuesChanged?.call([]);
    } else {
      widget.onChanged?.call(null);
    }
    restoreFormFocus(_focus, () => mounted);
  }

  void _choose(KSelectOption option) {
    if (option.disabled) return;
    if (widget.multiple) {
      final next = widget.values.contains(option.value)
          ? widget.values.where((value) => value != option.value).toList()
          : [...widget.values, option.value];
      widget.onValuesChanged?.call(next);
      _focus.requestFocus();
      return;
    }
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

  // Glyphs inside a field keep their size; the text grows (Decision 0015).
  @override
  Widget build(BuildContext context) =>
      KIconFixedScope(child: Builder(builder: _build));

  Widget _build(BuildContext context) {
    final t = formTokens(context);
    final field = KFieldScope.of(context);
    final canClear =
        widget.clearable &&
        widget.enabled &&
        (widget.multiple
            ? widget.values.isNotEmpty
            : widget.value != null || _query.isNotEmpty);
    final selectedOptions = widget.options
        .where((o) => _selected(o.value))
        .toList();
    final selected = selectedOptions.length == 1 ? selectedOptions.first : null;
    final inlineResting =
        widget.presentation == KSelectPresentation.inline &&
        !_focus.hasFocus &&
        !_open;
    final placeholder =
        widget.placeholder ?? KLocalization.of(context).text('choose');
    var appearance = formDecoration(
      context,
      placeholder: placeholder,
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
              SizedBox(
                width: math.max(t.sizeIconDefault, t.sizeHitTarget),
                height: t.sizeContent,
              ),
              SizedBox(width: t.spaceControlGap),
            ],
            Opacity(
              opacity: inlineResting && !widget.showInlineIndicator ? 0 : 1,
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
            button: !widget.editable,
            expanded: _open,
            label: widget.label ?? field?.label,
            value: _text.text.isEmpty ? placeholder : null,
            hint: field?.helperText,
            isRequired: field?.required,
            validationResult: field?.invalid == true
                ? SemanticsValidationResult.invalid
                : SemanticsValidationResult.none,
            child: Opacity(
              opacity: !widget.enabled ? .48 : 1,
              child: ConstrainedBox(
                key: _anchor,
                constraints: BoxConstraints(
                  minHeight: math.max(t.sizeControl, t.sizeHitTarget),
                ),
                child: Center(
                  heightFactor: 1,
                  child: _buildTrigger(context, appearance),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateQuery(String value) {
    if (!_open) _portal.show();
    setState(() {
      _query = value;
      _active = _visible.indexWhere((o) => !o.disabled);
    });
  }

  Widget _popup(BuildContext context) {
    final t = formTokens(context);
    final box = _anchor.currentContext!.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(this.context).context.findRenderObject()! as RenderBox;
    final layout = SelectionPopupLayout(
      box,
      overlay,
      View.of(context),
      t.spaceControlGap,
      preferredWidth: widget.expandedPopup ? t.layoutPickerWidth : null,
    );
    final options = _visible;
    return Positioned(
      left: layout.left,
      width: layout.width,
      top: layout.top,
      bottom: layout.bottom,
      child: KSelectionPopup(
        truncateLabels: widget.expandedPopup,
        optionsLabel: widget.optionsLabel,
        noResultsLabel: widget.noResultsLabel,
        options: options,
        active: _active,
        value: widget.value,
        multiple: widget.multiple,
        values: widget.values,
        maxHeight: layout.maxHeight,
        optionKeys: _optionKeys,
        onActive: (index) => setState(() => _active = index),
        onSelected: _choose,
      ),
    );
  }
}

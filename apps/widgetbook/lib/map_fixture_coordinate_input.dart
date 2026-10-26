import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class MapCoordinateInput extends StatefulWidget {
  const MapCoordinateInput({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  State<MapCoordinateInput> createState() => _MapCoordinateInputState();
}

class _MapCoordinateInputState extends State<MapCoordinateInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(6));
  }

  @override
  void didUpdateWidget(covariant MapCoordinateInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KField(
    label: widget.label,
    child: KInput(
      controller: _controller,
      label: widget.label,
      onSubmitted: (text) {
        final value = double.tryParse(text.replaceFirst(',', '.'));
        if (value != null && value >= widget.min && value <= widget.max) {
          widget.onChanged(value);
        }
      },
    ),
  );
}

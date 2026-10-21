import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_icon.dart';
import 'k_map_overlays.dart';

class KMapDefaultPin extends StatelessWidget {
  const KMapDefaultPin({required this.pin, required this.selected, super.key});
  final KMapPin pin;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final color = pin.color ?? tokens.colorBrandPrimaryAccent;
    final radius = switch (pin.shape) {
      KMapPinShape.pin => BorderRadius.only(
        topLeft: Radius.circular(pin.size / 2),
        topRight: Radius.circular(pin.size / 2),
        bottomLeft: Radius.circular(pin.size / 2),
        bottomRight: Radius.zero,
      ),
      KMapPinShape.circle => BorderRadius.circular(pin.size / 2),
      KMapPinShape.square => BorderRadius.circular(tokens.radiusControl),
    };
    final tipOffset = pin.shape == KMapPinShape.pin
        ? pin.size / 1.41421356237 - (pin.size < 44 ? 44 : pin.size) / 2
        : 0.0;
    return Transform.translate(
      offset: Offset(0, -tipOffset),
      child: Transform.rotate(
        angle: pin.shape == KMapPinShape.pin ? .785398 : 0,
        child: AnimatedContainer(
          duration: tokens.motionStandard,
          width: pin.size,
          height: pin.size,
          decoration: BoxDecoration(
            color: tokens.colorSurfaceRaised,
            borderRadius: radius,
            border: Border.all(color: color, width: tokens.spaceHairline * 3),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: tokens.colorBrandPrimaryAccent,
                  spreadRadius: tokens.spaceHairline * 6,
                ),
              if (selected)
                BoxShadow(
                  color: tokens.colorSurfaceRaised,
                  spreadRadius: tokens.spaceHairline * 3,
                ),
              ...tokens.elevationMedium,
            ],
          ),
          child: Transform.rotate(
            angle: pin.shape == KMapPinShape.pin ? -.785398 : 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(pin.size),
              child: pin.image != null
                  ? Image(image: pin.image!, fit: BoxFit.cover)
                  : Center(
                      child: SizedBox.square(
                        dimension:
                            tokens.sizeIconDefault - tokens.spaceHairline * 4,
                        child: KIcon(
                          pin.icon ?? KIconName.mapPin,
                          size:
                              tokens.sizeIconDefault - tokens.spaceHairline * 4,
                          color: color,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

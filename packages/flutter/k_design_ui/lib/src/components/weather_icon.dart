import 'package:flutter/material.dart';
import '../primitives/k_icon.dart';

enum KWeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  fog,
  drizzle,
  rain,
  snow,
  thunderstorm,
}

enum KWeatherPeriod { day, night }

KIconName kWeatherIconName(
  KWeatherCondition condition, {
  KWeatherPeriod period = KWeatherPeriod.day,
}) => switch (condition) {
  KWeatherCondition.clear =>
    period == KWeatherPeriod.night ? KIconName.moon : KIconName.sun,
  KWeatherCondition.partlyCloudy =>
    period == KWeatherPeriod.night ? KIconName.cloudMoon : KIconName.cloudSun,
  KWeatherCondition.cloudy => KIconName.cloud,
  KWeatherCondition.fog => KIconName.cloudFog,
  KWeatherCondition.drizzle => KIconName.cloudDrizzle,
  KWeatherCondition.rain => KIconName.cloudRain,
  KWeatherCondition.snow => KIconName.cloudSnow,
  KWeatherCondition.thunderstorm => KIconName.cloudLightning,
};

/// Shared semantic weather icons; provider data belongs to the consumer.
class KWeatherIcon extends StatelessWidget {
  const KWeatherIcon({
    required this.condition,
    this.period = KWeatherPeriod.day,
    this.size = 24,
    this.label,
    super.key,
  });

  final KWeatherCondition condition;
  final KWeatherPeriod period;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) => KIcon(
    kWeatherIconName(condition, period: period),
    size: size,
    label: label,
  );
}

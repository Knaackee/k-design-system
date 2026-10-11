import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  test('clear and partly cloudy use matching day and night variants', () {
    expect(kWeatherIconName(KWeatherCondition.clear), KIconName.sun);
    expect(
      kWeatherIconName(KWeatherCondition.clear, period: KWeatherPeriod.night),
      KIconName.moon,
    );
    expect(
      kWeatherIconName(KWeatherCondition.partlyCloudy),
      KIconName.cloudSun,
    );
    expect(
      kWeatherIconName(
        KWeatherCondition.partlyCloudy,
        period: KWeatherPeriod.night,
      ),
      KIconName.cloudMoon,
    );
  });

  test('precipitation remains identifiable at night', () {
    const expected = {
      KWeatherCondition.cloudy: KIconName.cloud,
      KWeatherCondition.fog: KIconName.cloudFog,
      KWeatherCondition.drizzle: KIconName.cloudDrizzle,
      KWeatherCondition.rain: KIconName.cloudRain,
      KWeatherCondition.snow: KIconName.cloudSnow,
      KWeatherCondition.thunderstorm: KIconName.cloudLightning,
    };
    for (final entry in expected.entries) {
      for (final period in KWeatherPeriod.values) {
        expect(kWeatherIconName(entry.key, period: period), entry.value);
      }
    }
  });
}

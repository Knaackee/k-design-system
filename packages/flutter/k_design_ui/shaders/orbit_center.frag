#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform vec4 uShadow;
uniform vec4 uBase;
uniform vec4 uHighlight;
uniform vec4 uRim;

out vec4 fragColor;

void main() {
  vec2 p = (FlutterFragCoord().xy / uSize) * 2.0 - 1.0;
  p.y = -p.y;
  float radius2 = dot(p, p);
  if (radius2 > 1.0) {
    fragColor = vec4(0.0);
    return;
  }

  vec3 normal = normalize(vec3(p, sqrt(max(0.0, 1.0 - radius2))));
  float light = max(0.0, dot(normal, normalize(vec3(-0.6, 0.8, 1.1))));
  float angle = uTime * 0.12;
  vec3 surface = vec3(normal.x * cos(angle) + normal.z * sin(angle),
    normal.y, -normal.x * sin(angle) + normal.z * cos(angle));
  float wave = sin(surface.y * 19.0 + sin(surface.x * 8.0 + uTime * 0.12) * 1.8 + surface.z * 4.0);
  float grain = sin(surface.x * 155.0) * sin(surface.y * 155.0) * 0.012;
  float latitude = abs(sin(asin(clamp(surface.y, -1.0, 1.0)) * 12.0));
  float longitude = abs(sin(atan(surface.z, surface.x) * 14.0));
  float grid = (1.0 - smoothstep(0.0, 0.035, min(latitude, longitude))) * 0.055;
  float rim = pow(1.0 - max(normal.z, 0.0), 3.0);
  vec3 bronze = mix(uShadow.rgb * 0.58, uBase.rgb, light);
  bronze += uHighlight.rgb * pow(light, 7.0) * 0.32;
  bronze += vec3(wave * 0.025 + grain + grid);
  bronze += uRim.rgb * rim * 0.42;
  float alpha = uBase.a * (1.0 - smoothstep(0.985, 1.0, sqrt(radius2)));
  fragColor = vec4(bronze * alpha, alpha);
}

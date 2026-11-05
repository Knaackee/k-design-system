# Decision 0013 — Sound and haptics

> Status: proposed (implemented on `feat/sound-haptics`, pending gallery acceptance)
> Date: 5 November 2026
> Sources: Apple Human Interface Guidelines — Playing haptics, Playing audio;
> Material Design — Haptics; W3C Vibration API

## Problem

The system had Foley sound cues (`KSoundController`, off by default) but no
haptics and no written rules for either: when a cue is appropriate, who
turns it on, and what happens on devices without the capability.

## Decision

1. **Haptics API, parallel to sound:** `KHapticCue` with seven cues that
   match the platform generators — `selection` (UIKit selection feedback),
   `light`/`medium`/`heavy` (impact), `success`/`warning`/`error`
   (notification). `KHapticController` is off by default, drops cues closer
   than `minInterval` (60 ms), stays silent while the app or tab is in the
   background and contains every failure. `KHapticsProvider` scopes it;
   `kHaptic(context, cue)` (Flutter) and `useOptionalKHaptics()` (Web) play
   through the nearest provider.
2. **Transports:** Flutter uses `HapticFeedback.*`; iOS and Android apply the
   person's system haptics setting themselves. Web uses `navigator.vibrate`
   with short patterns; `isSupported` is false where the API is missing
   (Safari on iOS and macOS, most desktops) and every cue is then a no-op.
   Both accept an injected backend for tests and native shells.
3. **Built-in cues:** `KSwitch` → `light`; `KThemeSwitcher` and
   `KLanguageSwitcher` → `selection` (next to their existing sound cue).
   Only with a provider; without one the controls stay silent.
4. **Rules** (skill `rules.md` → Sound and haptics): off by default, the
   person decides, never the only feedback, respect system settings, use
   sparingly for deliberate acts and their outcome, never for scroll, hover,
   typing or repeating events.

## Consequences

- New public API: `KHapticCue`, `KHapticController`, `KHapticBackend`
  (Flutter), `KHapticsProvider`, `kHaptic` (Flutter), `kHapticPatterns`,
  `useKHaptics`/`useOptionalKHaptics` (Web).
- Web haptics reach only Android browsers; iPhone web apps have none. Apps
  that need haptics on iPhone ship the Flutter app or a native shell that
  injects a `vibrate` transport.
- Gallery: Patterns/Haptics/haptics-review on both platforms; haptics can
  only be felt on a real device.

# Sound

`KSoundProvider`, `KSoundController` and `KSoundToggle` provide optional Foley
feedback. `useKSound()` accesses the Web controller; Flutter uses
`KSoundProvider.of(context)`. The consumer owns event mapping and persisted
preferences. Default: disabled, volume 0.25 (range 0–1).

The Web package bundles the same 28 recorded cues used by the Flutter package.
No network audio service, synthesis dependency, automatic click/hover sound or
background music is added. Recordings retain their Foley license and metadata.

## Web

```tsx
<KSoundProvider enabled={soundsEnabled} volume={0.25}>
  <Onboarding />
</KSoundProvider>;

// Inside Onboarding, invoke from committed events, not render/effect replays.
const sound = useKSound();
void sound.play("complete", { eventId: `import:${importId}` });
```

`play(cue, { eventId? })` replaces the current voice. Optional event IDs suppress
duplicate playback; the controller retains the most recent 128 IDs. Disabled,
zero-volume and background playback is skipped. Disabling or hiding stops the
current voice. Failures and autoplay rejection resolve silently and must never
prevent the consumer action. `stop`, `setEnabled`, `setVolume` and `dispose` are
available for non-React hosts. Web `unlock()` primes audio from a user gesture;
the provider listens for pointer and keyboard gestures automatically.

`KSoundToggle` is controlled through `enabled` and `onEnabledChange`; provide
localized `labelEnable` and `labelDisable` strings. It uses the existing public
icon button and volume icons. Sound preferences are independent of reduced-motion
preferences. Every event must remain understandable with sound disabled.

## Matching gallery

- Storybook: `patterns-foleysounds--onboarding`
- Shared fixture ID: `sound-onboarding`
- Selection `tap`, transition `tick`, import completion `complete`, insertion
  `pop`, committed drop `drop`, undo `release`.
- An action that also navigates should emit one cue, not both selection and
  transition. No sound for every render, keystroke, hover, or loading iteration.

The existing `foley-sounds-review` gallery remains the full palette audition.
Native silent-mode/audio-focus behavior and real browser playback require device
verification; a successful typecheck does not establish audible behavior.

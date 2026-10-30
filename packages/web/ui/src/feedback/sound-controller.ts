import { kSoundSources, type KSoundCue } from "./sound-cues.js";

export interface KSoundPlayer {
  src: string;
  volume: number;
  currentTime: number;
  play(): Promise<void>;
  pause(): void;
}
export interface KSoundControllerOptions {
  enabled?: boolean;
  /** Output gain from 0 to 1. */
  volume?: number;
  sources?: Partial<Record<KSoundCue, string>>;
  /** Allows non-DOM hosts and deterministic tests. */
  createPlayer?: () => KSoundPlayer;
}
const gain = (value: number) =>
  Number.isFinite(value) ? Math.max(0, Math.min(1, value)) : 0;
const silence =
  "data:audio/wav;base64,UklGRnQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YVAAAACAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgA==";

/** One voice per provider. Playback failures never escape into navigation. */
export class KSoundController {
  private player?: KSoundPlayer;
  private enabledValue: boolean;
  private volumeValue: number;
  private active = true;
  private disposed = false;
  private generation = 0;
  private unlocked = false;
  private readonly events = new Set<string>();
  constructor(private readonly options: KSoundControllerOptions = {}) {
    this.enabledValue = options.enabled ?? false;
    this.volumeValue = gain(options.volume ?? 0.25);
  }
  get enabled() {
    return this.enabledValue;
  }
  get volume() {
    return this.volumeValue;
  }
  setEnabled(enabled: boolean) {
    this.enabledValue = enabled;
    if (!enabled) this.stop();
  }
  setVolume(volume: number) {
    this.volumeValue = gain(volume);
    if (this.player) this.player.volume = this.volumeValue;
    if (!this.volumeValue) this.stop();
  }
  setActive(active: boolean) {
    // React StrictMode replays provider setup after cleanup using this same
    // controller. Only explicit foreground activation may reopen its lifetime.
    if (active) this.disposed = false;
    this.active = active;
    if (!active) this.stop();
  }
  private getPlayer() {
    this.player ??= this.options.createPlayer?.() ?? new Audio();
    return this.player;
  }
  /** Call from a user gesture; the provider also listens for pointer/key gestures. */
  async unlock(): Promise<void> {
    if (this.disposed || !this.active || this.unlocked) return;
    const generation = ++this.generation;
    try {
      const player = this.getPlayer();
      player.src = silence;
      player.volume = 0;
      await player.play();
      if (this.disposed || generation !== this.generation) return;
      this.unlocked = true;
      player.pause();
      player.volume = this.volumeValue;
    } catch {
      /* Browser policy or unavailable audio: a later gesture can retry. */
    }
  }
  async play(
    cue: KSoundCue,
    options: { eventId?: string } = {},
  ): Promise<void> {
    if (
      this.disposed ||
      !this.enabledValue ||
      !this.volumeValue ||
      !this.active
    )
      return;
    if (options.eventId && this.events.has(options.eventId)) return;
    if (options.eventId) {
      this.events.add(options.eventId);
      if (this.events.size > 128)
        this.events.delete(this.events.values().next().value!);
    }
    this.stop();
    const generation = this.generation;
    try {
      const player = this.getPlayer();
      player.src = this.options.sources?.[cue] ?? kSoundSources[cue];
      player.volume = this.volumeValue;
      await player.play();
      if (this.disposed || generation !== this.generation) return;
      this.unlocked = true;
    } catch {
      /* Audio is supplementary; failed or blocked playback is silent. */
    }
  }
  stop() {
    this.generation++;
    this.player?.pause();
  }
  dispose() {
    this.disposed = true;
    this.active = false;
    this.stop();
    this.player = undefined;
    this.unlocked = false;
    this.events.clear();
  }
}

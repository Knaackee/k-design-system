/** Consumer-supplied envelope; 0 is silence, 1 full scale. No audio is captured. */
export interface KRobotHeadAudioFrame {
  level: number;
  /** Optional normalized frequency bands, low to high. */
  bands?: readonly number[];
}

/** A reader avoids a React render for every audio sample. null means silence. */
export type KRobotHeadAudioSource =
  KRobotHeadAudioFrame | (() => KRobotHeadAudioFrame | null);

export const robotAudioUnit = (value: number): number =>
  Number.isFinite(value) ? Math.min(1, Math.max(0, value)) : 0;

/**
 * Reads an existing consumer-owned analyser (file, microphone or stream).
 * Does not connect nodes, start playback, request permission or own the context.
 * Feed the result to `audio`; disconnect/dispose the graph in the consumer.
 */
export function createKRobotHeadAudioReader(
  analyser: AnalyserNode,
  { gain = 3, bandCount = 12 }: { gain?: number; bandCount?: number } = {},
): () => KRobotHeadAudioFrame {
  let waveform = new Float32Array(analyser.fftSize);
  let spectrum = new Uint8Array(analyser.frequencyBinCount);
  const count = Math.max(1, Math.min(32, Math.round(bandCount) || 12));
  const bands = Array<number>(count).fill(0);
  const frame: KRobotHeadAudioFrame = { level: 0, bands };
  const amplification = Number.isFinite(gain) ? Math.max(0, gain) : 3;
  return () => {
    if (waveform.length !== analyser.fftSize)
      waveform = new Float32Array(analyser.fftSize);
    if (spectrum.length !== analyser.frequencyBinCount)
      spectrum = new Uint8Array(analyser.frequencyBinCount);
    analyser.getFloatTimeDomainData(waveform);
    analyser.getByteFrequencyData(spectrum);
    let sum = 0;
    for (const sample of waveform) sum += sample * sample;
    frame.level = robotAudioUnit(
      Math.sqrt(sum / waveform.length) * amplification,
    );
    // Logarithmic bands retain the lower speech frequencies.
    for (let i = 0; i < count; i++) {
      const start = Math.floor(Math.pow(spectrum.length, i / count)) - 1;
      const end = Math.max(
        start + 1,
        Math.floor(Math.pow(spectrum.length, (i + 1) / count)),
      );
      let peak = 0;
      for (let j = Math.max(0, start); j < Math.min(end, spectrum.length); j++)
        peak = Math.max(peak, spectrum[j] / 255);
      bands[i] = peak * frame.level;
    }
    return frame;
  };
}

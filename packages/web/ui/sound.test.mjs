import test from "node:test";
import assert from "node:assert/strict";
import { KSoundController } from "./dist/feedback/sound-controller.js";
import { kSoundSources } from "./dist/feedback/sound-cues.js";

function fixture(options = {}) {
  const calls = [];
  const player = {
    src: "",
    volume: 0,
    currentTime: 0,
    play: async () => {
      calls.push(["play", player.src]);
    },
    pause: () => calls.push(["pause"]),
  };
  return {
    calls,
    player,
    sound: new KSoundController({ createPlayer: () => player, ...options }),
  };
}
test("silent by default and volume is bounded", async () => {
  const { sound, calls } = fixture();
  await sound.play("tap");
  assert.equal(calls.length, 0);
  sound.setVolume(2);
  assert.equal(sound.volume, 1);
  sound.setVolume(NaN);
  assert.equal(sound.volume, 0);
});
test("one voice, event deduplication, muted and hidden states", async () => {
  const { sound, calls } = fixture({ enabled: true });
  await sound.play("tap", { eventId: "a" });
  await sound.play("tap", { eventId: "a" });
  assert.equal(calls.filter(([type]) => type === "play").length, 1);
  await sound.play("drop");
  assert.deepEqual(calls.at(-2), ["pause"]);
  sound.setActive(false);
  await sound.play("complete");
  assert.equal(calls.filter(([type]) => type === "play").length, 2);
  sound.setActive(true);
  sound.setEnabled(false);
  await sound.play("complete");
  assert.equal(calls.filter(([type]) => type === "play").length, 2);
});
test("playback and unlock failures cannot reject consumer action", async () => {
  const sound = new KSoundController({
    enabled: true,
    createPlayer: () => {
      throw new Error("unavailable");
    },
  });
  await assert.doesNotReject(sound.unlock());
  await assert.doesNotReject(sound.play("tap"));
});
test("all 28 cues use package-owned recordings", () => {
  assert.equal(Object.keys(kSoundSources).length, 28);
  assert.ok(
    Object.values(kSoundSources).every(
      (value) => value.includes("/src/assets/foley/") && value.endsWith(".wav"),
    ),
  );
});

test("disposed delayed callbacks stay silent; provider setup can reactivate", async () => {
  const { sound, calls } = fixture({ enabled: true });
  await sound.play("tap");
  sound.dispose();
  const count = calls.length;
  await sound.play("pop");
  await sound.unlock();
  assert.equal(calls.length, count);
  sound.setActive(true);
  await sound.play("tap");
  assert.equal(calls.filter(([type]) => type === "play").length, 2);
});

test("a completed unlock from an old lifetime cannot affect a new player", async () => {
  let resolveUnlock;
  let creations = 0;
  const players = [];
  const sound = new KSoundController({
    enabled: true,
    createPlayer: () => {
      creations++;
      const player = {
        src: "",
        currentTime: 0,
        volume: 0,
        pauses: 0,
        pause() {
          this.pauses++;
        },
        play:
          creations === 1
            ? () =>
                new Promise((resolve) => {
                  resolveUnlock = resolve;
                })
            : async () => {},
      };
      players.push(player);
      return player;
    },
  });
  const pending = sound.unlock();
  sound.dispose();
  sound.setActive(true);
  await sound.play("complete");
  resolveUnlock();
  await pending;
  assert.equal(players[1].pauses, 0);
  assert.equal(players[1].volume, 0.25);
});

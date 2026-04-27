import { createAudioPlayer, AudioPlayer, setAudioModeAsync } from 'expo-audio';
import { RECITERS } from './constants';

let currentPlayer: AudioPlayer | null = null;
let onCompleteCallback: (() => void) | null = null;
let currentReciterId: number = RECITERS[0].id;
let currentSpeed = 1.0;
let audioModeConfigured = false;
let playToken = 0;

// Preloaded player for the next ayah. Created during the current ayah's
// playback so that when the current ayah ends we can swap to a fully buffered
// player and start playing immediately, eliminating the audible gap.
let preloadedPlayer: AudioPlayer | null = null;
let preloadedKey: string | null = null;

export function setReciterId(id: number): void {
  if (currentReciterId === id) return;
  currentReciterId = id;
  // Reciter changed — preloaded URL is for the old voice, drop it.
  discardPreload();
}

export function getValidReciterId(id: number): number {
  return RECITERS.some((r) => r.id === id) ? id : RECITERS[0].id;
}

function getAudioUrl(surah: number, ayah: number): string {
  const reciter = RECITERS.find((r) => r.id === currentReciterId) ?? RECITERS[0];
  const surahStr = String(surah).padStart(3, '0');
  const ayahStr = String(ayah).padStart(3, '0');
  return reciter.urlTemplate.replace('{NNNAAA}', `${surahStr}${ayahStr}`);
}

function ayahKey(surah: number, ayah: number): string {
  return `${surah}:${ayah}`;
}

function discardPreload(): void {
  if (preloadedPlayer) {
    try { preloadedPlayer.remove(); } catch { /* already disposed */ }
    preloadedPlayer = null;
  }
  preloadedKey = null;
}

async function ensureAudioMode(): Promise<void> {
  if (audioModeConfigured) return;
  await setAudioModeAsync({
    playsInSilentMode: true,
    shouldPlayInBackground: false,
    interruptionMode: 'doNotMix',
    interruptionModeAndroid: 'doNotMix',
    shouldRouteThroughEarpiece: false,
    allowsRecording: false,
  });
  audioModeConfigured = true;
}

export async function stopAudio(): Promise<void> {
  if (currentPlayer) {
    try { currentPlayer.pause(); } catch { /* already disposed */ }
    try {
      currentPlayer.remove();
    } catch (err) {
      if (__DEV__) console.warn('[audioService] player.remove failed', err);
    }
    currentPlayer = null;
  }
}

// Spin up a player for the next ayah and let it buffer in the background. Cheap
// no-op if we already have a preload for this ayah; replaces any other preload.
export function preloadAyah(surah: number, ayah: number): void {
  const key = ayahKey(surah, ayah);
  if (preloadedKey === key && preloadedPlayer) return;
  discardPreload();
  try {
    const player = createAudioPlayer({ uri: getAudioUrl(surah, ayah) });
    preloadedPlayer = player;
    preloadedKey = key;
  } catch (err) {
    if (__DEV__) console.warn('[audioService] preload failed', surah, ayah, err);
    preloadedPlayer = null;
    preloadedKey = null;
  }
}

export async function playAyah(surah: number, ayah: number): Promise<void> {
  const myToken = ++playToken;
  await ensureAudioMode();

  const wantedKey = ayahKey(surah, ayah);

  // Fast path: preload matches what we're about to play. Swap it in without
  // tearing down audio across an HTTP round-trip.
  if (preloadedKey === wantedKey && preloadedPlayer) {
    const next = preloadedPlayer;
    preloadedPlayer = null;
    preloadedKey = null;

    // Tear down the previous player AFTER taking ownership of the preload, so
    // there's no window where neither player is current.
    if (currentPlayer) {
      try { currentPlayer.pause(); } catch { /* already disposed */ }
      try { currentPlayer.remove(); } catch { /* already disposed */ }
      currentPlayer = null;
    }

    next.setPlaybackRate(currentSpeed);
    next.addListener('playbackStatusUpdate', (status) => {
      if (myToken !== playToken) return;
      if (status.didJustFinish) onCompleteCallback?.();
    });

    if (myToken !== playToken) {
      try { next.remove(); } catch { /* superseded */ }
      return;
    }

    currentPlayer = next;
    next.play();
    if (__DEV__) console.log('[audioService] playAyah(preloaded)', surah, ayah);
    return;
  }

  // Slow path: no matching preload. Stop current and create a fresh player.
  await stopAudio();
  if (myToken !== playToken) return;

  const url = getAudioUrl(surah, ayah);
  if (__DEV__) console.log('[audioService] playAyah', surah, ayah, url);

  const player = createAudioPlayer({ uri: url });
  player.setPlaybackRate(currentSpeed);
  player.addListener('playbackStatusUpdate', (status) => {
    if (myToken !== playToken) return;
    if (status.didJustFinish) onCompleteCallback?.();
  });

  if (myToken !== playToken) {
    try { player.remove(); } catch { /* superseded */ }
    return;
  }

  currentPlayer = player;
  player.play();
}

export async function pauseAudio(): Promise<void> {
  currentPlayer?.pause();
}

export async function resumeAudio(): Promise<void> {
  currentPlayer?.play();
}

export function isAudioLoaded(): boolean {
  return currentPlayer !== null;
}

export function setAudioSpeed(speed: number): void {
  currentSpeed = speed;
  if (currentPlayer) {
    currentPlayer.setPlaybackRate(speed);
  }
  if (preloadedPlayer) {
    preloadedPlayer.setPlaybackRate(speed);
  }
}

export function setOnComplete(callback: (() => void) | null): void {
  onCompleteCallback = callback;
}

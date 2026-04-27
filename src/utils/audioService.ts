import { createAudioPlayer, AudioPlayer, setAudioModeAsync } from 'expo-audio';
import { RECITERS } from './constants';

let currentPlayer: AudioPlayer | null = null;
let onCompleteCallback: (() => void) | null = null;
let currentReciterId: number = RECITERS[0].id;
let currentSpeed = 1.0;
let audioModeConfigured = false;
let playToken = 0;

export function setReciterId(id: number): void {
  currentReciterId = id;
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
    try {
      currentPlayer.remove();
    } catch (err) {
      if (__DEV__) console.warn('[audioService] player.remove failed', err);
    }
    currentPlayer = null;
  }
}

export async function playAyah(surah: number, ayah: number): Promise<void> {
  const myToken = ++playToken;
  await ensureAudioMode();
  await stopAudio();
  if (myToken !== playToken) return; // a newer call superseded us

  const url = getAudioUrl(surah, ayah);
  if (__DEV__) console.log('[audioService] playAyah', surah, ayah, url);

  const player = createAudioPlayer({ uri: url });
  player.playbackRate = currentSpeed;

  player.addListener('playbackStatusUpdate', (status) => {
    if (myToken !== playToken) return;
    if (status.didJustFinish) {
      onCompleteCallback?.();
    }
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
    currentPlayer.playbackRate = speed;
  }
}

export function setOnComplete(callback: (() => void) | null): void {
  onCompleteCallback = callback;
}

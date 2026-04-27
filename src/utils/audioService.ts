import { createAudioPlayer, AudioPlayer, setAudioModeAsync } from 'expo-audio';
import { RECITERS } from './constants';

let currentPlayer: AudioPlayer | null = null;
let onCompleteCallback: (() => void) | null = null;
let currentReciterId: number = RECITERS[0].id;
let currentSpeed = 1.0;
let audioModeConfigured = false;

export function setReciterId(id: number): void {
  currentReciterId = id;
}

function getAudioUrl(surah: number, ayah: number): string {
  const reciter = RECITERS.find((r) => r.id === currentReciterId) ?? RECITERS[0];
  const surahStr = String(surah).padStart(3, '0');
  const ayahStr = String(ayah).padStart(3, '0');
  return reciter.urlTemplate.replace('{NNNAAA}', `${surahStr}${ayahStr}`);
}

async function ensureAudioMode(): Promise<void> {
  if (audioModeConfigured) return;
  try {
    await setAudioModeAsync({
      playsInSilentMode: true,
      shouldPlayInBackground: false,
      interruptionMode: 'doNotMix',
      interruptionModeAndroid: 'doNotMix',
      shouldRouteThroughEarpiece: false,
      allowsRecording: false,
    });
    audioModeConfigured = true;
  } catch (err) {
    console.warn('[audioService] setAudioModeAsync failed', err);
  }
}

export async function stopAudio(): Promise<void> {
  if (currentPlayer) {
    try {
      currentPlayer.remove();
    } catch {
      // ignore
    }
    currentPlayer = null;
  }
}

export async function playAyah(surah: number, ayah: number): Promise<void> {
  await ensureAudioMode();
  await stopAudio();

  const url = getAudioUrl(surah, ayah);
  if (__DEV__) console.log('[audioService] playAyah', surah, ayah, url);

  const player = createAudioPlayer({ uri: url });
  player.playbackRate = currentSpeed;

  player.addListener('playbackStatusUpdate', (status) => {
    if (status.didJustFinish) {
      onCompleteCallback?.();
    }
  });

  player.play();
  currentPlayer = player;
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

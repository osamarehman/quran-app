import { createAudioPlayer, AudioPlayer, setAudioModeAsync } from 'expo-audio';

let currentPlayer: AudioPlayer | null = null;
let onCompleteCallback: (() => void) | null = null;
let currentReciterId = 7;
let currentSpeed = 1.0;

const AUDIO_BASE_URL = 'https://verses.quran.com';

export function setReciterId(id: number): void {
  currentReciterId = id;
}

function getAudioUrl(surah: number, ayah: number): string {
  const surahStr = String(surah).padStart(3, '0');
  const ayahStr = String(ayah).padStart(3, '0');
  return `${AUDIO_BASE_URL}/${currentReciterId}/${surahStr}${ayahStr}.mp3`;
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
  await stopAudio();
  await setAudioModeAsync({ playsInSilentMode: true });

  const player = createAudioPlayer({ uri: getAudioUrl(surah, ayah) });
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

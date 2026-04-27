import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { MushafMode, ThemeMode } from '../types/mushaf';

interface AppState {
  mushafMode: MushafMode;
  themeMode: ThemeMode;
  lastReadPage: number;
  bookmarks: number[];
  isPlaying: boolean;
  audioSpeed: number;
  audioEnabled: boolean;
  selectedQariId: number;
  selectedFont: string;
  setMushafMode: (mode: MushafMode) => void;
  setThemeMode: (mode: ThemeMode) => void;
  setLastReadPage: (page: number) => void;
  toggleBookmark: (page: number) => void;
  isBookmarked: (page: number) => boolean;
  setIsPlaying: (playing: boolean) => void;
  setAudioSpeed: (speed: number) => void;
  setAudioEnabled: (enabled: boolean) => void;
  setSelectedQariId: (id: number) => void;
  setSelectedFont: (font: string) => void;
}

export const useAppStore = create<AppState>()(
  persist(
    (set, get) => ({
      mushafMode: '16-line',
      themeMode: 'light',
      lastReadPage: 1,
      bookmarks: [],
      isPlaying: false,
      audioSpeed: 1.0,
      audioEnabled: true,
      selectedQariId: 7,
      selectedFont: 'AlQuranIndoPak',
      setMushafMode: (mode) => set({ mushafMode: mode }),
      setThemeMode: (mode) => set({ themeMode: mode }),
      setLastReadPage: (page) => set({ lastReadPage: page }),
      toggleBookmark: (page) => {
        const { bookmarks } = get();
        const exists = bookmarks.includes(page);
        set({
          bookmarks: exists
            ? bookmarks.filter((p) => p !== page)
            : [...bookmarks, page],
        });
      },
      isBookmarked: (page) => get().bookmarks.includes(page),
      setIsPlaying: (playing) => set({ isPlaying: playing }),
      setAudioSpeed: (speed) => set({ audioSpeed: speed }),
      setAudioEnabled: (enabled) => set({ audioEnabled: enabled }),
      setSelectedQariId: (id) => set({ selectedQariId: id }),
      setSelectedFont: (font) => set({ selectedFont: font }),
    }),
    {
      name: 'quran-mushaf-store',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);

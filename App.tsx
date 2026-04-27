import React, { useState, useCallback, useRef, useMemo, useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import { StyleSheet, View, ActivityIndicator, Text } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { useFonts } from 'expo-font';
import { useDatabaseInit } from './src/hooks/useDatabase';
import { useAppStore } from './src/stores/appStore';
import { getTheme } from './src/theme/colors';
import { SURAH_LIST } from './src/utils/constants';
import { playAyah, pauseAudio, resumeAudio, stopAudio, setOnComplete, setAudioSpeed, setReciterId, getValidReciterId, preloadAyah } from './src/utils/audioService';
import { getSurahNumberForPage, getPageForSurah } from './src/db/database';
import PageSwiper, { PageSwiperRef } from './src/components/mushaf/PageSwiper';
import Header from './src/components/ui/Header';
import JumpToNavigator from './src/components/ui/JumpToNavigator';
import BookmarksList from './src/components/ui/BookmarksList';
import SettingsPanel from './src/components/ui/SettingsPanel';

function getSurahForPage(page: number): typeof SURAH_LIST[number] {
  for (let i = SURAH_LIST.length - 1; i >= 0; i--) {
    if (SURAH_LIST[i].page <= page) return SURAH_LIST[i];
  }
  return SURAH_LIST[0];
}

// Returns the ayah immediately following (surah, ayah), wrapping into the next
// surah at end-of-surah, or null at end of mushaf.
function nextAyahAfter(surahNumber: number, ayahNumber: number): { surah: number; ayah: number } | null {
  const surah = SURAH_LIST.find((s) => s.number === surahNumber);
  if (!surah) return null;
  if (ayahNumber + 1 <= surah.verses) return { surah: surahNumber, ayah: ayahNumber + 1 };
  if (surahNumber + 1 > 114) return null;
  return { surah: surahNumber + 1, ayah: 1 };
}

export default function App() {
  // Block first render until Zustand has rehydrated lastReadPage from AsyncStorage,
  // otherwise PageSwiper mounts with the default (page 1) before persisted state loads.
  // 5s timeout protects against AsyncStorage failures hanging the loading screen forever.
  const [hydrated, setHydrated] = useState(useAppStore.persist.hasHydrated());
  useEffect(() => {
    if (hydrated) return;
    const unsub = useAppStore.persist.onFinishHydration(() => setHydrated(true));
    const timeout = setTimeout(() => {
      console.warn('[App] hydration timed out; proceeding with defaults');
      setHydrated(true);
    }, 5000);
    return () => {
      unsub();
      clearTimeout(timeout);
    };
  }, [hydrated]);

  const mushafMode = useAppStore((s) => s.mushafMode);
  const themeMode = useAppStore((s) => s.themeMode);
  const lastReadPage = useAppStore((s) => s.lastReadPage);
  const setLastReadPage = useAppStore((s) => s.setLastReadPage);
  const setMushafMode = useAppStore((s) => s.setMushafMode);
  const bookmarks = useAppStore((s) => s.bookmarks);
  const toggleBookmark = useAppStore((s) => s.toggleBookmark);
  const setThemeMode = useAppStore((s) => s.setThemeMode);
  const isPlaying = useAppStore((s) => s.isPlaying);
  const setIsPlaying = useAppStore((s) => s.setIsPlaying);
  const audioEnabled = useAppStore((s) => s.audioEnabled);
  const audioSpeed = useAppStore((s) => s.audioSpeed);
  const selectedQariId = useAppStore((s) => s.selectedQariId);
  const setSelectedQariId = useAppStore((s) => s.setSelectedQariId);
  const selectedFont = useAppStore((s) => s.selectedFont);

  const [currentPage, setCurrentPage] = useState(lastReadPage);
  // After hydration, sync currentPage to the persisted lastReadPage (the initial
  // useState ran before persist finished loading from AsyncStorage).
  useEffect(() => {
    if (hydrated) setCurrentPage(lastReadPage);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [hydrated]);
  const [currentSurahName, setCurrentSurahName] = useState('');
  const [navigatorVisible, setNavigatorVisible] = useState(false);
  const [bookmarksVisible, setBookmarksVisible] = useState(false);
  const [settingsVisible, setSettingsVisible] = useState(false);
  const [audioAyah, setAudioAyah] = useState<{ surah: number; ayah: number } | null>(null);
  // Ref mirror of audioAyah so the long-lived onComplete callback can read the
  // latest value without needing the effect to re-register on every change.
  const audioAyahRef = useRef(audioAyah);
  useEffect(() => {
    audioAyahRef.current = audioAyah;
  }, [audioAyah]);
  const { ready: dbReady, error: dbError } = useDatabaseInit();
  const swiperRef = useRef<PageSwiperRef>(null);
  const surahQueryId = useRef(0);

  useEffect(() => {
    if (!dbReady) return;
    // Clear synchronously before the async query so the header doesn't show a stale surah name during navigation
    setCurrentSurahName('');
    const id = ++surahQueryId.current;
    getSurahNumberForPage(mushafMode, currentPage)
      .then((num) => {
        if (id !== surahQueryId.current) return;
        const surah = SURAH_LIST.find((s) => s.number === num);
        if (surah) setCurrentSurahName(surah.name);
      })
      .catch((err) => {
        console.warn('[App] getSurahNumberForPage failed for page', currentPage, err);
      });
  }, [dbReady, mushafMode, currentPage]);

  const theme = useMemo(() => getTheme(themeMode), [themeMode]);

  useEffect(() => {
    // When the current ayah finishes naturally, auto-advance to the next ayah
    // (continuing into the next surah at end-of-surah) and keep playing. Tapping
    // a different ayah or hitting pause overrides this chain via the normal
    // handlers — they call playAyah/pauseAudio which cancel any pending advance.
    setOnComplete(() => {
      const current = audioAyahRef.current;
      if (!current) {
        setIsPlaying(false);
        return;
      }
      const next = nextAyahAfter(current.surah, current.ayah);
      if (!next) {
        // End of mushaf — stop the chain.
        setIsPlaying(false);
        setAudioAyah(null);
        return;
      }
      setAudioAyah(next);
      playAyah(next.surah, next.ayah)
        .then(() => {
          // Preload the one after so the next gap-free swap can happen too.
          const after = nextAyahAfter(next.surah, next.ayah);
          if (after) preloadAyah(after.surah, after.ayah);
        })
        .catch((err) => {
          console.error('[App] auto-advance failed', next.surah, next.ayah, err);
          setIsPlaying(false);
          setAudioAyah(null);
        });
    });
    return () => {
      setOnComplete(null);
    };
  }, [setIsPlaying]);

  useEffect(() => {
    if (!audioEnabled && isPlaying) {
      stopAudio();
      setIsPlaying(false);
      setAudioAyah(null);
    }
  }, [audioEnabled, isPlaying, setIsPlaying]);

  useEffect(() => {
    setAudioSpeed(audioSpeed);
  }, [audioSpeed]);

  useEffect(() => {
    // If a previously persisted qari id is no longer in the RECITERS list (e.g. after
    // an upgrade that re-shaped the list), repair the persisted value rather than
    // silently falling back to a different reciter.
    const valid = getValidReciterId(selectedQariId);
    if (valid !== selectedQariId) setSelectedQariId(valid);
    setReciterId(valid);
  }, [selectedQariId, setSelectedQariId]);

  const [fontsLoaded] = useFonts({
    DigitalKhattIndoPak: require('./assets/fonts/DigitalKhattIndoPak.otf'),
    IndopakNastaleeq: require('./assets/fonts/indopak-nastaleeq.ttf'),
    AmiriQuran: require('./assets/fonts/AmiriQuran.ttf'),
    UthmanicHafs: require('./assets/fonts/UthmanicHafs.ttf'),
    AlQuranIndoPak: require('./assets/fonts/AlQuranIndoPak.ttf'),
  });

  const handlePageChange = useCallback(
    (page: number) => {
      setCurrentPage(page);
      setLastReadPage(page);
    },
    [setLastReadPage]
  );

  const handleToggleMode = useCallback(async () => {
    const next = mushafMode === '16-line' ? '15-line' : '16-line';
    // Page numbers don't align between the two modes — pages are laid out
    // differently. Look up the current surah and jump to its first page in
    // the target mode so the user keeps reading where they left off.
    let targetPage = 1;
    try {
      const surahNumber = await getSurahNumberForPage(mushafMode, currentPage);
      if (surahNumber) {
        const page = await getPageForSurah(next, surahNumber);
        if (page) targetPage = page;
      }
    } catch (err) {
      console.warn('[App] mode-switch lookup failed', err);
    }
    setLastReadPage(targetPage);
    setCurrentPage(targetPage);
    setMushafMode(next);
  }, [mushafMode, currentPage, setMushafMode, setLastReadPage]);

  const handleNavigate = useCallback(
    (page: number) => {
      swiperRef.current?.scrollToPage(page);
    },
    []
  );

  const handleToggleTheme = useCallback(() => {
    setThemeMode(themeMode === 'dark' ? 'light' : 'dark');
  }, [themeMode, setThemeMode]);

  const handleToggleAudio = useCallback(async () => {
    try {
      if (isPlaying) {
        await pauseAudio();
        setIsPlaying(false);
      } else {
        if (audioAyah) {
          await resumeAudio();
          setIsPlaying(true);
        } else {
          const surah = getSurahForPage(currentPage);
          await playAyah(surah.number, 1);
          setAudioAyah({ surah: surah.number, ayah: 1 });
          setIsPlaying(true);
          const after = nextAyahAfter(surah.number, 1);
          if (after) preloadAyah(after.surah, after.ayah);
        }
      }
    } catch (err) {
      console.error('[App] handleToggleAudio failed', err);
      setIsPlaying(false);
      setAudioAyah(null);
    }
  }, [isPlaying, audioAyah, currentPage, setIsPlaying]);

  const handleAyahPress = useCallback(async (surah: number, ayah: number) => {
    if (!audioEnabled) return;
    try {
      await playAyah(surah, ayah);
      setAudioAyah({ surah, ayah });
      setIsPlaying(true);
      const after = nextAyahAfter(surah, ayah);
      if (after) preloadAyah(after.surah, after.ayah);
    } catch (err) {
      console.error('[App] handleAyahPress failed', surah, ayah, err);
      setIsPlaying(false);
      setAudioAyah(null);
    }
  }, [audioEnabled, setIsPlaying]);

  if (!fontsLoaded || !dbReady || !hydrated) {
    return (
      <View style={[styles.loadingContainer, { backgroundColor: theme.pageBackground }]}>
        <ActivityIndicator size="large" color={theme.primary} />
        <Text style={[styles.loadingText, { color: theme.text }]}>
          {!fontsLoaded ? 'Loading fonts...' : !hydrated ? 'Restoring last position...' : 'Loading Quran data...'}
        </Text>
        {dbError && (
          <Text style={[styles.errorText, { color: theme.error }]}>{dbError.message}</Text>
        )}
      </View>
    );
  }

  return (
    <GestureHandlerRootView style={[styles.container, { backgroundColor: theme.background }]}>
      <StatusBar style={themeMode === 'dark' ? 'light' : 'dark'} />
      <Header
        mode={mushafMode}
        currentSurahName={currentSurahName}
        isBookmarked={bookmarks.includes(currentPage)}
        isPlaying={isPlaying}
        themeMode={themeMode}
        audioEnabled={audioEnabled}
        onToggleMode={handleToggleMode}
        onOpenNavigator={() => setNavigatorVisible(true)}
        onToggleBookmark={() => {
          toggleBookmark(currentPage);
        }}
        onOpenBookmarks={() => setBookmarksVisible(true)}
        onToggleTheme={handleToggleTheme}
        onToggleAudio={handleToggleAudio}
        onOpenSettings={() => setSettingsVisible(true)}
      />
      <PageSwiper
        // Remount when mode changes so initialPage applies in the new mode
        // (page numbers don't align between 15-line and 16-line layouts).
        key={mushafMode}
        ref={swiperRef}
        mode={mushafMode}
        initialPage={lastReadPage}
        onPageChange={handlePageChange}
        fontFamily={selectedFont}
        onAyahPress={handleAyahPress}
      />
      <JumpToNavigator
        visible={navigatorVisible}
        mode={mushafMode}
        onClose={() => setNavigatorVisible(false)}
        onNavigate={handleNavigate}
      />
      <BookmarksList
        visible={bookmarksVisible}
        mode={mushafMode}
        onClose={() => setBookmarksVisible(false)}
        onNavigate={handleNavigate}
      />
      <SettingsPanel
        visible={settingsVisible}
        onClose={() => setSettingsVisible(false)}
      />
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
  },
  errorText: {
    marginTop: 12,
    fontSize: 14,
    textAlign: 'center',
    paddingHorizontal: 24,
  },
});

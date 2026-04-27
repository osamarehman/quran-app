import React, { useState, useCallback, useRef, useMemo, useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import { StyleSheet, View, ActivityIndicator, Text } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { useFonts } from 'expo-font';
import { useDatabaseInit } from './src/hooks/useDatabase';
import { useAppStore } from './src/stores/appStore';
import { getTheme } from './src/theme/colors';
import { SURAH_LIST } from './src/utils/constants';
import { playAyah, pauseAudio, resumeAudio, stopAudio, setOnComplete, setAudioSpeed, setReciterId } from './src/utils/audioService';
import { getSurahNumberForPage } from './src/db/database';
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

export default function App() {
  // Block first render until Zustand has rehydrated lastReadPage from AsyncStorage,
  // otherwise PageSwiper mounts with the default (page 1) before persisted state loads.
  const [hydrated, setHydrated] = useState(useAppStore.persist.hasHydrated());
  useEffect(() => {
    if (hydrated) return;
    const unsub = useAppStore.persist.onFinishHydration(() => setHydrated(true));
    return unsub;
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
      .catch(() => {});
  }, [dbReady, mushafMode, currentPage]);

  const theme = useMemo(() => getTheme(themeMode), [themeMode]);

  useEffect(() => {
    setOnComplete(() => {
      setIsPlaying(false);
      setAudioAyah(null);
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
    setReciterId(selectedQariId);
  }, [selectedQariId]);

  const [fontsLoaded] = useFonts({
    DigitalKhattIndoPak: require('./assets/fonts/DigitalKhattIndoPak.otf'),
    IndopakNastaleeq: require('./assets/fonts/indopak-nastaleeq.ttf'),
    AmiriQuran: require('./assets/fonts/AmiriQuran.ttf'),
    UthmanicHafs: require('./assets/fonts/UthmanicHafs.ttf'),
  });

  const handlePageChange = useCallback(
    (page: number) => {
      setCurrentPage(page);
      setLastReadPage(page);
    },
    [setLastReadPage]
  );

  const handleToggleMode = useCallback(() => {
    const next = mushafMode === '16-line' ? '15-line' : '16-line';
    setMushafMode(next);
  }, [mushafMode, setMushafMode]);

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
        }
      }
    } catch {
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
    } catch {
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

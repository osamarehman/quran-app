import React, { useCallback, useRef, useImperativeHandle, forwardRef, useMemo } from 'react';
import {
  View,
  FlatList,
  useWindowDimensions,
  StyleSheet,
  Text,
  ActivityIndicator,
} from 'react-native';
import { MushafMode } from '../../types/mushaf';
import { usePageData } from '../../hooks/usePageData';
import MushafPage from './MushafPage';
import { MUSHAF_CONFIG, SURAH_LIST, JUZ_NAMES } from '../../utils/constants';
import { useTheme } from '../../hooks/useTheme';

export interface PageSwiperRef {
  scrollToPage: (page: number) => void;
}

interface Props {
  mode: MushafMode;
  initialPage: number;
  onPageChange: (page: number) => void;
  fontFamily: string;
  onAyahPress?: (surah: number, ayah: number) => void;
}

const PageSwiper = React.memo(
  forwardRef<PageSwiperRef, Props>(function PageSwiper(
    { mode, initialPage, onPageChange, fontFamily, onAyahPress },
    ref
  ) {
    const { width: screenWidth } = useWindowDimensions();
    const flatListRef = useRef<FlatList>(null);
    const totalPages = MUSHAF_CONFIG[mode].pages;
    const theme = useTheme();

    useImperativeHandle(ref, () => ({
      scrollToPage: (page: number) => {
        const index = Math.max(0, Math.min(page - 1, totalPages - 1));
        flatListRef.current?.scrollToIndex({ index, animated: true });
      },
    }));

    const renderItem = useCallback(
      ({ item }: { item: number }) => {
        return (
          <PageRenderer
            mode={mode}
            pageNumber={item}
            screenWidth={screenWidth}
            fontFamily={fontFamily}
            onAyahPress={onAyahPress}
          />
        );
      },
      [mode, screenWidth, fontFamily, onAyahPress]
    );

    const keyExtractor = useCallback(
      (item: number) => `${mode}-${item}`,
      [mode]
    );

    const getItemLayout = useCallback(
      (_: any, index: number) => ({
        length: screenWidth,
        offset: screenWidth * index,
        index,
      }),
      [screenWidth]
    );

    const pages = Array.from({ length: totalPages }, (_, i) => i + 1);

    const handleViewableItemsChanged = useCallback(
      ({ viewableItems }: { viewableItems: Array<{ item?: number }> }) => {
        if (viewableItems.length > 0 && viewableItems[0].item) {
          onPageChange(viewableItems[0].item);
        }
      },
      [onPageChange]
    );

    // Must be a stable ref — FlatList throws if onViewableItemsChanged changes after mount
    const viewabilityConfigCallbackPairs = useRef([
      {
        viewabilityConfig: { itemVisiblePercentThreshold: 80 },
        onViewableItemsChanged: handleViewableItemsChanged,
      },
    ]);

    return (
      <View style={[styles.container, { backgroundColor: theme.background }]}>
        <FlatList
          ref={flatListRef}
          data={pages}
          renderItem={renderItem}
          keyExtractor={keyExtractor}
          getItemLayout={getItemLayout}
          horizontal
          pagingEnabled
          inverted={true}
          initialScrollIndex={initialPage - 1}
          windowSize={3}
          initialNumToRender={1}
          maxToRenderPerBatch={2}
          viewabilityConfigCallbackPairs={viewabilityConfigCallbackPairs.current}
          showsHorizontalScrollIndicator={false}
          removeClippedSubviews={true}
        />
      </View>
    );
  })
);

const PageRenderer = React.memo(function PageRenderer({
  mode,
  pageNumber,
  screenWidth,
  fontFamily,
  onAyahPress,
}: {
  mode: MushafMode;
  pageNumber: number;
  screenWidth: number;
  fontFamily: string;
  onAyahPress?: (surah: number, ayah: number) => void;
}) {
  const { lines, pageSurahNumber, pageJuzNumber, loading, error } = usePageData(mode, pageNumber);
  const theme = useTheme();

  const surahName = useMemo(() => {
    if (!pageSurahNumber) return '';
    return SURAH_LIST.find(s => s.number === pageSurahNumber)?.name ?? '';
  }, [pageSurahNumber]);

  const juzLabel = JUZ_NAMES[pageJuzNumber - 1] ?? '';

  if (loading) {
    return (
      <View style={[styles.pageContainer, { width: screenWidth, backgroundColor: theme.mushafPaper }]}>
        <ActivityIndicator size="large" color={theme.primary} />
      </View>
    );
  }

  if (error) {
    return (
      <View style={[styles.pageContainer, { width: screenWidth, backgroundColor: theme.background }]}>
        <Text style={[styles.emptyText, { color: theme.error }]}>Error loading page {pageNumber}</Text>
      </View>
    );
  }

  if (lines.length === 0) {
    return (
      <View style={[styles.pageContainer, { width: screenWidth, backgroundColor: theme.background }]}>
        <Text style={[styles.emptyText, { color: theme.textSecondary }]}>Page {pageNumber} not found</Text>
      </View>
    );
  }

  return (
    <View style={[styles.pageContainer, { width: screenWidth, backgroundColor: theme.mushafPaper }]}>
      <MushafPage
        mode={mode}
        pageNumber={pageNumber}
        lines={lines}
        fontFamily={fontFamily}
        surahName={surahName}
        juzLabel={juzLabel}
        onAyahPress={onAyahPress}
      />
    </View>
  );
});

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  pageContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 16,
  },
});

export default PageSwiper;

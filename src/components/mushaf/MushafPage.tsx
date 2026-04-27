import React, { useMemo } from 'react';
import { View, Text, StyleSheet, useWindowDimensions, StatusBar, Platform } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, { useSharedValue, useAnimatedStyle, withSpring } from 'react-native-reanimated';
import { PageLine, MushafMode } from '../../types/mushaf';
import MushafLine from './MushafLine';
import { MUSHAF_CONFIG } from '../../utils/constants';
import { useTheme } from '../../hooks/useTheme';

interface Props {
  mode: MushafMode;
  pageNumber: number;
  lines: PageLine[];
  fontFamily: string;
  surahName: string;
  juzLabel: string;
  onAyahPress?: (surah: number, ayah: number) => void;
}

const AnimatedView = Animated.createAnimatedComponent(View);

const PAGE_MARGIN = 8;
const SIDEBAR_WIDTH = 26;
const META_STRIP_HEIGHT = 22;

const EASTERN_ARABIC = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
function toArabicNumeral(n: number): string {
  return String(n).split('').map(d => EASTERN_ARABIC[+d]).join('');
}

const MushafPage = React.memo(function MushafPage({
  mode,
  pageNumber,
  lines,
  fontFamily,
  surahName,
  juzLabel,
  onAyahPress,
}: Props) {
  const { height: screenHeight, width: screenWidth } = useWindowDimensions();
  const config = MUSHAF_CONFIG[mode];
  const theme = useTheme();

  const scale = useSharedValue(1);
  const savedScale = useSharedValue(1);

  const pinchGesture = Gesture.Pinch()
    .onUpdate((event) => {
      const newScale = savedScale.value * event.scale;
      scale.value = Math.min(Math.max(newScale, 1), 3);
    })
    .onEnd(() => {
      if (scale.value < 1.15) {
        scale.value = withSpring(1);
        savedScale.value = 1;
      } else {
        savedScale.value = scale.value;
      }
    });

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  const statusBarHeight = Platform.OS === 'android' ? (StatusBar.currentHeight ?? 24) : 0;
  const containerHeight = useMemo(() => screenHeight - 120 - statusBarHeight - META_STRIP_HEIGHT, [screenHeight, statusBarHeight]);

  const { displayLines, lineHeights, lineOffsets } = useMemo(() => {
    const baseHeight = containerHeight / config.linesPerPage;
    const result: PageLine[] = [];
    const heights: number[] = [];

    for (const line of lines) {
      const prev = result[result.length - 1];
      if (line.line_type === 'basmallah' && prev?.line_type === 'surah_name') {
        // Merge basmallah row into preceding surah_name: combine height and bubble up markers
        heights[heights.length - 1] += baseHeight;
        result[result.length - 1] = {
          ...prev,
          rukuNumber: prev.rukuNumber ?? line.rukuNumber,
          juzRukuNumber: prev.juzRukuNumber ?? line.juzRukuNumber,
          hizbMarker: prev.hizbMarker ?? line.hizbMarker,
          sajdaMarker: prev.sajdaMarker ?? line.sajdaMarker,
        };
        continue;
      }
      result.push(line);
      heights.push(baseHeight);
    }

    const offsets: number[] = [];
    let running = 0;
    for (const h of heights) {
      offsets.push(running);
      running += h;
    }

    return { displayLines: result, lineHeights: heights, lineOffsets: offsets };
  }, [lines, containerHeight, config.linesPerPage]);

  const pageWidth = screenWidth - PAGE_MARGIN * 2 - SIDEBAR_WIDTH;

  return (
    <View style={{ flexDirection: 'row', paddingHorizontal: PAGE_MARGIN }}>
      <View style={{ width: SIDEBAR_WIDTH, height: containerHeight, marginTop: META_STRIP_HEIGHT }}>
        {displayLines.map((line, index) => {
          const hasMarker = line.rukuNumber || line.hizbMarker || line.sajdaMarker;
          if (!hasMarker) return null;
          return (
            <View
              key={`marker-${index}`}
              style={{
                position: 'absolute',
                top: lineOffsets[index],
                height: lineHeights[index],
                width: SIDEBAR_WIDTH,
                alignItems: 'center',
                justifyContent: 'center',
                gap: 1,
              }}
            >
              {line.rukuNumber != null && (
                <>
                  <Text style={{ fontSize: 11, color: theme.mushafInk, lineHeight: 13 }}>
                    {'ع' + toArabicNumeral(line.rukuNumber)}
                  </Text>
                  {line.juzRukuNumber != null && (
                    <Text style={{ fontSize: 11, color: theme.mushafInk, lineHeight: 13, opacity: 0.6 }}>
                      {'ع' + toArabicNumeral(line.juzRukuNumber)}
                    </Text>
                  )}
                </>
              )}
              {line.hizbMarker && (
                <Text style={{ fontSize: 10, color: theme.mushafInk, lineHeight: 12 }} numberOfLines={1} adjustsFontSizeToFit>
                  {line.hizbMarker}
                </Text>
              )}
              {line.sajdaMarker && (
                <Text style={{ fontSize: 9, color: theme.mushafInk, lineHeight: 11 }} numberOfLines={1} adjustsFontSizeToFit>
                  {'سجدة'}
                </Text>
              )}
            </View>
          );
        })}
      </View>
      <View>
        <View style={[styles.metaStrip, { width: pageWidth }]}>
          <Text style={[styles.metaSurahName, { color: theme.mushafInk }]} numberOfLines={1}>
            {surahName}
          </Text>
          <Text style={[styles.metaPageNumber, { color: theme.mushafInk }]} numberOfLines={1}>
            {toArabicNumeral(pageNumber)}
          </Text>
          <Text style={[styles.metaJuzLabel, { color: theme.mushafInk }]} numberOfLines={1}>
            {juzLabel}
          </Text>
        </View>
        <GestureDetector gesture={pinchGesture}>
          <AnimatedView
            style={[
              styles.page,
              animatedStyle,
              {
                height: containerHeight,
                width: pageWidth,
                backgroundColor: theme.mushafPaper,
                borderColor: theme.mushafInk,
              },
            ]}
          >
            {displayLines.map((line, index) => {
              // Surah 1 (Al-Fatiha) starts with basmallah as ayah 1; surah 9 (At-Tawbah) has no basmallah
              const showBasmallah =
                line.line_type === 'surah_name' &&
                line.surah_number !== 9 &&
                line.surah_number !== 1;

              return (
                <MushafLine
                  key={`${pageNumber}-${line.line_number}`}
                  line={line}
                  fontSize={config.fontSize}
                  lineHeight={lineHeights[index]}
                  fontFamily={fontFamily}
                  isFirst={index === 0}
                  isLast={index === displayLines.length - 1}
                  showBasmallah={showBasmallah}
                  onAyahPress={line.line_type === 'ayah' ? onAyahPress : undefined}
                />
              );
            })}
          </AnimatedView>
        </GestureDetector>
      </View>
    </View>
  );
});

const styles = StyleSheet.create({
  metaStrip: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    height: META_STRIP_HEIGHT,
    paddingHorizontal: 4,
  },
  metaSurahName: {
    flex: 1,
    fontSize: 12,
    writingDirection: 'rtl',
  },
  metaPageNumber: {
    flex: 1,
    fontSize: 12,
    textAlign: 'center',
  },
  metaJuzLabel: {
    flex: 1,
    fontSize: 12,
    writingDirection: 'rtl',
    textAlign: 'right',
  },
  page: {
    borderWidth: 1,
    overflow: 'hidden',
  },
});

export default MushafPage;

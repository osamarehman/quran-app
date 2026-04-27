import React, { useMemo } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { PageLine } from '../../types/mushaf';
import { SURAH_LIST, SURAH_RUKU_COUNT } from '../../utils/constants';
import { useTheme } from '../../hooks/useTheme';
import { normalizeQuranText } from '../../utils/quranText';

interface Props {
  line: PageLine;
  fontSize: number;
  lineHeight: number;
  fontFamily: string;
  isFirst?: boolean;
  isLast?: boolean;
  onPress?: () => void;
  showBasmallah?: boolean;
}

const BISMILLAH = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
const EASTERN_ARABIC = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

function toArabicNumeral(n: number): string {
  return String(n).split('').map(d => EASTERN_ARABIC[+d]).join('');
}

// Quranic combining marks not present in IndopakNastaleeq — render via UthmanicHafs.
// Restricted to MARKS only (small high marks U+0610–U+061A, waqf signs U+06D6–U+06ED,
// Arabic Extended-A combining marks U+08D3–U+08FF). Avoids switching mid-word for
// regular letters in the Arabic Extended-A block which IndopakNastaleeq does support.
const WAQF_RE = /[ؐ-ؚۖ-ۭ࣓-ࣿ]/;

function segmentByWaqf(text: string): Array<{ t: string; waqf: boolean }> {
  const segments: Array<{ t: string; waqf: boolean }> = [];
  let buf = '';
  let prevWaqf = WAQF_RE.test(text[0]);
  for (const ch of text) {
    const w = WAQF_RE.test(ch);
    if (w !== prevWaqf) {
      if (buf) {
        // Transfer trailing space into the waqf segment so the mark has a base character
        if (w && buf.endsWith(' ')) {
          segments.push({ t: buf.slice(0, -1), waqf: false });
          buf = ' ' + ch;
        } else {
          segments.push({ t: buf, waqf: prevWaqf });
          buf = ch;
        }
      } else {
        buf = ch;
      }
      prevWaqf = w;
    } else {
      buf += ch;
    }
  }
  if (buf) segments.push({ t: buf, waqf: prevWaqf });
  return segments;
}

const MushafLine = React.memo(function MushafLine({
  line,
  fontSize,
  lineHeight,
  fontFamily,
  isFirst,
  isLast,
  onPress,
  showBasmallah,
}: Props) {
  const theme = useTheme();

  const surahInfo = useMemo(() => {
    if (line.line_type !== 'surah_name') return null;
    return SURAH_LIST.find(s => s.number === line.surah_number) ?? null;
  }, [line.line_type, line.surah_number]);

  const wordContent = useMemo(() => {
    if (line.line_type === 'basmallah') return BISMILLAH;
    if (line.line_type === 'ayah') return normalizeQuranText(line.wordText ?? '', fontFamily);
    return '';
  }, [line.line_type, line.wordText, fontFamily]);

  const words = useMemo(() => {
    if (line.line_type !== 'ayah' || line.is_centered === 1) return [];
    const raw = wordContent.split(' ').filter(Boolean);
    // Merge waqf-only tokens onto the preceding word so combining marks keep their base character
    return raw.reduce<string[]>((acc, token) => {
      if (acc.length > 0 && Array.from(token).every(ch => WAQF_RE.test(ch))) {
        acc[acc.length - 1] += ' ' + token;
      } else {
        acc.push(token);
      }
      return acc;
    }, []);
  }, [line.line_type, line.is_centered, wordContent]);

  const isJuzStart = line.line_type === 'basmallah';
  const isSurahName = line.line_type === 'surah_name';

  const containerStyle = [
    styles.container,
    {
      height: lineHeight,
      borderColor: theme.mushafLine,
      borderTopWidth: isFirst ? 0 : 1,
      borderBottomWidth: isLast ? 0 : 1,
      borderLeftWidth: 0,
      borderRightWidth: 0,
      ...(isSurahName && {
        backgroundColor: theme.mushafInk,
      }),
      ...(isJuzStart && {
        backgroundColor: theme.mushafInk,
        borderTopWidth: isFirst ? 0 : 2,
        borderBottomWidth: isLast ? 0 : 2,
        borderTopColor: theme.mushafInk,
        borderBottomColor: theme.mushafInk,
      }),
    },
  ];

  const inkColor = theme.mushafInk;
  const textColor = (isSurahName || isJuzStart) ? theme.mushafPaper : theme.mushafInk;
  const textStyle = { fontSize, fontFamily, color: textColor };

  function renderInner(): React.ReactElement {
    if (isSurahName) {
      const surahName = 'سورة ' + (surahInfo?.name ?? '');
      const surahNum = surahInfo?.number ?? 0;
      const rukyCount = surahNum > 0 ? (SURAH_RUKU_COUNT[surahNum] ?? 1) : 1;

      if (!showBasmallah) {
        return (
          <View style={styles.centeredWrap}>
            <Text style={[{ fontSize, color: textColor }]} numberOfLines={1}>
              {surahName}
            </Text>
          </View>
        );
      }

      return (
        <View style={styles.surahHLine}>
          <Text
            style={[styles.surahNameLeft, { fontSize: fontSize * 0.65, color: textColor }]}
            numberOfLines={1}
            adjustsFontSizeToFit
            minimumFontScale={0.4}
          >
            {surahName}
          </Text>
          <Text
            style={[styles.bismillahCenter, { fontSize: fontSize * 0.92, fontFamily, color: textColor }]}
            numberOfLines={1}
            adjustsFontSizeToFit
            minimumFontScale={0.4}
          >
            {BISMILLAH}
          </Text>
          <Text
            style={[styles.rukyCountRight, { fontSize: fontSize * 0.65, color: textColor }]}
            numberOfLines={1}
          >
            {'ع' + toArabicNumeral(rukyCount)}
          </Text>
        </View>
      );
    }

    if (isJuzStart) {
      return (
        <View style={styles.centeredWrap}>
          <Text
            style={[{ fontSize, fontFamily, color: textColor, fontWeight: '600' }]}
            numberOfLines={1}
            adjustsFontSizeToFit
            minimumFontScale={0.4}
          >
            {BISMILLAH}
          </Text>
        </View>
      );
    }

    if (line.is_centered === 1) {
      return (
        <View style={styles.centeredWrap}>
          <Text
            style={[{ fontSize, fontFamily, color: textColor }]}
            numberOfLines={1}
            adjustsFontSizeToFit
            minimumFontScale={0.4}
          >
            {wordContent}
          </Text>
        </View>
      );
    }

    // Render the full line as a single <Text> so adjustsFontSizeToFit can shrink it
    // to fit the line width. Words containing waqf marks are split into nested <Text>
    // segments so the Uthmanic font can render the marks the Indopak font lacks.
    const children: React.ReactNode[] = [];
    words.forEach((word, i) => {
      if (i > 0) children.push(' ');
      if (WAQF_RE.test(word)) {
        const segments = segmentByWaqf(word);
        segments.forEach((seg, j) => {
          if (seg.waqf) {
            children.push(
              <Text key={`${i}-${j}`} style={{ fontFamily: 'UthmanicHafs', color: textColor }}>
                {seg.t}
              </Text>
            );
          } else {
            children.push(<Text key={`${i}-${j}`}>{seg.t}</Text>);
          }
        });
      } else {
        children.push(word);
      }
    });

    return (
      <Text
        style={[textStyle, styles.lineText]}
        numberOfLines={1}
        adjustsFontSizeToFit
        minimumFontScale={0.5}
        allowFontScaling={false}
      >
        {children}
      </Text>
    );
  }

  const content = (
    <View style={containerStyle}>
      <View style={styles.lineContent}>{renderInner()}</View>
    </View>
  );

  if (line.line_type === 'ayah' && onPress) {
    return (
      <TouchableOpacity
        onPress={onPress}
        activeOpacity={0.6}
        accessibilityRole="button"
        accessibilityLabel={`Surah ${line.surah_number}, Ayah ${line.ayahNumber}`}
      >
        {content}
      </TouchableOpacity>
    );
  }

  return content;
});

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'stretch',
  },
  lineContent: {
    flex: 1,
    alignItems: 'stretch',
    justifyContent: 'center',
    paddingHorizontal: 8,
  },
  lineText: {
    flex: 1,
    textAlign: 'justify',
    writingDirection: 'rtl',
  },
  centeredWrap: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  surahHLine: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'stretch',
  },
  surahNameLeft: {
    flex: 1,
    textAlign: 'left',
    writingDirection: 'rtl',
  },
  bismillahCenter: {
    flex: 2,
    textAlign: 'center',
    writingDirection: 'rtl',
  },
  rukyCountRight: {
    flex: 1,
    textAlign: 'right',
  },
});

export default MushafLine;

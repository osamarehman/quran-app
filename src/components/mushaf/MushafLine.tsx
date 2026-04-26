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

const WAQF_RE = /[ۖ-ۛ]/;

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

function WordToken({ text, style, fontFamily, inkColor }: {
  text: string; style: object; fontFamily: string; inkColor: string;
}) {
  const hasWaqf = WAQF_RE.test(text);

  if (hasWaqf) {
    const segments = segmentByWaqf(text);
    return (
      <Text style={style}>
        {segments.map((seg, i) =>
          seg.waqf
            ? <Text key={i} style={{ fontFamily: 'UthmanicHafs', color: inkColor }}>{seg.t}</Text>
            : <Text key={i}>{seg.t}</Text>
        )}
      </Text>
    );
  }

  return <Text style={style}>{text}</Text>;
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

    return (
      <View style={styles.wordRow}>
        {words.map((word, i) => (
          <WordToken
            key={i}
            text={word}
            style={textStyle}
            fontFamily={fontFamily}
            inkColor={inkColor}
          />
        ))}
      </View>
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
  wordRow: {
    flex: 1,
    flexDirection: 'row-reverse',
    justifyContent: 'space-between',
    alignItems: 'center',
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

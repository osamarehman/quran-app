import React, { useMemo, useState, useRef, useEffect, useCallback } from 'react';
import { View, Text, StyleSheet, LayoutChangeEvent } from 'react-native';
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
  onAyahPress?: (surah: number, ayah: number) => void;
  showBasmallah?: boolean;
}

const BISMILLAH = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
const EASTERN_ARABIC = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

function toArabicNumeral(n: number): string {
  return String(n).split('').map(d => EASTERN_ARABIC[+d]).join('');
}

// Quranic combining marks. The primary mushaf font (AlQuranIndoPak) renders
// these correctly so we no longer need to swap to UthmanicHafs mid-word —
// keeping the regex around in case we need to special-case rendering.
// Restricted to MARKS only (small high marks U+0610–U+061A, waqf signs
// U+06D6–U+06ED, Arabic Extended-A combining marks U+08D3–U+08FF).
const WAQF_RE = /[ؐ-ؚۖ-ۭ࣓-ࣿ]/;
// Detect a token that's just an end-of-ayah marker (U+06DD) followed by digits.
// e.g. "۝٣". These should attach to the preceding word and render in
// UthmanicHafs (which has the contextual sub that puts the digit inside the
// ornate circle). IndopakNastaleeq doesn't, so the digit dangles huge.
const AYAH_END_RE = /^۝[٠-٩۰-۹]*$/;

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

type FittedWord = { surah: number; ayah: number; text: string };

interface FittedWordRowProps {
  line: PageLine;
  wordContent: string;
  baseFontSize: number;
  textStyle: { fontSize: number; fontFamily: string; color: string };
  onAyahPress?: (surah: number, ayah: number) => void;
  textColor: string;
}

// Renders the words flex-justified across the row, with a hidden mirror
// <Text> measured via onTextLayout to decide if/how much to shrink.
//
// onTextLayout reports shaping-aware width — it accounts for cursive glyph
// extensions that per-word `onLayout` misses. We render the same content
// invisibly with `numberOfLines` removed and width clamped to the container;
// if the layout engine had to wrap to multiple lines (or report a single line
// wider than the container), we know the natural width exceeds the row and
// can compute the exact scale needed. Single-pass, no iteration.
const FittedWordRow = React.memo(function FittedWordRow({
  line,
  wordContent,
  baseFontSize,
  textStyle,
  onAyahPress,
  textColor,
}: FittedWordRowProps) {
  // Build the per-word list ONCE inside the component, memoized on the line's
  // identity so React.memo on the parent works as intended.
  const words = useMemo<FittedWord[]>(() => {
    const fallbackSurah = line.endSurahNumber ?? line.surah_number ?? 0;
    const fallbackAyah = line.endAyahNumber ?? line.ayahNumber ?? 0;
    const segs = line.ayahSegments && line.ayahSegments.length > 0
      ? line.ayahSegments
      : [{ surah: fallbackSurah, ayah: fallbackAyah, text: wordContent }];
    const out: FittedWord[] = [];
    for (const seg of segs) {
      const raw = seg.text.split(' ').filter(Boolean);
      const merged: string[] = [];
      for (const tok of raw) {
        const isWaqfOnly = Array.from(tok).every((ch) => WAQF_RE.test(ch));
        const isAyahEnd = AYAH_END_RE.test(tok);
        if (merged.length > 0 && (isWaqfOnly || isAyahEnd)) {
          merged[merged.length - 1] += ' ' + tok;
        } else {
          merged.push(tok);
        }
      }
      for (const word of merged) {
        out.push({ surah: seg.surah, ayah: seg.ayah, text: word });
      }
    }
    return out;
  }, [line, wordContent]);

  const renderContent = useCallback((text: string, keyPrefix: string): React.ReactNode => {
    // Always wrap output in <Text> nodes so the row's per-word layout is
    // structurally consistent across words. Waqf marks inherit the parent's
    // primary font. The ayah-end token (۝ + digits) renders in UthmanicHafs
    // which has the OpenType contextual substitution that places the digit
    // inside the ornate end-of-ayah circle.
    const ayahEndMatch = text.match(/\s*(۝[٠-٩۰-۹]*)$/);
    let baseText = text;
    let ayahEndNode: React.ReactNode = null;
    if (ayahEndMatch) {
      baseText = text.slice(0, ayahEndMatch.index!);
      ayahEndNode = (
        <React.Fragment key={`${keyPrefix}-end`}>
          <Text> </Text>
          <Text style={{ fontFamily: 'UthmanicHafs', color: textColor }}>
            {ayahEndMatch[1]}
          </Text>
        </React.Fragment>
      );
    }

    const parts: React.ReactNode[] = [];
    if (baseText) {
      parts.push(<Text key={`${keyPrefix}-b`}>{baseText}</Text>);
    }
    if (ayahEndNode) parts.push(ayahEndNode);
    return parts;
  }, [textColor]);

  const [scale, setScale] = useState(1);
  const containerWidthRef = useRef(0);
  const settledRef = useRef(false);

  useEffect(() => {
    setScale(1);
    settledRef.current = false;
  }, [words, baseFontSize]);

  const onContainerLayout = useCallback((e: LayoutChangeEvent) => {
    const w = e.nativeEvent.layout.width;
    if (Math.abs(w - containerWidthRef.current) < 0.5) return;
    const hadPrev = containerWidthRef.current > 0;
    containerWidthRef.current = w;
    if (hadPrev) {
      settledRef.current = false;
      if (scale !== 1) setScale(1);
    }
  }, [scale]);

  // Hidden mirror reports actual shaping-aware text width via onTextLayout.
  // We render at the FULL baseFontSize with width clamped to the container; if
  // the text needs > 1 line, the natural single-line width = sum of lines.
  const onMirrorTextLayout = useCallback((e: { nativeEvent: { lines: Array<{ width: number }> } }) => {
    if (settledRef.current) return;
    const cw = containerWidthRef.current;
    if (cw <= 0) return;
    const lines = e.nativeEvent.lines;
    if (!lines || lines.length === 0) return;
    settledRef.current = true;
    // Sum of all reported line widths = the width the text would need to fit
    // on a single unconstrained line. Includes shaping/glyph extents.
    const trueWidth = lines.reduce((acc, l) => acc + l.width, 0);
    // Headroom scales with word count — denser lines need more safety because
    // shaping interactions between adjacent words add up.
    const headroom = 4 + Math.max(0, words.length - 4) * 0.4;
    if (trueWidth > cw - headroom) {
      // Add a 4 % cushion for any residual variance between mirror layout and
      // the visible flex layout's per-glyph advance.
      const next = Math.max(0.45, (cw - headroom) / trueWidth * 0.96);
      setScale(next);
    }
  }, [words.length]);

  const fontSize = baseFontSize * scale;
  const wordStyle = { ...textStyle, fontSize };

  return (
    <View style={styles.wordRow} onLayout={onContainerLayout}>
      {/* Hidden measurement mirror — same content, baseFontSize, NO scale.
          Width clamped so onTextLayout reports per-line widths (one or more). */}
      <View
        pointerEvents="none"
        style={[styles.mirror, { width: containerWidthRef.current || 1 }]}
      >
        <Text
          style={[textStyle, { fontSize: baseFontSize }]}
          onTextLayout={onMirrorTextLayout}
          allowFontScaling={false}
        >
          {words.map((w, i) => (
            <React.Fragment key={i}>
              {i > 0 ? ' ' : ''}
              {renderContent(w.text, `m${i}`)}
            </React.Fragment>
          ))}
        </Text>
      </View>

      {words.map((w, i) => (
        <Text
          key={i}
          onPress={onAyahPress ? () => onAyahPress(w.surah, w.ayah) : undefined}
          style={wordStyle}
          allowFontScaling={false}
        >
          {renderContent(w.text, String(i))}
        </Text>
      ))}
    </View>
  );
});

const MushafLine = React.memo(function MushafLine({
  line,
  fontSize,
  lineHeight,
  fontFamily,
  isFirst,
  isLast,
  onAyahPress,
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
  // Mid-surah Juz first line — invert styling so the boundary is obvious.
  // (New-surah Juz starts already get visual emphasis via the basmallah row.)
  const isJuzFirstAyah = !!line.isJuzFirstLine;
  const inverted = isSurahName || isJuzStart || isJuzFirstAyah;

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
      ...(isJuzFirstAyah && {
        backgroundColor: theme.mushafInk,
        borderTopWidth: isFirst ? 0 : 2,
        borderBottomWidth: isLast ? 0 : 2,
        borderTopColor: theme.mushafInk,
        borderBottomColor: theme.mushafInk,
      }),
    },
  ];

  const inkColor = theme.mushafInk;
  const textColor = inverted ? theme.mushafPaper : theme.mushafInk;
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
      <FittedWordRow
        line={line}
        wordContent={wordContent}
        baseFontSize={fontSize}
        textStyle={textStyle}
        onAyahPress={onAyahPress}
        textColor={textColor}
      />
    );
  }

  return (
    <View style={containerStyle}>
      <View style={styles.lineContent}>{renderInner()}</View>
    </View>
  );
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
    paddingHorizontal: 4,
  },
  wordRow: {
    flex: 1,
    flexDirection: 'row-reverse',
    justifyContent: 'space-between',
    alignItems: 'center',
    overflow: 'hidden',
  },
  mirror: {
    position: 'absolute',
    top: 0,
    left: 0,
    opacity: 0,
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

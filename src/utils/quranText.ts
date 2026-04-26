const EASTERN_ARABIC = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

function toEasternArabic(num: number): string {
  return String(num)
    .split('')
    .map((d) => EASTERN_ARABIC[parseInt(d)])
    .join('');
}

// PUA range U+F500-U+F699 -- used by Indopak fonts for ayah-end markers.
// For other fonts replace each PUA glyph with standard U+06DD + Eastern Arabic numeral.
export function normalizeQuranText(text: string, fontFamily: string): string {
  if (fontFamily === 'IndopakNastaleeq' || fontFamily === 'DigitalKhattIndoPak') {
    return text;
  }
  return [...text]
    .map((ch) => {
      const code = ch.charCodeAt(0);
      if (code >= 0xf500 && code <= 0xf699) {
        return '۝' + toEasternArabic(code - 0xf500 + 1);
      }
      return ch;
    })
    .join('');
}

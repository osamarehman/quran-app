export type ThemeMode = 'light' | 'dark';

export interface ThemeColors {
  // Backgrounds
  background: string;
  pageBackground: string;
  headerBackground: string;
  modalBackground: string;
  surface: string;
  overlay: string;

  // Text
  text: string;
  textSecondary: string;
  textMuted: string;
  textInverse: string;

  // Accents
  primary: string;
  primaryLight: string;
  accent: string;

  // Borders & dividers
  border: string;
  divider: string;

  // States
  error: string;
  success: string;
  bookmark: string;

  // Mushaf specific
  mushafPaper: string;
  mushafInk: string;
  mushafLine: string;
}

export const lightTheme: ThemeColors = {
  background: '#e8e4d9',
  pageBackground: '#fdfbf7',
  headerBackground: '#2e7d32',
  modalBackground: '#ffffff',
  surface: '#f5f5f5',
  overlay: 'rgba(0,0,0,0.5)',

  text: '#1a1a1a',
  textSecondary: '#666666',
  textMuted: '#999999',
  textInverse: '#ffffff',

  primary: '#2e7d32',
  primaryLight: 'rgba(255,255,255,0.2)',
  accent: '#1b5e20',

  border: '#e0e0e0',
  divider: '#f0f0f0',

  error: '#c62828',
  success: '#2e7d32',
  bookmark: '#ffc107',

  mushafPaper: '#fdfbf7',
  mushafInk: '#1a1a1a',
  mushafLine: '#e8e4d9',
};

export const darkTheme: ThemeColors = {
  background: '#121212',
  pageBackground: '#1e1e1e',
  headerBackground: '#1b5e20',
  modalBackground: '#1e1e1e',
  surface: '#2a2a2a',
  overlay: 'rgba(0,0,0,0.7)',

  text: '#e0e0e0',
  textSecondary: '#a0a0a0',
  textMuted: '#707070',
  textInverse: '#ffffff',

  primary: '#4caf50',
  primaryLight: 'rgba(255,255,255,0.15)',
  accent: '#66bb6a',

  border: '#333333',
  divider: '#2a2a2a',

  error: '#ef5350',
  success: '#66bb6a',
  bookmark: '#ffd54f',

  mushafPaper: '#1e1e1e',
  mushafInk: '#e0e0e0',
  mushafLine: '#2a2a2a',
};

export function getTheme(mode: ThemeMode): ThemeColors {
  return mode === 'dark' ? darkTheme : lightTheme;
}

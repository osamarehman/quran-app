import { useAppStore } from '../stores/appStore';
import { ThemeColors, getTheme } from '../theme/colors';

export function useTheme(): ThemeColors {
  const themeMode = useAppStore((s) => s.themeMode);
  return getTheme(themeMode);
}

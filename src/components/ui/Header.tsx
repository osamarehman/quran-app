import React from 'react';
import { Platform, StatusBar, StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { MushafMode, ThemeMode } from '../../types/mushaf';
import { MUSHAF_CONFIG } from '../../utils/constants';
import { useTheme } from '../../hooks/useTheme';

interface Props {
  mode: MushafMode;
  currentSurahName?: string;
  isBookmarked: boolean;
  isPlaying: boolean;
  themeMode: ThemeMode;
  audioEnabled: boolean;
  onToggleMode: () => void;
  onOpenNavigator: () => void;
  onToggleBookmark: () => void;
  onOpenBookmarks: () => void;
  onToggleTheme: () => void;
  onToggleAudio: () => void;
  onOpenSettings: () => void;
}

const STATUS_BAR_OFFSET =
  Platform.OS === 'android' ? StatusBar.currentHeight ?? 24 : 0;

type IconName = React.ComponentProps<typeof Ionicons>['name'];

interface IconButtonProps {
  icon: IconName;
  size: number;
  color: string;
  label: string;
  onPress: () => void;
}

function IconButton({ icon, size, color, label, onPress }: IconButtonProps): React.ReactElement {
  return (
    <TouchableOpacity
      onPress={onPress}
      style={styles.iconButton}
      activeOpacity={0.7}
      accessibilityLabel={label}
      accessibilityRole="button"
    >
      <Ionicons name={icon} size={size} color={color} />
    </TouchableOpacity>
  );
}

export default function Header({
  mode,
  currentSurahName,
  isBookmarked,
  isPlaying,
  themeMode,
  audioEnabled,
  onToggleMode,
  onOpenNavigator,
  onToggleBookmark,
  onOpenBookmarks,
  onToggleTheme,
  onToggleAudio,
  onOpenSettings,
}: Props): React.ReactElement {
  const config = MUSHAF_CONFIG[mode];
  const theme = useTheme();

  return (
    <View style={[styles.header, { backgroundColor: theme.headerBackground }]}>
      <View style={styles.leftSection}>
        <TouchableOpacity
          onPress={onToggleMode}
          style={[styles.modeButton, { backgroundColor: theme.primaryLight }]}
          activeOpacity={0.8}
          accessibilityLabel={`Switch mushaf mode, currently ${config.linesPerPage} line`}
          accessibilityRole="button"
        >
          <Text style={[styles.modeText, { color: theme.textInverse }]}>
            {config.linesPerPage}L
          </Text>
        </TouchableOpacity>
        {currentSurahName && (
          <TouchableOpacity
            onPress={onOpenNavigator}
            style={styles.surahButton}
            activeOpacity={0.7}
            accessibilityLabel={`Current surah: ${currentSurahName}. Tap to navigate.`}
            accessibilityRole="button"
          >
            <Text style={[styles.surahName, { color: theme.textInverse }]} numberOfLines={1}>
              {currentSurahName}
            </Text>
          </TouchableOpacity>
        )}
      </View>

      <View style={styles.rightSection}>
        {audioEnabled && (
          <IconButton
            icon={isPlaying ? 'pause-circle' : 'play-circle'}
            size={26}
            color={theme.textInverse}
            label={isPlaying ? 'Pause audio' : 'Play audio'}
            onPress={onToggleAudio}
          />
        )}
        <IconButton
          icon={isBookmarked ? 'bookmark' : 'bookmark-outline'}
          size={22}
          color={isBookmarked ? theme.bookmark : theme.textInverse}
          label={isBookmarked ? 'Remove bookmark' : 'Add bookmark'}
          onPress={onToggleBookmark}
        />
        <IconButton
          icon="list"
          size={22}
          color={theme.textInverse}
          label="Open bookmarks list"
          onPress={onOpenBookmarks}
        />
        <IconButton
          icon="settings-outline"
          size={22}
          color={theme.textInverse}
          label="Open settings"
          onPress={onOpenSettings}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    paddingTop: STATUS_BAR_OFFSET,
    height: 56 + STATUS_BAR_OFFSET,
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    paddingHorizontal: 10,
    paddingBottom: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 4,
    elevation: 4,
    zIndex: 10,
  },
  leftSection: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    overflow: 'hidden',
  },
  rightSection: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'center',
  },
  modeButton: {
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderRadius: 6,
    flexShrink: 0,
  },
  modeText: {
    fontWeight: '700',
    fontSize: 12,
  },
  surahButton: {
    flex: 1,
    paddingHorizontal: 6,
    paddingVertical: 2,
    overflow: 'hidden',
  },
  surahName: {
    fontSize: 13,
    fontWeight: '600',
    writingDirection: 'rtl',
  },
  iconButton: {
    padding: 6,
    marginLeft: 2,
  },
});

import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  Modal,
  StyleSheet,
  FlatList,
  useWindowDimensions,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { MushafMode } from '../../types/mushaf';
import { SURAH_LIST, JUZ_NAMES, JUZ_PAGE_MAP_16LINE, JUZ_PAGE_MAP_15LINE, MUSHAF_CONFIG } from '../../utils/constants';
import { getPageForSurah, getPageForJuz } from '../../db/database';
import { useTheme } from '../../hooks/useTheme';

type Tab = 'page' | 'juz' | 'surah';

interface Props {
  visible: boolean;
  mode: MushafMode;
  onClose: () => void;
  onNavigate: (page: number) => void;
}

export default function JumpToNavigator({ visible, mode, onClose, onNavigate }: Props) {
  const [activeTab, setActiveTab] = useState<Tab>('page');
  const [pageInput, setPageInput] = useState('');
  const { width } = useWindowDimensions();
  const totalPages = MUSHAF_CONFIG[mode].pages;
  const juzMap = mode === '16-line' ? JUZ_PAGE_MAP_16LINE : JUZ_PAGE_MAP_15LINE;
  const theme = useTheme();

  const handlePageSubmit = useCallback(() => {
    const page = parseInt(pageInput, 10);
    if (page >= 1 && page <= totalPages) {
      onNavigate(page);
      setPageInput('');
      onClose();
    }
  }, [pageInput, totalPages, onNavigate, onClose]);

  const handleJuzPress = useCallback(
    async (juz: number) => {
      try {
        const page = await getPageForJuz(mode, juz);
        if (page) { onNavigate(page); onClose(); }
      } catch {
        const fallback = juzMap[juz];
        if (fallback) { onNavigate(fallback); onClose(); }
      }
    },
    [mode, juzMap, onNavigate, onClose]
  );

  const handleSurahPress = useCallback(
    async (surahNumber: number) => {
      try {
        const page = await getPageForSurah(mode, surahNumber);
        if (page) {
          onNavigate(page);
          onClose();
        }
      } catch {
        // fall back to hardcoded page
        const surah = SURAH_LIST.find((s) => s.number === surahNumber);
        if (surah) { onNavigate(surah.page); onClose(); }
      }
    },
    [mode, onNavigate, onClose]
  );

  const renderTabButton = (tab: Tab, label: string) => (
    <TouchableOpacity
      style={[styles.tabButton, activeTab === tab && { borderBottomColor: theme.primary, borderBottomWidth: 2 }]}
      onPress={() => setActiveTab(tab)}
      accessibilityLabel={`${label} tab`}
      accessibilityRole="tab"
      accessibilityState={{ selected: activeTab === tab }}
    >
      <Text style={[styles.tabText, { color: theme.textSecondary }, activeTab === tab && { color: theme.primary }]}>{label}</Text>
    </TouchableOpacity>
  );

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <View style={[styles.overlay, { backgroundColor: theme.overlay }]}>
        <View style={[styles.container, { width: width - 32, backgroundColor: theme.modalBackground }]}>
          <View style={styles.header}>
            <Text style={[styles.title, { color: theme.text }]}>Go to</Text>
            <TouchableOpacity onPress={onClose} accessibilityLabel="Close navigator" accessibilityRole="button">
              <Ionicons name="close" size={24} color={theme.textSecondary} />
            </TouchableOpacity>
          </View>

          <View style={[styles.tabs, { borderBottomColor: theme.border }]}>
            {renderTabButton('page', 'Page')}
            {renderTabButton('juz', 'Juz')}
            {renderTabButton('surah', 'Surah')}
          </View>

          {activeTab === 'page' && (
            <View style={styles.pageTab}>
              <TextInput
                style={[styles.input, { borderColor: theme.border, color: theme.text, backgroundColor: theme.surface }]}
                keyboardType="number-pad"
                placeholder={`Enter page (1-${totalPages})`}
                placeholderTextColor={theme.textMuted}
                value={pageInput}
                onChangeText={setPageInput}
                onSubmitEditing={handlePageSubmit}
                maxLength={3}
                accessibilityLabel={`Page number input, range 1 to ${totalPages}`}
                accessibilityRole="search"
              />
              <TouchableOpacity
                style={[styles.goButton, { backgroundColor: theme.primary }]}
                onPress={handlePageSubmit}
                accessibilityLabel="Go to page"
                accessibilityRole="button"
              >
                <Text style={styles.goButtonText}>Go</Text>
              </TouchableOpacity>
            </View>
          )}

          {activeTab === 'juz' && (
            <FlatList
              data={Array.from({ length: 30 }, (_, i) => i + 1)}
              keyExtractor={(item) => `juz-${item}`}
              numColumns={5}
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={[styles.juzItem, { width: (width - 72) / 5, backgroundColor: theme.surface }]}
                  onPress={() => handleJuzPress(item)}
                  accessibilityLabel={`Juz ${item}`}
                  accessibilityRole="button"
                >
                  <Text style={[styles.juzText, { color: theme.text }]}>{item}</Text>
                </TouchableOpacity>
              )}
              contentContainerStyle={styles.juzList}
            />
          )}

          {activeTab === 'surah' && (
            <FlatList
              data={SURAH_LIST}
              keyExtractor={(item) => `surah-${item.number}`}
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={[styles.surahItem, { borderBottomColor: theme.divider }]}
                  onPress={() => handleSurahPress(item.number)}
                  accessibilityLabel={`Surah ${item.englishName}`}
                  accessibilityRole="button"
                >
                  <Text style={[styles.surahNumber, { color: theme.primary }]}>{item.number}</Text>
                  <View style={styles.surahInfo}>
                    <Text style={[styles.surahName, { color: theme.text }]}>{item.name}</Text>
                    <Text style={[styles.surahEnglish, { color: theme.textSecondary }]}>{item.englishName}</Text>
                  </View>
                  <Text style={[styles.surahPage, { color: theme.textMuted }]}>P{item.page}</Text>
                </TouchableOpacity>
              )}
              contentContainerStyle={styles.surahList}
            />
          )}
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  container: {
    borderRadius: 12,
    maxHeight: '80%',
    padding: 16,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
  },
  tabs: {
    flexDirection: 'row',
    marginBottom: 16,
    borderBottomWidth: 1,
  },
  tabButton: {
    flex: 1,
    paddingVertical: 10,
    alignItems: 'center',
  },
  tabText: {
    fontSize: 14,
    fontWeight: '600',
  },
  pageTab: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  input: {
    flex: 1,
    height: 48,
    borderWidth: 1,
    borderRadius: 8,
    paddingHorizontal: 12,
    fontSize: 16,
  },
  goButton: {
    paddingVertical: 12,
    paddingHorizontal: 20,
    borderRadius: 8,
  },
  goButtonText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 16,
  },
  juzList: {
    paddingBottom: 8,
  },
  juzItem: {
    alignItems: 'center',
    paddingVertical: 12,
    margin: 4,
    borderRadius: 8,
  },
  juzText: {
    fontSize: 16,
    fontWeight: '700',
  },
  juzPageText: {
    fontSize: 11,
    marginTop: 2,
  },
  surahList: {
    paddingBottom: 8,
  },
  surahItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    paddingHorizontal: 8,
    borderBottomWidth: 1,
  },
  surahNumber: {
    width: 32,
    fontSize: 14,
    fontWeight: '700',
  },
  surahInfo: {
    flex: 1,
  },
  surahName: {
    fontSize: 16,
    fontWeight: '600',
    writingDirection: 'rtl',
  },
  surahEnglish: {
    fontSize: 12,
    marginTop: 2,
  },
  surahPage: {
    fontSize: 13,
    fontWeight: '600',
  },
});

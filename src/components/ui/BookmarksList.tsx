import React, { useCallback } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Modal,
  StyleSheet,
  FlatList,
  useWindowDimensions,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useAppStore } from '../../stores/appStore';
import { MushafMode } from '../../types/mushaf';
import { SURAH_LIST, MUSHAF_CONFIG } from '../../utils/constants';
import { useTheme } from '../../hooks/useTheme';

interface Props {
  visible: boolean;
  mode: MushafMode;
  onClose: () => void;
  onNavigate: (page: number) => void;
}

function getSurahForPage(page: number) {
  for (let i = SURAH_LIST.length - 1; i >= 0; i--) {
    if (SURAH_LIST[i].page <= page) {
      return SURAH_LIST[i];
    }
  }
  return SURAH_LIST[0];
}

export default function BookmarksList({ visible, mode, onClose, onNavigate }: Props) {
  const { width } = useWindowDimensions();
  const bookmarks = useAppStore((s) => s.bookmarks);
  const toggleBookmark = useAppStore((s) => s.toggleBookmark);
  const totalPages = MUSHAF_CONFIG[mode].pages;
  const theme = useTheme();

  const sortedBookmarks = [...bookmarks].sort((a, b) => a - b);

  const handleNavigate = useCallback(
    (page: number) => {
      onNavigate(page);
      onClose();
    },
    [onNavigate, onClose]
  );

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <View style={[styles.overlay, { backgroundColor: theme.overlay }]}>
        <View style={[styles.container, { width: width - 32, backgroundColor: theme.modalBackground }]}>
          <View style={styles.header}>
            <Text style={[styles.title, { color: theme.text }]}>Bookmarks</Text>
            <TouchableOpacity onPress={onClose} accessibilityLabel="Close bookmarks" accessibilityRole="button">
              <Ionicons name="close" size={24} color={theme.textSecondary} />
            </TouchableOpacity>
          </View>

          {sortedBookmarks.length === 0 ? (
            <View style={styles.emptyState}>
              <Ionicons name="bookmark-outline" size={48} color={theme.textMuted} />
              <Text style={[styles.emptyText, { color: theme.textSecondary }]}>No bookmarks yet</Text>
              <Text style={[styles.emptySubtext, { color: theme.textMuted }]}>
                Tap the bookmark icon while reading to save a page
              </Text>
            </View>
          ) : (
            <FlatList
              data={sortedBookmarks}
              keyExtractor={(item) => `bookmark-${item}`}
              renderItem={({ item: page }) => {
                const surah = getSurahForPage(page);
                return (
                  <View style={[styles.bookmarkItem, { borderBottomColor: theme.divider }]}>
                    <TouchableOpacity
                      style={styles.bookmarkContent}
                      onPress={() => handleNavigate(page)}
                      accessibilityLabel={`Go to page ${page}, ${surah.englishName}`}
                      accessibilityRole="button"
                    >
                      <Text style={[styles.pageNumber, { color: theme.text }]}>Page {page}</Text>
                      <Text style={[styles.surahName, { color: theme.textSecondary }]}>
                        {surah.name} ({surah.englishName})
                      </Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                      onPress={() => toggleBookmark(page)}
                      style={styles.deleteButton}
                      accessibilityLabel={`Delete bookmark for page ${page}`}
                      accessibilityRole="button"
                    >
                      <Ionicons name="trash-outline" size={20} color={theme.error} />
                    </TouchableOpacity>
                  </View>
                );
              }}
              contentContainerStyle={styles.list}
            />
          )}

          <Text style={[styles.footer, { color: theme.textMuted, borderTopColor: theme.divider }]}>
            {sortedBookmarks.length} bookmark{sortedBookmarks.length !== 1 ? 's' : ''} · {mode} · {totalPages} pages
          </Text>
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
  emptyState: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  emptyText: {
    fontSize: 16,
    fontWeight: '600',
    marginTop: 12,
  },
  emptySubtext: {
    fontSize: 13,
    marginTop: 4,
    textAlign: 'center',
  },
  list: {
    paddingBottom: 8,
  },
  bookmarkItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 8,
    borderBottomWidth: 1,
  },
  bookmarkContent: {
    flex: 1,
  },
  pageNumber: {
    fontSize: 16,
    fontWeight: '700',
  },
  surahName: {
    fontSize: 13,
    marginTop: 2,
  },
  deleteButton: {
    padding: 8,
  },
  footer: {
    fontSize: 12,
    textAlign: 'center',
    marginTop: 8,
    paddingTop: 8,
    borderTopWidth: 1,
  },
});

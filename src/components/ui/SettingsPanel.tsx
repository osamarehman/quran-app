import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Modal,
  StyleSheet,
  Switch,
  ScrollView,
  useWindowDimensions,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useAppStore } from '../../stores/appStore';
import { useTheme } from '../../hooks/useTheme';
import { RECITERS, MUSHAF_FONTS } from '../../utils/constants';

interface Props {
  visible: boolean;
  onClose: () => void;
}

const SPEEDS = [0.5, 0.75, 1.0, 1.25, 1.5];

export default function SettingsPanel({ visible, onClose }: Props) {
  const { width } = useWindowDimensions();
  const theme = useTheme();

  const audioEnabled = useAppStore((s) => s.audioEnabled);
  const setAudioEnabled = useAppStore((s) => s.setAudioEnabled);
  const audioSpeed = useAppStore((s) => s.audioSpeed);
  const setAudioSpeed = useAppStore((s) => s.setAudioSpeed);
  const themeMode = useAppStore((s) => s.themeMode);
  const setThemeMode = useAppStore((s) => s.setThemeMode);
  const selectedQariId = useAppStore((s) => s.selectedQariId);
  const setSelectedQariId = useAppStore((s) => s.setSelectedQariId);
  const selectedFont = useAppStore((s) => s.selectedFont);
  const setSelectedFont = useAppStore((s) => s.setSelectedFont);

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <View style={[styles.overlay, { backgroundColor: theme.overlay }]}>
        <View style={[styles.container, { width: width - 32, backgroundColor: theme.modalBackground }]}>
          <View style={styles.header}>
            <Text style={[styles.title, { color: theme.text }]}>Settings</Text>
            <TouchableOpacity onPress={onClose} accessibilityLabel="Close settings" accessibilityRole="button">
              <Ionicons name="close" size={24} color={theme.textSecondary} />
            </TouchableOpacity>
          </View>

          <ScrollView showsVerticalScrollIndicator={false}>
            {/* Dark mode */}
            <View style={[styles.row, { borderBottomColor: theme.divider }]}>
              <View style={styles.rowLabel}>
                <Ionicons name="moon" size={18} color={theme.textSecondary} />
                <Text style={[styles.rowText, { color: theme.text }]}>Dark mode</Text>
              </View>
              <Switch
                value={themeMode === 'dark'}
                onValueChange={(v) => setThemeMode(v ? 'dark' : 'light')}
                trackColor={{ false: theme.border, true: theme.primary }}
                thumbColor="#fff"
                accessibilityLabel="Toggle dark mode"
              />
            </View>

            {/* Audio enable */}
            <View style={[styles.row, { borderBottomColor: theme.divider }]}>
              <View style={styles.rowLabel}>
                <Ionicons name="headset" size={18} color={theme.textSecondary} />
                <Text style={[styles.rowText, { color: theme.text }]}>Enable audio</Text>
              </View>
              <Switch
                value={audioEnabled}
                onValueChange={setAudioEnabled}
                trackColor={{ false: theme.border, true: theme.primary }}
                thumbColor="#fff"
                accessibilityLabel="Toggle audio playback"
              />
            </View>

            {audioEnabled && (
              <>
                {/* Speed — stacked to avoid overflow */}
                <View style={[styles.block, { borderBottomColor: theme.divider }]}>
                  <View style={styles.rowLabel}>
                    <Ionicons name="speedometer" size={18} color={theme.textSecondary} />
                    <Text style={[styles.rowText, { color: theme.text }]}>Playback speed</Text>
                  </View>
                  <View style={styles.chipRow}>
                    {SPEEDS.map((s) => (
                      <TouchableOpacity
                        key={s}
                        style={[styles.chip, { backgroundColor: audioSpeed === s ? theme.primary : theme.surface }]}
                        onPress={() => setAudioSpeed(s)}
                        accessibilityLabel={`Speed ${s}x`}
                        accessibilityRole="radio"
                        accessibilityState={{ checked: audioSpeed === s }}
                      >
                        <Text style={[styles.chipText, { color: audioSpeed === s ? '#fff' : theme.textSecondary }]}>
                          {s}x
                        </Text>
                      </TouchableOpacity>
                    ))}
                  </View>
                </View>

                {/* Reciter / Qari */}
                <View style={[styles.block, { borderBottomColor: theme.divider }]}>
                  <View style={[styles.rowLabel, styles.blockHeader]}>
                    <Ionicons name="mic" size={18} color={theme.textSecondary} />
                    <Text style={[styles.rowText, { color: theme.text }]}>Reciter</Text>
                  </View>
                  {RECITERS.map((r) => (
                    <TouchableOpacity
                      key={r.id}
                      style={[styles.optionRow, { borderColor: theme.divider }]}
                      onPress={() => setSelectedQariId(r.id)}
                      accessibilityRole="radio"
                      accessibilityState={{ checked: selectedQariId === r.id }}
                    >
                      <View style={[
                        styles.radio,
                        { borderColor: selectedQariId === r.id ? theme.primary : theme.border },
                      ]}>
                        {selectedQariId === r.id && (
                          <View style={[styles.radioDot, { backgroundColor: theme.primary }]} />
                        )}
                      </View>
                      <Text style={[styles.optionText, { color: theme.text }]}>{r.label}</Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </>
            )}

            {/* Font selection */}
            <View style={[styles.block, { borderBottomColor: theme.divider }]}>
              <View style={[styles.rowLabel, styles.blockHeader]}>
                <Ionicons name="text" size={18} color={theme.textSecondary} />
                <Text style={[styles.rowText, { color: theme.text }]}>Mushaf font</Text>
              </View>
              {MUSHAF_FONTS.map((f) => (
                <TouchableOpacity
                  key={f.family}
                  style={[styles.optionRow, { borderColor: theme.divider }]}
                  onPress={() => setSelectedFont(f.family)}
                  accessibilityRole="radio"
                  accessibilityState={{ checked: selectedFont === f.family }}
                >
                  <View style={[
                    styles.radio,
                    { borderColor: selectedFont === f.family ? theme.primary : theme.border },
                  ]}>
                    {selectedFont === f.family && (
                      <View style={[styles.radioDot, { backgroundColor: theme.primary }]} />
                    )}
                  </View>
                  <Text style={[styles.optionText, { color: theme.text }]}>{f.label}</Text>
                </TouchableOpacity>
              ))}
            </View>

            <View style={styles.footer}>
              <Text style={[styles.footerText, { color: theme.textMuted }]}>
                Audio: Quran.com CDN · Requires internet
              </Text>
            </View>
          </ScrollView>
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
    maxHeight: '85%',
    padding: 16,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 14,
    borderBottomWidth: 1,
  },
  block: {
    paddingVertical: 12,
    borderBottomWidth: 1,
  },
  blockHeader: {
    marginBottom: 10,
  },
  rowLabel: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  rowText: {
    fontSize: 15,
    fontWeight: '600',
  },
  chipRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 10,
  },
  chip: {
    paddingVertical: 6,
    paddingHorizontal: 14,
    borderRadius: 6,
  },
  chipText: {
    fontSize: 13,
    fontWeight: '700',
  },
  optionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    gap: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  radio: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 2,
    alignItems: 'center',
    justifyContent: 'center',
  },
  radioDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  optionText: {
    fontSize: 14,
  },
  footer: {
    paddingVertical: 12,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 11,
  },
});

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mushaf/data/mushaf_db.dart';
import 'package:mushaf/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppStateNotifier persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('defaults when no prefs are stored', () async {
      final state = await AppStateNotifier.load();
      expect(state.edition.id, MushafEdition.fifteenLine.id);
      expect(state.audioOnTap, isFalse);
      expect(state.selectedReciterId, isNull);
      expect(state.bookmarks, isEmpty);
    });

    test('round-trips edition / audio / reciter / bookmarks', () async {
      final state = await AppStateNotifier.load();
      state.setEdition(MushafEdition.sixteenLine);
      state.setAudioOnTap(true);
      state.setReciter('mishary');
      state.toggleBookmark(42);
      state.toggleBookmark(7);
      state.toggleBookmark(100);
      state.toggleBookmark(7); // remove
      // Allow microtasks to flush async setStringList calls.
      await Future<void>.delayed(Duration.zero);

      final reloaded = await AppStateNotifier.load();
      expect(reloaded.edition.id, MushafEdition.sixteenLine.id);
      expect(reloaded.audioOnTap, isTrue);
      expect(reloaded.selectedReciterId, 'mishary');
      // Insertion order preserved, with 7 removed.
      expect(reloaded.bookmarks, [42, 100]);
      expect(reloaded.isBookmarked(42), isTrue);
      expect(reloaded.isBookmarked(7), isFalse);
    });

    test('hydrates from preexisting prefs', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app.edition.id': MushafEdition.sixteenLine.id,
        'app.audioOnTap': true,
        'app.selectedReciterId': 'sudais',
        'app.bookmarks': <String>['3', '17', '604'],
      });
      final state = await AppStateNotifier.load();
      expect(state.edition.id, MushafEdition.sixteenLine.id);
      expect(state.audioOnTap, isTrue);
      expect(state.selectedReciterId, 'sudais');
      expect(state.bookmarks, [3, 17, 604]);
    });

    test('removeBookmark drops the entry and persists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app.bookmarks': <String>['3', '17', '604'],
      });
      final state = await AppStateNotifier.load();
      state.removeBookmark(17);
      await Future<void>.delayed(Duration.zero);

      final reloaded = await AppStateNotifier.load();
      expect(reloaded.bookmarks, [3, 604]);
    });

    test('clears reciter when set to null', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app.selectedReciterId': 'sudais',
      });
      final state = await AppStateNotifier.load();
      expect(state.selectedReciterId, 'sudais');
      state.setReciter(null);
      await Future<void>.delayed(Duration.zero);

      final reloaded = await AppStateNotifier.load();
      expect(reloaded.selectedReciterId, isNull);
    });
  });
}

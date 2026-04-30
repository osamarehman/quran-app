import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mushaf_db.dart';

/// Persistent app state for v0.2 Stage 1.
///
/// Backs the top bar, settings screen, jump-to modal, and bookmark toggle.
/// Hydrates from SharedPreferences on construction via [load], and writes
/// every mutation back to prefs so user choices survive across launches.
class AppStateNotifier extends ChangeNotifier {
  static const _kEditionId = 'app.edition.id';
  static const _kAudioOnTap = 'app.audioOnTap';
  static const _kSelectedReciterId = 'app.selectedReciterId';
  static const _kBookmarks = 'app.bookmarks';

  final SharedPreferences? _prefs;

  MushafEdition _edition;
  bool _audioOnTap;
  String? _selectedReciterId;

  /// Insertion-ordered list of bookmarked page numbers. Backed by a List so
  /// callers can render most-recent-first or first-added-first as they like.
  final List<int> _bookmarks;

  AppStateNotifier({
    SharedPreferences? prefs,
    MushafEdition edition = MushafEdition.fifteenLine,
    bool audioOnTap = false,
    String? selectedReciterId,
    List<int>? bookmarks,
  })  : _prefs = prefs,
        _edition = edition,
        _audioOnTap = audioOnTap,
        _selectedReciterId = selectedReciterId,
        _bookmarks = List<int>.of(bookmarks ?? const <int>[]);

  /// Hydrates an [AppStateNotifier] from [SharedPreferences]. Falls back to
  /// defaults for any missing or malformed key.
  static Future<AppStateNotifier> load({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();

    final editionId = p.getString(_kEditionId);
    final edition = MushafEdition.all.firstWhere(
      (e) => e.id == editionId,
      orElse: () => MushafEdition.fifteenLine,
    );

    final bookmarksRaw = p.getStringList(_kBookmarks) ?? const <String>[];
    final bookmarks = <int>[];
    for (final s in bookmarksRaw) {
      final n = int.tryParse(s);
      if (n != null) bookmarks.add(n);
    }

    return AppStateNotifier(
      prefs: p,
      edition: edition,
      audioOnTap: p.getBool(_kAudioOnTap) ?? false,
      selectedReciterId: p.getString(_kSelectedReciterId),
      bookmarks: bookmarks,
    );
  }

  MushafEdition get edition => _edition;
  bool get audioOnTap => _audioOnTap;
  String? get selectedReciterId => _selectedReciterId;

  /// Insertion-ordered, unmodifiable view of bookmarks.
  List<int> get bookmarks => List.unmodifiable(_bookmarks);

  void setEdition(MushafEdition e) {
    if (_edition.id == e.id) return;
    _edition = e;
    _prefs?.setString(_kEditionId, e.id);
    notifyListeners();
  }

  void setAudioOnTap(bool v) {
    if (_audioOnTap == v) return;
    _audioOnTap = v;
    _prefs?.setBool(_kAudioOnTap, v);
    notifyListeners();
  }

  void setReciter(String? id) {
    if (_selectedReciterId == id) return;
    _selectedReciterId = id;
    if (id == null) {
      _prefs?.remove(_kSelectedReciterId);
    } else {
      _prefs?.setString(_kSelectedReciterId, id);
    }
    notifyListeners();
  }

  bool isBookmarked(int page) => _bookmarks.contains(page);

  void toggleBookmark(int page) {
    if (_bookmarks.remove(page)) {
      // removed
    } else {
      _bookmarks.add(page);
    }
    _saveBookmarks();
    notifyListeners();
  }

  void removeBookmark(int page) {
    if (_bookmarks.remove(page)) {
      _saveBookmarks();
      notifyListeners();
    }
  }

  void _saveBookmarks() {
    _prefs?.setStringList(
      _kBookmarks,
      [for (final b in _bookmarks) b.toString()],
    );
  }
}

class AppStateScope extends InheritedNotifier<AppStateNotifier> {
  const AppStateScope({
    super.key,
    required AppStateNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppStateNotifier of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }
}

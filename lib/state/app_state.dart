import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mushaf_db.dart';

/// Persistent app state. Hydrated from SharedPreferences via [load]; every
/// mutation writes back so user choices survive across launches.
class AppStateNotifier extends ChangeNotifier {
  static const _kEditionId = 'app.edition.id';
  static const _kAudioOnTap = 'app.audioOnTap';
  static const _kSelectedReciterId = 'app.selectedReciterId';
  static const _kBookmarks = 'app.bookmarks';

  final SharedPreferences? _prefs;

  MushafEdition _edition;
  bool _audioOnTap;
  String? _selectedReciterId;

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

  /// Hydrates from [SharedPreferences]; defaults fill any missing/malformed key.
  static Future<AppStateNotifier> load({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final editionId = p.getString(_kEditionId);
    return AppStateNotifier(
      prefs: p,
      edition: MushafEdition.all.firstWhere(
        (e) => e.id == editionId,
        orElse: () => MushafEdition.fifteenLine,
      ),
      audioOnTap: p.getBool(_kAudioOnTap) ?? false,
      selectedReciterId: p.getString(_kSelectedReciterId),
      bookmarks: [
        for (final s in p.getStringList(_kBookmarks) ?? const <String>[])
          if (int.tryParse(s) case final n?) n,
      ],
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
    if (!_bookmarks.remove(page)) _bookmarks.add(page);
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
    _prefs?.setStringList(_kBookmarks, [
      for (final b in _bookmarks) b.toString(),
    ]);
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

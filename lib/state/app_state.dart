import 'package:flutter/material.dart';

import '../data/mushaf_db.dart';

/// Stub for v0.2 Stage 1 (Agent B): backs the top bar, settings screen,
/// and 15/16-line toggle with persistent state. v0.1 minimal shape lets
/// agents extend without restructuring callers.
class AppStateNotifier extends ChangeNotifier {
  MushafEdition _edition = MushafEdition.fifteenLine;
  bool _audioOnTap = false;
  String? _selectedReciterId;
  final Set<int> _bookmarks = <int>{};

  MushafEdition get edition => _edition;
  bool get audioOnTap => _audioOnTap;
  String? get selectedReciterId => _selectedReciterId;
  Set<int> get bookmarks => Set.unmodifiable(_bookmarks);

  void setEdition(MushafEdition e) {
    if (_edition.id == e.id) return;
    _edition = e;
    notifyListeners();
  }

  void setAudioOnTap(bool v) {
    if (_audioOnTap == v) return;
    _audioOnTap = v;
    notifyListeners();
  }

  void setReciter(String? id) {
    if (_selectedReciterId == id) return;
    _selectedReciterId = id;
    notifyListeners();
  }

  bool isBookmarked(int page) => _bookmarks.contains(page);

  void toggleBookmark(int page) {
    if (_bookmarks.contains(page)) {
      _bookmarks.remove(page);
    } else {
      _bookmarks.add(page);
    }
    notifyListeners();
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

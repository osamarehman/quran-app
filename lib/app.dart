import 'package:flutter/material.dart';

import 'audio/audio_service.dart';
import 'data/mushaf_db.dart';
import 'screens/jump_to_modal.dart';
import 'screens/settings_screen.dart';
import 'state/app_state.dart';
import 'widgets/mushaf_page.dart';
import 'widgets/top_bar.dart';

class MushafApp extends StatefulWidget {
  const MushafApp({super.key});

  @override
  State<MushafApp> createState() => _MushafAppState();
}

class _MushafAppState extends State<MushafApp> {
  late final Future<AppStateNotifier> _stateFuture =
      AppStateNotifier.load();

  ThemeData _theme() => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        scaffoldBackgroundColor: const Color(0xFFFAF7F0),
        useMaterial3: true,
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppStateNotifier>(
      future: _stateFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          return MaterialApp(
            title: 'Mushaf',
            debugShowCheckedModeBanner: false,
            theme: _theme(),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final state = snap.data!;
        // builder wraps every Navigator-pushed route so AppStateScope is
        // visible from settings/jump-to/etc., not just from MushafHome.
        return MaterialApp(
          title: 'Mushaf',
          debugShowCheckedModeBanner: false,
          theme: _theme(),
          builder: (context, child) =>
              AppStateScope(notifier: state, child: child!),
          home: MushafHome(state: state),
        );
      },
    );
  }
}

class MushafHome extends StatefulWidget {
  final AppStateNotifier state;
  const MushafHome({super.key, required this.state});

  @override
  State<MushafHome> createState() => _MushafHomeState();
}

class _MushafHomeState extends State<MushafHome> {
  late final AppStateNotifier _state = widget.state;
  late final PageController _pageController =
      PageController(initialPage: widget.state.currentPage - 1);

  Future<MushafDb>? _dbFuture;
  MushafEdition? _openedEdition;
  late int _pageNumber = widget.state.currentPage;

  @override
  void initState() {
    super.initState();
    _dbFuture = MushafDb.open(edition: _state.edition);
    _openedEdition = _state.edition;
    _state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _state.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (_state.edition.id != _openedEdition?.id) {
      // Edition changed — reopen DB against the matching layout asset.
      _openedEdition = _state.edition;
      setState(() {
        _dbFuture = MushafDb.open(edition: _state.edition);
        _pageNumber = 1;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    } else {
      // Bookmarks / audio / reciter changed — repaint top bar etc.
      setState(() {});
    }
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    setState(() => _pageNumber = page);
    _state.setCurrentPage(page);
  }

  Future<void> _openSettings(int totalPages) async {
    final target = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (target != null) {
      final clamped = target.clamp(1, totalPages);
      _pageController.jumpToPage(clamped - 1);
    }
  }

  Future<void> _openJumpTo(MushafDb db, int totalPages) async {
    final target = await showJumpToModal(
      context,
      totalPages: totalPages,
      db: db,
    );
    if (target == null) return;
    final clamped = target.clamp(1, totalPages);
    _pageController.jumpToPage(clamped - 1);
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _state,
      child: Scaffold(
        body: SafeArea(
          child: FutureBuilder<MushafDb>(
            future: _dbFuture,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Failed to open mushaf DB:\n${snap.error}'),
                  ),
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final db = snap.data!;
              final totalPages = db.edition.totalPages;
              final currentPage = _pageNumber.clamp(1, totalPages);
              return Column(
                children: [
                  TopBar(
                    currentEdition: _state.edition,
                    onSetEdition: _state.setEdition,
                    onOpenSettings: () => _openSettings(totalPages),
                    onToggleBookmark: () =>
                        _state.toggleBookmark(currentPage),
                    onOpenJumpTo: () => _openJumpTo(db, totalPages),
                    isBookmarked: _state.isBookmarked(currentPage),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      // reverse:true puts page index 0 at the right edge —
                      // matching how a printed Quran opens (page 1 on right).
                      reverse: true,
                      itemCount: totalPages,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) => MushafPage(
                        db: db,
                        pageNumber: index + 1,
                        onWordTap: _state.audioOnTap
                            ? (word) => AudioService().handleWordTap(
                                  context,
                                  db,
                                  _state,
                                  word,
                                )
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

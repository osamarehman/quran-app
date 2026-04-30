/// Stub for v0.2 Stage 1 (Agent C): fetches the merged reciter list from
/// alquran.cloud, Quran.com, and any other reachable CDN; caches to disk.
/// Until populated, this is empty.
library;

class Reciter {
  final String id;
  final String displayName;
  final String? languageEn;
  final String? languageAr;
  final String provider;
  final int? bitrate;
  final Uri Function(int globalAyahIndex) urlBuilder;

  const Reciter({
    required this.id,
    required this.displayName,
    required this.provider,
    required this.urlBuilder,
    this.languageEn,
    this.languageAr,
    this.bitrate,
  });
}

abstract class ReciterCatalog {
  /// Loaded list — empty until Agent C wires the providers.
  Future<List<Reciter>> all();

  /// Resolves a reciter by its catalog id.
  Future<Reciter?> byId(String id);

  /// Forces a network refresh of the merged list.
  Future<void> refresh();
}

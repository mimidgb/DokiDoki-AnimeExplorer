import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/anime_api.dart';
import '../models/anime.dart';

class AnimeProvider with ChangeNotifier {
  final AnimeApi api;
  AnimeProvider(this.api);

  // ===== Main lists
  List<Anime> _items = [];
  bool _loading = false;
  String? _error;
  String _currentLabel = 'Recommended';

  List<Anime> get items => _items;
  bool get loading => _loading;
  String? get error => _error;
  String get currentLabel => _currentLabel;

  // ===== Home sections
  List<Anime> _recommended = [];
  List<Anime> _popular = [];
  List<Anime> _seasonNow = [];
  List<Anime> _topMovies = [];
  bool _loadingSections = false;
  String? _errorSections;

  List<Anime> get recommended => _recommended;
  List<Anime> get popular => _popular;
  List<Anime> get seasonNow => _seasonNow;
  List<Anime> get topMovies => _topMovies;
  bool get loadingSections => _loadingSections;
  String? get errorSections => _errorSections;

  // ===== Genre mini-poster cache (anti-duplikat)
  final Map<int, String> _genrePosterUrl = {};
  final Set<int> _genrePending = {};
  final Set<String> _usedGenrePosterUrls = {}; // <- to avoid duplicates across genres
  String? posterForGenre(int genreId) => _genrePosterUrl[genreId];

  Future<void> ensureGenrePoster(int genreId) async {
    if (_genrePosterUrl.containsKey(genreId) || _genrePending.contains(genreId)) return;
    _genrePending.add(genreId);
    try {
      final list = await api.fetchAnimeByGenre(genreId: genreId, limit: 8);
      final candidates = list.where((a) => a.imageUrl.isNotEmpty).toList();

      String? chosen;
      for (final a in candidates) {
        if (!_usedGenrePosterUrls.contains(a.imageUrl)) {
          chosen = a.imageUrl;
          _usedGenrePosterUrls.add(a.imageUrl);
          break;
        }
      }
      // fallback: pakai pertama walau duplikat jika semua sama
      chosen ??= candidates.isNotEmpty ? candidates.first.imageUrl : null;

      if (chosen != null) {
        _genrePosterUrl[genreId] = chosen;
      }
    } catch (e) {
      if (kDebugMode) print('ensureGenrePoster($genreId) failed: $e');
    } finally {
      _genrePending.remove(genreId);
      notifyListeners();
    }
  }

  // ===== Loaders main
  Future<void> loadTopAnime() async {
    await _load(() async {
      _currentLabel = 'Recommended';
      _items = await api.fetchTopAnime(limit: 24);
    });
  }

  Future<void> loadByGenre({required String label, required int genreId}) async {
    await _load(() async {
      _currentLabel = label;
      _items = await api.fetchAnimeByGenre(genreId: genreId, limit: 24);
    });
  }

  Future<void> _load(Future<void> Function() runner) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await runner();
    } catch (e) {
      _error = 'Failed to load data. Please try again.';
      if (kDebugMode) print(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ===== Home sections – prefer seasonNow for Hero (≠ popular)
  Future<void> loadHomeSections() async {
    if (_loadingSections) return;
    _loadingSections = true;
    _errorSections = null;
    notifyListeners();
    try {
      final List<Anime> source =
          _items.isNotEmpty ? List<Anime>.from(_items) : await api.fetchTopAnime(limit: 40);

      _popular = source.take(12).toList();

      final rnd = Random();
      final shuffled = List<Anime>.from(source)..shuffle(rnd);
      _recommended = shuffled.take(12).toList();

      try {
        _seasonNow = await api.fetchSeasonNow(limit: 18);
      } catch (e) {
        if (kDebugMode) print('seasonNow failed: $e');
        _seasonNow = [];
      }

      try {
        _topMovies = await api.fetchTopMovies(limit: 18);
      } catch (e) {
        if (kDebugMode) print('topMovies failed: $e');
        _topMovies = [];
      }
    } catch (e) {
      _errorSections = 'Failed to load home sections. Pull to refresh.';
      if (kDebugMode) print(e);
    } finally {
      _loadingSections = false;
      notifyListeners();
    }
  }
}

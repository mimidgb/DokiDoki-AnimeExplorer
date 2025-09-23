import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/anime.dart';

/// Provider untuk menyimpan watchlist secara lokal (persisten).
class WatchlistProvider with ChangeNotifier {
  static const _prefsKey = 'watchlist_v1';

  /// Simpan sebagai map agar cek keanggotaan cepat.
  final Map<int, Anime> _items = {};
  bool _loaded = false;

  WatchlistProvider() {
    // muat data di background saat provider dibuat
    _load();
  }

  /// Daftar anime (urut sesuai urutan penambahan).
  List<Anime> get items => _items.values.toList(growable: false);

  bool get isLoaded => _loaded;

  /// Apakah id sudah ada di watchlist.
  bool isSaved(int id) => _items.containsKey(id);

  /// Tambah; return true jika berhasil tambah (baru).
  Future<bool> add(Anime a) async {
    if (_items.containsKey(a.id)) return false;
    _items[a.id] = _toRef(a);
    await _persist();
    notifyListeners();
    return true;
  }

  /// Hapus; return true jika benar-benar terhapus.
  Future<bool> remove(int id) async {
    final ok = _items.remove(id) != null;
    if (ok) {
      await _persist();
      notifyListeners();
    }
    return ok;
  }

  /// Toggle; return true kalau AKSI akhirnya “tersimpan”, false kalau “terhapus”.
  Future<bool> toggle(Anime a) async {
    if (_items.containsKey(a.id)) {
      await remove(a.id);
      return false;
    } else {
      await add(a);
      return true;
    }
  }

  // ================== internal ==================

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw) as List;
        _items
          ..clear()
          ..addEntries(list.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            final a = _fromRef(m);
            return MapEntry(a.id, a);
          }));
      }
    } catch (_) {
      // abaikan error parse
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _items.values.map(_toRefMap).toList();
    await prefs.setString(_prefsKey, jsonEncode(list));
  }

  /// Simpan hanya field penting (ringkas).
  Anime _toRef(Anime a) => Anime(
        id: a.id,
        title: a.title,
        imageUrl: a.imageUrl,
        score: a.score,
        episodes: a.episodes,
        synopsis: a.synopsis,
        type: a.type,
        status: a.status,
        rating: a.rating,
        duration: a.duration,
        season: a.season,
        year: a.year,
        genres: a.genres,
        studio: a.studio,
        trailerUrl: a.trailerUrl,
        malUrl: a.malUrl,
      );

  Map<String, dynamic> _toRefMap(Anime a) => {
        'mal_id': a.id,
        'title_english': a.title, // simpan di key ini agar kompatibel parser
        'images': {
          'jpg': {'image_url': a.imageUrl, 'large_image_url': a.imageUrl},
          'webp': {'image_url': a.imageUrl, 'large_image_url': a.imageUrl},
        },
        'score': a.score,
        'episodes': a.episodes,
        'synopsis': a.synopsis,
        'type': a.type,
        'status': a.status,
        'rating': a.rating,
        'duration': a.duration,
        'season': a.season,
        'year': a.year,
        'studios': a.studio == null ? [] : [{'name': a.studio}],
        'genres': a.genres.map((g) => {'name': g}).toList(),
        'trailer': a.trailerUrl == null
            ? null
            : {
                'url': a.trailerUrl,
              },
        'url': a.malUrl,
      };

  Anime _fromRef(Map<String, dynamic> json) => Anime.fromJson(json);
}

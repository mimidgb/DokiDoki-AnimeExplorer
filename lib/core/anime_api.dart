import 'package:dio/dio.dart';
import '../models/anime.dart';

/// Hasil berhalaman (pagination) generik.
class PagedResult<T> {
  final List<T> items;
  final bool hasNext;
  final int nextPage;
  PagedResult({
    required this.items,
    required this.hasNext,
    required this.nextPage,
  });
}

/// Item episode untuk tab Episodes.
class EpisodeItem {
  final int? number;
  final String title;
  final String? aired;
  final bool filler;
  final bool recap;
  final String? synopsis;

  EpisodeItem({
    required this.number,
    required this.title,
    this.aired,
    this.filler = false,
    this.recap = false,
    this.synopsis,
  });

  factory EpisodeItem.fromJson(Map<String, dynamic> j) {
    return EpisodeItem(
      number: j['mal_id'] is int ? j['mal_id'] as int : (j['episode'] as int?),
      // beberapa payload Jikan menyediakan variasi judul
      title: (j['title'] ?? j['title_romanji'] ?? j['title_japanese'] ?? '').toString(),
      aired: j['aired']?.toString(),
      filler: (j['filler'] as bool?) ?? false,
      recap: (j['recap'] as bool?) ?? false,
      synopsis: j['synopsis']?.toString(),
    );
  }
}

/// Seiyuu/voice actor ringkas.
class VoiceActor {
  final String name;
  final String? imageUrl;
  final String language;
  VoiceActor({required this.name, this.imageUrl, required this.language});
}

/// Karakter utk tab Characters.
class CharacterEntry {
  final int id;
  final String name;
  final String? imageUrl;
  final String role;
  final VoiceActor? vaJp;

  CharacterEntry({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.role,
    this.vaJp,
  });

  factory CharacterEntry.fromJson(Map<String, dynamic> j) {
    final c = j['character'] as Map<String, dynamic>? ?? {};
    final images = (c['images'] as Map<String, dynamic>?)?['jpg'] as Map<String, dynamic>?;
    VoiceActor? pickVA;
    final vas = j['voice_actors'];
    if (vas is List && vas.isNotEmpty) {
      Map<String, dynamic>? vaJp;
      for (final v in vas) {
        if (v is Map<String, dynamic> &&
            (v['language']?.toString().toLowerCase() == 'japanese')) {
          vaJp = v;
          break;
        }
      }
      vaJp ??= vas.first as Map<String, dynamic>;
      final person = vaJp?['person'] as Map<String, dynamic>? ?? {};
      final pimg =
          (person['images'] as Map<String, dynamic>?)?['jpg'] as Map<String, dynamic>?;
      pickVA = VoiceActor(
        name: (person['name'] ?? '').toString(),
        imageUrl: (pimg?['image_url'] ?? '').toString(),
        language: (vaJp?['language'] ?? '').toString(),
      );
    }
    return CharacterEntry(
      id: (c['mal_id'] ?? -1) as int,
      name: (c['name'] ?? '').toString(),
      imageUrl: (images?['image_url'] ?? '').toString(),
      role: (j['role'] ?? '').toString(),
      vaJp: pickVA,
    );
  }
}

/// Client API Jikan v4 untuk kebutuhan app.
/// - [sfw] akan dipakai sebagai query `sfw=true/false` pada endpoint yang mendukung.
/// - [preferEnglishTitle] disiapkan untuk logika pemilihan judul di layer atas (opsional).
class AnimeApi {
  AnimeApi({this.sfw = true, this.preferEnglishTitle = true});

  /// Diikat ke Settings → Content: Safe Mode (SFW)
  bool sfw;

  /// Disiapkan jika ingin memprioritaskan title English saat menampilkan.
  bool preferEnglishTitle;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.jikan.moe/v4',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Future<List<Anime>> fetchTopAnime({int page = 1, int limit = 24}) async {
    final res = await _dio.get('/top/anime', queryParameters: {
      'page': page,
      'limit': limit,
      'sfw': sfw,
    });
    final data = res.data['data'] as List<dynamic>;
    return data.map((e) => Anime.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Pencarian umum (global search).
  Future<List<Anime>> searchAnime({
    required String query,
    int page = 1,
    int limit = 24,
    String orderBy = 'score',
    String sort = 'desc',
    String? type, // tv/movie/ova/ona/special
  }) async {
    final params = <String, dynamic>{
      'q': query,
      'page': page,
      'limit': limit,
      'sfw': sfw,
      'order_by': orderBy,
      'sort': sort,
    };
    if (type != null && type.isNotEmpty) params['type'] = type;

    final res = await _dio.get('/anime', queryParameters: params);
    final data = res.data['data'] as List<dynamic>;
    return data.map((e) => Anime.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Anime berdasarkan genre (bisa dipadukan dengan query).
  Future<List<Anime>> fetchAnimeByGenre({
    required int genreId,
    String? query,
    int page = 1,
    int limit = 24,
    String orderBy = 'score',
    String sort = 'desc',
    String? type,
  }) async {
    final params = <String, dynamic>{
      'genres': genreId,
      'order_by': orderBy,
      'sort': sort,
      'sfw': sfw,
      'page': page,
      'limit': limit,
    };
    if (type != null && type.isNotEmpty) params['type'] = type;
    if (query != null && query.isNotEmpty) params['q'] = query;

    final res = await _dio.get('/anime', queryParameters: params);
    final data = res.data['data'] as List<dynamic>;
    return data.map((e) => Anime.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Anime>> fetchSeasonNow({int page = 1, int limit = 24}) async {
    final res = await _dio.get('/seasons/now', queryParameters: {
      'page': page,
      'limit': limit,
      'sfw': sfw,
    });
    final data = res.data['data'] as List<dynamic>;
    return data.map((e) => Anime.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Anime>> fetchTopMovies({int page = 1, int limit = 24}) async {
    final res = await _dio.get('/top/anime', queryParameters: {
      'type': 'movie',
      'page': page,
      'limit': limit,
      'sfw': sfw,
    });
    final data = res.data['data'] as List<dynamic>;
    return data.map((e) => Anime.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Anime> fetchAnimeDetail(int id) async {
    // endpoint /full tidak menyediakan parameter sfw
    final res = await _dio.get('/anime/$id/full');
    final data = res.data['data'] as Map<String, dynamic>;
    return Anime.fromJson(data);
  }

  Future<PagedResult<EpisodeItem>> fetchEpisodes({
    required int id,
    int page = 1,
    int limit = 25,
  }) async {
    final res = await _dio.get('/anime/$id/episodes', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final payload = res.data as Map<String, dynamic>;
    final data = payload['data'] as List<dynamic>;
    final pag = payload['pagination'] as Map<String, dynamic>? ?? {};
    final hasNext = (pag['has_next_page'] as bool?) ?? false;
    final items =
        data.map((e) => EpisodeItem.fromJson(e as Map<String, dynamic>)).toList();
    return PagedResult(
      items: items,
      hasNext: hasNext,
      nextPage: hasNext ? page + 1 : page,
    );
  }

  Future<List<CharacterEntry>> fetchCharacters(int id) async {
    final res = await _dio.get('/anime/$id/characters');
    final data = res.data['data'] as List<dynamic>;
    return data.map((e) => CharacterEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
}

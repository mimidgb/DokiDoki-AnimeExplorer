import 'package:dio/dio.dart';
import '../models/anime.dart';

class AnimeApi {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.jikan.moe/v4',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<List<Anime>> fetchTopAnime({int page = 1, int limit = 24}) async {
    final res = await _dio.get('/top/anime', queryParameters: {
      'page': page,
      'limit': limit,
      'sfw': true,
    });
    final data = res.data['data'] as List<dynamic>;
    return data.map((e) => Anime.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Anime>> fetchAnimeByGenre({
    required int genreId,
    int page = 1,
    int limit = 24,
  }) async {
    final res = await _dio.get('/anime', queryParameters: {
      'genres': genreId,
      'order_by': 'score',
      'sort': 'desc',
      'sfw': true,
      'page': page,
      'limit': limit,
    });
    final data = res.data['data'] as List<dynamic>;
    return data.map((e) => Anime.fromJson(e as Map<String, dynamic>)).toList();
  }

  // NEW: rilisan musim ini
  Future<List<Anime>> fetchSeasonNow({int page = 1, int limit = 24}) async {
    final res = await _dio.get('/seasons/now', queryParameters: {
      'page': page,
      'limit': limit,
      'sfw': true,
    });
    final data = res.data['data'] as List<dynamic>;
    return data.map((e) => Anime.fromJson(e as Map<String, dynamic>)).toList();
  }

  // NEW: top movies
  Future<List<Anime>> fetchTopMovies({int page = 1, int limit = 24}) async {
    final res = await _dio.get('/top/anime', queryParameters: {
      'type': 'movie',
      'page': page,
      'limit': limit,
      'sfw': true,
    });
    final data = res.data['data'] as List<dynamic>;
    return data.map((e) => Anime.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class Anime {
  final int id;
  final String title;
  final String imageUrl;
  final double? score;
  final int? episodes;
  final String? synopsis;

  // Tambahan untuk halaman detail:
  final String? type;         // TV, Movie, OVA, ...
  final String? status;       // Airing, Finished Airing
  final String? rating;       // PG-13, R, etc
  final String? duration;     // "23 min per ep"
  final String? season;       // spring/summer/fall/winter
  final int? year;            // 2024
  final List<String> genres;  // ["Action", "Fantasy"]
  final String? studio;       // ambil studio pertama jika ada
  final String? trailerUrl;   // youtube url (jika ada)
  final String? malUrl;       // halaman MAL

  Anime({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.score,
    this.episodes,
    this.synopsis,
    this.type,
    this.status,
    this.rating,
    this.duration,
    this.season,
    this.year,
    this.genres = const [],
    this.studio,
    this.trailerUrl,
    this.malUrl,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    String _pickTitle(Map<String, dynamic> j) {
      return (j['title'] ??
              j['title_english'] ??
              j['title_japanese'] ??
              (j['titles'] is List && (j['titles'] as List).isNotEmpty
                  ? ((j['titles'] as List).first['title'] ?? '')
                  : '') ??
              '')
          .toString();
    }

    String _pickImage(Map<String, dynamic> j) {
      final images = j['images'] as Map<String, dynamic>?;
      final jpg = images?['jpg'] as Map<String, dynamic>?;
      final webp = images?['webp'] as Map<String, dynamic>?;
      return (jpg?['large_image_url'] ??
              jpg?['image_url'] ??
              webp?['large_image_url'] ??
              webp?['image_url'] ??
              '')
          .toString();
    }

    List<String> _pickGenres(Map<String, dynamic> j) {
      final g = j['genres'];
      if (g is List) {
        return g
            .map((e) => (e is Map<String, dynamic> ? (e['name'] ?? '') : '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return const [];
    }

    String? _pickStudio(Map<String, dynamic> j) {
      final s = j['studios'];
      if (s is List && s.isNotEmpty) {
        final first = s.first;
        if (first is Map<String, dynamic>) return first['name']?.toString();
      }
      return null;
    }

    String? _pickTrailerUrl(Map<String, dynamic> j) {
      final t = j['trailer'];
      if (t is Map<String, dynamic>) {
        final yid = t['youtube_id']?.toString();
        final url = t['url']?.toString();
        if (url != null && url.isNotEmpty) return url;
        if (yid != null && yid.isNotEmpty) return 'https://youtu.be/$yid';
      }
      return null;
    }

    return Anime(
      id: (json['mal_id'] ?? json['id'] ?? -1) as int,
      title: _pickTitle(json),
      imageUrl: _pickImage(json),
      score: (json['score'] as num?)?.toDouble(),
      episodes: json['episodes'] as int?,
      synopsis: json['synopsis']?.toString(),
      type: json['type']?.toString(),
      status: json['status']?.toString(),
      rating: json['rating']?.toString(),
      duration: json['duration']?.toString(),
      season: json['season']?.toString(),
      year: json['year'] is int ? json['year'] as int : int.tryParse('${json['year']}'),
      genres: _pickGenres(json),
      studio: _pickStudio(json),
      trailerUrl: _pickTrailerUrl(json),
      malUrl: json['url']?.toString(),
    );
  }
}

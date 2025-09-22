class Anime {
  final int id;
  final String title;
  final String imageUrl;
  final double? score;
  final int? episodes;
  final String? synopsis;

  Anime({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.score,
    this.episodes,
    this.synopsis,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final jpg = images?['jpg'] as Map<String, dynamic>?;
    final webp = images?['webp'] as Map<String, dynamic>?;

    String? _img =
        jpg?['large_image_url'] ?? jpg?['image_url'] ?? webp?['large_image_url'] ?? webp?['image_url'];

    return Anime(
      id: json['mal_id'] as int,
      title: (json['title'] ?? json['title_english'] ?? 'Unknown Title').toString(),
      imageUrl: _img ?? '',
      score: (json['score'] is num) ? (json['score'] as num).toDouble() : null,
      episodes: (json['episodes'] is int) ? json['episodes'] as int : null,
      synopsis: json['synopsis']?.toString(),
    );
  }
}

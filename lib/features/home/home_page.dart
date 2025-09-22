import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/anime_provider.dart';
import '../../models/anime.dart';
import 'widgets/hero_carousel.dart';
import 'widgets/anime_horizontal_list.dart';
import 'widgets/genre_grid.dart'; // GenreStripPosters

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, Object?>> _genres = const [
    {'label': 'Action', 'id': 1},
    {'label': 'Adventure', 'id': 2},
    {'label': 'Comedy', 'id': 4},
    {'label': 'Drama', 'id': 8},
    {'label': 'Fantasy', 'id': 10},
    {'label': 'Horror', 'id': 14},
    {'label': 'Mystery', 'id': 7},
    {'label': 'Romance', 'id': 22},
    {'label': 'Sci-Fi', 'id': 24},
    {'label': 'Slice of Life', 'id': 36},
    {'label': 'Sports', 'id': 30},
    {'label': 'Supernatural', 'id': 37},
    {'label': 'Mecha', 'id': 18},
    {'label': 'Psychological', 'id': 40},
    {'label': 'Thriller', 'id': 41},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final prov = context.read<AnimeProvider>();
      prov.loadTopAnime().then((_) => prov.loadHomeSections());
    });
  }

  void _goDetail(BuildContext context, Anime a) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Details for "${a.title}" coming soon!')),
    );
  }

  Future<void> _openGenre(int index) async {
    final g = _genres[index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Genre page "${g['label']}" coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnimeProvider>();

    return RefreshIndicator(
      onRefresh: () async {
        final prov = context.read<AnimeProvider>();
        await prov.loadTopAnime();
        await prov.loadHomeSections();
      },
      child: CustomScrollView(
        slivers: [
          // HERO – prefer seasonNow (≠ popular)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Builder(
                builder: (_) {
                  final list = p.seasonNow.isNotEmpty
                      ? p.seasonNow
                      : (p.recommended.isNotEmpty ? p.recommended : p.items);
                  if ((p.loading || p.loadingSections) && list.isEmpty) {
                    return const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (list.isEmpty) return const SizedBox.shrink();
                  return HeroCarousel(
                    items: list,
                    onTapDetail: (a) => _goDetail(context, a),
                  );
                },
              ),
            ),
          ),

          // EXPLORE GENRES – square blurred posters
          SliverToBoxAdapter(
            child: GenreStripPosters(
              genres: _genres,
              onTap: (i) => _openGenre(i),
            ),
          ),

          // RECOMMENDED
          SliverToBoxAdapter(
            child: AnimeHorizontalList(
              title: 'Recommended For You',
              items: p.recommended,
              onTapItem: (a) => _goDetail(context, a),
            ),
          ),

          // TRENDING
          SliverToBoxAdapter(
            child: AnimeHorizontalList(
              title: 'Trending Now',
              items: p.popular,
              onTapItem: (a) => _goDetail(context, a),
            ),
          ),

          // THIS SEASON
          SliverToBoxAdapter(
            child: AnimeHorizontalList(
              title: 'This Season',
              items: p.seasonNow,
              onTapItem: (a) => _goDetail(context, a),
            ),
          ),

          // TOP MOVIES
          SliverToBoxAdapter(
            child: AnimeHorizontalList(
              title: 'Top Movies',
              items: p.topMovies,
              onTapItem: (a) => _goDetail(context, a),
            ),
          ),
        ],
      ),
    );
  }
}

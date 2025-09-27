import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/anime_provider.dart';
import '../../models/anime.dart';
import '../../l10n/app_localizations.dart';

import 'widgets/hero_carousel.dart';
import 'widgets/anime_horizontal_list.dart';
import 'widgets/genre_grid.dart'; // GenreStripPosters
import '../genre/genre_list_page.dart';
import '../detail/anime_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // List genre untuk strip di beranda (id = Jikan genre id)
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
    // Muat data setelah frame pertama (aman untuk context)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<AnimeProvider>();
      await prov.loadTopAnime();
      if (!mounted) return;
      await prov.loadHomeSections();
    });
  }

  void _goDetail(BuildContext context, Anime a) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimeDetailPage(animeId: a.id, title: a.title),
      ),
    );
  }

  void _openGenre(int index) {
    final g = _genres[index];
    final id = g['id'] as int;
    final label = g['label'] as String;
    Navigator.of(context).push(
      MaterialPageRoute(
        // GenreListPage membutuhkan genreName
        builder: (_) => GenreListPage(genreId: id, genreName: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnimeProvider>();
    final l = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        final prov = context.read<AnimeProvider>();
        await prov.loadTopAnime();
        await prov.loadHomeSections();
      },
      child: CustomScrollView(
        slivers: [
          // ===== HERO (pakai seasonNow bila ada, agar beda dengan Trending) =====
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

          // ===== EXPLORE GENRES (ikon + warna, horizontal) =====
          SliverToBoxAdapter(
            child: GenreStripPosters(
              genres: _genres,
              onTap: _openGenre, // callback menerima index
            ),
          ),

          // ===== RECOMMENDED =====
          SliverToBoxAdapter(
            child: AnimeHorizontalList(
              title: l.t('Recommended'),
              items: p.recommended,
              onTapItem: (a) => _goDetail(context, a),
            ),
          ),

          // ===== TRENDING =====
          SliverToBoxAdapter(
            child: AnimeHorizontalList(
              title: l.t('Trending'),
              items: p.popular,
              onTapItem: (a) => _goDetail(context, a),
            ),
          ),

          // ===== THIS SEASON =====
          SliverToBoxAdapter(
            child: AnimeHorizontalList(
              title: l.t('Season'),
              items: p.seasonNow,
              onTapItem: (a) => _goDetail(context, a),
            ),
          ),

          // ===== TOP MOVIES =====
          SliverToBoxAdapter(
            child: AnimeHorizontalList(
              title: l.t('Movies'),
              items: p.topMovies,
              onTapItem: (a) => _goDetail(context, a),
            ),
          ),
        ],
      ),
    );
  }
}

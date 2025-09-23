import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/anime_api.dart';
import '../../models/anime.dart';
import '../detail/anime_detail_page.dart';

class GenreListPage extends StatefulWidget {
  const GenreListPage({
    super.key,
    required this.genreId,
    required this.genreName,
  });

  final int genreId;
  final String genreName;

  @override
  State<GenreListPage> createState() => _GenreListPageState();
}

class _GenreListPageState extends State<GenreListPage> {
  final _api = AnimeApi();
  final _scroll = ScrollController();
  final _queryCtl = TextEditingController();

  String _orderBy = 'score';
  String _sort = 'desc';
  String? _type; // null=all, else tv/movie/ova/ona/special
  String _query = '';

  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  final List<Anime> _items = [];

  Timer? _deb;

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _queryCtl.dispose();
    _deb?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 500) {
      _fetch(reset: false);
    }
  }

  void _onQueryChanged(String v) {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 400), () {
      setState(() => _query = v.trim());
      _fetch(reset: true);
    });
  }

  Future<void> _fetch({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _page = 1;
        _items.clear();
        _hasMore = false;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final list = await _api.fetchAnimeByGenre(
        genreId: widget.genreId,
        query: _query.isEmpty ? null : _query,
        page: _page,
        limit: 24,
        orderBy: _orderBy,
        sort: _sort,
        type: _type,
      );
      setState(() {
        _items.addAll(list);
        _hasMore = list.length == 24;
        _page += 1;
      });
    } finally {
      if (reset) {
        setState(() => _loading = false);
      } else {
        setState(() => _loadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.genreName, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          // Search in {Genre}
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _queryCtl,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search in ${widget.genreName}…',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
              ),
            ),
          ),

          // Sort & Type
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _Drop(
                  label: 'Sort',
                  value: _orderBy,
                  items: const {
                    'score': 'Score',
                    'rank': 'Rank',
                    'popularity': 'Popularity',
                    'favorites': 'Favorites',
                    'title': 'Title',
                  },
                  onChanged: (v) {
                    setState(() => _orderBy = v);
                    _fetch(reset: true);
                  },
                ),
                const SizedBox(width: 10),
                _Drop(
                  label: 'Type',
                  value: _type ?? 'all',
                  items: const {
                    'all': 'All',
                    'tv': 'TV',
                    'movie': 'Movie',
                    'ova': 'OVA',
                    'ona': 'ONA',
                    'special': 'Special',
                  },
                  onChanged: (v) {
                    setState(() => _type = (v == 'all') ? null : v);
                    _fetch(reset: true);
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: _sort == 'desc' ? 'Desc' : 'Asc',
                  onPressed: () {
                    setState(() => _sort = _sort == 'desc' ? 'asc' : 'desc');
                    _fetch(reset: true);
                  },
                  icon: Icon(_sort == 'desc' ? Icons.south_rounded : Icons.north_rounded),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => _fetch(reset: true),
                    child: GridView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2 / 3,
                      ),
                      itemCount: _items.length + 1,
                      itemBuilder: (context, i) {
                        if (i == _items.length) {
                          return _loadingMore
                              ? const Center(child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ))
                              : const SizedBox.shrink();
                        }
                        final a = _items[i];
                        return _CardSmall(
                          anime: a,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AnimeDetailPage(animeId: a.id, title: a.title),
                            ));
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Drop extends StatelessWidget {
  const _Drop({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => items.entries
          .map((e) => PopupMenuItem<String>(value: e.key, child: Text(e.value)))
          .toList(),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Text(items[value] ?? value),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CardSmall extends StatelessWidget {
  const _CardSmall({required this.anime, required this.onTap});
  final Anime anime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (anime.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: anime.imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                placeholder: (c, _) => Container(color: cs.surfaceContainerHighest),
                errorWidget: (c, _, __) => Container(
                  color: cs.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              )
            else
              Container(color: cs.surfaceContainerHighest),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xB3000000)],
                  stops: [0.55, 1.0],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.2, height: 1.06),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(anime.score?.toStringAsFixed(1) ?? '-', style: const TextStyle(color: Colors.white)),
                        const Spacer(),
                        Text(anime.episodes != null ? '${anime.episodes} eps' : '',
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

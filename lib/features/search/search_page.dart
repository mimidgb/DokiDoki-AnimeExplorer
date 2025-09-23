import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/anime_api.dart';
import '../../models/anime.dart';
import '../detail/anime_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _api = AnimeApi();
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  String _query = '';
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  int _nextPage = 1;
  final List<Anime> _items = [];

  Timer? _deb;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _deb?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 400), () {
      setState(() => _query = v.trim());
      _search(reset: true);
    });
  }

  Future<void> _search({bool reset = false}) async {
    if (_query.isEmpty) {
      setState(() {
        _items.clear();
        _hasMore = false;
        _nextPage = 1;
      });
      return;
    }
    if (reset) {
      setState(() {
        _loading = true;
        _items.clear();
        _hasMore = false;
        _nextPage = 1;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final page = reset ? 1 : _nextPage;
      final list = await _api.searchAnime(query: _query, page: page, limit: 24);
      setState(() {
        _items.addAll(list);
        _hasMore = list.length == 24;
        _nextPage = page + 1;
      });
    } finally {
      if (reset) {
        setState(() => _loading = false);
      } else {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 500) {
      _search(reset: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search anime…',
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              prefixIcon: const Icon(Icons.search_rounded),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? const _IdleTips()
          : _loading && _items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async => _search(reset: true),
                  child: GridView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2 / 3,
                    ),
                    itemCount: _items.length + 1,
                    itemBuilder: (context, i) {
                      if (i == _items.length) {
                        if (_loadingMore) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        return const SizedBox.shrink();
                      }
                      final a = _items[i];
                      return _AnimeCardSmall(
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
    );
  }
}

class _IdleTips extends StatelessWidget {
  const _IdleTips();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 56, color: cs.onSurfaceVariant),
            const SizedBox(height: 10),
            Text('Find your favorite anime', style: t.titleMedium),
            const SizedBox(height: 6),
            Text('Type a title to start searching.',
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _AnimeCardSmall extends StatelessWidget {
  const _AnimeCardSmall({required this.anime, required this.onTap});
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
            // gradient bawah
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xB3000000)],
                  stops: [0.55, 1.0],
                ),
              ),
            ),
            // text
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

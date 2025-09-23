import 'dart:ui' show ImageFilter; // untuk blur glass
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/anime.dart';
import '../detail/anime_detail_page.dart';
import 'watchlist_provider.dart';

enum WLType { all, tv, movie, ova, ona, special }
enum WLSort { score, title, episodes }

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  final _query = TextEditingController();
  WLType _filter = WLType.all;
  WLSort _sort = WLSort.score;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WatchlistProvider>();
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    if (!wp.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    // --- data: filter & sort ---
    final all = wp.items;
    List<Anime> list = all.where((a) {
      final q = _query.text.trim().toLowerCase();
      final okQuery = q.isEmpty || a.title.toLowerCase().contains(q);

      final okType = () {
        if (_filter == WLType.all) return true;
        final type = (a.type ?? '').toLowerCase();
        switch (_filter) {
          case WLType.tv:
            return type == 'tv';
          case WLType.movie:
            return type == 'movie';
          case WLType.ova:
            return type == 'ova';
          case WLType.ona:
            return type == 'ona';
          case WLType.special:
            return type == 'special';
          case WLType.all:
            return true;
        }
      }();

      return okQuery && okType;
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case WLSort.score:
          final sa = a.score ?? -1;
          final sb = b.score ?? -1;
          return sb.compareTo(sa); // desc
        case WLSort.title:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase()); // asc
        case WLSort.episodes:
          final ea = a.episodes ?? -1;
          final eb = b.episodes ?? -1;
          return eb.compareTo(ea); // desc
      }
    });

    // --- UI ---
    if (all.isEmpty) {
      return _EmptyState(cs: cs, t: t);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & count
                Row(
                  children: [
                    Text('Your Watchlist', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('${all.length}', style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search + Sort
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _query,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search in watchlist…',
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
                    const SizedBox(width: 10),
                    _SortButton(
                      sort: _sort,
                      onChanged: (s) => setState(() => _sort = s),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Filter type
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _typeChip('All', WLType.all, cs),
                      _typeChip('TV', WLType.tv, cs, color: Colors.blue),
                      _typeChip('Movie', WLType.movie, cs, color: Colors.pink),
                      _typeChip('OVA', WLType.ova, cs, color: Colors.orange),
                      _typeChip('ONA', WLType.ona, cs, color: Colors.purple),
                      _typeChip('Special', WLType.special, cs, color: Colors.teal),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: list.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text('No results found', style: t.titleMedium),
                    ),
                  ),
                )
              : SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 2 / 3,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final a = list[i];
                    return _WatchCard(
                      anime: a,
                      onOpen: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AnimeDetailPage(animeId: a.id, title: a.title),
                          ),
                        );
                      },
                      onRemove: () async {
                        final ok = await context.read<WatchlistProvider>().remove(a.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Removed from Watchlist' : 'Failed to remove')),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _typeChip(String label, WLType type, ColorScheme cs, {Color? color}) {
    final selected = _filter == type;
    final bg = selected ? (color ?? cs.primary) : cs.surfaceContainerHighest;
    final fg = selected ? Colors.white : cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _filter = type),
        label: Text(label),
        labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w700),
        selectedColor: bg,
        backgroundColor: cs.surfaceContainerHighest,
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onChanged});
  final WLSort sort;
  final ValueChanged<WLSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<WLSort>(
      tooltip: 'Sort',
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: WLSort.score, child: _SortItem(icon: Icons.star_rounded, text: 'By Score')),
        PopupMenuItem(value: WLSort.title, child: _SortItem(icon: Icons.sort_by_alpha_rounded, text: 'A–Z Title')),
        PopupMenuItem(value: WLSort.episodes, child: _SortItem(icon: Icons.playlist_play_rounded, text: 'By Episodes')),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(_iconFor(sort), size: 20),
            const SizedBox(width: 8),
            Text(_labelFor(sort), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(WLSort s) {
    switch (s) {
      case WLSort.score:
        return Icons.star_rounded;
      case WLSort.title:
        return Icons.sort_by_alpha_rounded;
      case WLSort.episodes:
        return Icons.playlist_play_rounded;
    }
  }

  static String _labelFor(WLSort s) {
    switch (s) {
      case WLSort.score:
        return 'Score';
      case WLSort.title:
        return 'Title';
      case WLSort.episodes:
        return 'Episodes';
    }
  }
}

class _SortItem extends StatelessWidget {
  const _SortItem({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18),
      const SizedBox(width: 10),
      Text(text),
    ]);
  }
}

class _WatchCard extends StatelessWidget {
  const _WatchCard({
    required this.anime,
    required this.onOpen,
    required this.onRemove,
  });

  final Anime anime;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onOpen,
      onLongPress: onRemove,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster
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

              // Layer gelap tipis agar poster lebih “punchy”
              Container(color: Colors.black.withOpacity(0.08)),

              // Badge type kiri atas
              Positioned(
                left: 8,
                top: 8,
                child: _TypeBadge(type: anime.type ?? '-', scheme: cs),
              ),

              // Tombol remove kanan atas
              Positioned(
                right: 8,
                top: 8,
                child: Material(
                  color: Colors.black.withOpacity(0.35),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onRemove,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close_rounded, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),

              // Panel informasi bawah (glass)
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipRRect(
                  // Clip lagi untuk glass
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.28),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            anime.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              height: 1.08,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(anime.score?.toStringAsFixed(1) ?? '-', style: const TextStyle(color: Colors.white)),
                              const SizedBox(width: 10),
                              if (anime.episodes != null)
                                Row(
                                  children: [
                                    const Icon(Icons.play_circle_filled_rounded, size: 14, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text('${anime.episodes} eps', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.scheme});
  final String type;
  final ColorScheme scheme;

  Color _bgFor(String t) {
    switch (t.toLowerCase()) {
      case 'tv':
        return Colors.blue;
      case 'movie':
        return Colors.pink;
      case 'ova':
        return Colors.orange;
      case 'ona':
        return Colors.purple;
      case 'special':
        return Colors.teal;
      default:
        return scheme.secondaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgFor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        (type.isEmpty ? '-' : type).toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10.5, letterSpacing: .5),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cs, required this.t});
  final ColorScheme cs;
  final TextTheme t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border_rounded, size: 64, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Your watchlist is empty', style: t.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Save anime from the detail page and it will appear here.',
            style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/anime_api.dart';
import '../../models/anime.dart';
import '../watchlist/watchlist_provider.dart';

class AnimeDetailPage extends StatelessWidget {
  const AnimeDetailPage({super.key, required this.animeId, required this.title});

  final int animeId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => _AnimeDetailProvider(AnimeApi(), animeId)..init(),
      child: _AnimeDetailScaffold(fallbackTitle: title),
    );
  }
}

class _AnimeDetailProvider with ChangeNotifier {
  _AnimeDetailProvider(this.api, this.id);
  final AnimeApi api;
  final int id;

  // Overview
  Anime? detail;
  bool loading = false;
  String? error;

  // Episodes
  final List<EpisodeItem> episodes = [];
  bool epLoading = false;
  bool epLoadingMore = false;
  bool epHasMore = true;
  int _epNextPage = 1;

  // Characters (tanpa staff)
  List<CharacterEntry> characters = [];
  bool charLoading = false;
  String? charError;

  Future<void> init() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      detail = await api.fetchAnimeDetail(id);
    } catch (e) {
      error = 'Failed to load details. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ====== Episodes
  Future<void> ensureEpisodes() async {
    if (epLoading || epLoadingMore || episodes.isNotEmpty) return;
    await refreshEpisodes();
  }

  Future<void> refreshEpisodes() async {
    epLoading = true;
    epHasMore = true;
    _epNextPage = 1;
    episodes.clear();
    notifyListeners();
    try {
      final res = await api.fetchEpisodes(id: id, page: _epNextPage, limit: 25);
      episodes.addAll(res.items);
      epHasMore = res.hasNext;
      _epNextPage = res.nextPage;
    } finally {
      epLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreEpisodes() async {
    if (!epHasMore || epLoading || epLoadingMore) return;
    epLoadingMore = true;
    notifyListeners();
    try {
      final res = await api.fetchEpisodes(id: id, page: _epNextPage, limit: 25);
      episodes.addAll(res.items);
      epHasMore = res.hasNext;
      _epNextPage = res.nextPage;
    } finally {
      epLoadingMore = false;
      notifyListeners();
    }
  }

  // ====== Characters
  Future<void> ensureCharacters() async {
    if (charLoading || characters.isNotEmpty) return;
    charLoading = true; charError = null; notifyListeners();
    try {
      characters = await api.fetchCharacters(id);
    } catch (_) {
      charError = 'Failed to load characters.';
    } finally {
      charLoading = false; notifyListeners();
    }
  }
}

class _AnimeDetailScaffold extends StatefulWidget {
  const _AnimeDetailScaffold({required this.fallbackTitle});
  final String fallbackTitle;

  @override
  State<_AnimeDetailScaffold> createState() => _AnimeDetailScaffoldState();
}

class _AnimeDetailScaffoldState extends State<_AnimeDetailScaffold>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this); // 3 tab
  bool _watchlistedLocal = false; // hanya untuk animasi/snackbar jika perlu

  @override
  void initState() {
    super.initState();
    _tab.addListener(() {
      final p = context.read<_AnimeDetailProvider>();
      if (_tab.index == 1) p.ensureEpisodes();
      if (_tab.index == 2) p.ensureCharacters();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<_AnimeDetailProvider>();
    final d = p.detail;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final title = d?.title ?? widget.fallbackTitle;

    // ⬇️ status watchlist saat ini
    final wp = context.watch<WatchlistProvider>();
    final saved = d != null && wp.isSaved(d.id);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, inner) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 320,
            title: inner ? Text(title, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tab,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Episodes'),
                    Tab(text: 'Characters'),
                  ],
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (d?.imageUrl.isNotEmpty == true)
                    CachedNetworkImage(
                      imageUrl: d!.imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    )
                  else
                    Container(color: cs.surfaceContainerHighest),
                  // gradient bawah kuat agar teks terbaca
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF000000).withValues(alpha: 0.08),
                          const Color(0xFF000000).withValues(alpha: 0.28),
                          const Color(0xFF000000).withValues(alpha: 0.58),
                          const Color(0xFF000000).withValues(alpha: 0.92),
                        ],
                        stops: const [0.0, 0.45, 0.75, 1.0],
                      ),
                    ),
                  ),
                  // header content dekat bawah poster
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 56, // 48 TabBar + 8 spasi
                    child: _HeaderBlock(
                      anime: d,
                      fallbackTitle: widget.fallbackTitle,
                      saved: saved,
                      onToggleWatchlist: () async {
                        if (d == null) return;
                        final nowSaved = await wp.toggle(d);
                        setState(() => _watchlistedLocal = nowSaved);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(nowSaved ? 'Added to Watchlist' : 'Removed from Watchlist')),
                        );
                      },
                      onShare: () async {
                        final url = d?.malUrl ?? '';
                        if (url.isNotEmpty) {
                          await Clipboard.setData(ClipboardData(text: url));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied to clipboard')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No link available')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: Builder(
          builder: (_) {
            if (p.loading && d == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (p.error != null && d == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.error!, style: t.bodyMedium),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => context.read<_AnimeDetailProvider>().init(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              controller: _tab,
              children: [
                _OverviewTab(anime: d),
                _EpisodesTab(),
                _CharactersTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({
    required this.anime,
    required this.fallbackTitle,
    required this.onToggleWatchlist,
    required this.onShare,
    required this.saved,
  });

  final Anime? anime;
  final String fallbackTitle;
  final VoidCallback onToggleWatchlist;
  final VoidCallback onShare;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final title = anime?.title ?? fallbackTitle;
    final score = anime?.score != null ? anime!.score!.toStringAsFixed(1) : '-';
    final infoLine = [
      anime?.type,
      anime?.episodes != null ? '${anime!.episodes} eps' : null,
      anime?.duration,
    ].where((e) => e != null && e!.isNotEmpty).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.05,
            shadows: [Shadow(color: Color(0xAA000000), blurRadius: 8, offset: Offset(0, 1))],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(score, style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(width: 10),
            if (infoLine.isNotEmpty)
              Text(infoLine, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),

        // Genre chips (maks 3)
        Wrap(
          spacing: 6,
          runSpacing: -8,
          children: (anime?.genres ?? const [])
              .take(3)
              .map((g) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      g,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),

        // Actions
        Row(
          children: [
            SizedBox(
              height: 40,
              child: FilledButton.icon(
                onPressed: onToggleWatchlist,
                icon: Icon(saved ? Icons.bookmark_added_rounded : Icons.bookmark_add_rounded),
                label: Text(saved ? 'Saved' : 'Watchlist'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewTab extends StatefulWidget {
  const _OverviewTab({required this.anime});
  final Anime? anime;

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final a = widget.anime;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Synopsis', style: t.titleMedium),
        const SizedBox(height: 8),
        if ((a?.synopsis ?? '').isEmpty)
          Text('No synopsis available.', style: t.bodyMedium)
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedCrossFade(
                crossFadeState:
                    _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
                firstChild: Text(
                  a!.synopsis!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium,
                ),
                secondChild: Text(a!.synopsis!, style: t.bodyMedium),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Show less' : 'Read more'),
              ),
            ],
          ),

        const SizedBox(height: 16),
        Text('Info', style: t.titleMedium),
        const SizedBox(height: 8),
        _infoRow(context, 'Type', a?.type),
        _infoRow(context, 'Status', a?.status),
        _infoRow(context, 'Season', _capitalize('${a?.season ?? ''} ${a?.year ?? ''}'.trim())),
        _infoRow(context, 'Broadcast', '-'),
        _infoRow(context, 'Studio', a?.studio),
        _infoRow(context, 'Duration', a?.duration),
        _infoRow(context, 'Rating', a?.rating),

        const SizedBox(height: 16),
        Text('Links', style: t.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if ((a?.malUrl ?? '').isNotEmpty)
              _linkChip('MyAnimeList', onTap: () => _launchUrl(a!.malUrl!)),
            if ((a?.trailerUrl ?? '').isNotEmpty)
              _linkChip('Trailer', onTap: () => _launchUrl(a!.trailerUrl!)),
          ],
        ),
      ],
    );
  }

  static Widget _infoRow(BuildContext context, String label, String? value) {
    final cs = Theme.of(context).colorScheme;
    final color = cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value?.isNotEmpty == true ? value! : '-', maxLines: 3),
          ),
        ],
      ),
    );
  }

  static Widget _linkChip(String label, {required VoidCallback onTap}) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: const Icon(Icons.open_in_new_rounded, size: 18),
    );
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    // coba buka eksternal dulu, fallback ke default
    bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open link')),
      );
    }
  }
}

class _EpisodesTab extends StatefulWidget {
  @override
  State<_EpisodesTab> createState() => _EpisodesTabState();
}

class _EpisodesTabState extends State<_EpisodesTab> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = context.read<_AnimeDetailProvider>();
      if (_scroll.position.pixels >
              _scroll.position.maxScrollExtent - 500 &&
          !p.epLoadingMore &&
          p.epHasMore &&
          !p.epLoading) {
        p.loadMoreEpisodes();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<_AnimeDetailProvider>().ensureEpisodes();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<_AnimeDetailProvider>();
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    if (p.epLoading && p.episodes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => p.refreshEpisodes(),
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: p.episodes.length + 1,
        itemBuilder: (context, i) {
          if (i == p.episodes.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: p.epLoadingMore
                    ? const CircularProgressIndicator()
                    : (p.epHasMore
                        ? const SizedBox.shrink()
                        : Text('No more episodes', style: t.bodySmall)),
              ),
            );
          }

          final e = p.episodes[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul apa adanya dari API (prioritas Inggris/romaji jika parser kamu sudah disetel)
                Row(
                  children: [
                    Text('#${e.number ?? i + 1}',
                        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // hanya tanggal (yyyy-mm-dd)
                Text(_formatDate(e.aired) ?? '-', style: t.bodySmall),
                if ((e.synopsis ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(e.synopsis!, maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    if (iso.length >= 10) {
      final part = iso.substring(0, 10);
      final re = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (re.hasMatch(part)) return part;
    }
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd';
  }
}

class _CharactersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<_AnimeDetailProvider>();
    final t = Theme.of(context).textTheme;

    if (p.charLoading && p.characters.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<_AnimeDetailProvider>().ensureCharacters();
      });
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          sliver: SliverToBoxAdapter(child: Text('Main Cast', style: t.titleMedium)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: p.characters.isEmpty
              ? SliverToBoxAdapter(child: Text('No characters found.', style: t.bodyMedium))
              : SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 per baris (scroll ke bawah)
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2 / 3,
                  ),
                  itemCount: p.characters.length,
                  itemBuilder: (_, i) => _CharacterGridCard(p.characters[i]),
                ),
        ),
      ],
    );
  }
}

class _CharacterGridCard extends StatelessWidget {
  const _CharacterGridCard(this.c);
  final CharacterEntry c;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // gambar
          if (c.imageUrl != null && c.imageUrl!.isNotEmpty)
            CachedNetworkImage(imageUrl: c.imageUrl!, fit: BoxFit.cover)
          else
            Container(color: cs.surfaceContainerHighest),

          // gradient bawah (lebih transparan, tapi tidak terlalu)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF000000).withValues(alpha: 0.05),
                  const Color(0xFF000000).withValues(alpha: 0.60),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),

          // teks di bawah (aman dari overflow)
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

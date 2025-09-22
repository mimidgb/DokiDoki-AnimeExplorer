import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../models/anime.dart';

class AnimeHorizontalList extends StatelessWidget {
  const AnimeHorizontalList({
    super.key,
    required this.title,
    required this.items,
    this.onTapItem,
    this.onTapMore,
  });

  final String title;
  final List<Anime> items;
  final void Function(Anime)? onTapItem;
  final VoidCallback? onTapMore;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Text(title, style: t.titleLarge),
              const Spacer(),
              if (onTapMore != null)
                TextButton(onPressed: onTapMore, child: const Text('Lihat semua')),
            ],
          ),
        ),

        // List horizontal – tinggi disetel agar kartu 136x204 nampak pas
        SizedBox(
          height: 214, // 204 kartu + padding internal
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final a = items[i];
              return SizedBox(
                width: 136,
                // Tinggi kartu dihitung dari aspectRatio 2/3
                child: InkWell(
                  onTap: () => onTapItem?.call(a),
                  borderRadius: BorderRadius.circular(14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Poster
                          CachedNetworkImage(
                            imageUrl: a.imageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            placeholder: (c, _) =>
                                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (c, _, __) =>
                                const Center(child: Icon(Icons.broken_image_outlined)),
                          ),

                          // Overlay bawah
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFF000000).withValues(alpha: 0.12),
                                    const Color(0xFF000000).withValues(alpha: 0.65),
                                    const Color(0xFF000000).withValues(alpha: 0.90),
                                  ],
                                  stops: const [0.0, 0.6, 1.0],
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13, // judul kecil tapi tegas
                                      height: 1.1,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xAA000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 16, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(
                                        a.score?.toStringAsFixed(1) ?? '-',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11, // skor 11sp
                                        ),
                                      ),
                                      const Spacer(),
                                      if (a.episodes != null)
                                        Text(
                                          '${a.episodes} eps',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.95),
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Outline halus
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: cs.outlineVariant.withValues(alpha: 0.2),
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../models/anime.dart';

class AnimeCard extends StatelessWidget {
  const AnimeCard({super.key, required this.anime, this.onTap});
  final Anime anime;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster
              CachedNetworkImage(
                imageUrl: anime.imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                placeholder: (c, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (c, _, __) => const Center(child: Icon(Icons.broken_image_outlined)),
              ),

              // === Overlay gradien (lebih gelap) ===
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.92), // samar di atas
                        Colors.black.withOpacity(0.92), // agak gelap di tengah
                        Colors.black.withOpacity(0.92), // jelas di bawah
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        anime.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          // bantu keterbacaan
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            (anime.score?.toStringAsFixed(1) ?? '-'),
                            style: TextStyle(
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (anime.episodes != null)
                            Text(
                              '${anime.episodes} eps',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Outline halus (opsional)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(16),
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

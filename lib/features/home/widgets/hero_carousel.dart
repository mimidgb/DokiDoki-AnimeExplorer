import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../models/anime.dart';

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
    required this.items,
    this.onTapDetail,
  });

  final List<Anime> items;
  final void Function(Anime)? onTapDetail;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _page = PageController(viewportFraction: 0.90);
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items.take(6).toList(growable: false);
    if (items.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          height: min(220.0, MediaQuery.of(context).size.width * 0.52),
          child: PageView.builder(
            controller: _page,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final a = items[i];
              return AnimatedBuilder(
                animation: _page,
                builder: (context, child) {
                  double value = 1.0;
                  if (_page.positions.isNotEmpty && _page.position.haveDimensions) {
                    final current = _page.page ?? _page.initialPage.toDouble();
                    final diff = (current - i).abs();
                    value = (1 - diff * 0.07).clamp(0.9, 1.0).toDouble();
                  }
                  return Transform.scale(scale: value, child: child);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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

                        // Overlay gradien
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.10),
                                Colors.black.withValues(alpha: 0.65),
                                Colors.black.withValues(alpha: 0.92),
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),

                        // Konten (judul + badge kecil)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    a.score?.toStringAsFixed(1) ?? '-',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                a.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  shadows: [
                                    Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: -6,
                                children: [
                                  if (a.episodes != null) _chipMini('${a.episodes} eps'),
                                  _chipMini('Score ${a.score?.toStringAsFixed(1) ?? "-"}'),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // area klik menutupi banner
                        Positioned.fill(
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: () => widget.onTapDetail?.call(a),
                            ),
                          ),
                        ),

                        // outline halus
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),
        // indikator titik
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            final active = _index == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: active ? 18 : 8,
              decoration: BoxDecoration(
                color: active ? cs.primary : cs.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }

  static Widget _chipMini(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFFFFF).withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

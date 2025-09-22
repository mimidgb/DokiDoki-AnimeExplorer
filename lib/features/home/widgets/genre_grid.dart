import 'package:flutter/material.dart';

/// Horizontal strip of slightly-rectangular genre tiles (emoji + color), no images.
class GenreStripPosters extends StatelessWidget {
  const GenreStripPosters({
    super.key,
    required this.genres,
    required this.onTap,
  });

  /// Expected: [{'label':'Action','id':1}, ...]
  final List<Map<String, Object?>> genres;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul section (app language: English)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text('Explore Genres', style: t.titleLarge),
        ),

        // Sedikit persegi panjang: width > height (clean & readable)
        SizedBox(
          height: 136, // tile height 120 + margin visual
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: genres.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final label = genres[i]['label'] as String;
              return _GenreIconTile(
                label: label,
                colors: _genreColorPair(label),
                onTap: () => onTap(i),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  /// Map each genre to a gentler two-color gradient.
  static List<Color> _genreColorPair(String label) {
    final key = label.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    switch (key) {
      case 'action':
        return const [Color.fromARGB(255, 179, 39, 39), Color.fromARGB(255, 121, 64, 34)]; // red → orange
      case 'adventure':
        return const [Color.fromARGB(255, 25, 59, 57), Color.fromARGB(255, 29, 82, 78)]; // teal
      case 'comedy':
        return const [Color(0xFFFFD166), Color(0xFFFFA62B)]; // amber → orange
      case 'drama':
        return const [Color(0xFF9B5DE5), Color(0xFF6C5CE7)]; // purple
      case 'fantasy':
        return const [Color(0xFF6C63FF), Color(0xFFA66CFF)]; // indigo → violet
      case 'horror':
        return const [Color(0xFF3A0D0D), Color(0xFFB33939)]; // deep maroon → red
      case 'mystery':
        return const [Color(0xFF4361EE), Color(0xFF3A0CA3)]; // blue → indigo
      case 'romance':
        return const [Color(0xFFFF7AA2), Color(0xFFFFA6C9)]; // pink
      case 'scifi':
        return const [Color(0xFF00B4D8), Color(0xFF0077B6)]; // cyan → deep blue
      case 'sliceoflife':
        return const [Color(0xFFE9C46A), Color(0xFFF4A261)]; // sand → caramel
      case 'sports':
        return const [Color(0xFF2A9D8F), Color(0xFF34A0A4)]; // green-teal
      case 'supernatural':
        return const [Color(0xFF6D597A), Color(0xFF355070)]; // mystic violet → slate
      case 'mecha':
        return const [Color(0xFF7A7A7A), Color(0xFF4D4D4D)]; // steel gray
      case 'psychological':
        return const [Color(0xFF2C3E50), Color(0xFF3E5C76)]; // navy → steel blue
      case 'thriller':
        return const [Color(0xFFFF8C42), Color(0xFFEF6C00)]; // orange → deep orange
      default:
        return const [Color(0xFF8E9AAF), Color(0xFFCBC0D3)]; // fallback duotone
    }
  }
}

class _GenreIconTile extends StatelessWidget {
  const _GenreIconTile({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final emoji = _emojiFor(label);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 148, // sedikit lebih lebar dari tinggi
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Filmic tint untuk menyatukan warna & jaga kontras label
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF000000).withValues(alpha: 0.06),
                    const Color(0xFF000000).withValues(alpha: 0.18),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ikon/emoji besar di kiri atas
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                  const Spacer(),
                  // Label genre di kiri bawah
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.white, // selalu terbaca di atas gradient + tint
                      shadows: [
                        Shadow(
                          color: Color(0x88000000),
                          blurRadius: 8,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon mapping per genre (lebih profesional):
String _emojiFor(String label) {
  final key = label.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  switch (key) {
    case 'action':
      return '⚔️';
    case 'adventure':
      return '🗺️';
    case 'comedy':
      return '🎙️'; 
    case 'drama':
      return '🎭';
    case 'fantasy':
      return '🐉';
    case 'horror':
      return '👻';
    case 'mystery':
      return '🕵️';
    case 'romance':
      return '💞';
    case 'scifi':
      return '🚀';
    case 'sliceoflife':
      return '☕';
    case 'sports':
      return '🏃';
    case 'supernatural':
      return '✨';
    case 'mecha':
      return '🤖';
    case 'psychological':
      return '🧠';
    case 'thriller':
      return '🔦';
    default:
      return '🎬';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/anime_api.dart';
import 'providers/anime_provider.dart';
import 'features/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DokiDokiApp());
}

class DokiDokiApp extends StatelessWidget {
  const DokiDokiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Biru brand untuk judul
    const brandBlue = Color(0xFF2E7CF6);
    final seed = brandBlue;

    // (Opsional) tetap pakai Poppins untuk body; judul AppBar akan override ke Sora
    TextTheme fontTheme(TextTheme base) =>
        GoogleFonts.poppinsTextTheme(base).copyWith(
          titleLarge: GoogleFonts.poppins(
            textStyle: base.titleLarge,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: GoogleFonts.poppins(
            textStyle: base.titleMedium,
            fontWeight: FontWeight.w700,
          ),
        );

    ThemeData themed(Brightness b) {
      final base = ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seed,
        brightness: b,
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      );
      return base.copyWith(textTheme: fontTheme(base.textTheme));
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AnimeProvider(AnimeApi())),
      ],
      child: MaterialApp(
        title: 'DokiDoki',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: themed(Brightness.light),
        darkTheme: themed(Brightness.dark),
        home: const _ScaffoldRoot(),
      ),
    );
  }
}

class _ScaffoldRoot extends StatefulWidget {
  const _ScaffoldRoot({super.key});
  @override
  State<_ScaffoldRoot> createState() => _ScaffoldRootState();
}

class _ScaffoldRootState extends State<_ScaffoldRoot> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const brandBlue = Color.fromARGB(255, 84, 124, 189);

    final pages = <Widget>[
      const HomePage(),
      const _PlaceholderPage(title: 'Watchlist (coming soon)'),
      const _PlaceholderPage(title: 'Settings (coming soon)'),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 16,
        // === Title pakai TEKS (Sora) berwarna biru ===
        title: Row(
          children: [
            Text(
              'DokiDoki',
              style: GoogleFonts.sora(
                color: const Color.fromARGB(255, 38, 77, 136),
                fontWeight: FontWeight.w800,
                fontSize: 30,
                letterSpacing: .4,
                height: 1.0,
              ),
            ),
            const Spacer(),
            // Ikon search: tanpa border, gaya filled-tonal (Material 3), sedikit lebih besar
            IconButton(
        tooltip: 'Search',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Search page coming soon!')),
          );
        },
        icon: const Icon(Icons.search_rounded),
        iconSize: 28,               // sedikit lebih besar
        padding: const EdgeInsets.symmetric(horizontal: 4),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    ],
  ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.star_rounded), label: 'Watchlist'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(title, style: Theme.of(context).textTheme.titleMedium));
  }
}

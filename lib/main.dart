import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/anime_api.dart';
import 'providers/anime_provider.dart';
import 'features/home/home_page.dart';
import 'features/watchlist/watchlist_provider.dart';
import 'features/watchlist/watchlist_page.dart';
import 'features/settings/settings_provider.dart';
import 'features/settings/settings_page.dart';
import 'features/search/search_page.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DokiDokiApp());
}

class DokiDokiApp extends StatelessWidget {
  const DokiDokiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // warna seed (kamu pakai abu-abu, bisa diganti)
    const brand = Color.fromARGB(255, 114, 112, 112);

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
        colorSchemeSeed: brand,
        brightness: b,
        snackBarTheme:
            const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      );
      return base.copyWith(textTheme: fontTheme(base.textTheme));
    }

    return MultiProvider(
      providers: [
        // Settings harus duluan
        ChangeNotifierProvider(create: (_) => SettingsProvider()),

        // AnimeApi mengikuti Settings (SFW & preferEnglishTitle)
        ProxyProvider<SettingsProvider, AnimeApi>(
          update: (_, sp, api) {
            api ??= AnimeApi();
            api.sfw = sp.sfwOnly;
            api.preferEnglishTitle = sp.preferEnglishTitle;
            return api;
          },
        ),

        // Provider lain yang memakai AnimeApi / state app
        ChangeNotifierProvider(
          create: (ctx) => AnimeProvider(ctx.read<AnimeApi>()),
        ),
        ChangeNotifierProvider(create: (_) => WatchlistProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final locale = Locale(settings.localeCode);
          return MaterialApp(
            title: 'DokiDoki',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: themed(Brightness.light),
            darkTheme: themed(Brightness.dark),

            // Localizations
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            home: const _ScaffoldRoot(),
          );
        },
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
    final l = AppLocalizations.of(context);

    final pages = <Widget>[
      const HomePage(),
      const WatchlistPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Text(
              'DokiDoki',
              style: GoogleFonts.sora(
                color: const Color.fromARGB(255, 114, 112, 112),
                fontWeight: FontWeight.w800,
                fontSize: 30,
                letterSpacing: .4,
                height: 1.0,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Search',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
              },
              icon: const Icon(Icons.search_rounded),
              iconSize: 28,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints:
                  const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant,
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_rounded),
              label: l.t('nav.home')),
          NavigationDestination(
              icon: const Icon(Icons.star_rounded),
              label: l.t('nav.watchlist')),
          NavigationDestination(
              icon: const Icon(Icons.settings_rounded),
              label: l.t('nav.settings')),
        ],
      ),
    );
  }
}

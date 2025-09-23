import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('id')];

  static const _en = {
    'nav.home': 'Home',
    'nav.watchlist': 'Watchlist',
    'nav.settings': 'Settings',

    'settings.title': 'Settings',
    'settings.appearance': 'Appearance',
    'settings.language': 'Language',
    'settings.content': 'Content',
    'settings.about': 'About',

    'settings.theme.system': 'System',
    'settings.theme.light': 'Light',
    'settings.theme.dark': 'Dark',

    'settings.lang.app': 'App language',
    'settings.lang.en': 'English',
    'settings.lang.id': 'Indonesia',

    'settings.sfw': 'Safe Mode (SFW)',
    'settings.preferEn': 'Prefer English titles',

    'about.version': 'Version',
    'about.licenses': 'Licenses',

    'search.hint': 'Search…',
  };

  static const _id = {
    'nav.home': 'Home',
    'nav.watchlist': 'Watchlist',
    'nav.settings': 'Settings',

    'settings.title': 'Pengaturan',
    'settings.appearance': 'Tampilan',
    'settings.language': 'Bahasa',
    'settings.content': 'Konten',
    'settings.about': 'Tentang',

    'settings.theme.system': 'Sistem',
    'settings.theme.light': 'Terang',
    'settings.theme.dark': 'Gelap',

    'settings.lang.app': 'Bahasa aplikasi',
    'settings.lang.en': 'Inggris',
    'settings.lang.id': 'Indonesia',

    'settings.sfw': 'Mode Aman (SFW)',
    'settings.preferEn': 'Gunakan judul Inggris',

    'about.version': 'Versi',
    'about.licenses': 'Lisensi',

    'search.hint': 'Cari…',
  };

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String t(String key) {
    final table = (locale.languageCode == 'id') ? _id : _en;
    return table[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'id'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

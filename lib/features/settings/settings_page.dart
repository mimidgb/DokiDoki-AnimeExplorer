import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/anime_provider.dart';
import '../../l10n/app_localizations.dart';
import 'settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final l = AppLocalizations.of(context);

    if (!sp.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.t('settings.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SectionHeader(l.t('settings.appearance')),
          const SizedBox(height: 8),
          const _ThemePreviewRow(),
          const SizedBox(height: 16),

          _SectionHeader(l.t('settings.language')),
          const SizedBox(height: 8),
          _Tile(
            title: l.t('settings.lang.app'),
            subtitle: sp.localeCode == 'id' ? l.t('settings.lang.id') : l.t('settings.lang.en'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showLanguageSheet(context),
          ),
          const SizedBox(height: 16),

          _SectionHeader(l.t('settings.content')),
          const SizedBox(height: 8),
          SwitchListTile(
            value: sp.sfwOnly,
            onChanged: (v) async {
              await sp.setSfwOnly(v);
              if (!context.mounted) return;
              // refresh feed agar perubahan langsung terasa
              final prov = context.read<AnimeProvider>();
              await prov.loadTopAnime();
              await prov.loadHomeSections();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.t(v ? 'toast.sfw.on' : 'toast.sfw.off'))),
              );
            },
            title: Text(l.t('settings.sfw')),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: sp.preferEnglishTitle,
            onChanged: (v) => sp.setPreferEnglishTitle(v),
            title: Text(l.t('settings.preferEn')),
          ),

          const SizedBox(height: 16),
          _SectionHeader(l.t('settings.about')),
          const SizedBox(height: 8),
          const _Tile(title: 'Version', subtitle: '1.0.0'),
          // Licenses dihapus sesuai permintaan
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final sp = ctx.watch<SettingsProvider>();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LangOption(
                label: l.t('settings.lang.en'),
                selected: sp.localeCode == 'en',
                onTap: () {
                  sp.setLocaleCode('en');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
              _LangOption(
                label: l.t('settings.lang.id'),
                selected: sp.localeCode == 'id',
                onTap: () {
                  sp.setLocaleCode('id');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: t.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: cs.onSurface,
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  const _LangOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? cs.primary : Colors.transparent,
                  border: Border.all(color: selected ? cs.primary : cs.outlineVariant),
                  shape: BoxShape.circle,
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemePreviewRow extends StatelessWidget {
  const _ThemePreviewRow();

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 128,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _ThemeCard(
            label: l.t('settings.theme.system'),
            selected: sp.themeMode == ThemeMode.system,
            preview: const _PreviewMini(theme: ThemeMode.system),
            onTap: () => sp.setThemeMode(ThemeMode.system),
          ),
          const SizedBox(width: 12),
          _ThemeCard(
            label: l.t('settings.theme.light'),
            selected: sp.themeMode == ThemeMode.light,
            preview: const _PreviewMini(theme: ThemeMode.light),
            onTap: () => sp.setThemeMode(ThemeMode.light),
          ),
          const SizedBox(width: 12),
          _ThemeCard(
            label: l.t('settings.theme.dark'),
            selected: sp.themeMode == ThemeMode.dark,
            preview: const _PreviewMini(theme: ThemeMode.dark),
            onTap: () => sp.setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 180,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          children: [
            Expanded(child: preview),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                if (selected) const Icon(Icons.check_circle_rounded, size: 18),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _PreviewMini extends StatelessWidget {
  const _PreviewMini({required this.theme});
  final ThemeMode theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme == ThemeMode.dark;
    final bar = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF3F3F7);
    final card = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFFFFF);
    final text = isDark ? Colors.white : const Color(0xFF1D1D1D);
    final sub = isDark ? Colors.white70 : const Color(0xFF6A6A6A);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFF),
              isDark ? const Color(0xFF101010) : const Color(0xFFF2F4FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(height: 16, color: bar),
            const SizedBox(height: 6),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE9E9EF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 8, width: 80, color: text.withValues(alpha: 0.85)),
                  const SizedBox(height: 4),
                  Container(height: 6, width: 120, color: sub.withValues(alpha: 0.7)),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

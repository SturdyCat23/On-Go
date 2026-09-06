import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Theme picker, shared by the Client, Mechanic, Moderator and Admin shells.
///
/// The list is built from [AppThemes.all], so adding a theme there is all it
/// takes for it to show up here.
class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  final _controller = ThemeController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _select(AppThemeOption option) async {
    if (option.id == _controller.selectedId) return;
    await _controller.select(option.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${option.label} theme applied'), duration: AppDurations.snackBar),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textlight,
        title: const Text('Themes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'APPEARANCE',
            style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Pick a color theme. It applies everywhere in the app and is remembered the next time you open On Go.',
            style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 16),
          for (final option in AppThemes.all) ...[
            _ThemeOptionCard(
              option: option,
              selected: option.id == _controller.selectedId,
              onTap: () => _select(option),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final AppThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = option.palette;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.textmedium.withValues(alpha: 0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _PalettePreview(palette: palette),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textdark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textmedium.withValues(alpha: 0.5),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// A small card showing what the theme's key colors look like, so the choice
/// is readable without applying it first.
class _PalettePreview extends StatelessWidget {
  final AppPalette palette;

  const _PalettePreview({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textmedium.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(height: 16, color: palette.primary),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  _Swatch(color: palette.textdark),
                  const SizedBox(width: 4),
                  _Swatch(color: palette.info),
                  const SizedBox(width: 4),
                  _Swatch(color: palette.success),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;

  const _Swatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

/// The "Themes" row every role's Settings screen shows, so all four shells
/// reach the picker the same way.
class ThemesSettingsTile extends StatelessWidget {
  const ThemesSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.palette_outlined, color: AppColors.textdark),
        title: Text('Themes', style: TextStyle(fontSize: 15, color: AppColors.textdark)),
        subtitle: Text(
          ThemeController.instance.selected.label,
          style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textdark.withValues(alpha: 0.55)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ThemeScreen()),
        ),
      ),
    );
  }
}

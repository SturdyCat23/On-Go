import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'design_tokens.dart';
import 'theme_controller.dart';

/// One destination in [OnGoBottomNav].
@immutable
class OnGoNavItem {
  final IconData icon;

  /// Shown when this item is selected. Falls back to [icon] when null.
  final IconData? activeIcon;
  final String label;

  const OnGoNavItem({required this.icon, this.activeIcon, required this.label});
}

/// Floating rounded navigation bar. Unselected destinations show their icon
/// only; the selected one expands into a filled pill carrying its icon and
/// label side by side.
///
/// Drop-in replacement for [BottomNavigationBar] — same [currentIndex] /
/// [onTap] contract, so each shell keeps its own tabs and routing.
class OnGoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<OnGoNavItem> items;

  const OnGoBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  static const double _barHeight = 68;

  /// Gap between the bar's edge and the row of destinations.
  static const EdgeInsets _barPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 10);

  /// Narrowest an icon-only destination is allowed to get.
  static const double _minIconSlot = 40;

  static const double _sideMargin = 16;
  static const double _bottomMargin = 10;

  static const Duration _slide = Duration(milliseconds: 260);

  Color get _barColor => AppColors.surface;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.instance.selected.isDark;
    final barColor = _barColor;
    final onBar = isDark ? AppColors.textlight : AppColors.textdark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_sideMargin, 0, _sideMargin, _bottomMargin),
        child: Container(
          height: _barHeight,
          padding: _barPadding,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: AppRadii.borderXl,
            border: Border.all(color: onBar.withValues(alpha: 0.14), width: AppBorders.thin),
            boxShadow: AppShadows.raised,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final count = items.length;

                // The selected pill takes a fixed share of the bar and the rest
                // split what is left, so the pill has room for its label
                // without any of the icon-only slots collapsing.
                final maxPill = width - (count - 1) * _minIconSlot;
                final pillWidth = maxPill <= 0
                    ? width / count
                    : (width * (count <= 4 ? 0.36 : 0.32)).clamp(0.0, maxPill);
                final iconWidth = count > 1 ? (width - pillWidth) / (count - 1) : width;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < count; i++)
                      _slot(i, i == currentIndex ? pillWidth : iconWidth, onBar),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _slot(int index, double width, Color onBar) {
    final item = items[index];
    final selected = index == currentIndex;

    return AnimatedContainer(
      duration: _slide,
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(_barHeight),
      ),
      child: InkWell(
        onTap: () => onTap(index),
        customBorder: const StadiumBorder(),
        child: selected
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.activeIcon ?? item.icon, size: 20, color: AppColors.textlight),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textlight,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Icon(item.icon, size: 22, color: onBar.withValues(alpha: 0.7)),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/console_shell.dart';
import '../../backend/console_backend.dart';
import '../../theme/console_theme.dart';
import '../../widgets/console_widgets.dart';
import '../shared/settings_rows.dart';

/// Admin settings: this console's appearance, and the one piece of platform
/// branding an admin owns.
///
/// The split in the two cards is deliberate — the first only affects this
/// browser, the second reaches every phone. Grouping them together would blur
/// a difference that matters.
class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConsoleShell(
      child: ListView(
        padding: consolePagePadding(context),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ConsoleSettingsSection(
                  title: 'This console',
                  subtitle: 'Applies to your browser only',
                  children: [AppearanceSettingsRow()],
                ),
                SizedBox(height: context.layout.sectionSpacing),
                const ConsoleSettingsSection(
                  title: 'Mobile app',
                  subtitle: 'Branding every client and mechanic sees',
                  children: [BackgroundSettingsRow()],
                ),
                SizedBox(height: context.layout.sectionSpacing),
                const _ConnectionCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the console stands relative to the other application.
///
/// An admin looking at an empty queue and an empty ledger deserves to be told
/// why, in the product, rather than left to conclude the tool is broken.
class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ConsoleCard(
      boxedOnPhone: true,
      title: 'Mobile app connection',
      subtitle: 'How this console reaches the On Go app',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off_outlined, size: 18, color: ConsoleColors.warning),
              const SizedBox(width: 10),
              Text(
                'Not connected',
                style: text.titleSmall?.copyWith(color: ConsoleColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The console and the mobile app are separate applications that meet '
            'at an API. That API is not built yet, so the verification queue and '
            'the revenue ledger have nothing to receive: both fill up from the '
            'app once the two are connected.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          ConsoleField(
            icon: Icons.link_off,
            label: 'API base URL',
            value: 'Not configured',
          ),
          ConsoleField(
            icon: Icons.swap_horiz,
            label: 'Contract',
            value: 'package:on_go_shared · ${ApiEndpoints.version}',
          ),
          const SizedBox(height: 4),
          Text(
            'Both applications already code against that contract, so connecting '
            'them is a startup configuration change rather than a rewrite.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final notifier = ref.read(settingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ────────────────────────────────────────────────────
          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  tooltip: 'Light',
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  tooltip: 'System',
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  tooltip: 'Dark',
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (modes) => notifier.setThemeMode(modes.first),
            ),
          ),

          // ── Startup ───────────────────────────────────────────────────────
          const _SectionHeader('Startup'),
          ..._startupTabs.map(
            (tab) => RadioListTile<String>(
              title: Text(tab.label),
              secondary: Icon(tab.icon),
              value: tab.route,
              groupValue: settings.startupTab,
              onChanged: (route) {
                if (route != null) notifier.setStartupTab(route);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _TabOption {
  final String label;
  final String route;
  final IconData icon;
  const _TabOption(this.label, this.route, this.icon);
}

const _startupTabs = [
  _TabOption('Feed', '/feed', Icons.dynamic_feed_outlined),
  _TabOption('Studio', '/studio', Icons.science_outlined),
  _TabOption('Batches', '/batches', Icons.biotech_outlined),
  _TabOption('Inventory', '/inventory', Icons.inventory_2_outlined),
  _TabOption('Library', '/library', Icons.local_library_outlined),
];

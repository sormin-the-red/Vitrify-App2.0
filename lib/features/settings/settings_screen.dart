import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_provider.dart';

const _cones = [
  '022','021','020','019','018','017','016','015','014','013',
  '012','011','010','09','08','07','06','05','04','03','02','01',
  '1','2','3','4','5','6','7','8','9','10','11','12','13','14',
];
const _firingTypes = [
  'Oxidation', 'Reduction', 'Neutral', 'Soda', 'Wood', 'Salt',
];
const _applicationMethods = ['Brush', 'Dip', 'Spray', 'Pour', 'Other'];
const _atmospheres = [
  '', 'Oxidation', 'Reduction', 'Neutral', 'Soda', 'Wood', 'Salt',
];

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

          // ── Recipes ───────────────────────────────────────────────────────
          const _SectionHeader('Recipes'),
          ListTile(
            leading: const Icon(Icons.change_history),
            title: const Text('Default cone'),
            trailing: DropdownButton<String>(
              value: _cones.contains(settings.defaultCone)
                  ? settings.defaultCone
                  : '6',
              underline: const SizedBox.shrink(),
              items: _cones
                  .map((c) => DropdownMenuItem(value: c, child: Text('Cone $c')))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setDefaultCone(v);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.local_fire_department_outlined),
            title: const Text('Default firing type'),
            trailing: DropdownButton<String>(
              value: _firingTypes.contains(settings.defaultFiringType)
                  ? settings.defaultFiringType
                  : 'Oxidation',
              underline: const SizedBox.shrink(),
              items: _firingTypes
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setDefaultFiringType(v);
              },
            ),
          ),

          // ── Batch Testing ─────────────────────────────────────────────────
          const _SectionHeader('Batch Testing'),
          ListTile(
            leading: const Icon(Icons.layers_outlined),
            title: const Text('Default application method'),
            trailing: DropdownButton<String>(
              value: _applicationMethods.contains(settings.defaultApplicationMethod)
                  ? settings.defaultApplicationMethod
                  : 'Dip',
              underline: const SizedBox.shrink(),
              items: _applicationMethods
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setDefaultApplicationMethod(v);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.air_outlined),
            title: const Text('Default atmosphere'),
            trailing: DropdownButton<String>(
              value: _atmospheres.contains(settings.defaultAtmosphere)
                  ? settings.defaultAtmosphere
                  : '',
              underline: const SizedBox.shrink(),
              items: _atmospheres
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a.isEmpty ? 'None' : a),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setDefaultAtmosphere(v);
              },
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

import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppsSelectionScreen extends StatefulWidget {
  const AppsSelectionScreen({super.key});

  @override
  State<AppsSelectionScreen> createState() => _AppsSelectionScreenState();
}

class _AppsSelectionScreenState extends State<AppsSelectionScreen> {
  List<AppInfo> _apps = [];
  Set<String> _selectedApps = {};
  bool _allowAll = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final prefs = await SharedPreferences.getInstance();
    final savedApps = prefs.getStringList('allowed_apps') ?? [];
    final allowAll = prefs.getBool('allow_all_notifications') ?? false;

    setState(() {
      _selectedApps = savedApps.toSet();
      _allowAll = allowAll;
    });

    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );
      setState(() {
        // ignore: unnecessary_null_comparison
        _apps = apps.where((app) => app.packageName != null).toList();
        // Sort selected apps first, then alphabetically
        _apps.sort((a, b) {
          final aSelected = _selectedApps.contains(a.packageName);
          final bSelected = _selectedApps.contains(b.packageName);
          if (aSelected && !bSelected) return -1;
          if (!aSelected && bSelected) return 1;
          return (a.name).compareTo(b.name);
        });
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting apps: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAllowAll(bool value) async {
    setState(() => _allowAll = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allow_all_notifications', value);
  }

  Future<void> _toggleApp(String packageName) async {
    setState(() {
      if (_selectedApps.contains(packageName)) {
        _selectedApps.remove(packageName);
      } else {
        _selectedApps.add(packageName);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('allowed_apps', _selectedApps.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Allowed Apps')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SwitchListTile(
                  title: const Text('Allow All Notifications'),
                  subtitle: const Text(
                    'Capture alerts from every app installed',
                  ),
                  value: _allowAll,
                  onChanged: _toggleAllowAll,
                  activeThumbColor: const Color(0xFF6366F1),
                ),
                const Divider(height: 1),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _allowAll ? 0.4 : 1.0,
                    child: IgnorePointer(
                      ignoring: _allowAll,
                      child: ListView.builder(
                        itemCount: _apps.length,
                        itemBuilder: (context, index) {
                          final app = _apps[index];
                          final isSelected = _selectedApps.contains(
                            app.packageName,
                          );
                          return ListTile(
                            leading: app.icon != null
                                ? Image.memory(app.icon!, width: 40, height: 40)
                                : const Icon(Icons.android),
                            title: Text(app.name),
                            subtitle: Text(app.packageName),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleApp(app.packageName),
                              activeColor: const Color(0xFF6366F1),
                            ),
                            onTap: () => _toggleApp(app.packageName),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

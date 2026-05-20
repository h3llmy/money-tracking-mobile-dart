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
  List<AppInfo> _filteredApps = [];
  Set<String> _selectedApps = {};
  bool _allowAll = false;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadApps();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilter();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredApps = List.from(_apps);
      } else {
        _filteredApps = _apps.where((app) {
          return app.name.toLowerCase().contains(query) ||
              app.packageName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _sortApps() {
    _apps.sort((a, b) {
      final aSelected = _selectedApps.contains(a.packageName);
      final bSelected = _selectedApps.contains(b.packageName);
      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;
      return (a.name).compareTo(b.name);
    });
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
      // Include system apps so pre-installed apps like Gmail, etc. are shown
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        withIcon: true,
      );
      setState(() {
        // ignore: unnecessary_null_comparison
        _apps = apps.where((app) => app.packageName != null).toList();
        _sortApps();
        _filteredApps = List.from(_apps);
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
    final selectedCount = _selectedApps.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allowed Apps'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: selectedCount > 0
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '$selectedCount app${selectedCount == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Allow All toggle ──────────────────────────────────
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

                // ── Search bar ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Search apps...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF64748B),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: Color(0xFF64748B),
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF6366F1),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── App count info ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        _searchController.text.isEmpty
                            ? '${_apps.length} apps found'
                            : '${_filteredApps.length} of ${_apps.length} apps',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // ── App list ─────────────────────────────────────────
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _allowAll ? 0.4 : 1.0,
                    child: IgnorePointer(
                      ignoring: _allowAll,
                      child: _filteredApps.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.search_off_rounded,
                                    color: Color(0xFF475569),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchController.text.isEmpty
                                        ? 'No apps found'
                                        : 'No apps match "${_searchController.text}"',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredApps.length,
                              itemBuilder: (context, index) {
                                final app = _filteredApps[index];
                                final isSelected = _selectedApps.contains(
                                  app.packageName,
                                );
                                return ListTile(
                                  leading: app.icon != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.memory(
                                            app.icon!,
                                            width: 40,
                                            height: 40,
                                          ),
                                        )
                                      : Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF334155),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.android,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                  title: Text(
                                    app.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFFCBD5E1),
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    app.packageName,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Checkbox(
                                    value: isSelected,
                                    onChanged: (_) =>
                                        _toggleApp(app.packageName),
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

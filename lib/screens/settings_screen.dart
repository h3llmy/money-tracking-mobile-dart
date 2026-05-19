import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../providers/data_providers.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlController;
  bool _isSaving = false;
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final url = await ApiService.getSavedBaseUrl();
    if (mounted) {
      _urlController.text = url;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    try {
      // Strip /api/v1 prefix if present to call the root health endpoint
      String healthUrl = url;
      if (healthUrl.endsWith('/api/v1')) {
        healthUrl = healthUrl.substring(0, healthUrl.length - '/api/v1'.length);
      } else if (healthUrl.endsWith('/api/v1/')) {
        healthUrl = healthUrl.substring(0, healthUrl.length - '/api/v1/'.length);
      }
      
      if (healthUrl.endsWith('/')) {
        healthUrl = healthUrl.substring(0, healthUrl.length - 1);
      }
      healthUrl = '$healthUrl/health';

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      
      final response = await dio.get(healthUrl);

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        if (mounted) {
          setState(() {
            _testResult = 'Connection successful! (Health check passed)';
            _testSuccess = true;
          });
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Server returned unhealthy status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString().split('\n').first;
        if (e is DioException) {
          if (e.response != null && e.response!.data != null) {
            errorMsg = e.response!.data.toString().split('\n').first;
          } else {
            errorMsg = e.message ?? e.toString();
          }
        }
        setState(() {
          _testResult = 'Connection failed: $errorMsg';
          _testSuccess = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      // Persist to SharedPreferences
      await ApiService.saveBaseUrl(url);

      // Update the Riverpod provider so all downstream providers rebuild
      ref.read(baseUrlProvider.notifier).setBaseUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('API base URL updated successfully'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetToDefault() {
    _urlController.text = ApiService.defaultBaseUrl;
    setState(() {
      _testResult = null;
      _testSuccess = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = ref.watch(baseUrlProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User Profile Section ──────────────────────────────────
            _buildUserProfileSection(ref),

            const SizedBox(height: 32),

            // ── Section header ──────────────────────────────────────
            _buildSectionHeader(
              icon: Icons.dns_rounded,
              title: 'API Configuration',
              subtitle: 'Configure the server endpoint for data sync',
            ),

            const SizedBox(height: 24),

            // ── Current URL display ─────────────────────────────────
            _buildCurrentUrlCard(currentUrl),

            const SizedBox(height: 20),

            // ── URL input ───────────────────────────────────────────
            _buildUrlInputCard(),

            const SizedBox(height: 16),

            // ── Test result ─────────────────────────────────────────
            if (_testResult != null) _buildTestResultCard(),

            if (_testResult != null) const SizedBox(height: 16),

            // ── Action buttons ──────────────────────────────────────
            _buildActionButtons(),

            const SizedBox(height: 32),

            // ── Presets section ──────────────────────────────────────
            _buildPresetsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentUrlCard(String currentUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Endpoint',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUrl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'API Base URL',
            style: TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Include the full path with protocol and version (e.g. /api/v1)',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'https://your-server.com/api/v1',
              hintStyle: TextStyle(
                color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
                fontFamily: 'monospace',
              ),
              prefixIcon: const Icon(
                Icons.link_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF334155)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (_testSuccess ?? false)
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (_testSuccess ?? false)
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            (_testSuccess ?? false)
                ? Icons.check_circle_rounded
                : Icons.error_rounded,
            color: (_testSuccess ?? false) ? const Color(0xFF10B981) : Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _testResult!,
              style: TextStyle(
                color: (_testSuccess ?? false)
                    ? const Color(0xFF10B981)
                    : Colors.redAccent,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Test Connection
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isTesting ? null : _testConnection,
            icon: _isTesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6366F1),
                    ),
                  )
                : const Icon(Icons.wifi_tethering_rounded, size: 18),
            label: Text(_isTesting ? 'Testing...' : 'Test'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0xFF6366F1)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Save
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveUrl,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(_isSaving ? 'Saving...' : 'Save & Apply'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Presets',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap to fill the URL field with a preset value',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        const SizedBox(height: 16),
        _buildPresetTile(
          icon: Icons.home_rounded,
          label: 'Local Network',
          url: ApiService.defaultBaseUrl,
          color: const Color(0xFF6366F1),
        ),
        const SizedBox(height: 10),
        _buildPresetTile(
          icon: Icons.cloud_rounded,
          label: 'Production',
          url: 'https://api-money.dwikihome.my.id/api/v1',
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 24),
        // Reset button
        Center(
          child: TextButton.icon(
            onPressed: _resetToDefault,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('Reset to Default'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetTile({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        _urlController.text = url;
        setState(() {
          _testResult = null;
          _testSuccess = null;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF475569),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.person_rounded,
          title: 'User Profile',
          subtitle: 'Manage your authenticated session',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF334155),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        backgroundColor: const Color(0xFF0F172A),
                        title: const Text('Logout', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Are you sure you want to log out?',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFF334155)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogCtx).pop(); // pop dialog
                              ref.read(authProvider.notifier).logout();
                            },
                            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

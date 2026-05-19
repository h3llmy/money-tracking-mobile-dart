import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_list_item.dart';
import '../services/notification_service.dart';
import 'apps_selection_screen.dart';
import 'settings_screen.dart';

/// DashboardScreen as ConsumerStatefulWidget so every closure uses
/// [this.context] (the State's stable BuildContext), avoiding the
/// "Looking up a deactivated widget's ancestor is unsafe" assertion
/// that fires in Flutter debug mode when a plain method receives
/// BuildContext as a parameter and captures it in async/tap closures.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // ── navigation helpers ──────────────────────────────────────────────

  void _goToTab(int index) {
    ref.read(navigationIndexProvider.notifier).setIndex(index);
  }

  void _openAppsSelection() {
    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => const AppsSelectionScreen()));
  }

  void _openSettings() {
    if (!mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  // ── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pocketsAsync = ref.watch(pocketsProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Color(0xFF94A3B8)),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pocketsProvider);
          ref.invalidate(transactionsProvider);
          ref.invalidate(unresolvedNotificationsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Balance card ──────────────────────────────────────
              pocketsAsync.when(
                data: (response) {
                  final totalBalance = response.data.fold<double>(
                    0,
                    (sum, p) => sum + p.balanceAsDouble,
                  );
                  return BalanceCard(
                    totalBalance: totalBalance,
                    pocketsCount: response.totalData,
                    onTap: () => _goToTab(2),
                  );
                },
                loading: () => const BalanceCardLoading(),
                error: (e, __) => Text('Error: $e'),
              ),

              const SizedBox(height: 20),

              // ── Quick actions ─────────────────────────────────────
              // _buildQuickActions(),
              const SizedBox(height: 24),

              // ── Automation section ────────────────────────────────
              _buildAutomationSection(),

              const SizedBox(height: 32),

              // ── Recent transactions ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () => _goToTab(1),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              transactionsAsync.when(
                data: (response) {
                  if (response.data.isEmpty) {
                    return const Center(child: Text('No transactions yet'));
                  }
                  final count = response.data.length > 5
                      ? 5
                      : response.data.length;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: count,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) =>
                        TransactionListItem(transaction: response.data[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ── Automation / notification permission section ──────────────────────

  Widget _buildAutomationSection() {
    final hasPermission =
        ref.watch(notificationPermissionProvider).value ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
              const SizedBox(width: 12),
              Text(
                'Auto-Track Transactions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Enable notification listening to automatically sync bank and '
            'payment alerts to your dashboard.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Permission status / setup button
              Expanded(
                child: hasPermission
                    ? _serviceActiveBadge()
                    : ElevatedButton.icon(
                        onPressed: () async {
                          await NotificationService().requestPermission();
                          if (mounted) {
                            ref.invalidate(notificationPermissionProvider);
                          }
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Setup Permission'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Select Apps button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openAppsSelection,
                  icon: const Icon(Icons.apps),
                  label: const Text('Select Apps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceActiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, color: Colors.green, size: 10),
          SizedBox(width: 8),
          Text(
            'Service Active',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

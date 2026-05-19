import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'pockets_screen.dart';
import 'categories_screen.dart';
import '../widgets/add_transaction_bottom_sheet.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  /// Pages stored in State — never recreated on rebuild.
  /// Index: 0=Dashboard  1=Transactions  2=Pockets  3=Categories
  final List<Widget> _pages = const [
    DashboardScreen(),
    TransactionsScreen(),
    PocketsScreen(),
    CategoriesScreen(),
  ];

  /// Bottom-bar has 5 slots; slot 2 is the "Create" FAB button (no page).
  /// pageIndex 0→bottomIndex 0, 1→1, 2→3, 3→4
  int _toBottomIndex(int pageIndex) => pageIndex >= 2 ? pageIndex + 1 : pageIndex;
  int _toPageIndex(int bottomIndex) => bottomIndex > 2 ? bottomIndex - 1 : bottomIndex;

  void _onItemTapped(int bottomIndex) {
    if (bottomIndex == 2) {
      // Centre slot — show the create transaction sheet
      AddTransactionBottomSheet.show(context);
    } else {
      ref.read(navigationIndexProvider.notifier).setIndex(_toPageIndex(bottomIndex));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: pageIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _toBottomIndex(pageIndex),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0B0F19),
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded, size: 24),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded, size: 24),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF6366F1),
                child: Icon(Icons.add, color: Colors.white, size: 24),
              ),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded, size: 24),
              label: 'Pockets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_rounded, size: 24),
              label: 'Categories',
            ),
          ],
        ),
      ),
    );
  }
}

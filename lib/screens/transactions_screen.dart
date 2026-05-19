import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/add_transaction_bottom_sheet.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
        },
        child: transactionsAsync.when(
          data: (response) {
            if (response.data.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('No transactions found')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: response.data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return TransactionListItem(transaction: response.data[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => ListView(
            children: [
              const SizedBox(height: 100),
              Center(child: Text('Error: $e')),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_transactions',
        onPressed: () => AddTransactionBottomSheet.show(context),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

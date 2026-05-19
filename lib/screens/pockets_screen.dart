import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../models/pocket.dart';

class PocketsScreen extends ConsumerWidget {
  const PocketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pocketsAsync = ref.watch(pocketsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Pockets')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pocketsProvider);
        },
        child: pocketsAsync.when(
          data: (response) {
            if (response.data.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('No pockets yet')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: response.data.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final pocket = response.data[index];
                return PocketCard(
                  pocket: pocket,
                  onEdit: () => _showPocketFormDialog(context, ref, pocket),
                  onDelete: () => _confirmDeletePocket(context, ref, pocket),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, stack) => ListView(
            children: [
              const SizedBox(height: 100),
              Center(child: Text('Error: $e')),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_pockets',
        onPressed: () => _showPocketFormDialog(context, ref, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPocketFormDialog(BuildContext context, WidgetRef ref, Pocket? pocket) {
    final isEditing = pocket != null;
    final nameController = TextEditingController(text: pocket?.name ?? '');
    String pocketType = pocket?.pocketType ?? 'bank';
    final currencyController = TextEditingController(text: pocket?.currency ?? 'USD');
    final balanceController = TextEditingController(text: pocket?.balance?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Pocket' : 'Create New Pocket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              DropdownButtonFormField<String>(
                value: pocketType,
                items: ['bank', 'cash', 'ewallet', 'other']
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => pocketType = val!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextField(
                controller: currencyController,
                decoration: const InputDecoration(
                  labelText: 'Currency (e.g. USD)',
                ),
              ),
              if (!isEditing)
                TextField(
                  controller: balanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Initial Balance'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  try {
                    final api = ref.read(apiServiceProvider);
                    if (isEditing) {
                      await api.updatePocket(pocket.id, {
                        'name': nameController.text,
                        'pocket_type': pocketType,
                        'currency': currencyController.text,
                      });
                    } else {
                      await api.createPocket({
                        'name': nameController.text,
                        'pocket_type': pocketType,
                        'currency': currencyController.text,
                        'balance': balanceController.text.isEmpty ? '0' : balanceController.text,
                      });
                    }
                    ref.invalidate(pocketsProvider);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
              child: Text(isEditing ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePocket(BuildContext context, WidgetRef ref, Pocket pocket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pocket'),
        content: Text('Are you sure you want to delete "${pocket.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(apiServiceProvider).deletePocket(pocket.id);
                ref.invalidate(pocketsProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting pocket: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class PocketCard extends StatelessWidget {
  final Pocket pocket;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PocketCard({
    super.key,
    required this.pocket,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getPocketColor(pocket.pocketType).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPocketIcon(pocket.pocketType),
              color: _getPocketColor(pocket.pocketType),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pocket.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  pocket.pocketType.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            currencyFormatter.format(pocket.balanceAsDouble),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Actions menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
            color: const Color(0xFF1E293B),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_outlined, size: 20, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPocketColor(String type) {
    switch (type) {
      case 'bank':
        return Colors.blue;
      case 'cash':
        return Colors.green;
      case 'ewallet':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPocketIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance_rounded;
      case 'cash':
        return Icons.payments_rounded;
      case 'ewallet':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

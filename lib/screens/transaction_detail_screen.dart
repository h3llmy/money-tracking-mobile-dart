import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../providers/data_providers.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  String? _selectedPocketId;
  String? _selectedCategoryId;
  String? _destinationPocketId;
  String? _selectedType;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeEditFields(Transaction t) {
    _titleController.text = t.title;
    _amountController.text = t.amountAsDouble.toStringAsFixed(2);
    _descriptionController.text = t.description ?? '';
    _selectedPocketId = t.pocketId;
    _selectedCategoryId = t.categoryId;
    _destinationPocketId = t.destinationPocketId;
    _selectedType = t.type;
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionAsync = ref.watch(transactionDetailProvider(widget.transactionId));

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transaction Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          transactionAsync.when(
            data: (t) => IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit_rounded, color: const Color(0xFF6366F1)),
              onPressed: () {
                setState(() {
                  if (!_isEditing) {
                    _initializeEditFields(t);
                  }
                  _isEditing = !_isEditing;
                });
              },
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: transactionAsync.when(
        data: (transaction) {
          if (_isEditing) {
            return _buildEditForm(transaction);
          }
          return _buildDetailsView(transaction);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
        error: (e, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text(
                'Error loading details: $e',
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(transactionDetailProvider(widget.transactionId)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsView(Transaction t) {
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    final currencyFormatter = NumberFormat.currency(symbol: 'Rp', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Large Type Icon & Amount Card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E293B),
                  const Color(0xFF1E293B).withValues(alpha: 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getTypeColor(t.type).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getTypeIcon(t.type),
                    color: _getTypeColor(t.type),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  t.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${isIncome ? '+' : (isTransfer ? '' : '-')}${currencyFormatter.format(t.amountAsDouble)}',
                  style: TextStyle(
                    color: isIncome
                        ? const Color(0xFF10B981)
                        : (isTransfer ? Colors.blue : const Color(0xFFEF4444)),
                    fontWeight: FontWeight.w900,
                    fontSize: 36,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Detail Items List Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date & Time',
                  value: DateFormat('MMMM dd, yyyy • HH:mm').format(
                    DateTime.parse(t.transactionTime),
                  ),
                ),
                const Divider(color: Color(0xFF334155), height: 32),
                _buildDetailRow(
                  icon: Icons.account_balance_wallet_rounded,
                  label: isTransfer ? 'Source Pocket' : 'Pocket',
                  value: t.pocket?.name ?? 'Main Wallet',
                  badge: t.pocket?.pocketType.toUpperCase(),
                ),
                if (isTransfer) ...[
                  const Divider(color: Color(0xFF334155), height: 32),
                  _buildDetailRow(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Destination Pocket',
                    value: t.destinationPocket?.name ?? 'Secondary Pocket',
                    badge: t.destinationPocket?.pocketType.toUpperCase(),
                  ),
                ],
                if (!isTransfer && t.category != null) ...[
                  const Divider(color: Color(0xFF334155), height: 32),
                  _buildDetailRow(
                    icon: Icons.category_rounded,
                    label: 'Category',
                    value: t.category!.name,
                    badge: t.category!.type.toUpperCase(),
                  ),
                ],
                const Divider(color: Color(0xFF334155), height: 32),
                _buildDetailRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Status',
                  value: (t.status ?? 'Active').toUpperCase(),
                  valueColor: t.status == 'failed' ? Colors.redAccent : Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Description Card
          if (t.description != null && t.description!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes & Description',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.description!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Void/Delete Action Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _confirmVoidTransaction(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text(
                'Void Transaction',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    String? badge,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: valueColor ?? Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Color(0xFF818CF8),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(Transaction t) {
    final pocketsAsync = ref.watch(pocketsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Title'),
              validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Transaction Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Transaction Type'),
              items: const [
                DropdownMenuItem(value: 'income', child: Text('Income')),
                DropdownMenuItem(value: 'expense', child: Text('Expense')),
                DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedType = val;
                    if (val == 'transfer') {
                      _selectedCategoryId = null;
                    } else {
                      _destinationPocketId = null;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              style: const TextStyle(color: Colors.white),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration('Amount (Rp)'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Amount is required';
                if (double.tryParse(v) == null) return 'Enter a valid decimal value';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Pockets
            pocketsAsync.when(
              data: (response) => DropdownButtonFormField<String>(
                value: _selectedPocketId,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(_selectedType == 'transfer' ? 'Source Pocket' : 'Pocket'),
                items: response.data
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedPocketId = val),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading pockets', style: TextStyle(color: Colors.redAccent)),
            ),
            const SizedBox(height: 16),

            // Destination Pocket (For Transfers)
            if (_selectedType == 'transfer') ...[
              pocketsAsync.when(
                data: (response) => DropdownButtonFormField<String>(
                  value: _destinationPocketId,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Destination Pocket'),
                  items: response.data
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                      .toList(),
                  onChanged: (val) => setState(() => _destinationPocketId = val),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 16),
            ],

            // Categories
            if (_selectedType != 'transfer') ...[
              categoriesAsync.when(
                data: (response) {
                  final filtered = response.data.where((c) => c.type == _selectedType).toList();
                  final isCurrentSelectedValid = _selectedCategoryId != null &&
                      filtered.any((c) => c.id == _selectedCategoryId);
                  if (!isCurrentSelectedValid) {
                    _selectedCategoryId = filtered.isNotEmpty ? filtered.first.id : null;
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Category'),
                    items: filtered
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: _inputDecoration('Notes / Description (Optional)'),
            ),
            const SizedBox(height: 32),

            // Save Buttons
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _saveChanges(t),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges(Transaction original) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updatedData = {
        'title': _titleController.text.trim(),
        'amount': _amountController.text.trim(),
        'type': _selectedType,
        'pocket_id': _selectedPocketId,
        'category_id': _selectedCategoryId,
        'destination_pocket_id': _destinationPocketId,
        'description': _descriptionController.text.trim(),
        'transaction_time': original.transactionTime,
      };

      await ref.read(apiServiceProvider).updateTransaction(original.id, updatedData);

      // Invalidate both lists and specific transaction providers to force refetch
      ref.invalidate(transactionsProvider);
      ref.invalidate(pocketsProvider);
      ref.invalidate(transactionDetailProvider(original.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update transaction: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmVoidTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Void Transaction?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to void this transaction? This action is permanent and will restore/revert the respective pocket balances.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Void permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(apiServiceProvider).deleteTransaction(widget.transactionId);

        ref.invalidate(transactionsProvider);
        ref.invalidate(pocketsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction voided successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to void transaction: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'income':
        return const Color(0xFF10B981);
      case 'expense':
        return const Color(0xFFEF4444);
      case 'transfer':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'income':
        return Icons.arrow_downward_rounded;
      case 'expense':
        return Icons.arrow_upward_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

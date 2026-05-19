import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';

class AddTransactionBottomSheet extends ConsumerStatefulWidget {
  const AddTransactionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionBottomSheet(),
    );
  }

  @override
  ConsumerState<AddTransactionBottomSheet> createState() => _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends ConsumerState<AddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'expense'; // 'income', 'expense', 'transfer'
  String? _selectedPocketId;
  String? _destinationPocketId;
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
    final pocketsAsync = ref.watch(pocketsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B0F19),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(28.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag indicator & title
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Add Transaction',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Title'),
                  validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),

                // Transaction Type Selector
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Type'),
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

                // Pockets Dropdown
                pocketsAsync.when(
                  data: (response) {
                    if (_selectedPocketId == null && response.data.isNotEmpty) {
                      _selectedPocketId = response.data.first.id;
                    }
                    return DropdownButtonFormField<String>(
                      value: _selectedPocketId,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        _selectedType == 'transfer' ? 'Source Pocket' : 'Pocket',
                      ),
                      items: response.data
                          .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedPocketId = val),
                    );
                  },
                  loading: () => const LinearProgressIndicator(color: Color(0xFF6366F1)),
                  error: (_, __) => const Text(
                    'Error loading pockets',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 16),

                // Destination Pocket (Only for Transfers)
                if (_selectedType == 'transfer') ...[
                  pocketsAsync.when(
                    data: (response) {
                      final filteredPockets = response.data
                          .where((p) => p.id != _selectedPocketId)
                          .toList();
                      if (_destinationPocketId == null && filteredPockets.isNotEmpty) {
                        _destinationPocketId = filteredPockets.first.id;
                      }
                      return DropdownButtonFormField<String>(
                        value: _destinationPocketId,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Destination Pocket'),
                        items: filteredPockets
                            .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                            .toList(),
                        onChanged: (val) => setState(() => _destinationPocketId = val),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Categories (Only for Income / Expense)
                if (_selectedType != 'transfer') ...[
                  categoriesAsync.when(
                    data: (response) {
                      final filtered = response.data
                          .where((c) => c.type == _selectedType)
                          .toList();

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
                    loading: () => const LinearProgressIndicator(color: Color(0xFF6366F1)),
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

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                          side: const BorderSide(color: Color(0xFF334155)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPocketId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pocket.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final requestData = {
        'pocket_id': _selectedPocketId,
        'amount': _amountController.text.trim(),
        'type': _selectedType,
        'title': _titleController.text.trim(),
        'transaction_time': DateTime.now().toUtc().toIso8601String(),
        if (_selectedType == 'transfer') 'destination_pocket_id': _destinationPocketId,
        if (_selectedType != 'transfer') 'category_id': _selectedCategoryId,
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
      };

      await ref.read(apiServiceProvider).createTransaction(requestData);

      // Invalidate providers to reload screen lists
      ref.invalidate(transactionsProvider);
      ref.invalidate(pocketsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create transaction: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

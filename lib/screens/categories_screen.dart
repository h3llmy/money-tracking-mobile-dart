import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../models/category.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  String _selectedFilter = 'all'; // 'all', 'income', 'expense'

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Income', 'income'),
                const SizedBox(width: 8),
                _buildFilterChip('Expenses', 'expense'),
              ],
            ),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(categoriesProvider);
              },
              child: categoriesAsync.when(
                data: (response) {
                  // Filter categories based on selection
                  final filteredList = response.data.where((category) {
                    if (_selectedFilter == 'all') return true;
                    return category.type.toLowerCase() == _selectedFilter;
                  }).toList();

                  if (filteredList.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'No categories found',
                            style: TextStyle(color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final category = filteredList[index];
                      return CategoryCard(
                        category: category,
                        onEdit: () => _showCategoryFormDialog(context, category),
                        onDelete: () => _confirmDeleteCategory(context, category),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_categories',
        onPressed: () => _showCategoryFormDialog(context, null),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
      selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void _showCategoryFormDialog(BuildContext context, Category? category) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedType = category?.type ?? 'expense';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Category' : 'Create Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Category Type',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Expense')),
                      selected: selectedType == 'expense',
                      onSelected: (val) {
                        if (val) setDialogState(() => selectedType = 'expense');
                      },
                      selectedColor: Colors.redAccent.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: selectedType == 'expense' ? Colors.redAccent : Colors.white,
                      ),
                      side: BorderSide(
                        color: selectedType == 'expense' ? Colors.redAccent : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Income')),
                      selected: selectedType == 'income',
                      onSelected: (val) {
                        if (val) setDialogState(() => selectedType = 'income');
                      },
                      selectedColor: Colors.greenAccent.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: selectedType == 'income' ? Colors.greenAccent : Colors.white,
                      ),
                      side: BorderSide(
                        color: selectedType == 'income' ? Colors.greenAccent : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final api = ref.read(apiServiceProvider);
                try {
                  if (isEditing) {
                    await api.updateCategory(category.id, {
                      'name': name,
                      'type': selectedType,
                    });
                  } else {
                    await api.createCategory({
                      'name': name,
                      'type': selectedType,
                    });
                  }
                  
                  ref.invalidate(categoriesProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving category: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(apiServiceProvider).deleteCategory(category.id);
                ref.invalidate(categoriesProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting category: $e')),
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

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = category.type.toLowerCase() == 'income';
    final accentColor = isIncome ? Colors.greenAccent : Colors.redAccent;
    final typeText = isIncome ? 'Income' : 'Expense';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Circular leading icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Name and badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeText.toUpperCase(),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
}

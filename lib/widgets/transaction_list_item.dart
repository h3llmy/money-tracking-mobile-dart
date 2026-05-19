import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../screens/transaction_detail_screen.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TransactionDetailScreen(transactionId: transaction.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getTypeColor(transaction.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getTypeIcon(transaction.type),
                color: _getTypeColor(transaction.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • HH:mm',
                    ).format(DateTime.parse(transaction.transactionTime)),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : (isTransfer ? '' : '-')}${currencyFormatter.format(transaction.amountAsDouble)}',
              style: TextStyle(
                color: isIncome
                    ? const Color(0xFF10B981)
                    : (isTransfer ? Colors.blue : const Color(0xFFEF4444)),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
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

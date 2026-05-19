import 'package:json_annotation/json_annotation.dart';
import 'pocket.dart';
import 'category.dart';

part 'transaction.g.dart';

@JsonSerializable()
class Transaction {
  final String id;
  @JsonKey(name: 'pocket_id')
  final String pocketId;
  @JsonKey(name: 'category_id')
  final String? categoryId;
  final dynamic amount;
  @JsonKey(name: 'type_')
  final String type; // income, expense, transfer
  final String title;
  @JsonKey(name: 'transaction_time')
  final String transactionTime;
  @JsonKey(name: 'destination_pocket_id')
  final String? destinationPocketId;

  final Pocket? pocket;
  final Category? category;
  @JsonKey(name: 'destination_pocket')
  final Pocket? destinationPocket;
  final String? description;
  final String? status;

  Transaction({
    required this.id,
    required this.pocketId,
    this.categoryId,
    required this.amount,
    required this.type,
    required this.title,
    required this.transactionTime,
    this.destinationPocketId,
    this.pocket,
    this.category,
    this.destinationPocket,
    this.description,
    this.status,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    if (json['type_'] == null && json['type'] != null) {
      json['type_'] = json['type'];
    }
    return _$TransactionFromJson(json);
  }
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  double get amountAsDouble {
    if (amount is num) return (amount as num).toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }
}

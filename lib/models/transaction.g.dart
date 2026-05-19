// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
  id: json['id'] as String,
  pocketId: json['pocket_id'] as String,
  categoryId: json['category_id'] as String?,
  amount: json['amount'],
  type: json['type_'] as String,
  title: json['title'] as String,
  transactionTime: json['transaction_time'] as String,
  destinationPocketId: json['destination_pocket_id'] as String?,
  pocket: json['pocket'] == null
      ? null
      : Pocket.fromJson(json['pocket'] as Map<String, dynamic>),
  category: json['category'] == null
      ? null
      : Category.fromJson(json['category'] as Map<String, dynamic>),
  destinationPocket: json['destination_pocket'] == null
      ? null
      : Pocket.fromJson(json['destination_pocket'] as Map<String, dynamic>),
  description: json['description'] as String?,
  status: json['status'] as String?,
);

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pocket_id': instance.pocketId,
      'category_id': instance.categoryId,
      'amount': instance.amount,
      'type_': instance.type,
      'title': instance.title,
      'transaction_time': instance.transactionTime,
      'destination_pocket_id': instance.destinationPocketId,
      'pocket': instance.pocket,
      'category': instance.category,
      'destination_pocket': instance.destinationPocket,
      'description': instance.description,
      'status': instance.status,
    };

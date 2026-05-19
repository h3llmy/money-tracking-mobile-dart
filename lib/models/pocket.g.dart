// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pocket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pocket _$PocketFromJson(Map<String, dynamic> json) => Pocket(
  id: json['id'] as String,
  name: json['name'] as String,
  pocketType: json['pocket_type'] as String,
  currency: json['currency'] as String,
  balance: json['balance'],
);

Map<String, dynamic> _$PocketToJson(Pocket instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'pocket_type': instance.pocketType,
  'currency': instance.currency,
  'balance': instance.balance,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppNotification _$AppNotificationFromJson(Map<String, dynamic> json) =>
    AppNotification(
      id: json['id'] as String,
      appPackage: json['app_package'] as String,
      rawTitle: json['raw_title'] as String?,
      rawBody: json['raw_body'] as String,
      receivedAt: json['received_at'] as String,
      status: json['status'] as String,
      transactionId: json['transaction_id'] as String?,
      amount: json['amount'] as String?,
      type: json['type'] as String?,
      pocketId: json['pocket_id'] as String?,
      categoryId: json['category_id'] as String?,
      destinationPocketId: json['destination_pocket_id'] as String?,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$AppNotificationToJson(AppNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'app_package': instance.appPackage,
      'raw_title': instance.rawTitle,
      'raw_body': instance.rawBody,
      'received_at': instance.receivedAt,
      'status': instance.status,
      'transaction_id': instance.transactionId,
      'amount': instance.amount,
      'type': instance.type,
      'pocket_id': instance.pocketId,
      'category_id': instance.categoryId,
      'destination_pocket_id': instance.destinationPocketId,
      'title': instance.title,
    };

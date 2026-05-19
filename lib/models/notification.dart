import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

@JsonSerializable()
class AppNotification {
  final String id;
  @JsonKey(name: 'app_package')
  final String appPackage;
  @JsonKey(name: 'raw_title')
  final String? rawTitle;
  @JsonKey(name: 'raw_body')
  final String rawBody;
  @JsonKey(name: 'received_at')
  final String receivedAt;
  final String status; // pending, processed, failed, ignored
  @JsonKey(name: 'transaction_id')
  final String? transactionId;

  // Parsed / Default values from backend
  final String? amount;
  final String? type;
  @JsonKey(name: 'pocket_id')
  final String? pocketId;
  @JsonKey(name: 'category_id')
  final String? categoryId;
  @JsonKey(name: 'destination_pocket_id')
  final String? destinationPocketId;
  final String? title;

  AppNotification({
    required this.id,
    required this.appPackage,
    this.rawTitle,
    required this.rawBody,
    required this.receivedAt,
    required this.status,
    this.transactionId,
    this.amount,
    this.type,
    this.pocketId,
    this.categoryId,
    this.destinationPocketId,
    this.title,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);
}

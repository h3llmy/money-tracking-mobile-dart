import 'package:json_annotation/json_annotation.dart';

part 'pocket.g.dart';

@JsonSerializable()
class Pocket {
  final String id;
  final String name;
  @JsonKey(name: 'pocket_type')
  final String pocketType; // bank, cash, ewallet, other
  final String currency;
  final dynamic balance; // Decimal can be string or number

  Pocket({
    required this.id,
    required this.name,
    required this.pocketType,
    required this.currency,
    required this.balance,
  });

  factory Pocket.fromJson(Map<String, dynamic> json) => _$PocketFromJson(json);
  Map<String, dynamic> toJson() => _$PocketToJson(this);

  double get balanceAsDouble {
    if (balance is num) return (balance as num).toDouble();
    if (balance is String) return double.tryParse(balance) ?? 0.0;
    return 0.0;
  }
}

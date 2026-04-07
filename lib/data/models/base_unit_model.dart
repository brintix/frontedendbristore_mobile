// base_unit_model.dart
class UnitModel {
  final int id;
  final String name;
  final String symbol;

  UnitModel({required this.id, required this.name, required this.symbol});

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] as int,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
    );
  }
}

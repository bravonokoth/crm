class Item {
  final int id;
  final String name;
  final double rate;
  final double quantity;
  final String? unit;
  final String? skuCode;

  Item({
    required this.id,
    required this.name,
    required this.rate,
    required this.quantity,
    this.unit,
    this.skuCode,
  });

  factory Item.fromJson(Map json) {
    return Item(
      id: json['id'],
      name: json['name'],
      rate: (json['rate'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
      skuCode: json['sku_code'],
    );
  }

  Map toJson() {
    return {
      'id': id,
      'name': name,
      'rate': rate,
      'quantity': quantity,
      'unit': unit,
      'sku_code': skuCode,
    };
  }
}
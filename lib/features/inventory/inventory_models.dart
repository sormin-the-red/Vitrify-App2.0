class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();

class InventoryMaterial {
  final String name;
  final double quantity;
  final String unit;
  final double? targetQuantity;

  const InventoryMaterial({
    required this.name,
    required this.quantity,
    required this.unit,
    this.targetQuantity,
  });

  factory InventoryMaterial.fromJson(Map<String, dynamic> j) => InventoryMaterial(
        name: (j['Name'] ?? j['name'] ?? '') as String,
        quantity: ((j['Quantity'] ?? j['quantity'] ?? 0) as num).toDouble(),
        unit: (j['Unit'] ?? j['unit'] ?? 'lbs') as String,
        targetQuantity: ((j['TargetQuantity'] ?? j['targetQuantity']) as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'Name': name,
        'Quantity': quantity,
        'Unit': unit,
        if (targetQuantity != null) 'TargetQuantity': targetQuantity,
      };

  InventoryMaterial copyWith({
    String? name,
    double? quantity,
    String? unit,
    Object? targetQuantity = _sentinel,
  }) =>
      InventoryMaterial(
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        targetQuantity: targetQuantity == _sentinel
            ? this.targetQuantity
            : targetQuantity as double?,
      );

  bool get isLow =>
      targetQuantity != null && targetQuantity! > 0 && quantity < targetQuantity! * 0.25;

  bool get isEmpty => quantity <= 0;
}

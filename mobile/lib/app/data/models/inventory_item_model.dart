class InventoryItemModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final int quantity;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.quantity,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      quantity: json['quantity'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'quantity': quantity,
      'isAvailable': isAvailable,
    };
  }
}


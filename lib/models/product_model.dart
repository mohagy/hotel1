/// Product Model (POS)
/// 
/// Represents POS products for retail and restaurant modes

class ProductModel {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int? categoryId;
  final String? categoryName;
  final String? upc; // Barcode
  final int? stock;
  final bool isAvailable;
  final bool isRestaurantItem;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
    this.upc,
    this.stock,
    this.isAvailable = true,
    this.isRestaurantItem = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Handle different API response formats
    int? id;
    if (json['id'] != null) {
      id = json['id'] is int ? json['id'] : int.tryParse(json['id'].toString());
    } else if (json['product_id'] != null) {
      id = json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id'].toString());
    } else if (json['menu_id'] != null) {
      id = json['menu_id'] is int ? json['menu_id'] : int.tryParse(json['menu_id'].toString());
    }

    return ProductModel(
      id: id,
      name: json['name'] as String? ?? json['item_name'] as String? ?? json['product_name'] as String? ?? 'Unknown',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String? ?? json['image'] as String?,
      categoryId: json['category_id'] != null ? (json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id'].toString())) : null,
      categoryName: json['category_name'] as String? ?? json['category'] as String?,
      upc: json['upc'] as String? ?? json['barcode'] as String? ?? json['code'] as String?,
      stock: json['stock'] as int? ?? json['stock_quantity'] as int? ?? json['quantity'] as int?,
      isAvailable: json['is_available'] != null
          ? (json['is_available'] is bool ? json['is_available'] : (json['is_available'] as num).toInt() == 1)
          : (json['availability'] != null ? (json['availability'] is bool ? json['availability'] : (json['availability'] as num).toInt() == 1) : true),
      isRestaurantItem: json['menu_id'] != null || json['category'] != null || json['is_restaurant_item'] != null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      if (imageUrl != null) 'image_url': imageUrl,
      if (categoryId != null) 'category_id': categoryId,
      if (upc != null) 'upc': upc,
      if (stock != null) 'stock': stock,
      'is_available': isAvailable ? 1 : 0,
      'is_restaurant_item': isRestaurantItem ? 1 : 0,
    };
  }

  ProductModel copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    int? categoryId,
    String? categoryName,
    String? upc,
    int? stock,
    bool? isAvailable,
    bool? isRestaurantItem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      upc: upc ?? this.upc,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      isRestaurantItem: isRestaurantItem ?? this.isRestaurantItem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<ProductModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}


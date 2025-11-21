class Product {
  // Usaremos el SKU como ID único (Primary Key)
  final String sku;
  final String name;
  final String? description;
  final double systemStock;
  double countedQuantity;
  final String? imageUrl;
  DateTime lastUpdated;
  bool isSynced;

  Product({
    required this.sku,
    required this.name,
    this.description,
    this.systemStock = 0,
    this.countedQuantity = 0,
    this.imageUrl,
    required this.lastUpdated,
    this.isSynced = true,
  });

  // Convertir de JSON (API) a Objeto
  factory Product.fromJson(Map<String, dynamic> json) {
    dynamic getValue(List<String> candidates) {
      for (var key in candidates) {
        if (json.containsKey(key)) return json[key];
        if (json.containsKey(key.toLowerCase())) return json[key.toLowerCase()];
      }
      return null;
    }

    final valSku = getValue([
      'sku',
      'codigo',
      'code',
      'id_producto',
      'pk',
      'serial_number',
      'barcode',
    ]);
    final valName = getValue([
      'name',
      'nombre',
      'description',
      'descripcion',
      'producto',
    ]);
    final valStock = getValue([
      'stock',
      'system_stock',
      'cantidad',
      'quantity',
      'existencias',
    ]);
    final valImg = getValue(['image', 'image_url', 'foto', 'img']);

    return Product(
      sku:
          valSku?.toString() ??
          'SIN-SKU-${DateTime.now().millisecondsSinceEpoch}',
      name: valName?.toString() ?? 'Sin Nombre',
      description: valName?.toString(),
      systemStock: double.tryParse(valStock?.toString() ?? '0') ?? 0.0,
      countedQuantity: 0, // Al bajar del servidor, lo contado es 0
      imageUrl: valImg?.toString(),
      lastUpdated: DateTime.now(),
      isSynced: true,
    );
  }

  // Convertir de SQLite a Objeto
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      sku: map['sku'],
      name: map['name'],
      description: map['description'],
      systemStock: map['system_stock'],
      countedQuantity: map['counted_quantity'],
      imageUrl: map['image_url'],
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['last_updated']),
      isSynced: map['is_synced'] == 1, // SQLite guarda bool como 0 o 1
    );
  }

  // Convertir de Objeto a SQLite
  Map<String, dynamic> toMap() {
    return {
      'sku': sku,
      'name': name,
      'description': description,
      'system_stock': systemStock,
      'counted_quantity': countedQuantity,
      'image_url': imageUrl,
      'last_updated': lastUpdated.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
    };
  }
}

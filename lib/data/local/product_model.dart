import 'package:isar/isar.dart';

part 'product_model.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String sku;

  late String name;
  String? description;
  String? imageUrl;
  double systemStock = 0;
  double countedQuantity = 0;
  late DateTime lastUpdated;
  bool isSynced = false;

  Product();

  factory Product.fromJson(Map<String, dynamic> json) {
    dynamic getValue(List<String> candidates) {
      for (var key in candidates) {
        if (json.containsKey(key)) return json[key];
        if (json.containsKey(key.toLowerCase())) return json[key.toLowerCase()];
      }
      return null;
    }

    // --- CORRECCIÓN AQUÍ ---
    // Agregamos 'serial_number' a la lista de candidatos para SKU
    final valSku = getValue([
      'sku',
      'codigo',
      'code',
      'id_producto',
      'pk',
      'serial_number', // <--- ¡La clave de tu SQLite!
      'barcode',
    ]);

    final valName = getValue([
      'name',
      'nombre',
      'description',
      'descripcion',
      'producto',
    ]);

    // Agregamos 'quantity' por seguridad (aunque ya estaba, reforzamos)
    final valStock = getValue([
      'stock',
      'system_stock',
      'cantidad',
      'quantity',
      'existencias',
    ]);

    return Product()
      ..sku =
          valSku?.toString() ??
          'SIN-SKU-${DateTime.now().millisecondsSinceEpoch}'
      ..name = valName?.toString() ?? 'Sin Nombre'
      ..description = valName?.toString()
      ..systemStock = double.tryParse(valStock?.toString() ?? '0') ?? 0.0
      ..lastUpdated = DateTime.now()
      ..isSynced = true;
  }
}

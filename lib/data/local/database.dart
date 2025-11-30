import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'product_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        sku TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        system_stock REAL,
        counted_quantity REAL,
        image_url TEXT,
        last_updated INTEGER,
        is_synced INTEGER
      )
    ''');
  }

  // --- OPERACIONES ---

  Future<void> insertBatch(List<Product> products) async {
    final db = await instance.database;
    final batch = db.batch();

    for (var product in products) {
      batch.insert(
        'products',
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Estadísticas Numéricas
  Future<int> getCountImported() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --- NUEVO: Traer la LISTA de objetos (Para la pantalla de detalle) ---
  Future<List<Product>> getCountedProductsList() async {
    final db = await instance.database;
    // Traemos todo lo que tenga cantidad > 0, ordenado por lo último que tocaste
    final result = await db.query(
      'products',
      where: 'counted_quantity > 0',
      orderBy: 'last_updated DESC',
    );

    // Convertimos de Mapas SQL a Objetos Product
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<Product?> getProductBySku(String sku) async {
    final db = await instance.database;
    final maps = await db.query('products', where: 'sku = ?', whereArgs: [sku]);

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<void> updateCount(String sku, double quantity) async {
    final db = await instance.database;
    await db.update(
      'products',
      {
        'counted_quantity': quantity,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
        'is_synced': 0,
      },
      where: 'sku = ?',
      whereArgs: [sku],
    );
  }

  Future<void> deleteAll() async {
    final db = await instance.database;
    await db.delete('products');
  }

  Future<Map<String, double>> getPreviousCounts() async {
    final db = await instance.database;
    final result = await db.query('products', where: 'counted_quantity > 0');

    final Map<String, double> map = {};
    for (var row in result) {
      map[row['sku'] as String] = row['counted_quantity'] as double;
    }
    return map;
  }
}

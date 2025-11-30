import 'package:flutter/material.dart';

import '../../data/local/product_model.dart';
import '../../data/local/database.dart';
import '../../core/config/api_config.dart';

class InventoryProvider extends ChangeNotifier {
  InventoryProvider();

  // Listas y Modelos
  List<Product> _countedProducts = [];
  List<Product> get countedProducts => _countedProducts;

  Product? _scannedProduct;
  Product? get scannedProduct => _scannedProduct;

  // Estados de Carga
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Estadísticas
  int _totalImportedItems = 0;
  int get totalImportedItems => _totalImportedItems;

  int _totalCountedItems = 0;
  int get totalCountedItems => _totalCountedItems;

  // Fechas
  DateTime? _countStartDate; // Primer conteo realizado
  DateTime? get countStartDate => _countStartDate;

  DateTime? _countEndDate; // Último conteo realizado (Fin)
  DateTime? get countEndDate => _countEndDate;

  DateTime? _lastSync; // Cuándo se descargó el maestro
  DateTime? get lastSync => _lastSync;

  // ---------------------------------------------------------------------------
  // 1. HARD RESET (EL BOTÓN DE PÁNICO)
  // ---------------------------------------------------------------------------
  Future<void> hardReset() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper.instance;
      await db.deleteAll();

      _countedProducts = [];
      _totalImportedItems = 0;
      _totalCountedItems = 0;
      _countStartDate = null;
      _countEndDate = null; // <--- RESTABLECEMOS END DATE
      _lastSync = null;
      _scannedProduct = null;
      _error = null;
    } catch (e) {
      _error = "Error al resetear: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 2. LÓGICA DE RECURSIÓN
  // ---------------------------------------------------------------------------
  List<dynamic>? _findListRecursively(dynamic data, {int depth = 0}) {
    if (depth > 4) return null;
    if (data is List) return data;
    if (data is Map) {
      final commonKeys = [
        'results',
        'inventario',
        'data',
        'items',
        'products',
        'productos',
        'list',
        'payload',
      ];
      for (var key in commonKeys) {
        if (data.containsKey(key) && data[key] != null) {
          if (data[key] is List) return data[key];
          if (data[key] is Map) {
            final result = _findListRecursively(data[key], depth: depth + 1);
            if (result != null) return result;
          }
        }
      }
      for (var value in data.values) {
        if (value is Map || value is List) {
          final result = _findListRecursively(value, depth: depth + 1);
          if (result != null) return result;
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 3. SINCRONIZACIÓN (BAJADA)
  // ---------------------------------------------------------------------------
  Future<void> syncProductsDown() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dio = DioClient().dio;
      var response = await dio.get('v1/products/');

      if (response.statusCode == 200 && response.data is Map) {
        final map = response.data as Map;
        if (map.containsKey('inventario') && map['inventario'] is String) {
          final String redirectUrl = map['inventario'];
          print("LOG: Redirigiendo a $redirectUrl");
          response = await dio.get(redirectUrl);
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic>? dataList = _findListRecursively(response.data);
        if (dataList == null)
          throw Exception("No encontré lista de productos.");

        final db = DatabaseHelper.instance;

        final prevCounts = await db.getPreviousCounts();
        await db.deleteAll();

        List<Product> batchList = [];
        for (var item in dataList) {
          if (item is Map<String, dynamic>) {
            final p = Product.fromJson(item);
            if (prevCounts.containsKey(p.sku)) {
              p.countedQuantity = prevCounts[p.sku]!;
              p.lastUpdated = DateTime.now();
              p.isSynced = false;
            }
            batchList.add(p);
          }
        }

        await db.insertBatch(batchList);

        _lastSync = DateTime.now();
        await loadCountedProducts();
      } else {
        _error = "Error HTTP: ${response.statusCode}";
      }
    } catch (e) {
      _error = e.toString().replaceAll("Exception:", "").trim();
      print("Error Sync: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 4. GESTIÓN LOCAL
  // ---------------------------------------------------------------------------
  Future<void> loadCountedProducts() async {
    final db = DatabaseHelper.instance;

    // Esta lista viene ordenada por 'last_updated DESC' (del más reciente al más viejo)
    _countedProducts = await db.getCountedProductsList();

    _totalImportedItems = await db.getCountImported();
    _totalCountedItems = _countedProducts.length;

    // CÁLCULO DE FECHAS
    if (_countedProducts.isNotEmpty) {
      // El PRIMERO de la lista es el más reciente (Fin / Última actividad)
      _countEndDate = _countedProducts.first.lastUpdated;

      // El ÚLTIMO de la lista es el más antiguo (Inicio)
      _countStartDate = _countedProducts.last.lastUpdated;
    } else {
      _countStartDate = null;
      _countEndDate = null; // Si no hay conteos, no hay fin
    }

    if (_totalImportedItems == _totalCountedItems) {
      _countEndDate = _countedProducts.first.lastUpdated;
    } else {
      _countEndDate = null;
    }

    notifyListeners();
  }

  Future<void> scanProduct(String sku) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cleanSku = sku.trim();
    final db = DatabaseHelper.instance;

    final product = await db.getProductBySku(cleanSku);

    if (product != null) {
      _scannedProduct = product;
    } else {
      _scannedProduct = null;
      _error =
          "Producto no encontrado.\nTotal en Maestro: $_totalImportedItems items.";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateCount(double quantity) async {
    if (_scannedProduct == null) return;

    final db = DatabaseHelper.instance;
    await db.updateCount(_scannedProduct!.sku, quantity);

    _scannedProduct!.countedQuantity = quantity;
    _scannedProduct = null;

    await loadCountedProducts();
  }

  Future<void> updateQuantityDirectly(String sku, double newQuantity) async {
    final db = DatabaseHelper.instance;
    await db.updateCount(sku, newQuantity);
    await loadCountedProducts();
  }

  void clearSelection() {
    _scannedProduct = null;
    _error = null;
    notifyListeners();
  }
}

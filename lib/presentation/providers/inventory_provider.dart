import 'package:flutter/material.dart';
import '../../data/local/product_model.dart';
import '../../data/local/database.dart'; // <--- Usamos el Helper
import '../../core/config/api_config.dart';

class InventoryProvider extends ChangeNotifier {
  // Ya no inyectamos Isar, usaremos el Singleton de DatabaseHelper

  InventoryProvider();

  Product? _scannedProduct;
  Product? get scannedProduct => _scannedProduct;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Estadísticas
  int _totalImportedItems = 0;
  int get totalImportedItems => _totalImportedItems;

  int _totalCountedItems = 0;
  int get totalCountedItems => _totalCountedItems;

  DateTime? _countStartDate;
  DateTime? get countStartDate => _countStartDate;

  // --- LÓGICA DE RECURSIÓN (IGUAL QUE ANTES) ---
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

        // --- OPERACIÓN BD ---
        final db = DatabaseHelper.instance;

        // 1. RESPALDO: Guardamos conteos previos en RAM
        final prevCounts = await db.getPreviousCounts();

        // 2. LIMPIEZA: Borramos todo
        await db.deleteAll();

        // 3. PREPARACIÓN: Convertimos JSON a Objetos
        List<Product> batchList = [];
        for (var item in dataList) {
          if (item is Map<String, dynamic>) {
            final p = Product.fromJson(item);

            // 4. RESTAURACIÓN: Si ya estaba contado, le ponemos su valor
            if (prevCounts.containsKey(p.sku)) {
              p.countedQuantity = prevCounts[p.sku]!;
              p.lastUpdated = DateTime.now(); // Actualizamos fecha
              p.isSynced = false;
            }
            batchList.add(p);
          }
        }

        // 5. INSERCIÓN MASIVA (Batch)
        await db.insertBatch(batchList);

        await loadStats();
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

  // --- GESTIÓN ---
  Future<void> loadStats() async {
    final db = DatabaseHelper.instance;
    _totalImportedItems = await db.getCountImported();
    _totalCountedItems = await db.getCountWorked();

    // Para la fecha de inicio, podríamos hacer una query compleja,
    // o simplificar y asumir que es la fecha actual si hay items contados.
    if (_totalCountedItems > 0) {
      // Buscar el más viejo modificado
      // (Esto es opcional, para simplificar pondremos Now o null)
      _countStartDate = DateTime.now();
    } else {
      _countStartDate = null;
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

    // Actualizamos el producto en memoria para la UI inmediata
    _scannedProduct!.countedQuantity = quantity;

    _scannedProduct = null;
    await loadStats();
  }

  void clearSelection() {
    _scannedProduct = null;
    _error = null;
    notifyListeners();
  }
}

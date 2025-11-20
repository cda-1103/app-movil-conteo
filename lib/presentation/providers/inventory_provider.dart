import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:dio/dio.dart';
import '../../data/local/product_model.dart';
import '../../core/config/api_config.dart';

class InventoryProvider extends ChangeNotifier {
  final Isar _isar;
  InventoryProvider(this._isar);

  List<Product> _countedProducts = [];
  List<Product> get countedProducts => _countedProducts;

  Product? _scannedProduct;
  Product? get scannedProduct => _scannedProduct;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  // Variable nueva para saber cuántos tenemos en total (no solo contados)
  int _totalLocalItems = 0;
  int get totalLocalItems => _totalLocalItems;

  // ... (Misma función recursiva de antes, sin cambios) ...
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

      // Redirección automática (Tu caso específico)
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

        if (dataList == null) {
          throw Exception("No encontré lista de productos.");
        }

        // --- DIAGNÓSTICO DE CONSOLA ---
        print(
          "LOG: ¡Sincronización exitosa! Se encontraron ${dataList.length} items.",
        );
        if (dataList.isNotEmpty) {
          print("LOG: Ejemplo del primer item recibido: ${dataList.first}");
        }
        // -----------------------------

        await _isar.writeTxn(() async {
          for (var item in dataList) {
            try {
              if (item is Map<String, dynamic>) {
                final newProduct = Product.fromJson(
                  item,
                ); // Usa el nuevo parser flexible
                await _isar.products.put(newProduct);
              }
            } catch (e) {
              print("LOG: Error guardando item individual: $e");
            }
          }
        });

        await loadCountedProducts();

        // Actualizamos el contador total para dar feedback
        _totalLocalItems = await _isar.products.count();
        notifyListeners();
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

  Future<void> loadCountedProducts() async {
    // Carga lista visible (SOLO LOS CONTADOS)
    _countedProducts = await _isar.products
        .filter()
        .countedQuantityGreaterThan(0)
        .sortByLastUpdatedDesc()
        .findAll();

    // Actualiza el conteo total en background
    _totalLocalItems = await _isar.products.count();
    notifyListeners();
  }

  Future<void> scanProduct(String sku) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final cleanSku = sku.trim();

    // Búsqueda insensible a mayúsculas (más amigable)
    final product = await _isar.products
        .filter()
        .skuEqualTo(cleanSku, caseSensitive: false)
        .findFirst();

    if (product != null) {
      _scannedProduct = product;
    } else {
      _scannedProduct = null;
      // Mensaje de error mejorado
      _error = "Producto no encontrado.\nTotal en BD: $_totalLocalItems items.";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateCount(double quantity) async {
    if (_scannedProduct == null) return;

    await _isar.writeTxn(() async {
      _scannedProduct!.countedQuantity = quantity;
      _scannedProduct!.lastUpdated = DateTime.now();
      _scannedProduct!.isSynced = false;
      await _isar.products.put(_scannedProduct!);
    });

    _scannedProduct = null;
    await loadCountedProducts();
  }

  void clearSelection() {
    _scannedProduct = null;
    _error = null;
    notifyListeners();
  }
}

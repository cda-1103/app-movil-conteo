import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/product_model.dart';
import '../providers/inventory_provider.dart';
import 'scanner_page.dart'; // Asegúrate de tener este archivo del paso de la cámara

class InventoryCountScreen extends StatefulWidget {
  const InventoryCountScreen({super.key});

  @override
  State<InventoryCountScreen> createState() => _InventoryCountScreenState();
}

class _InventoryCountScreenState extends State<InventoryCountScreen> {
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final FocusNode _qtyFocusNode = FocusNode();

  final Color _primaryGreen = const Color(0xFF569D79);
  final Color _bgGrey = const Color(0xFFF5F5F5);
  final Color _textDark = const Color(0xFF1F2937);

  @override
  void initState() {
    super.initState();
    // SQFlite no necesita inicialización compleja, solo pedimos los datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // En SQFlite usamos loadStats o refrescamos la lista
      // Como no tenemos una lista visible aquí todavía, esto es opcional si no mostramos la lista abajo
    });
  }

  Future<void> _openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerPage()),
    );

    if (result != null && result is String) {
      _skuController.text = result;
      if (mounted) {
        context.read<InventoryProvider>().scanProduct(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos watch para que se actualice si scannedProduct cambia
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: _bgGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            provider.clearSelection(); // Limpiamos al salir
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Conteo",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (provider.isLoading) const LinearProgressIndicator(),

          Container(
            padding: const EdgeInsets.all(16.0),
            color: _bgGrey,
            child: Column(
              children: [
                // INPUT ESCANEAR
                _buildInputContainer(
                  child: TextField(
                    controller: _skuController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: "Escanear SKU...",
                      border: InputBorder.none,
                      prefixIcon: IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.black87,
                        ),
                        onPressed: _openScanner,
                        tooltip: "Abrir Cámara",
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _skuController.clear();
                          provider.clearSelection();
                        },
                      ),
                    ),
                    onSubmitted: (val) {
                      if (val.isNotEmpty) provider.scanProduct(val);
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // ERROR
                if (provider.error != null && provider.scannedProduct == null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red[100],
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                // PRODUCTO ENCONTRADO
                if (provider.scannedProduct != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _primaryGreen, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.scannedProduct!.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                  fontSize: 16,
                                ),
                              ),
                              Text("SKU: ${provider.scannedProduct!.sku}"),
                              // Mostramos stock contado vs sistema
                              Text(
                                "Contado: ${provider.scannedProduct!.countedQuantity.toInt()} / Sistema: ${provider.scannedProduct!.systemStock.toInt()}",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // INPUT CANTIDAD
                if (provider.scannedProduct != null) ...[
                  _buildInputContainer(
                    child: TextField(
                      controller: _qtyController,
                      focusNode: _qtyFocusNode,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "Cantidad a contar",
                        border: InputBorder.none,
                        icon: Icon(Icons.onetwothree, color: Colors.grey),
                      ),
                      onSubmitted: (_) => _confirmCount(context, provider),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _confirmCount(context, provider),
                      child: const Text(
                        "CONFIRMAR",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Escanea un producto para ver sus detalles y actualizar el conteo.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCount(BuildContext context, InventoryProvider provider) {
    final qty = double.tryParse(_qtyController.text);
    if (qty != null) {
      provider.updateCount(qty);
      _qtyController.clear();
      _skuController.clear();
      FocusScope.of(context).previousFocus(); // Ocultar teclado

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("¡Guardado!"),
          duration: Duration(milliseconds: 800),
        ),
      );
    }
  }

  Widget _buildInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: child,
    );
  }
}

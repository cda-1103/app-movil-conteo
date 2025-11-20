import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/local/product_model.dart';
import '../providers/inventory_provider.dart';
import 'scanner_page.dart'; // <--- IMPORTAMOS LA NUEVA PÁGINA

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadCountedProducts();
    });
  }

  // --- FUNCIÓN PARA ABRIR CÁMARA ---
  Future<void> _openScanner() async {
    // Navegamos a la página de cámara y esperamos el resultado
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerPage()),
    );

    // Si volvió con un código, lo buscamos
    if (result != null && result is String) {
      _skuController.text = result; // Llenamos el campo visualmente
      if (mounted) {
        context.read<InventoryProvider>().scanProduct(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: _bgGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Conteo",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download, color: Colors.black),
            onPressed: () async {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Descargando...")));
              await provider.syncProductsDown();
              if (provider.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error!),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("¡Sincronización OK!"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (provider.isLoading) const LinearProgressIndicator(),

          Container(
            padding: const EdgeInsets.all(16.0),
            color: _bgGrey,
            child: Column(
              children: [
                // --- INPUT ESCANEAR MEJORADO ---
                _buildInputContainer(
                  child: TextField(
                    controller: _skuController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: "Escanear SKU...",
                      border: InputBorder.none,
                      // EL ÍCONO AHORA ES UN BOTÓN DE CÁMARA FUNCIONAL
                      prefixIcon: IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.black87,
                        ),
                        onPressed: _openScanner, // <--- Acción de abrir cámara
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
                              Text(
                                "Stock Sistema: ${provider.scannedProduct!.systemStock.toInt()}",
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

          const Divider(),

          Expanded(
            child: provider.countedProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Lista vacía",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.countedProducts.length,
                    itemBuilder: (context, index) =>
                        _buildProductCard(provider.countedProducts[index]),
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
      FocusScope.of(context).previousFocus();
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

  Widget _buildProductCard(Product product) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              color: Colors.grey[100],
              child: const Icon(Icons.inventory, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "SKU: ${product.sku}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              "${product.countedQuantity.toInt()}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF569D79),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

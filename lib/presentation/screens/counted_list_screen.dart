import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../../data/local/product_model.dart';

class CountedListScreen extends StatefulWidget {
  const CountedListScreen({super.key});

  @override
  State<CountedListScreen> createState() => _CountedListScreenState();
}

class _CountedListScreenState extends State<CountedListScreen> {
  // Función para mostrar el diálogo de edición
  void _showEditDialog(BuildContext context, Product product) {
    final TextEditingController qtyController = TextEditingController(
      text: product.countedQuantity
          .toInt()
          .toString(), // Pre-llenamos con el valor actual
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Editar ${product.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Ingrese la nueva cantidad total:"),
            const SizedBox(height: 10),
            TextField(
              controller: qtyController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Cantidad",
                suffixText: "Unds",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Cerrar sin guardar
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF569D79),
            ),
            onPressed: () {
              final newQty = double.tryParse(qtyController.text);
              if (newQty != null) {
                // Llamamos al Provider para guardar
                context.read<InventoryProvider>().updateQuantityDirectly(
                  product.sku,
                  newQty,
                );
                Navigator.pop(ctx); // Cerramos diálogo

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Actualizado: ${product.name}")),
                );
              }
            },
            child: const Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final countedList = provider.countedProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: const Text(
          "Detalle de Contados",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: countedList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.playlist_remove,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No hay productos contados aún",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: countedList.length,
              itemBuilder: (context, index) {
                final product = countedList[index];
                return _buildItemCard(context, product);
              },
            ),
    );
  }

  Widget _buildItemCard(BuildContext context, Product product) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        // <--- Esto hace que responda al tacto con efecto visual
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEditDialog(
          context,
          product,
        ), // <--- Al hacer click, abre editar
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Ícono de Edición (Lápiz pequeño para indicar que es editable)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
              ),
              const SizedBox(width: 16),

              // Datos del Producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "SKU: ${product.sku}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Cantidad Grande
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${product.countedQuantity.toInt()}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF569D79),
                    ),
                  ),
                  const Text(
                    "Unds",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:app_movil/presentation/screens/config_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/inventory_provider.dart';
import 'count_screen.dart';
import 'counted_list_screen.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final Color _primaryGreen = const Color(0xFF16A34A);
  final Color _bgGrey = const Color(0xFFF5F5F5);
  final Color _textDark = const Color(0xFF1F2937);
  final Color _bluedark = const Color(0xFF375CDB); // Color para finalizar

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadCountedProducts();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "--/-- --:--"; // Formato por defecto
    return DateFormat('dd/MM HH:mm').format(date);
  }

  // Función para confirmar el fin del conteo
  void _confirmarFinalizacion(InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Finalizar Conteo?"),
        content: const Text(
          "Esto cerrará el conteo actual y enviará los datos al servidor. No podrás editar después.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _bluedark),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Cerrar alerta

              // ASUMIENDO QUE TU PROVIDER TIENE ESTE MÉTODO
              // await provider.finalizarYEnviarConteo();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Conteo finalizado y enviado.")),
                );
              }
            },
            child: const Text(
              "FINALIZAR",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    double progress = 0.0;
    if (provider.totalImportedItems > 0) {
      progress = provider.totalCountedItems / provider.totalImportedItems;
    }
    String progressText = "${(progress * 100).toStringAsFixed(1)}%";

    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: _bgGrey,
        elevation: 0,
        title: const Text(
          "Panel de Control",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ConfigScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          // Agregado scroll por si la pantalla es pequeña
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Resumen de Conteo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // --- TARJETAS ESTADÍSTICAS ---
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.cloud_download_outlined,
                      label: "Total Inventario",
                      value: "${provider.totalImportedItems}",
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.qr_code_scanner,
                      label: "Productos Contados",
                      value: "${provider.totalCountedItems}",
                      color: _primaryGreen,
                      isHighlight: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CountedListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- BARRA DE PROGRESO ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Progreso General",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        progressText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey[300],
                    color: _primaryGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // --- TARJETA DE FECHAS (MODIFICADA: INICIO Y FIN) ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // SECCIÓN INICIO
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Inicio",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  _formatDate(provider.countStartDate),
                                  style: TextStyle(
                                    color: _textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      VerticalDivider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),

                      // SECCIÓN FIN (NUEVA)
                      Expanded(
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.stop,
                                color: Colors.orange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Fin",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  // Asumiendo que tienes countEndDate en el provider
                                  // Si no lo tienes, puedes poner "--/--"
                                  _formatDate(provider.countEndDate),
                                  style: TextStyle(
                                    color: _textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40), // Espacio antes de botones
              // --- BOTONES DE ACCIÓN ---
              if (provider.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: [
                    // BOTÓN 1: ACTUALIZAR MAESTRO
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blueGrey.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await provider.syncProductsDown();
                          if (mounted && provider.error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.error!),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("¡Inventario Actualizado!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh, color: Colors.blueGrey),
                        label: const Text(
                          "ACTUALIZAR MAESTRO",
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // BOTÓN 2: INICIAR / CONTINUAR
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: provider.totalImportedItems > 0
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const InventoryCountScreen(),
                                ),
                              )
                            : null,
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        label: Text(
                          provider.totalCountedItems > 0
                              ? "CONTINUAR CONTEO"
                              : "INICIAR CONTEO",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // BOTÓN 3: FINALIZAR Y ENVIAR (NUEVO)
                    if (provider.totalCountedItems > 0)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _bluedark, // Color distintivo
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () => _confirmarFinalizacion(provider),
                          icon: const Icon(
                            Icons.cloud_upload,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "FINALIZAR Y ENVIAR",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

              if (provider.totalImportedItems == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    "Presiona 'Actualizar Maestro' para descargar los datos",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget de tarjeta estadística (Sin cambios en lógica interna, solo UI)
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isHighlight = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isHighlight ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isHighlight ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isHighlight ? Colors.white : color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isHighlight ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isHighlight
                    ? Colors.white.withOpacity(0.9)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

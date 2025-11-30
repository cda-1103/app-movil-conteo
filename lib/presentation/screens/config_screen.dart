import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart'; // <--- NECESARIO
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../providers/inventory_provider.dart'; // <--- NECESARIO
import 'syncdata_screen.dart'; // Asegúrate que este nombre coincida con tu archivo real

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final TextEditingController _ipController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final Color _primaryGreen = const Color(0xFF16A34A);
  final Color _bgGrey = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('server_ip');
    if (savedIp != null) {
      _ipController.text = savedIp;
    }
  }

  // --- NUEVO: LÓGICA PARA BORRAR DATOS ---
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Restablecer todo?"),
        content: const Text(
          "Esto borrará la base de datos local y los conteos.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Cierra diálogo
              // Llama al provider para borrar todo
              context.read<InventoryProvider>().hardReset();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Datos eliminados correctamente")),
              );
            },
            child: const Text(
              "BORRAR TODO",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    ApiConfig.instance.setServerIp(ip);

    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 3);
      final testUrl = 'http://$ip:8000/api/';

      try {
        await dio.get(testUrl);
      } catch (e) {
        if (e is DioException &&
            (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.connectionError)) {
          rethrow;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', ip);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SyncScreen()),
      );
    } on DioException catch (e) {
      setState(() {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          _errorMessage =
              "Tiempo agotado. Verifica que ambos equipos estén en el mismo Wi-Fi.";
        } else if (e.type == DioExceptionType.connectionError) {
          _errorMessage =
              "Conexión rechazada. Verifica que el servidor Django esté corriendo en 0.0.0.0:8000";
        } else {
          _errorMessage = "Error de conexión: ${e.message}";
        }
      });
    } catch (e) {
      setState(() => _errorMessage = "Error inesperado: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: _bgGrey,
        elevation: 0,
        // --- AQUÍ AGREGAMOS EL BOTÓN DE RESET ---
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: "Restablecer Datos (Dev Mode)",
            onPressed: _showResetDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- LOGO GRANDE ---
            Image.asset(
              'assets/images/kontar.png',
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),

            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _ipController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  hintText: "IP del Servidor (ej. 192.168.1.15)",
                  prefixIcon: Icon(Icons.wifi, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

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
                onPressed: _isLoading ? null : _connect,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Conectar",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const Spacer(),

            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  "Versión 1.0.0 (Dev)",
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

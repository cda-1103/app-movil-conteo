import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart'; // Asegúrate de que la ruta al config sea correcta
import '../screens/syncdata_screen.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final TextEditingController _ipController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Colores del diseño
  final Color _primaryGreen = const Color(0xFF569D79);
  final Color _bgGrey = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  // 1. Cargar IP guardada
  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('server_ip');
    if (savedIp != null) {
      _ipController.text = savedIp;
    }
  }

  // 2. Probar conexión y Navegar
  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    // Ocultar teclado
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // A. Configurar el Singleton
    ApiConfig.instance.setServerIp(ip);

    try {
      // B. Test de conexión (Ping)
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 3);

      // Intentamos conectar a la raíz de la API para ver si responde
      // Ajusta el puerto si tu Django no corre en el 8000
      final testUrl = 'http://$ip:8000/api/';

      // Hacemos una petición HEAD o GET simple
      // Nota: Si tu API requiere Auth para todo, esto podría dar 401 o 403,
      // pero eso significa que "llegamos" al servidor, lo cual es éxito de red.
      try {
        await dio.get(testUrl);
      } catch (e) {
        // Si es un error 404, 401, 403, significa que el servidor RESPONDIÓ.
        // Solo nos preocupa si es ConnectionTimeout o ConnectionRefused.
        if (e is DioException &&
            (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.connectionError)) {
          rethrow; // Re-lanzamos el error si es de conexión real
        }
      }

      // C. Guardar éxito
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_ip', ip);

      if (!mounted) return;

      // D. Navegar a la Pantalla REAL de Conteo
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SyncScreen()),
      );
    } on DioException catch (e) {
      setState(() {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          _errorMessage =
              "Tiempo agotado. ¿El PC y el celular están en el mismo Wi-Fi?";
        } else if (e.type == DioExceptionType.connectionError) {
          _errorMessage =
              "Conexión rechazada. Asegúrate de correr Django con: \npython manage.py runserver 0.0.0.0:8000";
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black54),
            onPressed: () {
              // Opciones futuras
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Inventario v1.0",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 60),

            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _ipController,
                keyboardType: TextInputType.number,
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
          ],
        ),
      ),
    );
  }
}

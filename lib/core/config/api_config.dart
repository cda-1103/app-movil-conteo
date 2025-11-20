import 'package:dio/dio.dart';

/// Singleton para manejar la configuración dinámica de la red.
/// Esto cumple con el requerimiento de NO tener la URL estática.
class ApiConfig {
  // Constructor privado
  ApiConfig._privateConstructor();
  static final ApiConfig instance = ApiConfig._privateConstructor();

  String? _serverIp;
  String _port = '8000'; // Puerto por defecto de Django
  
  // Getter para saber si ya está configurado
  bool get isConfigured => _serverIp != null && _serverIp!.isNotEmpty;

  /// Método llamado desde la pantalla de Configuración/Login
  void setServerIp(String ip, {String port = '8000'}) {
    _serverIp = ip;
    _port = port;
  }

  /// Construye la URL base dinámicamente
  String get baseUrl {
    if (_serverIp == null) throw Exception("IP del servidor no configurada");
    return 'http://$_serverIp:$_port/api/';
  }
}

/// Cliente HTTP wrapper que utiliza la configuración dinámica
class DioClient {
  final Dio _dio = Dio();

  DioClient() {
    // Interceptor para inyectar la URL base en cada petición
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Aquí es donde ocurre la magia: se asigna la URL justo antes de la petición
        options.baseUrl = ApiConfig.instance.baseUrl;
        
        // Configuración de timeouts para LAN
        options.connectTimeout = const Duration(seconds: 5);
        options.receiveTimeout = const Duration(seconds: 5);
        
        return handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;
}
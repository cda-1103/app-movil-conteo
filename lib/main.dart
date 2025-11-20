import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'data/local/product_model.dart';
import 'presentation/providers/inventory_provider.dart';
import 'presentation/screens/config_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Base de Datos Isar
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [ProductSchema], // Generado por build_runner
    directory: dir.path,
  );

  runApp(MyApp(isar: isar));
}

class MyApp extends StatelessWidget {
  final Isar isar;

  const MyApp({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Inyectamos la BD en el Provider
        ChangeNotifierProvider(create: (_) => InventoryProvider(isar)),
      ],
      child: MaterialApp(
        title: 'Inventario Offline',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF569D79)),
          useMaterial3: true,
        ),
        // Arrancamos en la configuración de IP
        home: const ConfigScreen(),
      ),
    );
  }
}

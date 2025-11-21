import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/inventory_provider.dart';
import 'presentation/screens/config_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Ya no hace falta inicializar Isar aquí.
  // SQLite se inicializa solo la p`rimera vez que lo llamas.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // El Provider ya no pide argumentos en el constructor
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
      ],
      child: MaterialApp(
        title: 'Inventario Offline',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF569D79)),
          useMaterial3: true,
        ),
        home: const ConfigScreen(),
      ),
    );
  }
}

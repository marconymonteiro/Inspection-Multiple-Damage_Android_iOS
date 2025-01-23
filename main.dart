import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Suporte à localização
import 'package:permission_handler/permission_handler.dart'; // Gerenciar permissões
import 'home_screen.dart'; // Importa a tela inicial

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Garante a inicialização correta
  await requestPermissions(); // Solicita permissões ao iniciar
  runApp(InspectionApp());
}

// Função para solicitar permissões
Future<void> requestPermissions() async {
  // Lista de permissões necessárias
  final permissions = [
    Permission.camera,         // Permissão para usar a câmera
    Permission.storage,        // Para acessar arquivos
  ];

  // Solicita permissões
  for (var permission in permissions) {
    if (await permission.isDenied || await permission.isPermanentlyDenied) {
      await permission.request();
    }
  }
}

class InspectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Desativa o banner de debug
      home: HomeScreen(), // Tela inicial
      supportedLocales: const [
        Locale('pt', 'BR'), // Apenas Português do Brasil
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate, // Suporte para widgets Material
        GlobalWidgetsLocalizations.delegate, // Suporte para widgets
        GlobalCupertinoLocalizations.delegate, // Suporte para widgets Cupertino
      ],
    );
  }
}

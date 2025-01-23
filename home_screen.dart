import 'package:flutter/material.dart';
import 'inspection_form.dart'; // Importa a tela de novo formulário
import 'saved_forms.dart';    // Importa a tela de formulários salvos
import 'package:uuid/uuid.dart';

String generateUniqueFormId() {
  var uuid = Uuid();
  return uuid.v4();
  }

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tela Inicial'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo do cliente - Imagem acima dos botões
            Image.asset(
              'assets/logo_cliente.png', // Caminho para a logo do cliente
              width: 150, // Ajuste o tamanho conforme necessário
              height: 150,
            ),
            SizedBox(height: 30), // Espaçamento entre a logo e os botões
            // Botão para iniciar um novo formulário
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                  builder: (context) => FormularioInspecao(formId: generateUniqueFormId()),
                  ),
                );
              },
              child: Text('Novo Formulário'),
            ),
            SizedBox(height: 20),
            // Botão para consultar formulários salvos
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SavedForms(), // Navega para a tela de formulários salvos
                  ),
                );
              },
              child: Text('Consultar Formulários'),
            ),
          ],
        ),
      ),
    );
  }
}

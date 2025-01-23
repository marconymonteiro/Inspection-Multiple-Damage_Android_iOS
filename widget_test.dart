import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inspection_multiple_damage/main.dart'; // Ajuste o caminho se necessário

void main() {
  testWidgets('Verifica se o título está correto', (WidgetTester tester) async {
    // Constrói o widget principal e dispara um frame.
    await tester.pumpWidget(InspectionApp());

    // Verifica se o título da AppBar está presente
    expect(find.text('Inspeção de Equipamentos'), findsOneWidget);

    // Verifica que um campo de texto está presente
    expect(find.byType(TextFormField), findsWidgets);
  });
}

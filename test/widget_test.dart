// Test pour l'app Soutrali Recensement
//
// Ce test vérifie que l'app se lance correctement et affiche l'écran de splash.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sdealsidentification/main.dart';

void main() {
  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    // Construire l'app et déclencher un frame
    await tester.pumpWidget(const SoutraliRecensementApp());

    // Vérifier que l'écran de splash s'affiche
    expect(find.text('Soutrali Recensement'), findsOneWidget);
    expect(find.text('Identification des prestataires, freelances et vendeurs'), findsOneWidget);
    expect(find.text('Version 1.0.0'), findsOneWidget);
    
    // Vérifier la présence du logo
    expect(find.byIcon(Icons.business), findsOneWidget);
    
    // Vérifier la présence de l'indicateur de chargement
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

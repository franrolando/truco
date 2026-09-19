import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truco_app/main.dart';

void main() {
  testWidgets('muestra tres cartas y permite repartir de nuevo',
      (tester) async {
    await tester.pumpWidget(const TrucoApp());

    expect(find.text('Tu mano'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));

    await tester.tap(find.text('Repartir de nuevo'));
    await tester.pump();
    expect(find.byType(ListTile), findsNWidgets(3));
  });
}

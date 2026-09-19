import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truco_app/juego/partida_local.dart';
import 'package:truco_app/main.dart';
import 'package:truco_app/pantallas/mesa_page.dart';
import 'package:truco_app/widgets/carta_widget.dart';

Finder get _mano => find.descendant(
      of: find.byKey(const Key('mano')),
      matching: find.byType(CartaWidget),
    );

void main() {
  testWidgets('la app abre la mesa con tres cartas y el marcador', (t) async {
    await t.pumpWidget(const TrucoApp());
    expect(find.text('Vos 0'), findsOneWidget);
    expect(find.text('Bot 0'), findsOneWidget);
    expect(_mano, findsNWidgets(3));
    expect(find.text('Al mazo'), findsOneWidget);
    // Dejar correr el timer del bot pendiente antes de cerrar el test.
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('jugar una carta la saca de la mano y responde el bot', (t) async {
    final partida = PartidaLocal(random: Random(2), pausaBot: Duration.zero);
    await t.pumpWidget(MaterialApp(home: MesaPage(partida: partida)));
    await t.pumpAndSettle();

    await t.tap(_mano.first);
    await t.pumpAndSettle();

    expect(_mano, findsNWidgets(2));
    expect(find.text('Baza 1'), findsOneWidget);
    expect(partida.registro.any((l) => l.startsWith('Vos jugaste')), isTrue);
  });

  testWidgets('los botones se habilitan según lo que permite el motor',
      (t) async {
    final partida = PartidaLocal(random: Random(2), pausaBot: Duration.zero);
    await t.pumpWidget(MaterialApp(home: MesaPage(partida: partida)));
    await t.pumpAndSettle();

    FilledButton boton(String texto) => t.widget<FilledButton>(
        find.ancestor(of: find.text(texto), matching: find.byType(FilledButton)));

    expect(boton('Truco').onPressed, isNotNull);
    expect(boton('Quiero').onPressed, isNull); // nada pendiente
    expect(boton('No quiero').onPressed, isNull);
  });
}

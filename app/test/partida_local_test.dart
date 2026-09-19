import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:truco_app/juego/partida_local.dart';
import 'package:truco_engine/truco_engine.dart';

void main() {
  test('partidas completas contra el bot: nunca se traba ni rompe', () async {
    for (var semilla = 0; semilla < 40; semilla++) {
      final rnd = Random(semilla);
      final p = PartidaLocal(
        config: TrucoConfig(puntosObjetivo: semilla.isEven ? 15 : 30),
        random: rnd,
        pausaBot: Duration.zero,
      );
      await p.iniciar();

      var pasos = 0;
      while (!p.terminada) {
        expect(++pasos, lessThan(5000), reason: 'semilla $semilla se trabó');
        final v = p.vista;
        // Tras cada jugada del bot vuelve a tocarle al humano.
        expect(v.actua, PartidaLocal.humano, reason: 'semilla $semilla');
        expect(v.acciones, isNotEmpty);
        await p.jugar(v.acciones[rnd.nextInt(v.acciones.length)]);
        expect(p.error, isNull);
      }
      expect(p.vista.terminado, isTrue);
      expect(p.vista.equipoGanador, isNotNull);
      p.dispose();
    }
  });

  test('una jugada ilegal deja un error y no cambia la mesa', () async {
    final p = PartidaLocal(random: Random(3), pausaBot: Duration.zero);
    await p.iniciar();
    final antes = p.vista.tusCartas;
    // Carta que no está en la mano del humano.
    final ajena = baraja().firstWhere((c) => !antes.contains(c));
    await p.jugar(Accion.jugarCarta(ajena));
    expect(p.error, isNotNull);
    expect(p.vista.tusCartas, antes);
    p.dispose();
  });

  test('el registro cuenta lo que pasó en español', () async {
    final p = PartidaLocal(random: Random(5), pausaBot: Duration.zero);
    await p.iniciar();
    final carta = p.vista.tusCartas.first;
    await p.jugar(Accion.jugarCarta(carta));
    expect(p.registro.any((l) => l.startsWith('Vos jugaste')), isTrue);
    p.dispose();
  });
}

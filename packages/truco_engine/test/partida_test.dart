import 'dart:math';

import 'package:test/test.dart';
import 'package:truco_engine/truco_engine.dart';

/// Juega partidas enteras eligiendo siempre una acción legal al azar.
/// Si la máquina de estados se traba o rompe una invariante, esto lo detecta.
void main() {
  for (final jugadores in [2, 4, 6]) {
    for (final objetivo in [15, 30]) {
      test('partidas aleatorias: $jugadores jugadores a $objetivo', () {
        for (var semilla = 0; semilla < 60; semilla++) {
          final rnd = Random(semilla);
          final g = TrucoGame(
            TrucoConfig(jugadores: jugadores, puntosObjetivo: objetivo),
            random: rnd,
          );
          var pasos = 0;
          while (!g.juegoTerminado) {
            expect(++pasos, lessThan(20000), reason: 'semilla $semilla se trabó');
            final actua = g.asientoQueActua!;

            // Solo actúa quien corresponde.
            for (var s = 0; s < jugadores; s++) {
              final acciones = g.accionesPermitidas(s);
              expect(acciones.isNotEmpty, s == actua,
                  reason: 'semilla $semilla asiento $s');
            }

            final acciones = g.accionesPermitidas(actua);
            // Sesgo hacia jugar carta para que las manos avancen.
            final cartas =
                acciones.where((a) => a.tipo == TipoAccion.jugarCarta).toList();
            final elegida = cartas.isNotEmpty && rnd.nextInt(3) > 0
                ? cartas[rnd.nextInt(cartas.length)]
                : acciones[rnd.nextInt(acciones.length)];
            final eventos = g.aplicar(actua, elegida);

            for (final e in eventos) {
              expect(e.toString(), isNot(contains('tusCartas')));
            }
            final p = g.puntos;
            expect(p.every((x) => x >= 0), isTrue);
          }

          final ganador = g.equipoGanador!;
          expect(g.puntos[ganador], greaterThanOrEqualTo(objetivo));
          expect(g.puntos[1 - ganador], lessThan(objetivo));
          expect(g.asientoQueActua, isNull);
          for (var s = 0; s < jugadores; s++) {
            expect(g.accionesPermitidas(s), isEmpty);
          }
        }
      });
    }
  }
}

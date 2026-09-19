import 'package:test/test.dart';
import 'package:truco_engine/truco_engine.dart';

Carta c(Palo palo, int n) => Carta(palo, n);
Accion jugar(Carta carta) => Accion.jugarCarta(carta);
const truco = Accion(TipoAccion.truco);
const retruco = Accion(TipoAccion.retruco);
const valeCuatro = Accion(TipoAccion.valeCuatro);
const quiero = Accion(TipoAccion.quiero);
const noQuiero = Accion(TipoAccion.noQuiero);
const envido = Accion(TipoAccion.envido);
const real = Accion(TipoAccion.realEnvido);
const falta = Accion(TipoAccion.faltaEnvido);
const mazo = Accion(TipoAccion.irseAlMazo);

/// Partida de 2 con manos fijas. El asiento 0 es mano.
TrucoGame partida2(List<Carta> a, List<Carta> b, {int objetivo = 15}) =>
    TrucoGame(
      TrucoConfig(jugadores: 2, puntosObjetivo: objetivo),
      manosIniciales: [a, b],
    );

// Manos base sin envido relevante: nadie tiene dos del mismo palo.
final manoFuerte = [c(Palo.espada, 1), c(Palo.copa, 4), c(Palo.basto, 5)];
final manoDebil = [c(Palo.oro, 3), c(Palo.copa, 6), c(Palo.basto, 6)];

void main() {
  group('bazas', () {
    test('gana la carta más fuerte y empieza la siguiente baza', () {
      final g = partida2(
        [c(Palo.espada, 1), c(Palo.copa, 4), c(Palo.basto, 5)],
        [c(Palo.oro, 3), c(Palo.oro, 4), c(Palo.copa, 5)],
      );
      g.aplicar(0, jugar(c(Palo.espada, 1)));
      expect(g.asientoQueActua, 1);
      g.aplicar(1, jugar(c(Palo.oro, 3)));
      expect(g.asientoQueActua, 0); // ganó el 0, abre él
    });

    test('en 4 jugadores abre la siguiente baza quien ganó la anterior', () {
      final g = TrucoGame(
        const TrucoConfig(jugadores: 4),
        manosIniciales: [
          [c(Palo.copa, 4), c(Palo.copa, 5), c(Palo.copa, 6)],
          [c(Palo.oro, 3), c(Palo.oro, 4), c(Palo.oro, 5)],
          [c(Palo.espada, 1), c(Palo.basto, 4), c(Palo.basto, 5)],
          [c(Palo.basto, 6), c(Palo.copa, 10), c(Palo.copa, 11)],
        ],
      );
      g.aplicar(0, jugar(c(Palo.copa, 4)));
      g.aplicar(1, jugar(c(Palo.oro, 3)));
      g.aplicar(2, jugar(c(Palo.espada, 1)));
      g.aplicar(3, jugar(c(Palo.basto, 6)));
      expect(g.asientoQueActua, 2);
    });

    test('parda en la primera: decide la segunda', () {
      final g = partida2(
        [c(Palo.copa, 4), c(Palo.espada, 1), c(Palo.basto, 5)],
        [c(Palo.oro, 4), c(Palo.oro, 3), c(Palo.copa, 5)],
      );
      g.aplicar(0, jugar(c(Palo.copa, 4)));
      g.aplicar(1, jugar(c(Palo.oro, 4))); // parda
      expect(g.asientoQueActua, 0); // vuelve a abrir el mano
      g.aplicar(0, jugar(c(Palo.espada, 1)));
      g.aplicar(1, jugar(c(Palo.oro, 3)));
      expect(g.puntos, [1, 0]);
    });

    test('gana la primera y parda en la segunda: se lleva la mano el primero', () {
      final g = partida2(
        [c(Palo.espada, 1), c(Palo.copa, 4), c(Palo.basto, 5)],
        [c(Palo.oro, 3), c(Palo.oro, 4), c(Palo.copa, 5)],
      );
      g.aplicar(0, jugar(c(Palo.espada, 1)));
      g.aplicar(1, jugar(c(Palo.oro, 3)));
      g.aplicar(0, jugar(c(Palo.copa, 4)));
      g.aplicar(1, jugar(c(Palo.oro, 4))); // parda
      expect(g.puntos, [1, 0]);
    });

    test('1ª para uno, 2ª para el otro y parda en la 3ª: gana el de la 1ª', () {
      final g = partida2(
        [c(Palo.espada, 3), c(Palo.copa, 4), c(Palo.copa, 5)],
        [c(Palo.oro, 4), c(Palo.oro, 3), c(Palo.oro, 5)],
      );
      g.aplicar(0, jugar(c(Palo.espada, 3)));
      g.aplicar(1, jugar(c(Palo.oro, 4)));
      g.aplicar(0, jugar(c(Palo.copa, 4)));
      g.aplicar(1, jugar(c(Palo.oro, 3)));
      g.aplicar(1, jugar(c(Palo.oro, 5)));
      g.aplicar(0, jugar(c(Palo.copa, 5))); // parda
      expect(g.puntos, [1, 0]);
    });

    test('tres pardas: gana el equipo del mano', () {
      final g = partida2(
        [c(Palo.espada, 3), c(Palo.copa, 4), c(Palo.copa, 5)],
        [c(Palo.oro, 3), c(Palo.oro, 4), c(Palo.oro, 5)],
      );
      for (final n in [3, 4, 5]) {
        final pa = n == 3 ? Palo.espada : Palo.copa;
        g.aplicar(0, jugar(c(pa, n)));
        g.aplicar(1, jugar(c(Palo.oro, n)));
      }
      expect(g.puntos, [1, 0]);
    });
  });

  group('truco', () {
    test('quiero sube el valor de la mano', () {
      final g = partida2(
        [c(Palo.espada, 1), c(Palo.copa, 4), c(Palo.basto, 5)],
        [c(Palo.oro, 3), c(Palo.oro, 4), c(Palo.copa, 5)],
      );
      g.aplicar(0, truco);
      expect(g.asientoQueActua, 1);
      g.aplicar(1, quiero);
      expect(g.nivelTruco, 2);
      expect(g.asientoQueActua, 0);
      g.aplicar(0, jugar(c(Palo.espada, 1)));
      g.aplicar(1, jugar(c(Palo.oro, 3)));
      g.aplicar(0, jugar(c(Palo.copa, 4)));
      g.aplicar(1, jugar(c(Palo.oro, 4)));
      expect(g.puntos, [2, 0]);
    });

    test('no quiero da 1 punto al que cantó', () {
      final g = partida2(manoFuerte, manoDebil);
      g.aplicar(0, truco);
      g.aplicar(1, noQuiero);
      expect(g.puntos, [1, 0]);
      expect(g.mano, 1); // rotó el mano
    });

    test('retruco sin quiero previo cobra el truco; vale cuatro cobra el retruco', () {
      final g = partida2(manoFuerte, manoDebil);
      g.aplicar(0, truco);
      g.aplicar(1, retruco); // implica quiero al truco
      expect(g.nivelTruco, 2);
      expect(g.asientoQueActua, 0);
      g.aplicar(0, noQuiero);
      expect(g.puntos, [0, 2]);
    });

    test('solo el equipo que quiso puede subir', () {
      final g = partida2(manoFuerte, manoDebil);
      g.aplicar(0, truco);
      g.aplicar(1, quiero);
      // El 0 cantó, así que no puede volver a subir; le toca al 1.
      expect(g.accionesPermitidas(0), isNot(contains(retruco)));
      g.aplicar(0, jugar(c(Palo.espada, 1)));
      expect(g.accionesPermitidas(1), contains(retruco));
    });

    test('cadena completa hasta vale cuatro', () {
      final g = partida2(manoFuerte, manoDebil);
      g.aplicar(0, truco);
      g.aplicar(1, retruco);
      g.aplicar(0, valeCuatro);
      expect(g.asientoQueActua, 1);
      expect(g.accionesPermitidas(1), isNot(contains(valeCuatro)));
      g.aplicar(1, quiero);
      expect(g.nivelTruco, 4);
    });

    test('irse al mazo da 1 punto, o el nivel de truco aceptado', () {
      final g = partida2(manoFuerte, manoDebil);
      g.aplicar(0, mazo);
      expect(g.puntos, [0, 1]);

      final h = partida2(manoFuerte, manoDebil);
      h.aplicar(0, truco);
      h.aplicar(1, quiero);
      h.aplicar(0, mazo);
      expect(h.puntos, [0, 2]);
    });
  });

  group('envido', () {
    final a = [c(Palo.espada, 7), c(Palo.espada, 6), c(Palo.basto, 1)]; // 33
    final b = [c(Palo.oro, 7), c(Palo.copa, 5), c(Palo.basto, 4)]; // 7

    test('quiero: gana el más alto y cobra 2', () {
      final g = partida2(a, b);
      g.aplicar(0, envido);
      g.aplicar(1, quiero);
      expect(g.puntos, [2, 0]);
    });

    test('no quiero: 1 punto al que cantó', () {
      final g = partida2(a, b);
      g.aplicar(0, envido);
      g.aplicar(1, noQuiero);
      expect(g.puntos, [1, 0]);
    });

    test('envido y real envido: cobra 5 si se quiere', () {
      final g = partida2(a, b);
      g.aplicar(0, envido);
      g.aplicar(1, real);
      g.aplicar(0, quiero);
      expect(g.puntos, [5, 0]);
    });

    test('no quiero a un aumento cobra lo anterior', () {
      final g = partida2(a, b);
      g.aplicar(0, envido);
      g.aplicar(1, real);
      g.aplicar(0, noQuiero);
      expect(g.puntos, [0, 2]);
    });

    test('empate: gana el más cercano al mano', () {
      final g = partida2(
        [c(Palo.espada, 5), c(Palo.espada, 2), c(Palo.basto, 1)],
        [c(Palo.oro, 5), c(Palo.oro, 2), c(Palo.copa, 1)],
      );
      g.aplicar(0, envido);
      g.aplicar(1, quiero);
      expect(g.puntos, [2, 0]);
    });

    test('falta envido: gana lo que falta para el objetivo', () {
      final g = partida2(a, b);
      g.aplicar(0, falta);
      g.aplicar(1, quiero);
      expect(g.juegoTerminado, isTrue);
      expect(g.equipoGanador, 0);
    });

    test('solo en la primera baza', () {
      final g = partida2(a, b);
      g.aplicar(0, jugar(c(Palo.espada, 7)));
      g.aplicar(1, jugar(c(Palo.oro, 7)));
      expect(g.accionesPermitidas(g.asientoQueActua!).map((x) => x.tipo),
          isNot(contains(TipoAccion.envido)));
    });

    test('no se puede cantar con el truco ya aceptado', () {
      final g = partida2(a, b);
      g.aplicar(0, truco);
      g.aplicar(1, quiero);
      expect(g.accionesPermitidas(0).map((x) => x.tipo),
          isNot(contains(TipoAccion.envido)));
    });

    test('el envido va primero: se responde antes del truco pendiente', () {
      final g = partida2(a, b);
      g.aplicar(0, truco);
      expect(g.accionesPermitidas(1), contains(envido));
      g.aplicar(1, envido);
      expect(g.asientoQueActua, 0);
      g.aplicar(0, quiero);
      expect(g.puntos, [2, 0]);
      expect(g.asientoQueActua, 1); // vuelve el truco pendiente
      g.aplicar(1, quiero);
      expect(g.nivelTruco, 2);
    });
  });

  group('ilegales', () {
    test('fuera de turno o carta ajena: lanza y no toca el estado', () {
      final g = partida2(manoFuerte, manoDebil);
      final antes = g.vistaPara(0).toString() + g.vistaPara(1).toString();
      expect(() => g.aplicar(1, jugar(c(Palo.oro, 3))), throwsA(isA<AccionIlegal>()));
      expect(() => g.aplicar(0, jugar(c(Palo.oro, 3))), throwsA(isA<AccionIlegal>()));
      expect(() => g.aplicar(0, quiero), throwsA(isA<AccionIlegal>()));
      expect(g.vistaPara(0).toString() + g.vistaPara(1).toString(), antes);
    });

    test('vistaPara no expone cartas ajenas', () {
      final g = partida2(manoFuerte, manoDebil);
      final v = g.vistaPara(1);
      expect(v['tusCartas'], hasLength(3));
      expect(v.toString(), isNot(contains('espada')));
    });
  });
}

import 'dart:math';

import 'package:test/test.dart';
import 'package:truco_engine/truco_engine.dart';

List<String> tipos(List<Mensaje> ms) => [for (final m in ms) m.type];

void main() {
  group('Mensaje', () {
    test('hace ida y vuelta por texto', () {
      final m = Mensaje(TipoMensaje.join, {'nombre': 'Fran'});
      final d = Mensaje.decode(m.encode());
      expect(d.type, TipoMensaje.join);
      expect(d.payload['nombre'], 'Fran');
    });

    test('rechaza versión distinta y basura', () {
      expect(() => Mensaje.decode('{"v":99,"type":"join","payload":{}}'),
          throwsFormatException);
      expect(() => Mensaje.decode('no es json'), throwsFormatException);
      expect(() => Mensaje.decode('[1,2]'), throwsFormatException);
    });
  });

  group('SalaHost', () {
    SalaHost sala() =>
        SalaHost(const TrucoConfig(jugadores: 2), random: Random(1));

    test('asigna asientos en orden y rechaza cuando está llena', () {
      final s = sala();
      expect(s.unirse('Ana'), 0);
      expect(s.unirse('Beto'), 1);
      expect(s.unirse('Cami'), isNull);
      expect(s.puedeIniciar, isTrue);
    });

    test('el saludo manda welcome al nuevo y lobby a todos', () {
      final s = sala();
      final a = s.unirse('Ana')!;
      expect(tipos(s.saludo(a)[a]!), ['welcome', 'lobby']);
      final b = s.unirse('Beto')!;
      final r = s.saludo(b);
      expect(tipos(r[b]!), ['welcome', 'lobby']);
      expect(tipos(r[a]!), ['lobby']);
      expect(r[a]!.single.payload['jugadores'], ['Ana', 'Beto']);
    });

    test('no se puede iniciar sin sala completa', () {
      final s = sala()..unirse('Ana');
      expect(s.iniciar, throwsStateError);
    });

    test('iniciar reparte una mano distinta a cada jugador', () {
      final s = sala()
        ..unirse('Ana')
        ..unirse('Beto');
      final r = s.iniciar();
      final m0 = r[0]!.last.payload['tusCartas'] as List;
      final m1 = r[1]!.last.payload['tusCartas'] as List;
      expect(m0, hasLength(3));
      expect(m1, hasLength(3));
      expect(m0.toSet().intersection(m1.toSet()), isEmpty);
      expect(r[0]!.last.type, TipoMensaje.state);
    });

    test('una acción legal llega como eventos + estado a todos', () {
      final s = sala()
        ..unirse('Ana')
        ..unirse('Beto');
      s.iniciar();
      final r = s.recibir(0, const Mensaje(TipoMensaje.action, {'tipo': 'truco'}));
      for (final asiento in [0, 1]) {
        expect(tipos(r[asiento]!), ['events', 'state']);
      }
      expect(r[1]!.last.payload['actua'], 1);
    });

    test('un error va solo a quien lo causó', () {
      final s = sala()
        ..unirse('Ana')
        ..unirse('Beto');
      s.iniciar();
      final r = s.recibir(1, const Mensaje(TipoMensaje.action, {'tipo': 'truco'}));
      expect(r.keys, [1]);
      expect(r[1]!.single.type, TipoMensaje.error);
      expect(r[1]!.single.payload['codigo'], 'accion_ilegal');

      final basura = s.recibir(0, const Mensaje(TipoMensaje.action, {'tipo': 'volar'}));
      expect(basura.keys, [0]);
      expect(basura[0]!.single.payload['codigo'], 'accion_invalida');
    });

    test('acciones antes de iniciar dan error', () {
      final s = sala()..unirse('Ana');
      final r = s.recibir(0, const Mensaje(TipoMensaje.action, {'tipo': 'truco'}));
      expect(r[0]!.single.payload['codigo'], 'no_iniciada');
    });

    test('reconectar con el token devuelve el asiento y el estado actual', () {
      final s = sala();
      s.unirse('Ana');
      final b = s.unirse('Beto')!;
      final token = s.saludo(b)[b]!.first.payload['token'] as String;
      s.iniciar();
      expect(s.reconectar('token-falso'), isNull);
      final asiento = s.reconectar(token);
      expect(asiento, b);
      expect(tipos(s.saludo(asiento!)[asiento]!), ['welcome', 'state']);
    });
  });
}

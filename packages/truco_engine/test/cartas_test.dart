import 'package:test/test.dart';
import 'package:truco_engine/truco_engine.dart';

Carta c(Palo palo, int n) => Carta(palo, n);

void main() {
  group('baraja', () {
    test('tiene 40 cartas distintas, sin 8 ni 9', () {
      final b = baraja();
      expect(b, hasLength(40));
      expect(b.toSet(), hasLength(40));
      expect(b.any((x) => x.numero == 8 || x.numero == 9), isFalse);
    });
  });

  group('jerarquía del truco', () {
    test('respeta el orden real de mayor a menor', () {
      final orden = [
        c(Palo.espada, 1),
        c(Palo.basto, 1),
        c(Palo.espada, 7),
        c(Palo.oro, 7),
        c(Palo.copa, 3),
        c(Palo.copa, 2),
        c(Palo.copa, 1),
        c(Palo.copa, 12),
        c(Palo.copa, 11),
        c(Palo.copa, 10),
        c(Palo.copa, 7),
        c(Palo.copa, 6),
        c(Palo.copa, 5),
        c(Palo.copa, 4),
      ];
      final j = [for (final x in orden) x.jerarquia];
      for (var i = 0; i < j.length - 1; i++) {
        expect(j[i], greaterThan(j[i + 1]), reason: '${orden[i]} > ${orden[i + 1]}');
      }
    });

    test('cartas equivalentes empatan', () {
      expect(c(Palo.oro, 1).jerarquia, c(Palo.copa, 1).jerarquia);
      expect(c(Palo.copa, 7).jerarquia, c(Palo.basto, 7).jerarquia);
      for (final n in [2, 3, 4, 5, 6, 10, 11, 12]) {
        final js = {for (final p in Palo.values) c(p, n).jerarquia};
        expect(js, hasLength(1), reason: 'el $n');
      }
    });
  });

  group('envido', () {
    test('dos del mismo palo suman 20 más los valores', () {
      expect(puntosEnvido([c(Palo.espada, 7), c(Palo.espada, 6), c(Palo.basto, 1)]), 33);
    });

    test('las figuras valen 0', () {
      expect(puntosEnvido([c(Palo.oro, 12), c(Palo.oro, 11), c(Palo.copa, 1)]), 20);
      expect(puntosEnvido([c(Palo.oro, 12), c(Palo.oro, 5), c(Palo.copa, 1)]), 25);
    });

    test('sin palo repetido vale la carta más alta', () {
      expect(puntosEnvido([c(Palo.oro, 7), c(Palo.copa, 5), c(Palo.basto, 4)]), 7);
      expect(puntosEnvido([c(Palo.oro, 12), c(Palo.copa, 11), c(Palo.basto, 10)]), 0);
    });

    test('con tres del mismo palo toma las dos mejores', () {
      expect(puntosEnvido([c(Palo.oro, 7), c(Palo.oro, 6), c(Palo.oro, 5)]), 33);
    });
  });

  group('serialización', () {
    test('Carta y Accion hacen ida y vuelta', () {
      final carta = c(Palo.basto, 10);
      expect(Carta.fromJson(carta.toJson()), carta);
      final a = Accion.jugarCarta(carta);
      expect(Accion.fromJson(a.toJson()), a);
      expect(Accion.fromJson(const Accion(TipoAccion.truco).toJson()),
          const Accion(TipoAccion.truco));
    });

    test('rechaza cartas y acciones inválidas', () {
      expect(() => Carta.fromJson({'palo': 'oro', 'numero': 8}), throwsFormatException);
      expect(() => Carta.fromJson({'palo': 'x', 'numero': 1}), throwsFormatException);
      expect(() => Accion.fromJson({'tipo': 'volar'}), throwsFormatException);
      expect(() => Accion.fromJson({'tipo': 'jugarCarta'}), throwsFormatException);
    });
  });
}

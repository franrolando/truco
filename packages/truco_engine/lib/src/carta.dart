/// Palos de la baraja española.
enum Palo { espada, basto, oro, copa }

/// Una carta de la baraja de 40 (sin 8 ni 9).
class Carta {
  final Palo palo;
  final int numero;

  const Carta(this.palo, this.numero)
      : assert(
          numero >= 1 && numero <= 12 && numero != 8 && numero != 9,
          'Número de carta inválido',
        );

  /// Números que existen en la baraja española de 40.
  static const numeros = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12];

  /// Fuerza de la carta para ganar una baza (más alto = más fuerte).
  ///
  /// Orden real del truco: 1 espada, 1 basto, 7 espada, 7 oro, los 3, los 2,
  /// 1 copa y 1 oro, los 12, 11, 10, 7 copa y 7 basto, 6, 5 y 4.
  int get jerarquia {
    if (numero == 1 && palo == Palo.espada) return 14;
    if (numero == 1 && palo == Palo.basto) return 13;
    if (numero == 7 && palo == Palo.espada) return 12;
    if (numero == 7 && palo == Palo.oro) return 11;
    switch (numero) {
      case 3:
        return 10;
      case 2:
        return 9;
      case 1: // copa u oro
        return 8;
      case 12:
        return 7;
      case 11:
        return 6;
      case 10:
        return 5;
      case 7: // copa o basto
        return 4;
      case 6:
        return 3;
      case 5:
        return 2;
      default: // 4
        return 1;
    }
  }

  /// Valor de la carta para el envido: las figuras (10, 11, 12) valen 0.
  int get valorEnvido => numero < 10 ? numero : 0;

  Map<String, dynamic> toJson() => {'palo': palo.name, 'numero': numero};

  factory Carta.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Carta inválida');
    }
    final paloNombre = json['palo'];
    final numero = json['numero'];
    final palo = Palo.values.where((p) => p.name == paloNombre).firstOrNull;
    if (palo == null || numero is! int || !numeros.contains(numero)) {
      throw const FormatException('Carta inválida');
    }
    return Carta(palo, numero);
  }

  @override
  bool operator ==(Object other) =>
      other is Carta && other.palo == palo && other.numero == numero;

  @override
  int get hashCode => Object.hash(palo, numero);

  @override
  String toString() => '$numero de ${palo.name}';
}

/// La baraja completa ordenada (40 cartas).
List<Carta> baraja() => [
      for (final palo in Palo.values)
        for (final n in Carta.numeros) Carta(palo, n),
    ];

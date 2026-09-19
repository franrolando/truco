import 'carta.dart';

enum TipoAccion {
  jugarCarta,
  envido,
  realEnvido,
  faltaEnvido,
  truco,
  retruco,
  valeCuatro,
  quiero,
  noQuiero,
  irseAlMazo,
}

/// Intención de un jugador. Los clientes mandan esto, nunca estado.
class Accion {
  final TipoAccion tipo;

  /// Solo para [TipoAccion.jugarCarta].
  final Carta? carta;

  const Accion(this.tipo, [this.carta]);

  const Accion.jugarCarta(Carta this.carta) : tipo = TipoAccion.jugarCarta;

  Map<String, dynamic> toJson() => {
        'tipo': tipo.name,
        if (carta != null) 'carta': carta!.toJson(),
      };

  factory Accion.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Acción inválida');
    }
    final tipo =
        TipoAccion.values.where((t) => t.name == json['tipo']).firstOrNull;
    if (tipo == null) throw const FormatException('Acción inválida');
    if (tipo == TipoAccion.jugarCarta) {
      return Accion.jugarCarta(Carta.fromJson(json['carta']));
    }
    return Accion(tipo);
  }

  @override
  bool operator ==(Object other) =>
      other is Accion && other.tipo == tipo && other.carta == carta;

  @override
  int get hashCode => Object.hash(tipo, carta);

  @override
  String toString() => carta == null ? tipo.name : '${tipo.name}($carta)';
}

/// Se lanza cuando un jugador intenta algo que las reglas no permiten ahora.
/// El estado de la partida no se modifica.
class AccionIlegal implements Exception {
  final String motivo;
  const AccionIlegal(this.motivo);

  @override
  String toString() => 'AccionIlegal: $motivo';
}

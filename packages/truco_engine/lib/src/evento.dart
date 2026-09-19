enum TipoEvento {
  manoRepartida,
  cartaJugada,
  bazaResuelta,
  cantoTruco,
  respuestaTruco,
  cantoEnvido,
  respuestaEnvido,
  envidoResuelto,
  irseAlMazo,
  manoTerminada,
  juegoTerminado,
}

/// Algo que pasó en la mesa y que ven todos los jugadores.
///
/// Nunca incluye cartas que sigan en mano de alguien: las cartas propias
/// viajan por separado en la vista de cada jugador.
class Evento {
  final TipoEvento tipo;
  final Map<String, dynamic> datos;

  const Evento(this.tipo, [this.datos = const {}]);

  Map<String, dynamic> toJson() => {'tipo': tipo.name, 'datos': datos};

  @override
  String toString() => 'Evento(${tipo.name}, $datos)';
}

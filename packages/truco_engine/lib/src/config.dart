/// Configuración de una partida.
///
/// Los asientos se alternan por equipo: par = equipo 0, impar = equipo 1.
class TrucoConfig {
  /// Cantidad de jugadores: 2, 4 o 6.
  final int jugadores;

  /// Puntos para ganar: 15 o 30.
  final int puntosObjetivo;

  /// Asiento que es mano en la primera mano; después rota.
  final int primerMano;

  const TrucoConfig({
    this.jugadores = 2,
    this.puntosObjetivo = 15,
    this.primerMano = 0,
  })  : assert(jugadores == 2 || jugadores == 4 || jugadores == 6),
        assert(puntosObjetivo == 15 || puntosObjetivo == 30),
        assert(primerMano >= 0 && primerMano < jugadores);

  Map<String, dynamic> toJson() => {
        'jugadores': jugadores,
        'puntosObjetivo': puntosObjetivo,
        'primerMano': primerMano,
      };

  factory TrucoConfig.fromJson(Map<String, dynamic> json) {
    final j = json['jugadores'];
    final p = json['puntosObjetivo'];
    final m = json['primerMano'] ?? 0;
    if (j is! int || p is! int || m is! int) {
      throw const FormatException('Configuración inválida');
    }
    if (!(j == 2 || j == 4 || j == 6) ||
        !(p == 15 || p == 30) ||
        m < 0 ||
        m >= j) {
      throw const FormatException('Configuración inválida');
    }
    return TrucoConfig(jugadores: j, puntosObjetivo: p, primerMano: m);
  }
}

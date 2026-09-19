import 'package:truco_engine/truco_engine.dart';

class JugadaVista {
  final int asiento;
  final Carta carta;
  const JugadaVista(this.asiento, this.carta);
}

class BazaVista {
  final List<JugadaVista> jugadas;

  /// -1 = parda; 0 o 1 = equipo ganador.
  final int resultado;
  const BazaVista(this.jugadas, this.resultado);
}

/// Lo que ve un jugador de la mesa: el `Map` de `TrucoGame.vistaPara` (o del
/// mensaje `state` del protocolo) ya tipado. La UI solo lee esto.
class VistaMesa {
  final int asiento;
  final int equipo;
  final List<Carta> tusCartas;
  final List<int> cartasRestantes;
  final List<int> puntos;
  final int objetivo;
  final int mano;
  final int? actua;
  final List<JugadaVista> bazaActual;
  final List<BazaVista> bazas;
  final int nivelTruco;
  final ({int nivel, int cantor})? trucoPendiente;
  final ({List<String> cantos, int cantor})? envidoPendiente;
  final List<Accion> acciones;
  final bool terminado;
  final int? equipoGanador;

  const VistaMesa({
    required this.asiento,
    required this.equipo,
    required this.tusCartas,
    required this.cartasRestantes,
    required this.puntos,
    required this.objetivo,
    required this.mano,
    required this.actua,
    required this.bazaActual,
    required this.bazas,
    required this.nivelTruco,
    required this.trucoPendiente,
    required this.envidoPendiente,
    required this.acciones,
    required this.terminado,
    required this.equipoGanador,
  });

  factory VistaMesa.fromJson(Map<String, dynamic> j) {
    final truco = j['trucoPendiente'] as Map<String, dynamic>?;
    final envido = j['envidoPendiente'] as Map<String, dynamic>?;
    return VistaMesa(
      asiento: j['asiento'] as int,
      equipo: j['equipo'] as int,
      tusCartas: [for (final c in _lista(j['tusCartas'])) Carta.fromJson(c)],
      cartasRestantes: _ints(j['cartasRestantes']),
      puntos: _ints(j['puntos']),
      objetivo: j['objetivo'] as int,
      mano: j['mano'] as int,
      actua: j['actua'] as int?,
      bazaActual: _jugadas(j['bazaActual']),
      bazas: [
        for (final b in _lista(j['bazas']))
          BazaVista(
            _jugadas((b as Map<String, dynamic>)['jugadas']),
            b['resultado'] as int,
          ),
      ],
      nivelTruco: j['nivelTruco'] as int,
      trucoPendiente: truco == null
          ? null
          : (nivel: truco['nivel'] as int, cantor: truco['cantor'] as int),
      envidoPendiente: envido == null
          ? null
          : (
              cantos: [for (final c in _lista(envido['cantos'])) c as String],
              cantor: envido['cantor'] as int,
            ),
      acciones: [for (final a in _lista(j['acciones'])) Accion.fromJson(a)],
      terminado: j['terminado'] as bool,
      equipoGanador: j['equipoGanador'] as int?,
    );
  }

  bool puede(TipoAccion tipo) => acciones.any((a) => a.tipo == tipo);
  bool puedeJugar(Carta carta) => acciones.contains(Accion.jugarCarta(carta));

  static List<Object?> _lista(Object? o) => o as List<Object?>;
  static List<int> _ints(Object? o) => [for (final e in _lista(o)) e as int];
  static List<JugadaVista> _jugadas(Object? o) => [
        for (final e in _lista(o))
          JugadaVista(
            (e as Map<String, dynamic>)['asiento'] as int,
            Carta.fromJson(e['carta']),
          ),
      ];
}

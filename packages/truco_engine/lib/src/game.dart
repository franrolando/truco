import 'dart:math';

import 'accion.dart';
import 'carta.dart';
import 'config.dart';
import 'envido.dart';
import 'evento.dart';

class _Jugada {
  final int asiento;
  final Carta carta;
  const _Jugada(this.asiento, this.carta);

  Map<String, dynamic> toJson() =>
      {'asiento': asiento, 'carta': carta.toJson()};
}

class _Baza {
  final List<_Jugada> jugadas = [];

  /// null mientras se juega; -1 = parda; 0 o 1 = equipo ganador.
  int? resultado;
}

class _CantoTruco {
  final int nivel; // 2 truco, 3 retruco, 4 vale cuatro
  final int cantor;
  const _CantoTruco(this.nivel, this.cantor);
}

class _CantoEnvido {
  final List<TipoAccion> cantos;
  int cantor;
  _CantoEnvido(TipoAccion primero, this.cantor) : cantos = [primero];
}

/// Máquina de estados del Truco. Es la única que conoce las reglas.
///
/// Los jugadores se identifican por asiento (0..jugadores-1). Los asientos
/// pares son el equipo 0 y los impares el equipo 1.
class TrucoGame {
  final TrucoConfig config;
  final Random _random;

  final List<int> _puntos = [0, 0];
  int _mano;
  late List<List<Carta>> _original; // las 3 cartas repartidas (para el envido)
  late List<List<Carta>> _enMano; // las que todavía no se jugaron
  late List<_Baza> _bazas; // bazas cerradas
  late _Baza _actual;
  late int _turno;

  int _nivelTruco = 1; // puntos en juego por las cartas
  int? _equipoQueQuiso; // único equipo que puede subir el truco
  _CantoTruco? _trucoPendiente;
  _CantoEnvido? _envidoPendiente;
  bool _envidoCerrado = false;

  bool _terminado = false;
  int? _equipoGanador;

  TrucoGame(
    this.config, {
    Random? random,
    List<List<Carta>>? manosIniciales,
  })  : _random = random ?? Random(),
        _mano = config.primerMano {
    _repartir(manosIniciales);
  }

  int get _n => config.jugadores;
  int _sig(int asiento) => (asiento + 1) % _n;

  /// Equipo (0 o 1) de un asiento.
  int equipoDe(int asiento) => asiento % 2;

  bool get juegoTerminado => _terminado;
  int? get equipoGanador => _equipoGanador;
  List<int> get puntos => List.unmodifiable(_puntos);
  int get mano => _mano;
  int get nivelTruco => _nivelTruco;

  /// Evento con el que arranca la primera mano (las siguientes llegan dentro
  /// de los eventos de [aplicar]).
  Evento get eventoInicio => _eventoManoRepartida();

  /// Asiento al que le toca decidir ahora, o null si el juego terminó.
  int? get asientoQueActua {
    if (_terminado) return null;
    final envido = _envidoPendiente;
    if (envido != null) return _sig(envido.cantor);
    final truco = _trucoPendiente;
    if (truco != null) return _sig(truco.cantor);
    return _turno;
  }

  // ---------------------------------------------------------------- reparto

  void _repartir(List<List<Carta>>? manos) {
    if (manos != null) {
      if (manos.length != _n) {
        throw ArgumentError('Se esperaban $_n manos');
      }
    } else {
      final mazo = baraja()..shuffle(_random);
      manos = [
        for (var i = 0; i < _n; i++) mazo.sublist(i * 3, i * 3 + 3),
      ];
    }
    _original = [for (final m in manos) List.of(m)];
    _enMano = [for (final m in manos) List.of(m)];
    _bazas = [];
    _actual = _Baza();
    _turno = _mano;
    _nivelTruco = 1;
    _equipoQueQuiso = null;
    _trucoPendiente = null;
    _envidoPendiente = null;
    _envidoCerrado = false;
  }

  Evento _eventoManoRepartida() =>
      Evento(TipoEvento.manoRepartida, {'mano': _mano});

  // ------------------------------------------------------- acciones válidas

  bool get _envidoDisponible =>
      !_envidoCerrado &&
      _bazas.isEmpty &&
      _nivelTruco == 1 &&
      (_trucoPendiente == null || _trucoPendiente!.nivel == 2);

  static const _envidoInicial = [
    TipoAccion.envido,
    TipoAccion.realEnvido,
    TipoAccion.faltaEnvido,
  ];

  /// Qué se puede cantar encima de una cadena de envidos ya cantada.
  List<TipoAccion> _envidosSiguientes(List<TipoAccion> cantos) {
    final ultimo = cantos.last;
    if (ultimo == TipoAccion.faltaEnvido) return const [];
    if (ultimo == TipoAccion.realEnvido) return const [TipoAccion.faltaEnvido];
    final envidos = cantos.where((c) => c == TipoAccion.envido).length;
    return [
      if (envidos < 2) TipoAccion.envido,
      TipoAccion.realEnvido,
      TipoAccion.faltaEnvido,
    ];
  }

  static TipoAccion? _cantoDeTruco(int nivelActual) => switch (nivelActual) {
        1 => TipoAccion.truco,
        2 => TipoAccion.retruco,
        3 => TipoAccion.valeCuatro,
        _ => null,
      };

  static int _nivelDe(TipoAccion t) => switch (t) {
        TipoAccion.truco => 2,
        TipoAccion.retruco => 3,
        TipoAccion.valeCuatro => 4,
        _ => throw ArgumentError('No es un canto de truco'),
      };

  /// Lo que [asiento] puede hacer ahora mismo (vacío si no le toca).
  List<Accion> accionesPermitidas(int asiento) {
    _validarAsiento(asiento);
    if (_terminado || asiento != asientoQueActua) return const [];

    final envido = _envidoPendiente;
    if (envido != null) {
      return [
        const Accion(TipoAccion.quiero),
        const Accion(TipoAccion.noQuiero),
        for (final t in _envidosSiguientes(envido.cantos)) Accion(t),
      ];
    }

    final truco = _trucoPendiente;
    if (truco != null) {
      final subir = _cantoDeTruco(truco.nivel);
      return [
        const Accion(TipoAccion.quiero),
        const Accion(TipoAccion.noQuiero),
        if (subir != null) Accion(subir),
        if (_envidoDisponible)
          for (final t in _envidoInicial) Accion(t),
      ];
    }

    final cantoTruco = _cantoDeTruco(_nivelTruco);
    final puedeCantarTruco = cantoTruco != null &&
        (_nivelTruco == 1 || equipoDe(asiento) == _equipoQueQuiso);
    return [
      for (final c in _enMano[asiento].toSet()) Accion.jugarCarta(c),
      if (puedeCantarTruco) Accion(cantoTruco),
      if (_envidoDisponible)
        for (final t in _envidoInicial) Accion(t),
      const Accion(TipoAccion.irseAlMazo),
    ];
  }

  void _validarAsiento(int asiento) {
    if (asiento < 0 || asiento >= _n) {
      throw RangeError('Asiento inexistente: $asiento');
    }
  }

  // ---------------------------------------------------------------- aplicar

  /// Aplica una acción y devuelve los eventos públicos que produjo.
  /// Si es ilegal lanza [AccionIlegal] sin tocar el estado.
  List<Evento> aplicar(int asiento, Accion accion) {
    if (asiento < 0 || asiento >= _n) {
      throw const AccionIlegal('Asiento inexistente');
    }
    if (_terminado) throw const AccionIlegal('La partida ya terminó');
    if (!accionesPermitidas(asiento).contains(accion)) {
      throw AccionIlegal(
        asiento == asientoQueActua
            ? 'No podés hacer eso ahora: $accion'
            : 'No es tu turno',
      );
    }

    final ev = <Evento>[];
    switch (accion.tipo) {
      case TipoAccion.jugarCarta:
        _jugarCarta(asiento, accion.carta!, ev);
      case TipoAccion.envido:
      case TipoAccion.realEnvido:
      case TipoAccion.faltaEnvido:
        _cantarEnvido(asiento, accion.tipo, ev);
      case TipoAccion.truco:
      case TipoAccion.retruco:
      case TipoAccion.valeCuatro:
        _cantarTruco(asiento, accion.tipo, ev);
      case TipoAccion.quiero:
        if (_envidoPendiente != null) {
          _responderEnvido(asiento, true, ev);
        } else {
          _responderTruco(asiento, true, ev);
        }
      case TipoAccion.noQuiero:
        if (_envidoPendiente != null) {
          _responderEnvido(asiento, false, ev);
        } else {
          _responderTruco(asiento, false, ev);
        }
      case TipoAccion.irseAlMazo:
        ev.add(Evento(TipoEvento.irseAlMazo, {
          'asiento': asiento,
          'equipo': equipoDe(asiento),
        }));
        _terminarMano(1 - equipoDe(asiento), _nivelTruco, ev);
    }
    return ev;
  }

  // ------------------------------------------------------------------ cartas

  void _jugarCarta(int asiento, Carta carta, List<Evento> ev) {
    _enMano[asiento].remove(carta);
    _actual.jugadas.add(_Jugada(asiento, carta));
    ev.add(Evento(TipoEvento.cartaJugada, {
      'asiento': asiento,
      'carta': carta.toJson(),
    }));
    if (_actual.jugadas.length < _n) {
      _turno = _sig(asiento);
      return;
    }
    _cerrarBaza(ev);
  }

  void _cerrarBaza(List<Evento> ev) {
    final mejor =
        _actual.jugadas.map((j) => j.carta.jerarquia).reduce(max);
    final tope =
        _actual.jugadas.where((j) => j.carta.jerarquia == mejor).toList();
    final equipos = tope.map((j) => equipoDe(j.asiento)).toSet();

    final int lider;
    if (equipos.length > 1) {
      _actual.resultado = -1; // parda: empieza el mano de la mano
      lider = _mano;
    } else {
      _actual.resultado = equipos.first;
      lider = tope.first.asiento;
    }
    _bazas.add(_actual);
    ev.add(Evento(TipoEvento.bazaResuelta, {
      'resultado': _actual.resultado,
      if (_actual.resultado != -1) 'asiento': lider,
    }));

    final ganador = _ganadorDeMano();
    if (ganador != null) {
      _terminarMano(ganador, _nivelTruco, ev);
    } else {
      _actual = _Baza();
      _turno = lider;
    }
  }

  /// Equipo que ganó la mano por las bazas jugadas, o null si sigue abierta.
  int? _ganadorDeMano() {
    final r = [for (final b in _bazas) b.resultado!];
    if (r.length == 2) {
      if (r[0] != -1 && (r[1] == -1 || r[1] == r[0])) return r[0];
      if (r[0] == -1 && r[1] != -1) return r[1];
      return null;
    }
    if (r.length == 3) {
      if (r[2] != -1) return r[2];
      if (r[0] != -1) return r[0];
      return equipoDe(_mano);
    }
    return null;
  }

  // ------------------------------------------------------------------- truco

  void _cantarTruco(int asiento, TipoAccion canto, List<Evento> ev) {
    final previo = _trucoPendiente;
    if (previo != null) {
      // Subir en la respuesta equivale a decir "quiero" al canto anterior.
      _nivelTruco = previo.nivel;
      _equipoQueQuiso = equipoDe(asiento);
    }
    _trucoPendiente = _CantoTruco(_nivelDe(canto), asiento);
    ev.add(Evento(TipoEvento.cantoTruco, {
      'asiento': asiento,
      'canto': canto.name,
      'nivel': _nivelDe(canto),
    }));
  }

  void _responderTruco(int asiento, bool quiero, List<Evento> ev) {
    final pendiente = _trucoPendiente!;
    ev.add(Evento(TipoEvento.respuestaTruco, {
      'asiento': asiento,
      'quiero': quiero,
    }));
    if (quiero) {
      _nivelTruco = pendiente.nivel;
      _equipoQueQuiso = equipoDe(asiento);
      _trucoPendiente = null;
    } else {
      _terminarMano(equipoDe(pendiente.cantor), _nivelTruco, ev);
    }
  }

  // ------------------------------------------------------------------ envido

  int get _puntosFalta => max(1, config.puntosObjetivo - _puntos.reduce(max));

  int _valorCanto(TipoAccion t) => switch (t) {
        TipoAccion.envido => 2,
        TipoAccion.realEnvido => 3,
        _ => _puntosFalta,
      };

  void _cantarEnvido(int asiento, TipoAccion canto, List<Evento> ev) {
    final actual = _envidoPendiente;
    if (actual == null) {
      _envidoPendiente = _CantoEnvido(canto, asiento);
    } else {
      actual.cantos.add(canto);
      actual.cantor = asiento;
    }
    ev.add(Evento(TipoEvento.cantoEnvido, {
      'asiento': asiento,
      'canto': canto.name,
    }));
  }

  void _responderEnvido(int asiento, bool quiero, List<Evento> ev) {
    final envido = _envidoPendiente!;
    _envidoPendiente = null;
    _envidoCerrado = true;

    if (!quiero) {
      // Se cobra lo cantado antes del último aumento (mínimo 1).
      final previos = envido.cantos.sublist(0, envido.cantos.length - 1);
      final pts = previos.isEmpty
          ? 1
          : previos.map(_valorCanto).reduce((a, b) => a + b);
      final equipo = equipoDe(envido.cantor);
      ev.add(Evento(TipoEvento.respuestaEnvido, {
        'asiento': asiento,
        'quiero': false,
        'equipo': equipo,
        'puntos': pts,
      }));
      _puntos[equipo] += pts;
      _verificarFin(equipo, ev);
      return;
    }

    ev.add(Evento(TipoEvento.respuestaEnvido, {
      'asiento': asiento,
      'quiero': true,
    }));
    // Una falta en la cadena reemplaza el valor de lo anterior.
    final pts = envido.cantos.contains(TipoAccion.faltaEnvido)
        ? _puntosFalta
        : envido.cantos.map(_valorCanto).reduce((a, b) => a + b);

    // Gana el más alto; en empate, el más cercano al mano.
    final valores = [for (final m in _original) puntosEnvido(m)];
    final orden = List.generate(_n, (i) => i)
      ..sort((a, b) {
        final porPuntos = valores[b].compareTo(valores[a]);
        if (porPuntos != 0) return porPuntos;
        return ((a - _mano) % _n).compareTo((b - _mano) % _n);
      });
    final ganador = orden.first;
    final equipo = equipoDe(ganador);
    ev.add(Evento(TipoEvento.envidoResuelto, {
      'asiento': ganador,
      'equipo': equipo,
      'envido': valores[ganador],
      'puntos': pts,
    }));
    _puntos[equipo] += pts;
    _verificarFin(equipo, ev);
  }

  // -------------------------------------------------------------- fin de mano

  bool _verificarFin(int equipo, List<Evento> ev) {
    if (_puntos[equipo] < config.puntosObjetivo) return false;
    _terminado = true;
    _equipoGanador = equipo;
    _envidoPendiente = null;
    _trucoPendiente = null;
    ev.add(Evento(TipoEvento.juegoTerminado, {
      'equipo': equipo,
      'puntos': List.of(_puntos),
    }));
    return true;
  }

  void _terminarMano(int equipo, int pts, List<Evento> ev) {
    _puntos[equipo] += pts;
    ev.add(Evento(TipoEvento.manoTerminada, {
      'equipo': equipo,
      'puntos': pts,
      'marcador': List.of(_puntos),
    }));
    if (_verificarFin(equipo, ev)) return;
    _mano = _sig(_mano);
    _repartir(null);
    ev.add(_eventoManoRepartida());
  }

  // -------------------------------------------------------------------- vista

  /// Lo único que sale hacia un jugador: sus cartas y el estado público.
  Map<String, dynamic> vistaPara(int asiento) {
    _validarAsiento(asiento);
    final truco = _trucoPendiente;
    final envido = _envidoPendiente;
    return {
      'asiento': asiento,
      'equipo': equipoDe(asiento),
      'tusCartas': [for (final c in _enMano[asiento]) c.toJson()],
      'cartasRestantes': [for (final m in _enMano) m.length],
      'puntos': List.of(_puntos),
      'objetivo': config.puntosObjetivo,
      'mano': _mano,
      'actua': asientoQueActua,
      'bazaActual': [for (final j in _actual.jugadas) j.toJson()],
      'bazas': [
        for (final b in _bazas)
          {
            'jugadas': [for (final j in b.jugadas) j.toJson()],
            'resultado': b.resultado,
          },
      ],
      'nivelTruco': _nivelTruco,
      'trucoPendiente':
          truco == null ? null : {'nivel': truco.nivel, 'cantor': truco.cantor},
      'envidoPendiente': envido == null
          ? null
          : {
              'cantos': [for (final c in envido.cantos) c.name],
              'cantor': envido.cantor,
            },
      'acciones': [
        for (final a in accionesPermitidas(asiento)) a.toJson(),
      ],
      'terminado': _terminado,
      'equipoGanador': _equipoGanador,
    };
  }
}

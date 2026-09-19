import 'dart:math';

import 'accion.dart';
import 'config.dart';
import 'game.dart';
import 'protocolo.dart';

class _Jugador {
  final String nombre;
  final String token;
  _Jugador(this.nombre, this.token);
}

/// Sala del host: arma la mesa y reparte los mensajes por asiento.
///
/// No conoce el transporte. Cada método devuelve `Map<asiento, mensajes>`:
/// lo que hay que mandar a cada jugador. Los errores van solo a quien los causó.
class SalaHost {
  final TrucoConfig config;
  final Random _random;
  final List<_Jugador> _jugadores = [];
  TrucoGame? _game;

  SalaHost(this.config, {Random? random})
      : _random = random ?? Random.secure();

  bool get iniciada => _game != null;
  bool get completa => _jugadores.length == config.jugadores;
  bool get puedeIniciar => !iniciada && completa;
  int get cantidadJugadores => _jugadores.length;
  TrucoGame? get partida => _game;

  /// Suma un jugador y devuelve su asiento, o null si la sala está llena o la
  /// partida ya empezó.
  int? unirse(String nombre) {
    if (iniciada || completa) return null;
    final limpio = nombre.trim();
    final asiento = _jugadores.length;
    _jugadores.add(_Jugador(
      limpio.isEmpty ? 'Jugador ${asiento + 1}' : limpio,
      _nuevoToken(),
    ));
    return asiento;
  }

  /// Devuelve el asiento que le corresponde a un token, o null si no existe.
  /// Sirve para volver a entrar después de perder la conexión.
  int? reconectar(String token) {
    final i = _jugadores.indexWhere((j) => j.token == token);
    return i < 0 ? null : i;
  }

  /// Saludo para quien acaba de entrar (o volver): su `welcome` más la foto
  /// actual, que es el lobby para todos o el estado de la partida.
  Map<int, List<Mensaje>> saludo(int asiento) {
    final j = _jugadores[asiento];
    final welcome = Mensaje(TipoMensaje.welcome, {
      'asiento': asiento,
      'nombre': j.nombre,
      'token': j.token,
      'config': config.toJson(),
    });
    if (iniciada) {
      return {
        asiento: [welcome, _estado(asiento)],
      };
    }
    return {
      for (var s = 0; s < _jugadores.length; s++)
        s: [if (s == asiento) welcome, _lobby()],
    };
  }

  /// Arranca la partida y manda a cada jugador su mano.
  Map<int, List<Mensaje>> iniciar() {
    if (!puedeIniciar) {
      throw StateError('La sala tiene que estar completa y sin iniciar');
    }
    final game = _game = TrucoGame(config, random: _random);
    final eventos = Mensaje(TipoMensaje.events, {
      'eventos': [game.eventoInicio.toJson()],
    });
    return {
      for (var s = 0; s < _jugadores.length; s++) s: [eventos, _estado(s)],
    };
  }

  /// Procesa un mensaje de un jugador ya sentado.
  Map<int, List<Mensaje>> recibir(int asiento, Mensaje mensaje) {
    switch (mensaje.type) {
      case TipoMensaje.action:
        return _recibirAccion(asiento, mensaje);
      case TipoMensaje.join:
      case TipoMensaje.rejoin:
        return _error(asiento, 'ya_en_sala', 'Ya estás en la sala');
      default:
        return _error(asiento, 'mensaje_desconocido',
            'Mensaje desconocido: ${mensaje.type}');
    }
  }

  Map<int, List<Mensaje>> _recibirAccion(int asiento, Mensaje mensaje) {
    final game = _game;
    if (game == null) {
      return _error(asiento, 'no_iniciada', 'La partida todavía no empezó');
    }
    try {
      final accion = Accion.fromJson(mensaje.payload);
      final eventos = game.aplicar(asiento, accion);
      final publico = Mensaje(TipoMensaje.events, {
        'eventos': [for (final e in eventos) e.toJson()],
      });
      return {
        for (var s = 0; s < _jugadores.length; s++) s: [publico, _estado(s)],
      };
    } on AccionIlegal catch (e) {
      return _error(asiento, 'accion_ilegal', e.motivo);
    } on FormatException catch (e) {
      return _error(asiento, 'accion_invalida', e.message);
    }
  }

  Mensaje _estado(int asiento) =>
      Mensaje(TipoMensaje.state, _game!.vistaPara(asiento));

  Mensaje _lobby() => Mensaje(TipoMensaje.lobby, {
        'jugadores': [for (final j in _jugadores) j.nombre],
        'capacidad': config.jugadores,
        'puedeIniciar': puedeIniciar,
      });

  Map<int, List<Mensaje>> _error(int asiento, String codigo, String texto) => {
        asiento: [
          Mensaje(TipoMensaje.error, {'codigo': codigo, 'mensaje': texto}),
        ],
      };

  String _nuevoToken() => List.generate(
        16,
        (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
}

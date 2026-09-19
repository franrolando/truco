import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:truco_engine/truco_engine.dart';

import 'vista_mesa.dart';

/// Partida de una persona contra un bot, sin red.
///
/// La UI no decide reglas: muestra [vista] y llama a [jugar] con una [Accion].
/// El motor valida todo; el bot solo elige entre lo que el motor le permite.
class PartidaLocal extends ChangeNotifier {
  static const humano = 0;
  static const bot = 1;

  final TrucoGame _game;
  final Random _random;

  /// Pausa antes de cada jugada del bot, para que se note. En tests va en cero.
  final Duration pausaBot;

  final List<String> _registro = [];
  bool _pensando = false;
  bool _cerrada = false;
  String? _error;

  PartidaLocal({
    TrucoConfig config = const TrucoConfig(),
    Random? random,
    this.pausaBot = const Duration(milliseconds: 900),
  })  : _random = random ?? Random(),
        _game = TrucoGame(config, random: random) {
    _registrar([_game.eventoInicio]);
  }

  VistaMesa get vista => VistaMesa.fromJson(_game.vistaPara(humano));

  /// Últimas cosas que pasaron, de la más vieja a la más nueva.
  List<String> get registro => List.unmodifiable(_registro);

  bool get pensando => _pensando;
  bool get terminada => _game.juegoTerminado;

  /// Motivo del último intento ilegal del humano, si lo hubo.
  String? get error => _error;

  /// Arranca la partida: si el bot es mano, juega primero.
  Future<void> iniciar() => _turnosDelBot();

  /// Aplica una acción del humano y deja jugar al bot hasta que vuelva a tocarle.
  Future<void> jugar(Accion accion) async {
    if (_pensando || terminada || _cerrada) return;
    try {
      _registrar(_game.aplicar(humano, accion));
      _error = null;
    } on AccionIlegal catch (e) {
      _error = e.motivo;
      _notificar();
      return;
    }
    _notificar();
    await _turnosDelBot();
  }

  Future<void> _turnosDelBot() async {
    if (_pensando) return;
    _pensando = true;
    _notificar();
    try {
      while (!_cerrada &&
          !_game.juegoTerminado &&
          _game.asientoQueActua == bot) {
        await Future<void>.delayed(pausaBot);
        if (_cerrada) return;
        _registrar(_game.aplicar(bot, _elegirBot()));
        _notificar();
      }
    } finally {
      _pensando = false;
      _notificar();
    }
  }

  /// Bot simple: responde con criterio grueso y, si no hay nada pendiente,
  /// casi siempre juega carta; de vez en cuando canta.
  Accion _elegirBot() {
    final acciones = _game.accionesPermitidas(bot);
    Accion? de(TipoAccion t) =>
        acciones.where((a) => a.tipo == t).firstOrNull;
    final r = _random.nextDouble();

    if (de(TipoAccion.quiero) != null) {
      final subidas = [
        for (final a in acciones)
          if (a.tipo != TipoAccion.quiero && a.tipo != TipoAccion.noQuiero) a,
      ];
      if (subidas.isNotEmpty && r < 0.15) {
        return subidas[_random.nextInt(subidas.length)];
      }
      return r < 0.65 ? de(TipoAccion.quiero)! : de(TipoAccion.noQuiero)!;
    }

    final truco = de(TipoAccion.truco) ??
        de(TipoAccion.retruco) ??
        de(TipoAccion.valeCuatro);
    if (truco != null && r < 0.08) return truco;
    final envido = [
      for (final t in [
        TipoAccion.envido,
        TipoAccion.realEnvido,
        TipoAccion.faltaEnvido,
      ])
        if (de(t) != null) de(t)!,
    ];
    if (envido.isNotEmpty && r > 0.92) {
      return envido[_random.nextInt(envido.length)];
    }
    final cartas = [
      for (final a in acciones)
        if (a.tipo == TipoAccion.jugarCarta) a,
    ];
    return cartas[_random.nextInt(cartas.length)];
  }

  void _registrar(List<Evento> eventos) {
    for (final e in eventos) {
      final texto = _describir(e);
      if (texto != null) _registro.add(texto);
    }
    if (_registro.length > 60) _registro.removeRange(0, _registro.length - 60);
  }

  void _notificar() {
    if (!_cerrada) notifyListeners();
  }

  @override
  void dispose() {
    _cerrada = true;
    super.dispose();
  }
}

String _quien(Object? asiento, String vos, String bot) =>
    asiento == PartidaLocal.humano ? 'Vos $vos' : 'El bot $bot';

String _equipo(Object? equipo) => equipo == 0 ? 'vos' : 'el bot';

String _canto(Object? nombre) => switch (nombre) {
      'truco' => '¡Truco!',
      'retruco' => '¡Retruco!',
      'valeCuatro' => '¡Vale cuatro!',
      'envido' => '¡Envido!',
      'realEnvido' => '¡Real envido!',
      'faltaEnvido' => '¡Falta envido!',
      _ => '$nombre',
    };

String? _describir(Evento e) {
  final d = e.datos;
  switch (e.tipo) {
    case TipoEvento.manoRepartida:
      return 'Nueva mano. Es mano ${_equipo(d['mano'] == 0 ? 0 : 1)}';
    case TipoEvento.cartaJugada:
      return '${_quien(d['asiento'], 'jugaste', 'jugó')} '
          '${Carta.fromJson(d['carta'])}';
    case TipoEvento.bazaResuelta:
      return d['resultado'] == -1
          ? 'Parda'
          : 'Baza para ${_equipo(d['resultado'])}';
    case TipoEvento.cantoTruco:
    case TipoEvento.cantoEnvido:
      return '${_quien(d['asiento'], 'cantaste', 'cantó')} '
          '${_canto(d['canto'])}';
    case TipoEvento.respuestaTruco:
      return '${_quien(d['asiento'], 'dijiste', 'dijo')} '
          '${d['quiero'] == true ? 'quiero' : 'no quiero'}';
    case TipoEvento.respuestaEnvido:
      if (d['quiero'] == true) {
        return '${_quien(d['asiento'], 'dijiste', 'dijo')} quiero';
      }
      return '${_quien(d['asiento'], 'dijiste', 'dijo')} no quiero '
          '(+${d['puntos']} para ${_equipo(d['equipo'])})';
    case TipoEvento.envidoResuelto:
      return '${_quien(d['asiento'], 'ganaste', 'ganó')} el envido con '
          '${d['envido']} (+${d['puntos']})';
    case TipoEvento.irseAlMazo:
      return '${_quien(d['asiento'], 'te fuiste', 'se fue')} al mazo';
    case TipoEvento.manoTerminada:
      return 'Mano para ${_equipo(d['equipo'])}: +${d['puntos']}';
    case TipoEvento.juegoTerminado:
      return '¡Terminó la partida!';
  }
}

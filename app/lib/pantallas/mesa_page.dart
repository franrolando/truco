import 'package:flutter/material.dart';
import 'package:truco_engine/truco_engine.dart';

import '../juego/partida_local.dart';
import '../juego/vista_mesa.dart';
import '../widgets/carta_widget.dart';

/// Mesa contra un bot local. Solo muestra la vista y manda acciones.
class MesaPage extends StatefulWidget {
  /// Permite inyectar una partida (tests). Por defecto arma una nueva.
  final PartidaLocal? partida;

  const MesaPage({super.key, this.partida});

  @override
  State<MesaPage> createState() => _MesaPageState();
}

class _MesaPageState extends State<MesaPage> {
  late PartidaLocal _p;

  @override
  void initState() {
    super.initState();
    _p = widget.partida ?? PartidaLocal();
    _p.iniciar();
  }

  void _nueva() {
    final vieja = _p;
    setState(() => _p = PartidaLocal());
    _p.iniciar();
    vieja.dispose();
  }

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _p,
      builder: (context, _) {
        final v = _p.vista;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Truco'),
            actions: [
              IconButton(
                tooltip: 'Nueva partida',
                icon: const Icon(Icons.refresh),
                onPressed: _nueva,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _Marcador(vista: v),
                Expanded(child: _Mesa(vista: v, partida: _p, onNueva: _nueva)),
                _Registro(partida: _p),
                _Acciones(vista: v, partida: _p),
                _Mano(vista: v, partida: _p),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _nombre(int asiento) => asiento == PartidaLocal.humano ? 'Vos' : 'Bot';

class _Marcador extends StatelessWidget {
  final VistaMesa vista;
  const _Marcador({required this.vista});

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.titleLarge;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Vos ${vista.puntos[0]}', style: estilo),
              Text('a ${vista.objetivo}'),
              Text('Bot ${vista.puntos[1]}', style: estilo),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text('Mano: ${_nombre(vista.mano)}'),
                visualDensity: VisualDensity.compact,
              ),
              if (vista.nivelTruco > 1)
                Chip(
                  label: Text('Truco x${vista.nivelTruco}'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mesa extends StatelessWidget {
  final VistaMesa vista;
  final PartidaLocal partida;
  final VoidCallback onNueva;

  const _Mesa({
    required this.vista,
    required this.partida,
    required this.onNueva,
  });

  @override
  Widget build(BuildContext context) {
    final rival = vista.cartasRestantes[PartidaLocal.bot];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < rival; i++)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: DorsoWidget(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < vista.bazas.length; i++)
            _FilaBaza(
              titulo: 'Baza ${i + 1}',
              jugadas: vista.bazas[i].jugadas,
              detalle: switch (vista.bazas[i].resultado) {
                -1 => 'Parda',
                final e => e == vista.equipo ? 'Para vos' : 'Para el bot',
              },
            ),
          if (!vista.terminado)
            _FilaBaza(
              titulo: 'Baza ${vista.bazas.length + 1}',
              jugadas: vista.bazaActual,
              detalle: '',
              activa: true,
            ),
          if (vista.terminado) _FinDePartida(vista: vista, onNueva: onNueva),
        ],
      ),
    );
  }
}

class _FilaBaza extends StatelessWidget {
  final String titulo;
  final List<JugadaVista> jugadas;
  final String detalle;
  final bool activa;

  const _FilaBaza({
    required this.titulo,
    required this.jugadas,
    required this.detalle,
    this.activa = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: activa ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(width: 64, child: Text(titulo)),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: [
                  for (final j in jugadas)
                    Column(
                      children: [
                        CartaWidget(carta: j.carta),
                        Text(_nombre(j.asiento),
                            style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                ],
              ),
            ),
            Text(detalle),
          ],
        ),
      ),
    );
  }
}

class _FinDePartida extends StatelessWidget {
  final VistaMesa vista;
  final VoidCallback onNueva;

  const _FinDePartida({required this.vista, required this.onNueva});

  @override
  Widget build(BuildContext context) {
    final gane = vista.equipoGanador == vista.equipo;
    return Card(
      color: gane ? Colors.green.shade100 : Colors.red.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              gane ? '¡Ganaste!' : 'Ganó el bot',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onNueva, child: const Text('Jugar de nuevo')),
          ],
        ),
      ),
    );
  }
}

class _Registro extends StatelessWidget {
  final PartidaLocal partida;
  const _Registro({required this.partida});

  @override
  Widget build(BuildContext context) {
    final v = partida.vista;
    final ultimas = partida.registro.reversed.take(3).toList().reversed;
    final estado = partida.error ??
        switch ((v.terminado, v.actua == PartidaLocal.humano)) {
          (true, _) => '',
          (false, true) => v.trucoPendiente != null || v.envidoPendiente != null
              ? 'Te cantaron: respondé'
              : 'Tu turno',
          _ => 'Piensa el bot…',
        };
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in ultimas)
            Text(l, style: Theme.of(context).textTheme.bodySmall),
          if (estado.isNotEmpty)
            Text(
              estado,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

class _Acciones extends StatelessWidget {
  final VistaMesa vista;
  final PartidaLocal partida;

  const _Acciones({required this.vista, required this.partida});

  @override
  Widget build(BuildContext context) {
    Widget boton(String texto, Iterable<TipoAccion> tipos) {
      final accion = vista.acciones
          .where((a) => tipos.contains(a.tipo))
          .firstOrNull;
      return FilledButton.tonal(
        onPressed:
            accion == null || partida.pensando ? null : () => partida.jugar(accion),
        child: Text(texto),
      );
    }

    final tipoTruco = [
      TipoAccion.truco,
      TipoAccion.retruco,
      TipoAccion.valeCuatro,
    ].where(vista.puede).firstOrNull;
    final textoTruco = switch (tipoTruco) {
      TipoAccion.retruco => 'Retruco',
      TipoAccion.valeCuatro => 'Vale cuatro',
      _ => 'Truco',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: [
          boton(textoTruco, [tipoTruco ?? TipoAccion.truco]),
          boton('Envido', [TipoAccion.envido]),
          boton('Real', [TipoAccion.realEnvido]),
          boton('Falta', [TipoAccion.faltaEnvido]),
          boton('Quiero', [TipoAccion.quiero]),
          boton('No quiero', [TipoAccion.noQuiero]),
          boton('Al mazo', [TipoAccion.irseAlMazo]),
        ],
      ),
    );
  }
}

class _Mano extends StatelessWidget {
  final VistaMesa vista;
  final PartidaLocal partida;

  const _Mano({required this.vista, required this.partida});

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('mano'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final c in vista.tusCartas)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: CartaWidget(
              carta: c,
              grande: true,
              onTap: vista.puedeJugar(c) && !partida.pensando
                  ? () => partida.jugar(Accion.jugarCarta(c))
                  : null,
            ),
          ),
      ],
    );
  }
}

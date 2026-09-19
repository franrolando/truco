import 'package:flutter/material.dart';
import 'package:truco_engine/truco_engine.dart';

void main() => runApp(const TrucoApp());

class TrucoApp extends StatelessWidget {
  const TrucoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truco',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HolaMundo(),
    );
  }
}

/// Pantalla de prueba: reparte una mano con el motor y la muestra.
/// Sirve para comprobar que el motor corre en el dispositivo.
class HolaMundo extends StatefulWidget {
  const HolaMundo({super.key});

  @override
  State<HolaMundo> createState() => _HolaMundoState();
}

class _HolaMundoState extends State<HolaMundo> {
  late TrucoGame _game = TrucoGame(const TrucoConfig());

  void _repartir() => setState(() => _game = TrucoGame(const TrucoConfig()));

  @override
  Widget build(BuildContext context) {
    final vista = _game.vistaPara(0);
    final cartas = [
      for (final c in vista['tusCartas'] as List<Object?>) Carta.fromJson(c),
    ];
    final envido = puntosEnvido(cartas);

    return Scaffold(
      appBar: AppBar(title: const Text('Truco')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tu mano', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              for (final c in cartas)
                Card(
                  child: ListTile(
                    title: Text('${c.numero} de ${c.palo.name}'),
                    trailing: Text('fuerza ${c.jerarquia}'),
                  ),
                ),
              const SizedBox(height: 8),
              Text('Envido: $envido'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _repartir,
                child: const Text('Repartir de nuevo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

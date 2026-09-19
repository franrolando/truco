import 'package:flutter/material.dart';
import 'package:truco_engine/truco_engine.dart';

extension PaloVisual on Palo {
  String get etiqueta => switch (this) {
        Palo.espada => 'Espada',
        Palo.basto => 'Basto',
        Palo.oro => 'Oro',
        Palo.copa => 'Copa',
      };

  Color get color => switch (this) {
        Palo.espada => const Color(0xFF1E4E8C),
        Palo.basto => const Color(0xFF3F6B2F),
        Palo.oro => const Color(0xFFB8860B),
        Palo.copa => const Color(0xFFB3261E),
      };
}

/// Una carta dibujada con texto y color de palo (sin imágenes).
class CartaWidget extends StatelessWidget {
  final Carta carta;
  final bool grande;
  final VoidCallback? onTap;

  const CartaWidget({
    super.key,
    required this.carta,
    this.grande = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ancho = grande ? 78.0 : 52.0;
    final alto = grande ? 116.0 : 78.0;
    final color = carta.palo.color;
    final habilitada = onTap != null;

    return Semantics(
      button: habilitada,
      label: '${carta.numero} de ${carta.palo.etiqueta}',
      child: Opacity(
        opacity: habilitada || !grande ? 1 : 0.55,
        child: Material(
          color: Colors.white,
          elevation: habilitada ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: SizedBox(
              width: ancho,
              height: alto,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${carta.numero}',
                    style: TextStyle(
                      fontSize: grande ? 34 : 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    carta.palo.etiqueta,
                    style: TextStyle(fontSize: grande ? 13 : 10, color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dorso de carta, para las que el rival todavía tiene en mano.
class DorsoWidget extends StatelessWidget {
  const DorsoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

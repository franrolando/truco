import 'dart:math';

import 'carta.dart';

/// Puntos de envido de una mano de tres cartas.
///
/// Dos cartas del mismo palo suman 20 más sus valores (las figuras valen 0).
/// Sin dos del mismo palo, vale la carta más alta (las figuras valen 0).
int puntosEnvido(List<Carta> mano) {
  var mejor = 0;
  for (final c in mano) {
    mejor = max(mejor, c.valorEnvido);
  }
  for (var i = 0; i < mano.length; i++) {
    for (var j = i + 1; j < mano.length; j++) {
      if (mano[i].palo == mano[j].palo) {
        mejor = max(mejor, 20 + mano[i].valorEnvido + mano[j].valorEnvido);
      }
    }
  }
  return mejor;
}

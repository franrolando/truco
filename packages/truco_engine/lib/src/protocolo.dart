import 'dart:convert';

/// Versión del protocolo. Si cambia el formato, se sube.
const versionProtocolo = 1;

/// Tipos de mensaje que viajan entre host y clientes.
abstract final class TipoMensaje {
  // cliente -> host
  static const join = 'join';
  static const action = 'action';
  static const rejoin = 'rejoin';

  // host -> cliente
  static const welcome = 'welcome';
  static const lobby = 'lobby';
  static const state = 'state';
  static const events = 'events';
  static const error = 'error';
}

/// Sobre de todos los mensajes: `{"v":1,"type":...,"payload":...}`.
class Mensaje {
  final String type;
  final Map<String, dynamic> payload;

  const Mensaje(this.type, [this.payload = const {}]);

  Map<String, dynamic> toJson() =>
      {'v': versionProtocolo, 'type': type, 'payload': payload};

  String encode() => jsonEncode(toJson());

  /// Lanza [FormatException] si el texto no es un mensaje válido.
  factory Mensaje.decode(String texto) {
    final Object? json;
    try {
      json = jsonDecode(texto);
    } on FormatException {
      throw const FormatException('Mensaje no es JSON válido');
    }
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Mensaje inválido');
    }
    if (json['v'] != versionProtocolo) {
      throw const FormatException('Versión de protocolo no soportada');
    }
    final type = json['type'];
    final payload = json['payload'] ?? const <String, dynamic>{};
    if (type is! String || payload is! Map<String, dynamic>) {
      throw const FormatException('Mensaje inválido');
    }
    return Mensaje(type, payload);
  }

  @override
  String toString() => 'Mensaje($type, $payload)';
}

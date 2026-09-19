# Truco

Truco argentino multijugador presencial para celulares (Android e iOS).
Los jugadores están cerca y se conectan por WiFi compartido o hotspot: un
celular hace de host y los demás se conectan a él. Sin servidores propios,
cuentas ni base de datos.

- `packages/truco_engine/` — motor en Dart puro (reglas, partida, protocolo).
- `docs/REGLAS.md` — reglas implementadas y simplificaciones.
- `app/` — app Flutter (todavía no existe).

```
cd packages/truco_engine
dart pub get
dart analyze
dart test
```

# Reglas implementadas

El motor (`packages/truco_engine`) es la única fuente de verdad de las reglas.
Si se cambia una regla, se actualiza este documento y los tests.

## Mesa

- Baraja española de 40 cartas (sin 8 ni 9), 3 cartas por jugador.
- 2, 4 o 6 jugadores. Los asientos se alternan por equipo: **par = equipo 0,
  impar = equipo 1**. Con 2 jugadores cada uno es su propio equipo.
- Se juega a 15 o a 30 puntos.
- El **mano** rota un asiento en cada mano. Abre la primera baza.
- Las cartas se juegan en el orden de los asientos, a partir de quien abre.

## Jerarquía (de mayor a menor)

1 espada, 1 basto, 7 espada, 7 oro, los 3, los 2, 1 copa y 1 oro, los 12,
los 11, los 10, 7 copa y 7 basto, los 6, los 5 y los 4.

## Bazas

- Gana la baza la carta más fuerte. Abre la siguiente quien la ganó.
- Si empatan las cartas más altas de equipos distintos, hay **parda**; abre
  la siguiente el mano.
- Se gana la mano con 2 bazas. Casos con parda:
  - parda en la 1ª: decide la 2ª;
  - gana la 1ª y parda la 2ª: gana el de la 1ª;
  - 1ª y 2ª de equipos distintos y parda la 3ª: gana el de la 1ª;
  - tres pardas: gana el equipo del mano.

## Truco

- Truco (2), retruco (3), vale cuatro (4).
- Cantar: solo en tu turno de jugar, sin nada pendiente.
- Responde el asiento siguiente al que cantó (siempre un rival). Puede
  *quiero*, *no quiero* o subir. Subir implica *quiero* al canto anterior.
- Solo puede subir el equipo que dijo *quiero* al último canto.
- *No quiero* da al que cantó el nivel ya aceptado (1 si no había ninguno).

## Envido

- Solo en la **primera baza** y con el truco sin aceptar. También se puede
  responder a un truco con envido ("el envido va primero"); el truco queda
  pendiente y se responde después.
- Cantos: envido (2, hasta dos veces), real envido (3), falta envido.
  Orden de la cadena: envido → envido → real → falta.
- Falta envido: vale lo que le falta al equipo que va ganando para llegar al
  objetivo (mínimo 1). Si hay una falta en la cadena, reemplaza lo anterior.
- *Quiero*: cobra la suma de lo cantado. *No quiero*: el que cantó cobra lo
  cantado antes del último aumento (mínimo 1).
- Puntos de envido: dos cartas del mismo palo suman 20 más sus valores (las
  figuras valen 0); si no hay dos del mismo palo, vale la carta más alta.

## Simplificaciones

- **Envido automático:** gana el más alto y en empate el más cercano al mano.
  No hay "son buenas".
- Sin flor ni "malas y buenas".
- Irse al mazo lo hace el **equipo entero**, solo en el propio turno y sin
  nada pendiente. Da al rival el nivel de truco aceptado (o 1).
- Solo puede cantar quien tiene el turno de jugar; solo puede responder el
  asiento siguiente al que cantó.
- El juego termina apenas un equipo llega al objetivo, incluso a mitad de
  mano (por ejemplo, con un envido).

## Protocolo (versión 1)

Sobre: `{"v":1,"type":...,"payload":...}`.

| Sentido | Tipo | Contenido |
|---|---|---|
| cliente → host | `join` | nombre |
| cliente → host | `action` | una `Accion` (`{"tipo":...,"carta":...}`) |
| cliente → host | `rejoin` | token (lo procesa la capa de transporte con `SalaHost.reconectar`) |
| host → cliente | `welcome` | asiento, nombre, token, config |
| host → cliente | `lobby` | jugadores, capacidad, puedeIniciar |
| host → cliente | `state` | `TrucoGame.vistaPara(asiento)` |
| host → cliente | `events` | eventos públicos |
| host → cliente | `error` | código y mensaje (solo a quien lo causó) |

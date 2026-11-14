# Frases del modo guasa

Las frases que suelta el marcador con el **modo guasa** activado están todas en
`frases.js`, en cinco listas:

| Lista | Cuándo se usa |
|---|---|
| `PUNTO_PIERDE` / `PUNTO_GANA` | En 4 de cada 10 puntos, al azar, y nunca más de dos puntos seguidos sin frase |
| `JUEGO_PIERDE` / `JUEGO_GANA` | Siempre, al acabar cada juego o set |
| `PARTIDO` | Siempre, al acabar el partido |

En cada punto o juego se elige al azar dar caña al que pierde o pavonear al que
gana. No se repite una frase hasta haber dicho todas las de su lista.

Huecos que se rellenan solos:

- `{G}` pareja que gana · `{g}` uno de sus jugadores, al azar
- `{P}` pareja que pierde · `{p}` uno de sus jugadores, al azar

## Añadir o cambiar frases

El marcador solo sabe **quién** gana el punto, el juego o el partido, no **cómo**.
Ninguna frase puede dar por hecho lo que ha pasado en la pista: ni el golpe
(bandeja, víbora, remate, globo, dejada…), ni por dónde ha ido la bola (red,
cristal, por el medio, por cuatro…), ni si ha sido error o golpe ganador, ni si
el juego o el partido han sido una paliza o muy igualados. Tampoco si es el
primer juego perdido o ya van varios («otro juego más»). Como `{g}` y `{p}` se
eligen al azar, mejor no echarle a uno solo la culpa del punto.

1. Edita `frases.js` (sin comillas dobles, barras invertidas ni el signo del dólar).
2. Desde la carpeta del proyecto:

   ```bash
   node frases-guasa/generar.js
   ```

   Vuelca las frases en la web, en Android (`Guasa.kt`) y en iPhone (final de
   `Phrases.swift`), así las tres versiones dicen lo mismo.

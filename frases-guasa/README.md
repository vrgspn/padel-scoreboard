# Frases del modo guasa

Las frases que suelta el marcador con el **modo guasa** activado están todas en
`frases.js`, en cinco listas:

| Lista | Cuándo se usa |
|---|---|
| `PUNTO_PIERDE` / `PUNTO_GANA` | Tras uno de cada cuatro puntos, al azar |
| `JUEGO_PIERDE` / `JUEGO_GANA` | Siempre, al acabar cada juego o set |
| `PARTIDO` | Siempre, al acabar el partido |

En cada punto o juego se elige al azar dar caña al que pierde o pavonear al que
gana. No se repite una frase hasta haber dicho todas las de su lista.

Huecos que se rellenan solos:

- `{G}` pareja que gana · `{g}` uno de sus jugadores, al azar
- `{P}` pareja que pierde · `{p}` uno de sus jugadores, al azar

## Añadir o cambiar frases

1. Edita `frases.js` (sin comillas dobles, barras invertidas ni el signo del dólar).
2. Desde la carpeta del proyecto:

   ```bash
   node frases-guasa/generar.js
   ```

   Vuelca las frases en la web, en Android (`Guasa.kt`) y en iPhone (final de
   `Phrases.swift`), así las tres versiones dicen lo mismo.

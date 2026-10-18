# Marcador de Pádel · app nativa para iPhone y iPad

App nativa en **Swift + SwiftUI**. Es el mismo desarrollo que la versión web
(`web\padel-scoreboard.html`) y que la app Android de `android\`: mismas reglas, mismos
textos, mismos colores y la misma voz.

Funciona en iPhone y en iPad (universal), en vertical y en horizontal.

---

## Qué hay dentro

```
ios\
├─ PadelScoreboard.xcodeproj\      ← proyecto de Xcode
└─ PadelScoreboard\
   ├─ PadelScoreboardApp.swift     ← arranque y pantalla raíz
   ├─ Model.swift                  ← Match, SetScore, Events, Cfg
   ├─ Rules.swift                  ← reglas del partido (traducción del Kotlin)
   ├─ Phrases.swift                ← cómo se canta cada tanteo
   ├─ Speech.swift                 ← voz del sistema en español
   ├─ Store.swift                  ← ajustes y partido guardados en el aparato
   ├─ AppState.swift               ← estado, deshacer/rehacer, avisos, mando
   ├─ RemoteKeys.swift             ← pulsador Bluetooth y teclas de volumen
   ├─ Haptics.swift                ← vibración al apuntar
   ├─ Theme.swift                  ← los colores de siempre
   ├─ Assets.xcassets\             ← icono y color de acento
   └─ Views\
      ├─ MatchView.swift           ← el marcador
      ├─ HeaderView.swift          ← barra de arriba
      ├─ Overlays.swift            ← carteles, avisos y pantalla de ganador
      ├─ SetupView.swift           ← parejas, saque inicial y formato
      ├─ SettingsView.swift        ← sonido, mando y pantalla
      └─ Controls.swift            ← tarjetas, interruptores y botones
```

Requisitos: **Xcode 16 o posterior** e **iOS 17 o posterior** en el aparato.

El proyecto usa carpetas sincronizadas (`PBXFileSystemSynchronizedRootGroup`), así que
cualquier archivo `.swift` que se añada a `PadelScoreboard\` entra solo en la app; no
hay que tocar el `.xcodeproj`.

---

## Abrir y compilar

En un Mac:

```bash
open ios/PadelScoreboard.xcodeproj
```

Elige tu iPhone o iPad arriba, pon tu equipo de firma en
*Signing & Capabilities* y dale a ▶.

Desde la línea de órdenes, para comprobar que compila:

```bash
xcodebuild -project ios/PadelScoreboard.xcodeproj -scheme PadelScoreboard -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Sin Mac, GitHub lo compila solo: ver
[`COMO-HACER-LA-APP-IOS.md`](../COMO-HACER-LA-APP-IOS.md).

---

## Lo único que cambia respecto a Android

Las reglas, la voz y la pantalla son idénticas. La diferencia está en el mando.

En Android la app se queda con las teclas de volumen y asunto resuelto. **iOS no deja
interceptarlas**, así que aquí el pulsador se escucha por dos caminos a la vez:

1. **Pulsador emparejado como teclado** (la mayoría de los baratos lo hacen): se leen
   Enter, espacio y flechas con el *framework* GameController. Es el camino fiable.
2. **Cambios de volumen del sistema**: cuando el pulsador sube o baja el volumen, la
   app detecta el salto y apunta el punto. Para que el volumen no se quede atascado en
   el tope y deje de haber saltos, la app lo vuelve a centrar sola, y mantiene un
   control de volumen invisible en pantalla para que no salga el cartel del sistema
   encima del marcador.

Consecuencias prácticas:

- Con el ajuste **Usar las teclas de volumen** activado, el volumen del aparato se
  moverá un poco mientras juegas. Es normal: así es como se detecta la pulsación.
- Si tu pulsador manda Enter o espacio, va todo por el camino 1 y el volumen ni se
  entera. Es la opción recomendada.
- En ⚙ → *Mando de disparo* se ve en verde la **última señal recibida**, para
  comprobar qué está llegando.

El resto de diferencias son de plataforma y no se notan al usarla:

| | Android | iOS |
|---|---|---|
| Voz | `TextToSpeech` | `AVSpeechSynthesizer` |
| Vibración | `Vibrator` por milisegundos | `UIImpactFeedbackGenerator` |
| Guardado | `SharedPreferences` + JSON | `UserDefaults` + `Codable` |
| Pantalla encendida | `FLAG_KEEP_SCREEN_ON` | `isIdleTimerDisabled` |

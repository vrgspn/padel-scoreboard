# Cómo conseguir la app de iPhone y iPad, paso a paso

Ya tienes la versión web y la app Android. Esto es lo mismo, pero nativo para iOS.

Hay una diferencia importante respecto a Android: **Apple no deja instalar una app sin
firmarla con una cuenta de Apple**. No es difícil, pero hay que elegir camino.

| | ¿Necesitas Mac? | ¿Cuánto cuesta? | ¿Cada cuánto hay que repetirlo? |
|---|---|---|---|
| **A · Con Mac y Xcode** | Sí | Gratis | Cada 7 días (o 1 año con cuenta de 99 €) |
| **B · Sin Mac, desde Windows** | No | Gratis | Cada 7 días |
| **C · Cuenta de desarrollador** | Sí | 99 €/año | Cada año |

Si no tienes Mac, ve directo al **camino B**.

---

## Qué hay en esta carpeta

```
Padel Scoreboard\
├─ padel-scoreboard.html      ← la versión web
├─ android\                   ← la app Android, en Kotlin
├─ ios\                       ← la app de iPhone y iPad, en Swift
└─ .github\workflows\         ← las recetas para que GitHub compile las apps solas
```

---

# Camino A · Tienes un Mac

Es el más cómodo si puedes.

1. Instala **Xcode** desde la App Store (es gratis, pero ocupa bastante).
2. Copia esta carpeta al Mac y haz doble clic en
   `ios\PadelScoreboard.xcodeproj`.
3. En el panel izquierdo pulsa el proyecto **PadelScoreboard** → pestaña
   **Signing & Capabilities**.
4. En **Team** elige tu Apple ID. Si no sale ninguno:
   *Xcode → Settings → Accounts → +* y entra con tu Apple ID normal.
5. Cambia el **Bundle Identifier** a algo único tuyo, por ejemplo
   `com.ismaelvargas.padel`.
6. Conecta el iPhone o el iPad por cable, elígelo arriba en la barra y pulsa **▶**.
7. La primera vez el iPhone dirá que el desarrollador no es de confianza:
   *Ajustes → General → VPN y gestión de dispositivos* → tu Apple ID → **Confiar**.

Con un Apple ID gratuito la app **caduca a los 7 días**: se vuelve a abrir Xcode y se
pulsa ▶ otra vez. Con una cuenta de desarrollador (99 €/año) dura un año.

---

# Camino B · No tienes Mac (desde Windows)

GitHub compila la app en un Mac suyo y te deja el archivo. Tú sólo lo firmas con tu
Apple ID desde Windows con un programa gratuito.

## Paso 1 · Cuenta de GitHub y repositorio

Si ya lo hiciste para la app Android, **sáltate al paso 3**: es el mismo repositorio.

1. Entra en <https://github.com> y pulsa **Sign up** (gratis).
2. Entra en <https://github.com/new>.
3. **Repository name**: `padel-scoreboard` · marca **Private**.
4. No marques ninguna casilla de README, .gitignore ni licencia.
5. **Create repository**.

## Paso 2 · Subir el proyecto

Abre una terminal **en esta carpeta** y pega esto, cambiando `TU-USUARIO`:

```bash
git init
git add .
git commit -m "Marcador de padel: web, Android e iOS"
git branch -M main
git remote add origin https://github.com/TU-USUARIO/padel-scoreboard.git
git push -u origin main
```

## Paso 3 · Si ya tenías el repositorio, sólo sube lo nuevo

```bash
git add .
git commit -m "App de iPhone y iPad"
git push
```

## Paso 4 · Esperar a que GitHub compile la app

1. Entra en tu repositorio en GitHub → pestaña **Actions**.
2. Verás **Compilar app iOS** con un círculo amarillo girando.
3. Tarda unos 5-10 minutos la primera vez. Cuando acabe, se pone un ✅ verde.

**¿Sale una ✗ roja?** Pulsa encima, luego en el paso que falló, copia el texto del
error y pásamelo. Lo corrijo y volvemos a intentarlo.

## Paso 5 · Descargar el archivo

Con el ✅ verde, en tu repositorio → **Releases** (columna derecha) →
**Último IPA (iOS)** → descarga `MarcadorPadel-sin-firmar.ipa`.

Ese archivo todavía **no se puede instalar**: le falta tu firma. Eso es el paso 6.

## Paso 6 · Firmar e instalar con Sideloadly

1. Descarga **Sideloadly** desde <https://sideloadly.io> (gratis, hay versión
   Windows) e instálalo.
2. Instala también **iTunes de Apple** si Windows no reconoce el iPhone
   (la versión de la web de Apple, no la de la Microsoft Store).
3. Conecta el iPhone o el iPad por cable y desbloquéalo. Pulsa **Confiar** si lo pide.
4. Abre Sideloadly:
   - **IPA**: arrastra ahí el archivo `MarcadorPadel-sin-firmar.ipa`.
   - **Apple ID**: tu correo de Apple.
   - Pulsa **Start**. Te pedirá la contraseña de tu Apple ID (y el código de
     verificación en dos pasos si lo tienes).
5. Cuando termine, en el iPhone ve a
   *Ajustes → General → VPN y gestión de dispositivos* → tu Apple ID → **Confiar**.
6. Ya tienes **Marcador de Pádel** en la pantalla de inicio.

> **Tu Apple ID no se la das a nadie**: Sideloadly se comunica directamente con Apple
> desde tu ordenador. Si prefieres no usar la cuenta principal, puedes crear un Apple
> ID aparte sólo para esto.

**La app caduca a los 7 días.** Para renovarla, vuelve a conectar el cable y pulsa
**Start** otra vez en Sideloadly con el mismo archivo. No pierdes ni los ajustes ni el
partido en curso.

### Alternativa sin ordenador: AltStore / SideStore

Si prefieres renovar la app desde el propio iPhone sin cable, instala
**AltStore PAL** o **SideStore** y mete ahí el `.ipa`. Se renuevan solos por wifi
mientras el iPhone esté en la misma red. Se configuran una vez y son algo más
enrevesados; si quieres ir por ahí, dímelo y lo vemos.

---

# Camino C · Cuenta de desarrollador de Apple

99 € al año. Te quita el límite de los 7 días (la app dura un año) y permite
instalarla en varios aparatos o repartirla por TestFlight. Hace falta Mac igualmente
para la parte de firma. Si te interesa, dímelo y lo preparo.

---

## Probar el mando del reloj en iOS

Aquí hay una diferencia real con Android que conviene conocer.

En Android la app se queda las teclas de volumen y listo. **iOS no deja hacer eso**,
así que la app escucha de dos maneras:

- **Si tu pulsador se empareja como teclado** y manda Enter, espacio o flechas: va
  perfecto y el volumen del iPhone ni se mueve. Es la mejor opción.
- **Si tu pulsador sube y baja el volumen**: la app detecta el salto de volumen y
  apunta el punto igual, pero verás que el volumen se mueve un poco mientras juegas.
  Es normal, y la app lo recoloca sola para que no se atasque en el tope.

Para comprobar qué está llegando: ⚙ → *Mando de disparo* → abajo verás en verde la
**última señal recibida**. Pulsa el mando y mira qué pone.

- **Pulsador de un solo botón** → activa **Modo un solo botón**:
  1 pulsación = punto para quien saca · 2 = punto para quien resta · 3 = deshacer,
  con la espera que elijas (5 segundos de serie).
- **Mando de dos botones** → sin el modo un botón, una tecla suma a la pareja de la
  izquierda y la otra a la de la derecha.
- **Sin mando** → un toque en cada mitad de la pantalla suma punto. Funciona siempre.

---

## Preguntas que te van a surgir

**¿Esto cuesta dinero?** No, salvo que elijas el camino C. GitHub da minutos gratis al
mes; los Mac de GitHub gastan 10 veces más rápido que los Linux, así que una
compilación de iOS consume unos 50-100 minutos de los 2.000 del plan gratuito. Da para
unas 20 compilaciones al mes, de sobra.

**¿Por qué caduca a los 7 días?** Es el límite que pone Apple a las apps firmadas con
un Apple ID gratuito. No hay forma de saltárselo sin la cuenta de 99 €/año.

**¿Puedo publicarla en la App Store?** Sí, con la cuenta de desarrollador. Dímelo si
quieres ir por ahí.

**¿Funciona en iPad?** Sí, es la misma app. En el iPad se ve en grande y aprovecha la
pantalla, igual que en horizontal en el iPhone.

**¿Pierdo la versión web o la de Android?** No. Las tres son independientes y siguen
funcionando igual. Lo que no comparten son los ajustes: cada una guarda los suyos en
su propio aparato.

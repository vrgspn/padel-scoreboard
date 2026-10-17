# Cómo conseguir la app Android, paso a paso

No necesitas instalar nada en el ordenador. GitHub compila la app por ti y te deja
un archivo `.apk` que descargas en el móvil y lo instalas.

Tiempo total la primera vez: unos 20 minutos, casi todo esperando.

---

## Qué hay en esta carpeta

```
Padel Scoreboard\
├─ padel-scoreboard.html      ← la versión web (sigue funcionando igual)
├─ android\                   ← la app Android, escrita en Kotlin
├─ ios\                       ← la app de iPhone y iPad, en Swift
└─ .github\workflows\         ← las recetas para que GitHub compile las apps solas
```

*(Para la app de iPhone y iPad, mira
[`COMO-HACER-LA-APP-IOS.md`](COMO-HACER-LA-APP-IOS.md).)*

---

## Paso 1 · Cuenta de GitHub

Si ya tienes, sáltate esto.

1. Entra en <https://github.com> y pulsa **Sign up**.
2. Correo, contraseña y nombre de usuario. Es gratis.

---

## Paso 2 · Crear el repositorio

1. Entra en <https://github.com/new>.
2. **Repository name**: `padel-scoreboard`
3. Marca **Private** (solo tú lo verás).
4. **No marques** ninguna casilla de añadir README, .gitignore ni licencia.
5. Pulsa **Create repository**.
6. Te saldrá una página con una dirección parecida a
   `https://github.com/TU-USUARIO/padel-scoreboard.git`. Tenla a mano.

---

## Paso 3 · Subir el proyecto

Abre una terminal **en esta carpeta** y pega estos comandos uno a uno.
Cambia `TU-USUARIO` por tu nombre de usuario de GitHub.

```bash
git init
git add .
git commit -m "Marcador de padel: web y app Android"
git branch -M main
git remote add origin https://github.com/TU-USUARIO/padel-scoreboard.git
git push -u origin main
```

La primera vez te pedirá iniciar sesión en GitHub: se abre una ventana del navegador,
aceptas y listo.

> Si es la primera vez que usas git en este ordenador, antes ejecuta:
> ```bash
> git config --global user.name "Ismael"
> git config --global user.email "tu-correo@ejemplo.com"
> ```

---

## Paso 4 · Esperar a que GitHub compile la app

1. Entra en tu repositorio en GitHub.
2. Pestaña **Actions** (arriba).
3. Verás una ejecución llamada **Compilar APK** con un círculo amarillo girando.
4. Tarda unos 3-5 minutos la primera vez. Cuando acabe, se pone un ✅ verde.

**¿Sale una ✗ roja?** No pasa nada: pulsa encima, luego en el paso que falló, copia el
texto del error y pásamelo. Lo corrijo y volvemos a intentarlo.

---

## Paso 5 · Descargar el APK en el móvil

Con el ✅ verde:

1. **Desde el móvil**, abre tu repositorio en GitHub y entra en **Releases**
   (columna derecha) → **Último APK**.
2. Pulsa el archivo que acaba en `.apk` para descargarlo.

*(Otra vía: en la pestaña Actions, dentro de la ejecución, abajo del todo hay un
apartado **Artifacts** con `marcador-padel-apk`. Ese se descarga comprimido, por eso
es más cómodo el de Releases.)*

---

## Paso 6 · Instalar la app

1. Abre el archivo descargado (en Descargas o desde la notificación).
2. Android avisará de que no se permiten apps de orígenes desconocidos:
   pulsa **Ajustes** → activa **Permitir esta fuente** → vuelve atrás.
3. Pulsa **Instalar** y luego **Abrir**.

Es una app normal: aparece en el cajón de aplicaciones como **Marcador de Pádel**
y puedes ponerla en la pantalla de inicio.

> Aviso de Play Protect: al ser una app tuya y no de la tienda, puede salir un
> "No se ha podido comprobar". Pulsa **Instalar de todos modos**.

---

## Paso 7 · Probar el mando del reloj

Esta es la ventaja de la app frente a la web: **las teclas de volumen sí llegan**.

1. Empareja el pulsador con el móvil como siempre.
2. Abre la app y pulsa el botón del mando.
3. Con el ajuste **Usar las teclas de volumen** activado (lo está de serie), el
   volumen del móvil ya no cambia: el marcador se lleva la pulsación.

- **Pulsador con un solo botón** → activa en ⚙ **Modo un solo botón**:
  1 pulsación = punto para quien saca · 2 = punto para quien resta · 3 = deshacer,
  con la espera que elijas (5 segundos de serie).
- **Mando con dos botones** (volumen + y −) → sin el modo un botón, bajar volumen
  suma a la pareja de la izquierda y subirlo a la de la derecha.

En ⚙ → *Mando de disparo* verás en verde la **última señal recibida**: sirve para
comprobar que el mando llega a la app.

---

## Hacer cambios más adelante

Cada vez que yo cambie algo, tú solo tienes que subirlo:

```bash
git add .
git commit -m "cambios"
git push
```

GitHub vuelve a compilar y en unos minutos tendrás el APK nuevo en **Releases**.
Instálalo encima del anterior: se actualiza y conserva tus ajustes.

---

## Preguntas que te van a surgir

**¿Esto cuesta dinero?** No. GitHub da 2.000 minutos de compilación gratis al mes
en repositorios privados; cada compilación gasta unos 4.

**¿Puedo publicarla en Google Play?** Sí, pero eso ya requiere cuenta de desarrollador
(25 $ una vez) y firmar la app con una clave propia. Dímelo si quieres ir por ahí.

**¿La web deja de funcionar?** No. El archivo HTML sigue ahí y funciona igual.

**¿Y mis partidos guardados?** La app guarda sus ajustes y el partido en curso en el
propio móvil, igual que hacía la web, pero son independientes entre sí.

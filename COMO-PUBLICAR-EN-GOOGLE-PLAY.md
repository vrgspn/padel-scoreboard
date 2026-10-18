# Publicar el Marcador de Pádel en Google Play

Guía completa, en orden. Lo que ya está hecho en el proyecto va marcado como ✅;
lo demás son pasos tuyos.

> **Lo primero que debes saber**: entre que creas la cuenta y la app aparece
> publicada pasan **unas 3 semanas**, no por el trabajo sino por dos esperas de Google:
> la verificación de tu identidad (días) y la **prueba obligatoria con 12 personas
> durante 14 días seguidos**, que Google exige a todas las cuentas personales nuevas.
> No hay forma de saltársela.

---

## Lo que ya está preparado ✅

| Requisito de Play | Estado |
|---|---|
| Apuntar a Android 16 (API 36), obligatorio desde el 31/08/2026 | ✅ hecho |
| Formato AAB (Play no acepta APK para apps nuevas) | ✅ flujo `Paquete para Google Play` |
| App firmada con clave propia | ✅ preparado, falta que generes tu clave (paso 2) |
| Política de privacidad publicada | ✅ `docs/privacidad.html`, falta activarla (paso 5) |
| Permisos mínimos (solo vibración) | ✅ |
| Sin publicidad, sin analítica, sin internet | ✅ |

---

## Paso 1 · Crear la cuenta de desarrollador

1. Entra en <https://play.google.com/console/signup>.
2. Elige cuenta **personal**.
3. Paga la cuota única de **25 USD** (unos 23 €, una sola vez de por vida).
4. Google te pedirá **verificar tu identidad**: DNI o pasaporte, y dirección.
   Tarda entre unas horas y varios días.
5. Rellena el perfil: nombre de desarrollador público (aparecerá bajo el nombre de
   la app), correo y teléfono de contacto.

> El nombre de desarrollador y el correo de contacto serán **públicos** en la ficha
> de la app. Usa un correo que no te importe mostrar.

---

## Paso 2 · Crear tu clave de firma

Es el carné de identidad de tu app: Google comprueba con ella que una actualización
viene de ti. **Si la pierdes del todo, no puedes actualizar la app.**

No necesitas instalar nada: estos comandos funcionan con el Git que ya tienes.
Ábrelos en la carpeta del proyecto, uno a uno.

**2.1 · Generar el certificado** (30 años de validez):

```bash
openssl req -x509 -newkey rsa:4096 -sha256 -days 10950 -nodes -keyout clave.pem -out cert.pem -subj "/CN=Ismael Vargas/O=Marcador de Padel/L=Sevilla/C=ES"
```

**2.2 · Empaquetarlo como clave de firma.** Te pedirá una contraseña dos veces:
inventa una larga y **guárdala en tu gestor de contraseñas**, la necesitarás siempre:

```bash
openssl pkcs12 -export -inkey clave.pem -in cert.pem -name subida -out upload-keystore.p12
```

**2.3 · Convertirla a texto** para poder guardarla en GitHub:

```bash
base64 -w0 upload-keystore.p12 > keystore.base64.txt
```

**2.4 · Guardarla como secreto en GitHub**:

1. Ve a <https://github.com/ismavarpi/padel-scoreboard/settings/secrets/actions>.
2. **New repository secret** → nombre `KEYSTORE_BASE64` → pega **todo** el contenido
   de `keystore.base64.txt` (es una línea larguísima) → **Add secret**.
3. Otro secreto → nombre `KEYSTORE_PASSWORD` → la contraseña del paso 2.2 → **Add secret**.

**2.5 · Pon a salvo los archivos y bórralos de la carpeta**:

Copia `upload-keystore.p12`, `clave.pem` y `cert.pem` a un sitio seguro (gestor de
contraseñas, disco externo, Drive privado). Después bórralos de la carpeta del proyecto:

```bash
rm -f clave.pem cert.pem keystore.base64.txt
```

> `.gitignore` ya impide que esos archivos se suban a GitHub por accidente, pero mejor
> no tenerlos ahí.

---

## Paso 3 · Generar el paquete para Play (AAB)

1. Ve a <https://github.com/ismavarpi/padel-scoreboard/actions>.
2. En la izquierda, **Paquete para Google Play** → botón **Run workflow**.
3. Deja `1.0` y `1` la primera vez. Pulsa **Run workflow**.
4. Cuando acabe (✅, unos 4 minutos), entra en la ejecución y abajo verás
   **Artifacts → marcador-padel-play-aab**. Descárgalo: dentro va el archivo
   `app-release.aab`. **Ese** es el que se sube a Play.

> En cada nueva versión que subas a Play, el **número de versión interno** debe ser
> mayor que el anterior: 1, 2, 3… El nombre visible (1.0, 1.1…) lo eliges tú.

---

## Paso 4 · Activar la política de privacidad

Play no deja publicar sin una dirección web con la política. Ya está escrita, solo hay
que encenderla:

1. Ve a <https://github.com/ismavarpi/padel-scoreboard/settings/pages>.
2. En **Source** elige **Deploy from a branch**.
3. Branch: **main**, carpeta: **/docs** → **Save**.
4. Espera un par de minutos. Tu política quedará en:

```
https://ismavarpi.github.io/padel-scoreboard/privacidad.html
```

Ábrela para comprobar que carga. Esa es la URL que pide Play.

> Si prefieres no usar tu correo personal ahí, edita `docs/privacidad.html` y cambia
> la línea del contacto antes de activarlo.

---

## Paso 5 · Crear la app en Play Console

En <https://play.google.com/console> → **Crear app**:

- **Nombre de la app**: `Marcador de Pádel`
- **Idioma predeterminado**: Español (España)
- **Tipo**: Aplicación
- **Gratis o de pago**: Gratis
- Acepta las declaraciones de normas y leyes de exportación.

---

## Paso 6 · Rellenar la ficha de la tienda

**Presencia en Play Store → Ficha de Play Store principal**. Puedes copiar esto tal cual:

**Descripción breve** (máx. 80 caracteres):

```
Marcador de pádel con voz, control del saque y mando para apuntar los puntos.
```

**Descripción completa**:

```
Marcador de pádel pensado para usarlo en la pista, no para mirarlo de cerca.

Números enormes que se leen desde el otro lado de la pista, los nombres de los cuatro
jugadores colocados como en la cancha y una pelota que marca en todo momento quién saca.

QUÉ HACE

• Puntuación completa de pádel: 15, 30, 40, ventaja, juegos y sets.
• Punto de oro opcional, tie-break a 6-6 y super tie-break en el set decisivo.
• Partidos a 1, 3 o 5 sets.
• Controla el saque automáticamente: rotación entre los cuatro jugadores y aviso del
  cambio de lado.
• Avisa de punto de juego, break, punto de set y punto de partido.
• Deshacer y rehacer, por si te equivocas al apuntar.
• El partido se guarda solo: si cierras la app, lo encuentras donde lo dejaste.

CANTA EL MARCADOR EN VOZ ALTA

La app dice el tanteo después de cada punto, empezando siempre por quien saca, como en
la pista: «cuarenta treinta, saca Miguel Ángel desde la izquierda». También canta quién
gana cada juego, cada set y el partido. Puedes elegir qué dice y a qué velocidad.

APUNTA LOS PUNTOS SIN TOCAR EL MÓVIL

Funciona con los pulsadores Bluetooth de hacer fotos, esos mandos pequeños que caben en
la mano o van en el reloj. La app captura las teclas de volumen que envían, así que
puedes apuntar el punto sin acercarte al móvil.

Si tu mando tiene un solo botón: una pulsación suma el punto a quien saca, dos al que
resta y tres deshacen. El tiempo de espera entre pulsaciones es ajustable, para mandos
que tardan en responder.

También puedes apuntar tocando cada mitad de la pantalla.

PENSADO PARA LA PISTA

• Se ve bien en vertical y en horizontal, en móvil y en tablet.
• La pantalla no se apaga mientras juegas.
• Sin internet, sin publicidad, sin cuentas y sin recoger ningún dato.
```

**Recursos gráficos** (los dos primeros los tienes ya generados en la carpeta
`graficos/` del proyecto):

| Qué | Tamaño | De dónde sale |
|---|---|---|
| Icono | 512 × 512 PNG | `graficos/icono-512.png` ✅ |
| Gráfico destacado | 1024 × 500 PNG | `graficos/destacado-1024x500.png` ✅ |
| Capturas de móvil | mínimo 2, máx. 8 | las haces tú (abajo) |

**Cómo hacer las capturas**: abre la app en el móvil y pulsa *bajar volumen + botón de
encendido* a la vez. Haz al menos estas cuatro:

1. Un partido en marcha en horizontal, con tanteo interesante (40-30).
2. El mismo en vertical.
3. La pantalla de ajustes de sonido.
4. La pantalla de configuración del partido.

Pásalas al ordenador y súbelas en la ficha.

---

## Paso 7 · Los cuestionarios obligatorios

En **Política y programas → Contenido de la app**:

- **Política de privacidad**: pega la URL del paso 4.
- **Anuncios**: *No, mi app no contiene anuncios*.
- **Acceso a la app**: *Todas las funciones están disponibles sin restricciones*.
- **Clasificación de contenido**: rellena el cuestionario. Al no tener violencia, ni
  contenido sexual, ni lenguaje soez, ni compras, saldrá apta para todos los públicos.
- **Público objetivo**: elige los tramos de edad adultos (18+ o 13+); así evitas las
  normas adicionales de apps para niños.
- **Seguridad de los datos**: responde **«No, mi app no recoge ni comparte datos de
  usuario»**. Es cierto: todo se guarda en el propio móvil y la app no usa internet.
- **App de salud**: no.
- **Publicidad gubernamental, finanzas, préstamos**: no.

---

## Paso 8 · La prueba obligatoria con 12 personas

Este es el paso largo y donde encalla todo el mundo.

1. En **Prueba y publicación → Pruebas → Prueba cerrada**, crea una versión
   (*Crear nueva versión*) y sube ahí el `app-release.aab` del paso 3.
2. Crea una **lista de correos** con al menos **12 personas** (familia, amigos,
   compañeros de pádel). Hacen falta sus cuentas de Gmail.
3. Comparte con ellos el enlace de la prueba que te da Play. **Cada uno debe aceptar e
   instalar la app** desde ese enlace.
4. Los 12 deben permanecer apuntados **14 días seguidos**. Si alguien se da de baja, el
   contador se resiente: avísales de que no desinstalen ni salgan de la prueba.
5. Pasados los 14 días, Play te habilita el botón **Solicitar acceso a producción**.

> Ojo: la prueba **interna** no cuenta para este requisito, tiene que ser **cerrada**.
> Ten también en cuenta que cumplir el mínimo te deja *solicitar* el acceso; Google
> revisa la solicitud y puede tardar unos días más.

---

## Paso 9 · Publicar

1. **Solicitar acceso a producción** y esperar la aprobación.
2. Una vez aprobado: **Producción → Crear nueva versión** → sube el mismo `.aab`
   (o uno nuevo con número mayor) → revisa la ficha → **Enviar a revisión**.
3. La primera revisión suele tardar entre unas horas y 7 días.
4. Cuando la aprueben, la app aparece en Play en
   `https://play.google.com/store/apps/details?id=com.vrgspn.marcadorpadel`.

---

## Más adelante: publicar una versión nueva

1. Yo cambio lo que haga falta en el código y lo subes con `git push`.
2. Lanzas el flujo **Paquete para Google Play** con un número de versión mayor
   (2, 3, 4…) y el nombre que quieras (1.1, 1.2…).
3. Descargas el `.aab` y lo subes en **Producción → Crear nueva versión**.

---

## Preguntas que te van a surgir

**¿Puedo saltarme los 14 días de prueba?** No, salvo que registres una cuenta de
*organización* (requiere un número DUNS de empresa). Para una cuenta personal creada
hoy, el requisito es obligatorio.

**¿Y si no consigo 12 personas?** Es el motivo más común de bloqueo. Cuenta a familia,
compañeros del club, grupo de WhatsApp del pádel… Necesitas 12 cuentas de Google
distintas que instalen y mantengan la app.

**¿Cuánto cuesta mantenerla?** Nada. Los 25 USD son únicos. Si tu app no se actualiza en
mucho tiempo, Play puede dejar de ofrecerla a móviles nuevos, pero no te cobra.

**¿Tengo que renovar algo cada año?** Sí, una cosa: cada año Google sube el nivel de
Android obligatorio. Toca cambiar un número en el proyecto y volver a subir. Avísame
cuando te llegue el aviso de Play y lo hacemos.

**¿Puedo publicarla sin Play?** Sí, es lo que ya tienes: el APK de la pestaña Releases
se instala directamente. Play solo hace falta si quieres que la gente la encuentre en
la tienda.

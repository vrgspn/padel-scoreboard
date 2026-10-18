# Marcador de Pádel · versión web

Un solo fichero, `padel-scoreboard.html`, sin dependencias ni instalación: se abre
con doble clic o se sube a cualquier sitio y funciona. Guarda el partido y los
ajustes en el propio navegador.

Es el mismo desarrollo que la app Android de `android\` y la de iPhone de `ios\`:
mismas reglas, mismos textos, mismos colores y la misma voz. Vive aquí, aparte,
para no mezclarse con el código de las apps.

## Usarla en el móvil

1. Sube el fichero a cualquier sitio con **https** (GitHub Pages, Netlify, Drive…)
   o ábrelo desde el propio móvil.
2. En Android: menú de Chrome → **Añadir a la pantalla de inicio**.
   En iPhone: compartir → **Añadir a pantalla de inicio**.
3. Ábrelo desde el icono: se abre a pantalla completa, sin barra del navegador.

El https (o abrir el fichero en local) hace falta para mantener la pantalla
encendida y para las teclas de medios.

## El mando Bluetooth en Android

El pulsador de fotos Bluetooth se empareja como un teclado. Qué tecla manda
depende del mando y del modo en que esté:

| Lo que manda el mando | ¿Lo recibe la web? |
|---|---|
| `Enter` (modo iOS en casi todos los pulsadores) | Sí |
| Play/pausa, pista siguiente o anterior | Sí, pulsando antes **Activar teclas de medios** |
| Flechas, espacio, letras | Sí |
| Botones de un gamepad | Sí |
| **Subir/bajar volumen** (modo Android de muchos pulsadores) | **No** |

Las teclas de volumen se las queda el sistema antes de que lleguen al navegador:
ninguna página web de Android puede verlas. Si tu mando sólo sabe mandar volumen,
cámbialo a **modo iOS** o usa la app de Android, que sí puede quedárselas.

Dos cosas que conviene saber en Android:

- Las teclas sólo llegan si la página tiene el foco del teclado. Toca una vez el
  marcador antes de empezar; la página se lo queda sola después de cada toque.
- En **Ajustes → Mando de disparo** hay un registro en verde de lo que va
  llegando. Si al apretar el mando no aparece nada, esa tecla no está pasando
  por el navegador.

Con **Aprender** se asigna cualquier tecla a cualquier acción, incluso las que el
navegador no sabe nombrar (aparecen como «Tecla nº …»).

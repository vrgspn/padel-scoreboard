/**
 * Genera los dos gráficos que Google Play exige, sin instalar nada:
 *   graficos/icono-512.png            (512 x 512)
 *   graficos/destacado-1024x500.png   (1024 x 500)
 *
 * Uso:  node graficos/generar-graficos.js
 */
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

// ---------- utilidades de dibujo sobre un lienzo RGBA ----------

function lienzo(w, h, fondo) {
  const px = Buffer.alloc(w * h * 4);
  for (let i = 0; i < w * h; i++) {
    px[i * 4] = fondo[0];
    px[i * 4 + 1] = fondo[1];
    px[i * 4 + 2] = fondo[2];
    px[i * 4 + 3] = 255;
  }
  return { w, h, px };
}

function mezclar(c, x, y, color, alpha) {
  if (x < 0 || y < 0 || x >= c.w || y >= c.h || alpha <= 0) return;
  const i = (y * c.w + x) * 4;
  const a = Math.min(1, alpha);
  c.px[i] = Math.round(c.px[i] * (1 - a) + color[0] * a);
  c.px[i + 1] = Math.round(c.px[i + 1] * (1 - a) + color[1] * a);
  c.px[i + 2] = Math.round(c.px[i + 2] * (1 - a) + color[2] * a);
}

/** Círculo con borde suavizado y luz desplazada, para que parezca una pelota. */
function circulo(c, cx, cy, r, colorDe, colorA, luzX, luzY) {
  const lx = luzX === undefined ? cx : luzX;
  const ly = luzY === undefined ? cy : luzY;
  const r2 = r + 1;
  for (let y = Math.floor(cy - r2); y <= Math.ceil(cy + r2); y++) {
    for (let x = Math.floor(cx - r2); x <= Math.ceil(cx + r2); x++) {
      const d = Math.hypot(x - cx, y - cy);
      if (d > r + 0.8) continue;
      const borde = Math.min(1, Math.max(0, r + 0.5 - d));
      const t = Math.min(1, Math.hypot(x - lx, y - ly) / (r * 1.5));
      const color = [
        Math.round(colorDe[0] + (colorA[0] - colorDe[0]) * t),
        Math.round(colorDe[1] + (colorA[1] - colorDe[1]) * t),
        Math.round(colorDe[2] + (colorA[2] - colorDe[2]) * t)
      ];
      mezclar(c, x, y, color, borde);
    }
  }
}

/** Arco grueso, para las costuras de la pelota. */
function arco(c, cx, cy, r, grosor, desde, hasta, color) {
  const pasos = Math.ceil(r * 8);
  for (let i = 0; i <= pasos; i++) {
    const ang = desde + (hasta - desde) * (i / pasos);
    const x = cx + Math.cos(ang) * r;
    const y = cy + Math.sin(ang) * r;
    for (let dy = -grosor; dy <= grosor; dy++) {
      for (let dx = -grosor; dx <= grosor; dx++) {
        const d = Math.hypot(dx, dy);
        if (d <= grosor) mezclar(c, Math.round(x + dx), Math.round(y + dy), color, 1 - d / (grosor + 1));
      }
    }
  }
}

function rect(c, x0, y0, x1, y1, color, alpha) {
  for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) mezclar(c, x, y, color, alpha);
}

/** Degradado vertical suave sobre todo el lienzo. */
function degradado(c, arriba, abajo) {
  for (let y = 0; y < c.h; y++) {
    const t = y / (c.h - 1);
    const color = [
      Math.round(arriba[0] + (abajo[0] - arriba[0]) * t),
      Math.round(arriba[1] + (abajo[1] - arriba[1]) * t),
      Math.round(arriba[2] + (abajo[2] - arriba[2]) * t)
    ];
    for (let x = 0; x < c.w; x++) mezclar(c, x, y, color, 1);
  }
}

// ---------- escritura del PNG ----------

function crc32(buf) {
  let c, tabla = [];
  for (let n = 0; n < 256; n++) {
    c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    tabla[n] = c >>> 0;
  }
  let crc = 0xffffffff;
  for (const b of buf) crc = tabla[(crc ^ b) & 0xff] ^ (crc >>> 8);
  return (crc ^ 0xffffffff) >>> 0;
}

function trozo(tipo, datos) {
  const largo = Buffer.alloc(4);
  largo.writeUInt32BE(datos.length);
  const cuerpo = Buffer.concat([Buffer.from(tipo, "ascii"), datos]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(cuerpo));
  return Buffer.concat([largo, cuerpo, crc]);
}

function guardarPng(c, destino) {
  const filas = Buffer.alloc(c.h * (c.w * 4 + 1));
  for (let y = 0; y < c.h; y++) {
    filas[y * (c.w * 4 + 1)] = 0; // sin filtro
    c.px.copy(filas, y * (c.w * 4 + 1) + 1, y * c.w * 4, (y + 1) * c.w * 4);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(c.w, 0);
  ihdr.writeUInt32BE(c.h, 4);
  ihdr[8] = 8;    // bits por canal
  ihdr[9] = 6;    // RGBA
  const png = Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    trozo("IHDR", ihdr),
    trozo("IDAT", zlib.deflateSync(filas, { level: 9 })),
    trozo("IEND", Buffer.alloc(0))
  ]);
  fs.writeFileSync(destino, png);
  console.log("Creado " + destino + "  (" + c.w + "x" + c.h + ", " + Math.round(png.length / 1024) + " KB)");
}

// ---------- los dos gráficos ----------

const FONDO = [11, 18, 32];      // #0B1220
const PELOTA_CLARO = [234, 255, 121];
const PELOTA = [203, 233, 47];
const PELOTA_OSCURO = [140, 175, 20];
const VERDE = [54, 211, 153];
const AMARILLO = [251, 191, 36];

function pelota(c, cx, cy, r) {
  // cuerpo con la luz arriba a la izquierda
  circulo(c, cx, cy, r, PELOTA_CLARO, PELOTA_OSCURO, cx - r * 0.35, cy - r * 0.4);

  // las dos costuras: arcos que recorren la pelota de polo a polo por cada lado
  const g = Math.max(1.5, r * 0.032);
  const d = r * 0.1413;     // desplazamiento del centro del arco
  const R = r * 0.8913;     // radio del arco
  arco(c, cx + d, cy, R, g, 1.730, 4.553, [96, 124, 24]);   // costura izquierda
  arco(c, cx - d, cy, R, g, -1.412, 1.412, [96, 124, 24]);  // costura derecha
}

function icono() {
  const c = lienzo(512, 512, FONDO);
  degradado(c, [16, 26, 46], [9, 15, 27]);
  pelota(c, 256, 256, 186);
  return c;
}

function destacado() {
  const c = lienzo(1024, 500, FONDO);
  degradado(c, [17, 28, 49], [9, 14, 26]);

  // dos mitades, como los cuadros del marcador
  rect(c, 70, 90, 480, 410, VERDE, 0.1);
  rect(c, 544, 90, 954, 410, AMARILLO, 0.1);
  // líneas de la pista
  rect(c, 508, 60, 516, 440, [255, 255, 255], 0.22);
  rect(c, 70, 248, 480, 252, VERDE, 0.35);
  rect(c, 544, 248, 954, 252, AMARILLO, 0.35);

  pelota(c, 512, 250, 92);
  return c;
}

const dir = path.join(__dirname);
guardarPng(icono(), path.join(dir, "icono-512.png"));
guardarPng(destacado(), path.join(dir, "destacado-1024x500.png"));

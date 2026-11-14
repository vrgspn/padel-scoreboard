// Genera el banco de frases del modo guasa en Kotlin, Swift y JavaScript.
const fs = require("fs");
const path = require("path");
const F = require("./frases.js");
const root = process.argv[2] || path.resolve(__dirname, "..");
const NAMES = ["PUNTO_PIERDE", "PUNTO_GANA", "JUEGO_PIERDE", "JUEGO_GANA", "PARTIDO"];
let total = 0;
for (const n of NAMES) {
  for (const s of F[n]) {
    if (/["\\$]/.test(s)) throw new Error("Carácter no permitido: " + s);
    if (!/\{[GgPp]\}/.test(s)) throw new Error("Frase sin hueco: " + s);
  }
  total += F[n].length;
}
const list = (n, ind) => F[n].map(s => ind + JSON.stringify(s)).join(",\n");

// ---------------- Kotlin
const kt = `package com.vrgspn.marcadorpadel

import kotlin.random.Random

/**
 * Modo guasa: coletillas con mala uva que se dicen después del tanteo.
 * Mismo banco de frases que en la web y en iPhone (${total} frases).
 *
 * Huecos de cada frase:
 *  {G} pareja que gana el punto · {g} uno de sus jugadores
 *  {P} pareja que lo pierde      · {p} uno de sus jugadores
 */
object Guasa {

    /** Uno de cada cuatro puntos, más o menos, al azar. */
    private const val POINT_CHANCE = 0.25

${NAMES.map(n => `    private val ${n} = listOf(\n${list(n, "        ")}\n    )`).join("\n\n")}

    /** Bolsas barajadas: no se repite una frase hasta haber dicho todas las de su lista. */
    private val bags = HashMap<String, ArrayDeque<String>>()

    private fun draw(key: String, pool: List<String>): String {
        val bag = bags.getOrPut(key) { ArrayDeque() }
        if (bag.isEmpty()) bag.addAll(pool.shuffled())
        return bag.removeFirst()
    }

    /**
     * Coletilla para el punto que acaba de ganar [winner], o "" si no toca.
     * Siempre al acabar juego, set o partido; en los demás puntos, uno de cada cuatro.
     * La mitad de las veces da caña a quien pierde y la otra mitad alaba a quien gana.
     */
    fun phrase(winner: Int, ev: Events, cfg: Cfg): String {
        if (!cfg.guasa || winner !in 0..1) return ""
        val alaba = Random.nextBoolean()
        val (key, pool) = when {
            ev.match -> "PARTIDO" to PARTIDO
            ev.game || ev.set -> if (alaba) "JUEGO_GANA" to JUEGO_GANA else "JUEGO_PIERDE" to JUEGO_PIERDE
            Random.nextDouble() < POINT_CHANCE ->
                if (alaba) "PUNTO_GANA" to PUNTO_GANA else "PUNTO_PIERDE" to PUNTO_PIERDE
            else -> return ""
        }
        val loser = 1 - winner
        return draw(key, pool)
            .replace("{G}", cfg.names[winner])
            .replace("{P}", cfg.names[loser])
            .replace("{g}", cfg.players[winner].random())
            .replace("{p}", cfg.players[loser].random())
    }
}
`;
fs.writeFileSync(path.join(root, "android/app/src/main/java/com/vrgspn/marcadorpadel/Guasa.kt"), kt);

// ---------------- Swift (al final de Phrases.swift, para no tocar el proyecto de Xcode)
const swift = `
// MARK: - Modo guasa

/**
 Modo guasa: coletillas con mala uva que se dicen después del tanteo.
 Mismo banco de frases que en la web y en Android (${total} frases).

 Huecos de cada frase:
  {G} pareja que gana el punto · {g} uno de sus jugadores
  {P} pareja que lo pierde      · {p} uno de sus jugadores
 */
enum Guasa {

    /// Uno de cada cuatro puntos, más o menos, al azar.
    private static let pointChance = 0.25

${NAMES.map(n => `    private static let ${n}: [String] = [\n${list(n, "        ")}\n    ]`).join("\n\n")}

    /// Bolsas barajadas: no se repite una frase hasta haber dicho todas las de su lista.
    private static var bags: [String: [String]] = [:]

    private static func draw(_ key: String, _ pool: [String]) -> String {
        var bag = bags[key] ?? []
        if bag.isEmpty { bag = pool.shuffled() }
        let s = bag.removeFirst()
        bags[key] = bag
        return s
    }

    /// Coletilla para el punto que acaba de ganar \`winner\`, o "" si no toca.
    /// Siempre al acabar juego, set o partido; en los demás puntos, uno de cada cuatro.
    /// La mitad de las veces da caña a quien pierde y la otra mitad alaba a quien gana.
    static func phrase(winner: Int, _ ev: Events, _ cfg: Cfg) -> String {
        guard cfg.guasa, winner == 0 || winner == 1 else { return "" }
        let alaba = Bool.random()
        let key: String
        if ev.match {
            key = "PARTIDO"
        } else if ev.game || ev.set {
            key = alaba ? "JUEGO_GANA" : "JUEGO_PIERDE"
        } else if Double.random(in: 0..<1) < pointChance {
            key = alaba ? "PUNTO_GANA" : "PUNTO_PIERDE"
        } else {
            return ""
        }
        let pools: [String: [String]] = [
            "PUNTO_PIERDE": PUNTO_PIERDE, "PUNTO_GANA": PUNTO_GANA,
            "JUEGO_PIERDE": JUEGO_PIERDE, "JUEGO_GANA": JUEGO_GANA, "PARTIDO": PARTIDO
        ]
        let pool = pools[key] ?? []
        guard !pool.isEmpty else { return "" }
        let loser = 1 - winner
        return draw(key, pool)
            .replacingOccurrences(of: "{G}", with: cfg.names[winner])
            .replacingOccurrences(of: "{P}", with: cfg.names[loser])
            .replacingOccurrences(of: "{g}", with: cfg.players[winner].randomElement() ?? "")
            .replacingOccurrences(of: "{p}", with: cfg.players[loser].randomElement() ?? "")
    }
}
`;
const swPath = path.join(root, "ios/PadelScoreboard/Phrases.swift");
let sw = fs.readFileSync(swPath, "utf8");
const swMark = "\n// MARK: - Modo guasa";
if (sw.includes(swMark)) sw = sw.slice(0, sw.indexOf(swMark));
fs.writeFileSync(swPath, sw.replace(/\s*$/, "\n") + swift);

// ---------------- JavaScript (dentro del HTML, entre marcas)
const js = `/* @guasa-inicio — generado: mismo banco que Android e iPhone (${total} frases)
   Huecos: {G} pareja que gana el punto · {g} uno de sus jugadores
           {P} pareja que lo pierde      · {p} uno de sus jugadores */
const GUASA = {
${NAMES.map(n => `  ${n}:[\n${list(n, "    ")}\n  ]`).join(",\n")}
};
const GUASA_PUNTO = 0.25;   // uno de cada cuatro puntos, más o menos, al azar
const guasaBolsas = {};
/** Bolsas barajadas: no se repite una frase hasta haber dicho todas las de su lista. */
function guasaSaca(k){
  let b = guasaBolsas[k];
  if(!b || !b.length){
    b = GUASA[k].slice();
    for(let i=b.length-1;i>0;i--){ const j = Math.floor(Math.random()*(i+1)); [b[i],b[j]] = [b[j],b[i]]; }
    guasaBolsas[k] = b;
  }
  return b.shift();
}
/** Coletilla para el punto que acaba de ganar \`t\`, o "" si no toca.
    Siempre al acabar juego, set o partido; en los demás puntos, uno de cada cuatro.
    La mitad de las veces da caña a quien pierde y la otra mitad alaba a quien gana. */
function guasaFrase(t, ev){
  if(!cfg.guasa || (t !== 0 && t !== 1)) return "";
  const alaba = Math.random() < 0.5;
  let k;
  if(ev.match) k = "PARTIDO";
  else if(ev.game || ev.set) k = alaba ? "JUEGO_GANA" : "JUEGO_PIERDE";
  else if(Math.random() < GUASA_PUNTO) k = alaba ? "PUNTO_GANA" : "PUNTO_PIERDE";
  else return "";
  const o = 1-t, uno = arr => arr[Math.floor(Math.random()*arr.length)];
  return guasaSaca(k)
    .replace(/\\{G\\}/g, cfg.names[t]).replace(/\\{P\\}/g, cfg.names[o])
    .replace(/\\{g\\}/g, uno(cfg.players[t])).replace(/\\{p\\}/g, uno(cfg.players[o]));
}
/* @guasa-fin */
`;
const htmlPath = path.join(root, "web/padel-scoreboard.html");
let html = fs.readFileSync(htmlPath, "utf8");
const a = html.indexOf("/* @guasa-inicio"), z = html.indexOf("/* @guasa-fin */");
if (a >= 0 && z > a) html = html.slice(0, a) + js + html.slice(z + "/* @guasa-fin */\n".length);
else {
  const anchor = "function updateVoiceBtn(){";
  if (!html.includes(anchor)) throw new Error("No encuentro dónde meter las frases en el HTML");
  html = html.replace(anchor, js + "\n" + anchor);
}
fs.writeFileSync(htmlPath, html);
console.log("Frases:", NAMES.map(n => n + "=" + F[n].length).join(" "), "total", total);

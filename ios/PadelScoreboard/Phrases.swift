import Foundation

/// Construcción de las frases que canta el marcador, separada de la voz
/// para poder probarla. Son las mismas que en la versión web y Android.
enum Phrases {

    private static let pointWords = ["cero", "quince", "treinta", "cuarenta"]
    private static let numbers = [
        "cero", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete",
        "ocho", "nueve", "diez", "once", "doce", "trece", "catorce", "quince"
    ]

    static func nw(_ n: Int) -> String {
        (n >= 0 && n < numbers.count) ? numbers[n] : String(n)
    }

    /// Tanteo del juego en curso, empezando por quien saca.
    static func points(_ m: Match, _ cfg: Cfg) -> String {
        let srv = Rules.serverOf(m, cfg).team
        let rec = 1 - srv
        if m.tiebreak {
            return m.tb[srv] == m.tb[rec]
                ? "iguales a " + nw(m.tb[srv])
                : nw(m.tb[srv]) + " " + nw(m.tb[rec])
        }
        let a = m.pts[srv]
        let b = m.pts[rec]
        if a == 4 { return "ventaja " + cfg.names[srv] }
        if b == 4 { return "ventaja " + cfg.names[rec] }
        if a == 3 && b == 3 { return cfg.golden ? "cuarenta iguales punto de oro" : "iguales" }
        if a == b { return pointWords[a] + " iguales" }
        return pointWords[a] + " " + pointWords[b]
    }

    static func serveLine(_ m: Match, _ cfg: Cfg) -> String {
        if m.finished { return "" }
        let side = cfg.voiceCourtSide ? " desde la " + Rules.serveSide(m) : ""
        if cfg.voiceServer { return "saca " + Rules.serverName(m, cfg) + side }
        if cfg.voiceCourtSide { return "saque desde la " + Rules.serveSide(m) }
        return ""
    }

    static func games(_ m: Match, _ cfg: Cfg, alreadySaid: Int = -1) -> String {
        let g = m.games
        if g[0] == 0 && g[1] == 0 { return "" }
        if g[0] == g[1] { return "iguales a " + nw(g[0]) }
        let l = g[0] > g[1] ? 0 : 1
        let tail = alreadySaid == l ? "" : " para " + cfg.names[l]
        return nw(g[l]) + " " + nw(g[1 - l]) + tail
    }

    static func sets(_ m: Match, _ cfg: Cfg) -> String {
        let a = m.setsWon[0]
        let b = m.setsWon[1]
        if a == b { return "empate a " + (a == 1 ? "un set" : nw(a) + " sets") }
        let l = a > b ? 0 : 1
        let n = m.setsWon[l]
        let part = n == 1 ? "un set a " : nw(n) + " sets a "
        return cfg.names[l] + " gana " + part + nw(m.setsWon[1 - l])
    }

    /// El super tie-break se canta por sus puntos, no por el juego.
    static func setScore(_ s: SetScore, _ t: Int) -> String {
        let sup = s.hadTiebreak && (s.a + s.b) == 1
        let a = sup ? s.tb(t) : s.games(t)
        let b = sup ? s.tb(1 - t) : s.games(1 - t)
        return nw(a) + " " + nw(b)
    }

    /// Devuelve las partes a decir y si van separadas por punto (fin de juego,
    /// set o partido) o por coma (tanteo dentro del juego).
    static func announce(_ m: Match, _ t: Int, _ ev: Events, _ cfg: Cfg) -> ([String], Bool) {
        var parts: [String] = []
        let change = (ev.side && !ev.match && cfg.voiceSwitch) ? "cambio de lado" : ""

        if ev.match {
            parts.append("juego set y partido para " + cfg.names[m.winner])
            parts.append(m.sets.map { setScore($0, m.winner) }.joined(separator: " "))
            return (parts, true)
        }
        if ev.set {
            let s = m.sets.last ?? SetScore(a: 0, b: 0)
            parts.append("juego y set para " + cfg.names[t])
            parts.append(setScore(s, t))
            parts.append(sets(m, cfg))
            if ev.tbStart { parts.append("se decide en super tie break a " + nw(m.tbTarget) + " puntos") }
            parts.append(change)
            parts.append(serveLine(m, cfg))
            return (parts, true)
        }
        if ev.game {
            parts.append("juego para " + cfg.names[t])
            parts.append(games(m, cfg, alreadySaid: t))
            if ev.tbStart { parts.append("tie break") }
            parts.append(change)
            parts.append(serveLine(m, cfg))
            return (parts, true)
        }

        parts.append(points(m, cfg))
        parts.append(change)
        parts.append(serveLine(m, cfg))
        for k in 0...1 {
            let s = Rules.stake(m, k, cfg)
            if s == "Punto de set" || s == "Punto de partido" {
                parts.append(s.lowercased() + " para " + cfg.names[k])
            }
        }
        return (parts, false)
    }
}

// MARK: - Modo guasa

/**
 Modo guasa: coletillas con mala uva que se dicen después del tanteo.
 Mismo banco de frases que en la web y en Android (138 frases).

 Huecos de cada frase:
  {G} pareja que gana el punto · {g} uno de sus jugadores
  {P} pareja que lo pierde      · {p} uno de sus jugadores
 */
enum Guasa {

    /// Probabilidad de frase en un punto normal.
    private static let pointChance = 0.4
    /// Como mucho, dos puntos seguidos sin frase: el tercero siempre la lleva.
    private static let maxSilent = 2
    private static var silent = 0

    private static let PUNTO_PIERDE: [String] = [
        "{p}, esa bola la devolvía mejor mi abuela con el andador",
        "{p}, la pala se coge por el mango, por si nadie te lo había dicho",
        "{p}, ¿has venido a jugar o a hacerte fotos para Instagram?",
        "Tranquilidad, {p}, que la red también necesita cariño",
        "{p}, eso no ha sido un golpe, ha sido un estornudo",
        "{p}, la próxima vez apunta, que es gratis",
        "{p}, el cristal ya ha pedido una orden de alejamiento contra ti",
        "Ánimo, {p}, que hacer el ridículo también quema calorías",
        "{p}, menos zapatillas caras y más flexionar las piernas",
        "{p}, juegas como si la pelota te debiera dinero",
        "{p}, hoy no es tu día. Ni tu semana. Ni tu año",
        "{p}, eso en mi pueblo se llama regalar",
        "{p}, ese golpe merece una multa",
        "{p}, si quieres te dejo mi pala, que la tuya está claro que no funciona",
        "{p}, aún estás buscando la pelota, ¿verdad?",
        "{p}, has mandado la bola tan lejos que va a llegar a Portugal",
        "{p}, tu revés es como el wifi del club: va cuando quiere",
        "{p}, la bandeja era para la pelota, no para servir cañas",
        "{p}, ¿eso era un globo o una consulta al cielo?",
        "{p}, hasta los de la pista de al lado se están riendo",
        "{p}, se te ha visto venir desde el aparcamiento",
        "{p}, ese punto lo cuento en la cena de Navidad",
        "{p}, piernas de gelatina y manos de mantequilla. Combo completo",
        "{p}, tu pala acaba de pedir el traslado",
        "{p}, la pared es tu amiga, pero hoy no te habla",
        "{p}, ¿necesitas gafas o es que te da igual?",
        "{p}, más que pádel lo tuyo es danza contemporánea",
        "{p}, la culpa no es de la pala, te lo aseguro",
        "{p}, has llegado a esa bola con la puntualidad de un tren de cercanías",
        "{p}, la red te ha ganado el punto. La red, que ni se mueve",
        "{P}, ¿os pongo una silla y lo veis desde fuera?",
        "{P}, os recuerdo que esto se juega con pelota",
        "{P}, parecéis dos estatuas decorando la pista",
        "{P}, si regalar puntos diera dinero estaríais jubilados",
        "{P}, la comunicación en pareja no es lo vuestro, ¿eh?",
        "{P}, ¿seguís calentando? Porque llevamos un buen rato",
        "Punto para {G}, y {P} mirando a las musarañas",
        "{P}, os habéis quedado mirando la pelota como quien mira un eclipse",
        "{P}: mía, tuya, de nadie. Clásico",
        "{P}, ¿jugáis juntos o cada uno en su partido?",
        "{P}, ese punto lo habéis perdido con mucho estilo. Del malo",
        "{P}, alguien debería llamar a vuestro entrenador. Y despedirlo",
        "{P}, por el centro de la pista ha pasado un autobús y nadie se ha movido"
    ]

    private static let PUNTO_GANA: [String] = [
        "{g}, eso ha sido nivel profesional. Que alguien le firme un contrato",
        "{g}, con esa derecha deberían ponerte una calle",
        "{g}, eso no es un golpe, es una obra de arte",
        "Cuidado, que {g} está en modo bestia",
        "{g}, juegas tan bien que da hasta rabia",
        "{g} acaba de humillar a {p} en directo y sin anestesia",
        "{g}, esa víbora ha dejado a {p} temblando",
        "{g}, ese remate se ha oído en el pueblo de al lado",
        "{g}, por cuatro y a la calle. Que vayan a buscarla al bar",
        "{g}, qué muñeca. Eso no se entrena, eso se nace",
        "{g}, tienes más clase que un colegio entero",
        "{g}, buena planta y encima juegas bien. Qué injusto es el mundo",
        "{g}, esa dejada ha sido una caricia. Con mala intención, pero una caricia",
        "{g}, si sigues así vamos a tener que cobrar entrada",
        "{g}, el pádel te debería pagar a ti",
        "{g}, eso ha sido tan bonito que casi lloro",
        "Atención, que {g} está jugando con el modo dios activado",
        "{g}, ese golpe se merece repetición a cámara lenta",
        "{g}, de mayor quiero jugar como tú",
        "{g}, has puesto la bola donde has querido. Como siempre",
        "{g}, eso ha sido un misil teledirigido",
        "{g}, {p} todavía está buscando por dónde ha pasado eso",
        "{g}, tu pala debería estar en un museo",
        "{G}, así se juega. El resto, que tome apuntes",
        "{G}, estáis on fire. Que alguien traiga un extintor",
        "{G}, punto de libro. Y de libro de los caros",
        "{G}, qué química. Ni en las telenovelas",
        "{G}, os entendéis con la mirada. Qué bonito es el amor",
        "{G}, esto ya no es un partido, es una exhibición",
        "{G}, sois una pared. Y además con mala leche",
        "{G}, con vosotros en la pista hasta el cristal sonríe",
        "{G}, punto de los que se cuentan a los nietos",
        "{G}, qué manera de bailar a los de enfrente",
        "{G}, menudo puntazo. Que suene la música",
        "Lo de {G} es delito. Que alguien llame a la policía",
        "{G}, ni en la tele se ven puntos así"
    ]

    private static let JUEGO_PIERDE: [String] = [
        "{P}, otro juego que se os escapa. Como vuestra dignidad",
        "{P}, ese juego lo habéis regalado con lazo y todo",
        "{P}, tranquilos, que perder también es un arte. Y lo domináis",
        "{P}, cuando queráis empezáis a jugar, sin prisa",
        "{P}, las cañas de después las pagáis vosotros. Está decidido",
        "{P}, a este paso os van a cobrar la pista el doble",
        "{P}, dicen que entrenáis. Pues no se nota",
        "¿Alguien ha visto a {P}? Porque en la pista no están",
        "{P}, juego perdido. Id preparando la excusa del sol",
        "{P}, os han pasado por encima como una apisonadora",
        "{P}, a este ritmo acabamos antes de que se caliente la cerveza",
        "{P}, otro juego más para la colección de desastres",
        "{P}, más que un juego eso ha sido una donación",
        "{P}, el marcador no miente. Vosotros sí, cuando decís que sabéis jugar",
        "{P}, ¿pedimos un tiempo muerto? Porque muertos ya estáis",
        "{P}, se os ve con muchas ganas. De que acabe",
        "{p}, invita tú a las cañas, que este juego lo has perdido tú solito",
        "{p}, ese juego va directo a tu historial delictivo",
        "{p}, ¿quieres que llamemos a alguien para que te sustituya?",
        "{p}, el pádel no es lo tuyo. Prueba con la petanca",
        "{p}, ese juego lo vas a soñar esta noche. En pesadilla",
        "{p}, tranquilidad, que tu pareja te sigue queriendo. Más o menos",
        "{p}, a tu pareja se le está poniendo cara de divorcio",
        "{p}, ¿has pensado en el ajedrez? Ahí se corre menos",
        "{p}, tu pala está pidiendo a gritos otro dueño"
    ]

    private static let JUEGO_GANA: [String] = [
        "{G}, ese juego lo enmarcamos y lo colgamos en el bar del club",
        "{G}, otro juego al saco. Esto ya es un atraco a mano armada",
        "{G}, mandáis en la pista. El resto, que mire y aprenda",
        "{G}, juegazo. Y sin despeinarse",
        "{G}, qué fácil se juega cuando enfrente no hay nadie",
        "{G}, juego de campeones. Id preparando el discurso",
        "{G}, qué paseo militar. Solo faltaba la banda de música",
        "{G}, esto es como quitarle un caramelo a un niño",
        "{G}, la pista es vuestra. Los demás pagan alquiler",
        "{G}, otro juego más. Ya no sabemos ni dónde guardarlos",
        "{G}, sois la envidia del club. Y con razón",
        "{G}, ese juego merece una ovación. Venga, todos de pie",
        "{G}, juego limpio, rápido y con humillación incluida",
        "{G}, seguid así y os hacen una estatua a la entrada",
        "{G}, vais sobrados. Sobradísimos",
        "{G}, ese juego ha sido más redondo que la pelota",
        "{g}, ese juego ha sido tuyo. {p} sigue buscando la pelota",
        "{g}, si sigues así te van a pedir autógrafos en el aparcamiento",
        "{g}, ese juego lo has firmado tú. Y con letra bonita",
        "{g}, hoy estás que te sales. Y {p} que no entra",
        "Todos querrían a {g} de pareja. Y nadie enfrente",
        "{g}, lo tuyo no es talento, es brujería"
    ]

    private static let PARTIDO: [String] = [
        "{G}, campeones. Y {P}, a pagar las cañas, como manda la tradición",
        "{P}, partido para la historia. Para la historia del ridículo",
        "{G}, os habéis paseado. {P} todavía no sabe ni qué ha pasado",
        "{p}, vete pensando una excusa, que lo del codo ya no cuela",
        "{G}, enhorabuena. Lo de enfrente ha sido un entrenamiento",
        "{P}, mañana más. Y seguramente peor",
        "{G}, leyendas. Que os pongan una placa en esta pista",
        "{P}, la revancha cuando queráis. Y la paliza también",
        "{g}, hoy invitas tú, que para eso has sido el mejor de la pista",
        "{P}, no estéis tristes. Bueno, un poco sí",
        "{G}, partido redondo. A presumir al grupo de WhatsApp",
        "{p}, borra este partido de tu memoria. Nosotros no lo haremos"
    ]

    /// Bolsas barajadas: siempre al azar, nunca en el orden de la lista, y no se repite
    /// una frase hasta haber dicho todas las de su lista. Al rebarajar, la primera de la
    /// bolsa nueva nunca es la última que se dijo.
    private static var bags: [String: [String]] = [:]
    private static var last: [String: String] = [:]

    private static func draw(_ key: String, _ pool: [String]) -> String {
        var bag = bags[key] ?? []
        if bag.isEmpty {
            bag = pool.shuffled()
            if bag.count > 1, bag[0] == last[key] {
                bag.swapAt(0, Int.random(in: 1..<bag.count))
            }
        }
        let s = bag.removeFirst()
        bags[key] = bag
        last[key] = s
        return s
    }

    /// Coletilla para el punto que acaba de ganar `winner`, o "" si no toca.
    /// Siempre al acabar juego, set o partido; en los demás puntos, al azar (4 de cada 10)
    /// y nunca más de dos puntos seguidos sin frase.
    /// La mitad de las veces da caña a quien pierde y la otra mitad alaba a quien gana.
    static func phrase(winner: Int, _ ev: Events, _ cfg: Cfg) -> String {
        guard cfg.guasa, winner == 0 || winner == 1 else { return "" }
        let alaba = Bool.random()
        let key: String
        if ev.match {
            key = "PARTIDO"
        } else if ev.game || ev.set {
            key = alaba ? "JUEGO_GANA" : "JUEGO_PIERDE"
        } else if silent >= maxSilent || Double.random(in: 0..<1) < pointChance {
            key = alaba ? "PUNTO_GANA" : "PUNTO_PIERDE"
        } else {
            silent += 1
            return ""
        }
        silent = 0
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

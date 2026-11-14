package com.vrgspn.marcadorpadel

import kotlin.random.Random

/**
 * Modo guasa: coletillas con mala uva que se dicen después del tanteo.
 * Mismo banco de frases que en la web y en iPhone (138 frases).
 *
 * Huecos de cada frase:
 *  {G} pareja que gana el punto · {g} uno de sus jugadores
 *  {P} pareja que lo pierde      · {p} uno de sus jugadores
 */
object Guasa {

    /** Uno de cada cuatro puntos, más o menos, al azar. */
    private const val POINT_CHANCE = 0.25

    private val PUNTO_PIERDE = listOf(
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
    )

    private val PUNTO_GANA = listOf(
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
    )

    private val JUEGO_PIERDE = listOf(
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
    )

    private val JUEGO_GANA = listOf(
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
    )

    private val PARTIDO = listOf(
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
    )

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

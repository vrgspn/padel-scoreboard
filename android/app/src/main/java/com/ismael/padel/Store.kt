package com.ismael.padel

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Guarda ajustes y partido en el propio móvil, para que nada se pierda al salir. */
class Store(context: Context) {

    private val prefs = context.getSharedPreferences("padel", Context.MODE_PRIVATE)

    fun saveCfg(cfg: Cfg) {
        val j = JSONObject()
        j.put("names", JSONArray(cfg.names))
        j.put("players", JSONArray(listOf(JSONArray(cfg.players[0]), JSONArray(cfg.players[1]))))
        j.put("firstServeTeam", cfg.firstServeTeam)
        j.put("firstServePlayer", cfg.firstServePlayer)
        j.put("bestOf", cfg.bestOf)
        j.put("golden", cfg.golden)
        j.put("tiebreak", cfg.tiebreak)
        j.put("superTb", cfg.superTb)
        j.put("oneButton", cfg.oneButton)
        j.put("burstWindowMs", cfg.burstWindowMs)
        j.put("volumeKeys", cfg.volumeKeys)
        j.put("voice", cfg.voice)
        j.put("voiceServer", cfg.voiceServer)
        j.put("voiceCourtSide", cfg.voiceCourtSide)
        j.put("voiceSwitch", cfg.voiceSwitch)
        j.put("voiceRate", cfg.voiceRate.toDouble())
        j.put("vibrate", cfg.vibrate)
        j.put("keepAwake", cfg.keepAwake)
        j.put("autoSwap", cfg.autoSwap)
        j.put("sideAlert", cfg.sideAlert)
        prefs.edit().putString("cfg", j.toString()).apply()
    }

    fun loadCfg(): Cfg {
        val raw = prefs.getString("cfg", null) ?: return Cfg()
        return try {
            val j = JSONObject(raw)
            val d = Cfg()
            val names = j.optJSONArray("names")
            val players = j.optJSONArray("players")
            Cfg(
                names = if (names != null) listOf(names.getString(0), names.getString(1)) else d.names,
                players = if (players != null) listOf(
                    listOf(players.getJSONArray(0).getString(0), players.getJSONArray(0).getString(1)),
                    listOf(players.getJSONArray(1).getString(0), players.getJSONArray(1).getString(1))
                ) else d.players,
                firstServeTeam = j.optInt("firstServeTeam", d.firstServeTeam),
                firstServePlayer = j.optInt("firstServePlayer", d.firstServePlayer),
                bestOf = j.optInt("bestOf", d.bestOf),
                golden = j.optBoolean("golden", d.golden),
                tiebreak = j.optBoolean("tiebreak", d.tiebreak),
                superTb = j.optBoolean("superTb", d.superTb),
                oneButton = j.optBoolean("oneButton", d.oneButton),
                burstWindowMs = j.optLong("burstWindowMs", d.burstWindowMs),
                volumeKeys = j.optBoolean("volumeKeys", d.volumeKeys),
                voice = j.optBoolean("voice", d.voice),
                voiceServer = j.optBoolean("voiceServer", d.voiceServer),
                voiceCourtSide = j.optBoolean("voiceCourtSide", d.voiceCourtSide),
                voiceSwitch = j.optBoolean("voiceSwitch", d.voiceSwitch),
                voiceRate = j.optDouble("voiceRate", d.voiceRate.toDouble()).toFloat(),
                vibrate = j.optBoolean("vibrate", d.vibrate),
                keepAwake = j.optBoolean("keepAwake", d.keepAwake),
                autoSwap = j.optBoolean("autoSwap", d.autoSwap),
                sideAlert = j.optBoolean("sideAlert", d.sideAlert)
            )
        } catch (e: Exception) {
            Cfg()
        }
    }

    fun saveMatch(m: Match) {
        val j = JSONObject()
        j.put("pts", JSONArray(m.pts))
        j.put("games", JSONArray(m.games))
        j.put("setsWon", JSONArray(m.setsWon))
        val sets = JSONArray()
        m.sets.forEach {
            sets.put(JSONObject().apply {
                put("a", it.a); put("b", it.b); put("tbA", it.tbA); put("tbB", it.tbB)
            })
        }
        j.put("sets", sets)
        j.put("serveIdx", m.serveIdx)
        j.put("tiebreak", m.tiebreak)
        j.put("tb", JSONArray(m.tb))
        j.put("tbTarget", m.tbTarget)
        j.put("tbStartIdx", m.tbStartIdx)
        j.put("swapped", m.swapped)
        j.put("startedAt", m.startedAt)
        j.put("elapsed", m.elapsed)
        j.put("finished", m.finished)
        j.put("winner", m.winner)
        prefs.edit().putString("match", j.toString()).apply()
    }

    fun loadMatch(): Match {
        val raw = prefs.getString("match", null) ?: return Match()
        return try {
            val j = JSONObject(raw)
            val sets = mutableListOf<SetScore>()
            val arr = j.optJSONArray("sets")
            if (arr != null) for (i in 0 until arr.length()) {
                val s = arr.getJSONObject(i)
                sets += SetScore(s.getInt("a"), s.getInt("b"), s.optInt("tbA", -1), s.optInt("tbB", -1))
            }
            fun ints(name: String, def: List<Int>): List<Int> {
                val a = j.optJSONArray(name) ?: return def
                return listOf(a.getInt(0), a.getInt(1))
            }
            Match(
                pts = ints("pts", listOf(0, 0)),
                games = ints("games", listOf(0, 0)),
                setsWon = ints("setsWon", listOf(0, 0)),
                sets = sets,
                serveIdx = j.optInt("serveIdx", 0),
                tiebreak = j.optBoolean("tiebreak", false),
                tb = ints("tb", listOf(0, 0)),
                tbTarget = j.optInt("tbTarget", 7),
                tbStartIdx = j.optInt("tbStartIdx", 0),
                swapped = j.optBoolean("swapped", false),
                startedAt = j.optLong("startedAt", 0L),
                elapsed = j.optLong("elapsed", 0L),
                finished = j.optBoolean("finished", false),
                winner = j.optInt("winner", -1)
            )
        } catch (e: Exception) {
            Match()
        }
    }
}

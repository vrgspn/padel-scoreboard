import Foundation

/// Guarda ajustes y partido en el propio iPhone o iPad,
/// para que nada se pierda al cerrar la app.
struct Store {

    private let defaults = UserDefaults.standard
    private let cfgKey = "padel.cfg"
    private let matchKey = "padel.match"

    init() {}

    func saveCfg(_ cfg: Cfg) {
        if let data = try? JSONEncoder().encode(cfg) {
            defaults.set(data, forKey: cfgKey)
        }
    }

    func loadCfg() -> Cfg {
        guard let data = defaults.data(forKey: cfgKey),
              let cfg = try? JSONDecoder().decode(Cfg.self, from: data) else { return Cfg() }
        return cfg
    }

    func saveMatch(_ m: Match) {
        if let data = try? JSONEncoder().encode(m) {
            defaults.set(data, forKey: matchKey)
        }
    }

    func loadMatch() -> Match {
        guard let data = defaults.data(forKey: matchKey),
              let m = try? JSONDecoder().decode(Match.self, from: data) else { return Match() }
        return m
    }
}

import Foundation

/// macOS's own languages; `Locale.preferredLanguages` reads Tinycast's own language instead.
enum SystemLanguages {
    static var preferred: [String] {
        #if os(macOS)
        let global = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)
        return global?["AppleLanguages"] as? [String] ?? Locale.preferredLanguages
        #else
        return Locale.crossSystemPreferredLanguages
        #endif
    }
}

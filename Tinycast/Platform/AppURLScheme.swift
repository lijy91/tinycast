import Foundation

/// This channel's own link scheme: `tinycast`, or `tinycast-dev` for Debug. Set in project.yml.
enum AppURLScheme {
    static let current: String = {
        if let scheme = Bundle.main.object(forInfoDictionaryKey: "TinycastURLScheme") as? String {
            return scheme
        }
        #if os(macOS)
        preconditionFailure("Info.plist must name TinycastURLScheme")
        #elseif DEBUG
        return "tinycast-dev"
        #else
        return "tinycast"
        #endif
    }()
}

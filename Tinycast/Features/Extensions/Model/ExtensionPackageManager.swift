import Foundation

/// Installs an extension's dependencies before a build. Only an install from GitHub needs one.
enum ExtensionPackageManager: String, CaseIterable, Codable, Identifiable, Sendable {
    case automatic
    case pnpm
    case npm
    case yarn
    case bun

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return String(localized: "Automatic")
        case .pnpm: return "pnpm"
        case .npm: return "npm"
        case .yarn: return "Yarn"
        case .bun: return "Bun"
        }
    }

    /// `automatic`'s order: fastest and most disk-frugal first, npm last as the one always there.
    static let preferenceOrder: [ExtensionPackageManager] = [.pnpm, .bun, .yarn, .npm]

    var executableName: String {
        switch self {
        case .automatic: return ""
        #if os(Windows)
        case .pnpm: return "pnpm.cmd"
        case .npm: return "npm.cmd"
        case .yarn: return "yarn.cmd"
        case .bun: return "bun.exe"
        #else
        case .pnpm: return "pnpm"
        case .npm: return "npm"
        case .yarn: return "yarn"
        case .bun: return "bun"
        #endif
        }
    }

    static var pathSeparator: Character {
        #if os(Windows)
        return ";"
        #else
        return ":"
        #endif
    }

    /// Not the frozen-lockfile variants: a committed lockfile is often stale.
    var installArguments: [String] {
        switch self {
        case .automatic: return []
        case .pnpm: return ["install", "--ignore-scripts"]
        case .npm: return ["install", "--ignore-scripts", "--no-audit", "--no-fund"]
        case .yarn: return ["install", "--ignore-scripts"]
        case .bun: return ["install", "--ignore-scripts"]
        }
    }

    /// Runs the manifest's `build` script, which for a Raycast extension is `ray build`.
    var buildArguments: [String] {
        switch self {
        case .automatic: return []
        case .pnpm: return ["run", "build"]
        case .npm: return ["run", "build"]
        case .yarn: return ["run", "build"]
        case .bun: return ["run", "build"]
        }
    }

    /// A GUI app inherits no shell PATH; anything rarer is `extensionCustomSearchPaths`.
    #if os(Windows)
    static let searchPaths: [String] = {
        let env = ProcessInfo.processInfo.environment
        var paths: [String] = []
        if let pf = env["ProgramFiles"] { paths.append(pf + "\\nodejs") }
        if let local = env["LOCALAPPDATA"] {
            paths.append(local + "\\pnpm")
            paths.append(local + "\\Volta\\bin")
        }
        if let appData = env["APPDATA"] { paths.append(appData + "\\npm") }
        paths.append(NSHomeDirectory() + "\\.bun\\bin")
        paths.append(NSHomeDirectory() + "\\.volta\\bin")
        if let sysPath = env["PATH"] {
            for p in sysPath.split(separator: ";").map(String.init) where !p.isEmpty && !paths.contains(p) {
                paths.append(p)
            }
        }
        return paths
    }()
    #else
    static let searchPaths: [String] = [
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/usr/bin",
        "/bin",
        NSHomeDirectory() + "/.volta/bin",
        NSHomeDirectory() + "/.bun/bin",
        NSHomeDirectory() + "/.asdf/shims",
        NSHomeDirectory() + "/.local/share/mise/shims",
        NSHomeDirectory() + "/.local/share/fnm/aliases/default/bin",
        NSHomeDirectory() + "/.nvm/versions/node/current/bin",
        NSHomeDirectory() + "/.yarn/bin",
        NSHomeDirectory() + "/.npm-global/bin"
    ]
    #endif

    /// `additionalSearchPaths` is checked first, so a user folder can win over a built-in.
    func resolve(
        in fileManager: FileManager = .default, additionalSearchPaths: [String] = []
    ) -> (manager: ExtensionPackageManager, url: URL)? {
        guard self != .automatic else {
            for candidate in Self.preferenceOrder {
                if let found = candidate.resolve(
                    in: fileManager, additionalSearchPaths: additionalSearchPaths)
                {
                    return found
                }
            }
            return nil
        }
        for directory in additionalSearchPaths + Self.searchPaths {
            let candidate = URL(fileURLWithPath: directory).appendingPathComponent(executableName)
            if fileManager.isExecutableFile(atPath: candidate.path) { return (self, candidate) }
        }
        return nil
    }

    /// `ray build` runs on Node, and bun is the one manager that doesn't imply it.
    static func nodeURL(
        in fileManager: FileManager = .default, additionalSearchPaths: [String] = []
    ) -> URL? {
        #if os(Windows)
        let nodeName = "node.exe"
        #else
        let nodeName = "node"
        #endif
        for directory in additionalSearchPaths + searchPaths {
            let candidate = URL(fileURLWithPath: directory).appendingPathComponent(nodeName)
            if fileManager.isExecutableFile(atPath: candidate.path) { return candidate }
        }
        return nil
    }
}

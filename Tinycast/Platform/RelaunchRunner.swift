import Foundation

/// `open` on a running bundle id only re-activates it, so the relaunch outlives us.
enum RelaunchRunner {
    static func relaunchAfterExit(_ bundleURL: URL) {
        #if os(macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        let quoted = bundleURL.path.replacingOccurrences(of: "'", with: "'\\''")
        process.arguments = [
            "-c",
            "while /bin/kill -0 \(getpid()) 2>/dev/null; do /bin/sleep 0.2; done; "
                + "/usr/bin/open '\(quoted)'"
        ]
        // Orphaned on our exit and reparented to launchd, which is the whole point.
        try? process.run()
        #elseif os(Windows)
        guard let exe = ProcessInfo.processInfo.arguments.first else { return }
        let process = Process()
        let comspec = ProcessInfo.processInfo.environment["ComSpec"] ?? "C:\\Windows\\System32\\cmd.exe"
        process.executableURL = URL(fileURLWithPath: comspec)
        process.arguments = ["/c", "ping -n 2 127.0.0.1 >nul & start \"\" \"\(exe)\""]
        try? process.run()
        #endif
    }
}

import Foundation
#if os(Windows)
import WinSDK
#endif

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
        guard let exe = ProcessInfo.processInfo.arguments.first, !exe.isEmpty else { return }
        let escaped = exe.replacingOccurrences(of: "\"", with: "\\\"")
        var commandLine = Array("\"\(escaped)\" --relaunch\0".utf16)
        var startupInfo = STARTUPINFOW()
        startupInfo.cb = DWORD(MemoryLayout<STARTUPINFOW>.size)
        var processInfo = PROCESS_INFORMATION()
        let flags = DWORD(CREATE_NEW_PROCESS_GROUP | DETACHED_PROCESS)
        let launched = exe.withCString(encodedAs: UTF16.self) { appPtr in
            commandLine.withUnsafeMutableBufferPointer { cmdBuf in
                CreateProcessW(
                    appPtr, cmdBuf.baseAddress, nil, nil, false, flags, nil, nil,
                    &startupInfo, &processInfo)
            }
        }
        if launched {
            CloseHandle(processInfo.hThread)
            CloseHandle(processInfo.hProcess)
        }
        #endif
    }
}

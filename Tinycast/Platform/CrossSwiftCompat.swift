#if !os(macOS)
@_exported import CrossFoundation
typealias NSCache = CrossFoundation.NSCache
typealias DispatchSourceTimer = CrossFoundation._CrossDispatchSourceTimer
#if os(Windows)
typealias timespec = Darwin._CrossTimespec
#endif
#endif

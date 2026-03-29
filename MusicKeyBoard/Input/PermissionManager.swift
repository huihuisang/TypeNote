import Cocoa

/// Manages system permissions required for keyboard monitoring.
struct PermissionManager {

    /// Check and request "Input Monitoring" permission.
    /// CGEventTap in .listenOnly mode only requires this permission.
    static func ensureInputMonitoring() {
        if !CGPreflightListenEventAccess() {
            CGRequestListenEventAccess()
        }
    }

    /// Check if Input Monitoring permission has been granted.
    static var hasInputMonitoring: Bool {
        CGPreflightListenEventAccess()
    }

    /// Check and optionally prompt for "Accessibility" permission.
    /// Only needed if intercepting/modifying events (not for listen-only mode).
    @discardableResult
    static func ensureAccessibility() -> Bool {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt as String: true
        ]
        return AXIsProcessTrustedWithOptions(options)
    }

    /// Check Accessibility permission without prompting.
    static var hasAccessibility: Bool {
        AXIsProcessTrusted()
    }
}

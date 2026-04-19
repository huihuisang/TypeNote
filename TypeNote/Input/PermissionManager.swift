import Cocoa

/// Manages system permissions required for keyboard monitoring.
struct PermissionManager {

    private static let onboardingCompletedKey = "onboardingCompleted"

    // MARK: - Input Monitoring

    /// Check and request "Input Monitoring" permission.
    static func ensureInputMonitoring() {
        if !CGPreflightListenEventAccess() {
            CGRequestListenEventAccess()
        }
    }

    /// Check if Input Monitoring permission has been granted.
    static var hasInputMonitoring: Bool {
        CGPreflightListenEventAccess()
    }

    // MARK: - Onboarding

    /// Whether onboarding has been completed.
    static var isOnboardingCompleted: Bool {
        UserDefaults.standard.bool(forKey: onboardingCompletedKey)
    }

    /// Mark onboarding as completed.
    static func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
    }

}

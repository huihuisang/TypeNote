import Cocoa
import Carbon

/// Monitors global keyboard events using CGEventTap.
/// Requires "Input Monitoring" permission (System Settings > Privacy & Security).
final class GlobalKeyboardMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var onKeyDown: ((Int64) -> Void)?
    var onKeyUp: ((Int64) -> Void)?

    func start() {
        guard eventTap == nil else { return }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
                                   | (1 << CGEventType.keyUp.rawValue)
        let userInfo = Unmanaged.passRetained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, userInfo -> Unmanaged<CGEvent>? in
                // Handle tap being disabled by system timeout protection
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let userInfo {
                        let monitor = Unmanaged<GlobalKeyboardMonitor>
                            .fromOpaque(userInfo).takeUnretainedValue()
                        if let tap = monitor.eventTap {
                            CGEvent.tapEnable(tap: tap, enable: true)
                        }
                    }
                    return Unmanaged.passUnretained(event)
                }

                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<GlobalKeyboardMonitor>
                    .fromOpaque(userInfo).takeUnretainedValue()
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

                if type == .keyDown {
                    monitor.onKeyDown?(keyCode)
                } else if type == .keyUp {
                    monitor.onKeyUp?(keyCode)
                }

                return Unmanaged.passUnretained(event)
            },
            userInfo: userInfo
        ) else { return }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)!
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        CFMachPortInvalidate(tap)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    deinit {
        stop()
    }
}

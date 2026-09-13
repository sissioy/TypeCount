import Foundation

public enum MonitoringStartDecision: Equatable {
    case start
    case permissionRequired
}

public enum MonitoringPolicy {
    public static func startDecision(permissionGranted: Bool) -> MonitoringStartDecision {
        permissionGranted ? .start : .permissionRequired
    }

    public static func shouldRecord(isPaused: Bool) -> Bool {
        !isPaused
    }

    public static func shouldReenable(eventTypeRawValue: UInt32) -> Bool {
        eventTypeRawValue == UInt32.max || eventTypeRawValue == UInt32.max - 1
    }
}

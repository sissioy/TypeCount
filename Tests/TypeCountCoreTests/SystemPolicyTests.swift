import Testing
@testable import TypeCountCore

@Suite("System policy")
struct SystemPolicyTests {
    @Test func permissionDecision() {
        #expect(MonitoringPolicy.startDecision(permissionGranted: true) == .start)
        #expect(MonitoringPolicy.startDecision(permissionGranted: false) == .permissionRequired)
    }

    @Test func disabledEventTapRequestsReenable() {
        #expect(MonitoringPolicy.shouldReenable(eventTypeRawValue: UInt32.max))
        #expect(MonitoringPolicy.shouldReenable(eventTypeRawValue: UInt32.max - 1))
        #expect(!MonitoringPolicy.shouldReenable(eventTypeRawValue: 10))
    }

    @Test func pausePolicy() {
        #expect(MonitoringPolicy.shouldRecord(isPaused: false))
        #expect(!MonitoringPolicy.shouldRecord(isPaused: true))
    }
}

import AppKit
import Combine
import CoreGraphics
import Foundation
import TypeCountCore

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var permissionGranted = false
    @Published private(set) var monitoringActive = false

    let store: DailyStatsStore

    private let inputSource: InputSourceMonitor
    private let eventMonitor: EventTapMonitor
    private var permissionTimer: Timer?

    init(defaults: UserDefaults = .standard) {
        self.store = DailyStatsStore(defaults: defaults)
        self.inputSource = InputSourceMonitor()
        self.eventMonitor = EventTapMonitor(store: store, inputSource: inputSource)
    }

    func start() {
        refreshSystemState()
        if !permissionGranted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.requestPermission()
            }
        }

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshSystemState()
            }
        }
    }

    func stop() {
        permissionTimer?.invalidate()
        permissionTimer = nil
        eventMonitor.stop()
        store.flush()
    }

    func requestPermission() {
        _ = CGRequestListenEventAccess()
        refreshSystemState()
        if !permissionGranted {
            openInputMonitoringSettings()
        }
    }

    func openInputMonitoringSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

    func refreshSystemState() {
        store.rolloverIfNeeded()
        inputSource.refresh()

        if CGPreflightListenEventAccess() {
            monitoringActive = eventMonitor.start()
        } else {
            eventMonitor.stop()
            monitoringActive = false
        }
        permissionGranted = monitoringActive
    }

    func setTrackingEnabled(_ enabled: Bool) {
        store.setPaused(!enabled)
        if enabled {
            refreshSystemState()
        }
    }

    func retryMonitoring() {
        refreshSystemState()
    }
}

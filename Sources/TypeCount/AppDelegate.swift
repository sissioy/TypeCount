import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var menuBarController: MenuBarController?
    private var observers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let model = AppModel()
        self.model = model
        self.menuBarController = MenuBarController(model: model)
        installLifecycleObservers()
        model.start()

        let processInfo = ProcessInfo.processInfo
        if processInfo.environment["TYPECOUNT_SHOW_POPOVER_FOR_UI_TEST"] == "1" ||
            processInfo.arguments.contains("--ui-test-popover") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.menuBarController?.showPopoverForUITest()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        model?.stop()
        removeLifecycleObservers()
    }

    private func installLifecycleObservers() {
        let workspace = NSWorkspace.shared.notificationCenter
        observers.append(workspace.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.model?.store.flush() }
        })
        observers.append(workspace.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.model?.refreshSystemState() }
        })

        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.model?.store.rolloverIfNeeded() }
        })
        observers.append(center.addObserver(
            forName: NSNotification.Name.NSSystemClockDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.model?.refreshSystemState() }
        })
    }

    private func removeLifecycleObservers() {
        let workspace = NSWorkspace.shared.notificationCenter
        let center = NotificationCenter.default
        for observer in observers {
            workspace.removeObserver(observer)
            center.removeObserver(observer)
        }
        observers.removeAll()
    }
}

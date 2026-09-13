import AppKit
import Combine
import SwiftUI

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let model: AppModel
    private var cancellables = Set<AnyCancellable>()

    init(model: AppModel) {
        self.model = model
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        configureStatusItem()
        configurePopover()
        observeStats()
        updateTooltip()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "TypeCount")
        image?.isTemplate = true
        button.image = image
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(togglePopover)
        button.sendAction(on: [.leftMouseUp])
        button.setAccessibilityLabel("TypeCount")
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: PopoverView(model: model))
        popover.contentSize = NSSize(width: 310, height: 360)
    }

    private func observeStats() {
        model.store.$records
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateTooltip() }
            .store(in: &cancellables)

        model.store.$isPaused
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateTooltip() }
            .store(in: &cancellables)

        model.$permissionGranted
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updatePopoverSize() }
            .store(in: &cancellables)
    }

    private func updateTooltip() {
        let count = model.store.todayCount.formatted(.number.grouping(.automatic))
        let prefix = model.store.isPaused ? "Paused · " : ""
        let tooltip = "\(prefix)Today: \(count)"
        statusItem.button?.toolTip = tooltip
        statusItem.button?.setAccessibilityHelp(tooltip)
    }

    private func updatePopoverSize() {
        var height: CGFloat = 360
        if !model.permissionGranted { height += 180 }
        popover.contentSize = NSSize(width: 310, height: height)
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }

        showPopover()
    }

    func showPopoverForUITest() {
        popover.behavior = .applicationDefined
        showPopover()
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        model.refreshSystemState()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
}

import CoreGraphics
import Foundation
import TypeCountCore

final class EventTapMonitor {
    private let store: DailyStatsStore
    private let inputSource: InputSourceMonitor
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(store: DailyStatsStore, inputSource: InputSourceMonitor) {
        self.store = store
        self.inputSource = inputSource
    }

    var isRunning: Bool { eventTap != nil }

    func start() -> Bool {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
            return CGEvent.tapIsEnabled(tap: eventTap)
        }

        let context = Unmanaged.passUnretained(self).toOpaque()
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { _, type, event, context in
                guard let context else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<EventTapMonitor>.fromOpaque(context).takeUnretainedValue()
                DispatchQueue.main.async {
                    monitor.handle(type: type, event: event)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: context
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
        return CGEvent.tapIsEnabled(tap: tap)
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    @MainActor
    private func handle(type: CGEventType, event: CGEvent) {
        if MonitoringPolicy.shouldReenable(eventTypeRawValue: type.rawValue) {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return
        }
        guard type == .keyDown else { return }

        let flags = event.flags
        let keystroke = Keystroke(
            keyCode: UInt16(event.getIntegerValueField(.keyboardEventKeycode)),
            hasCommand: flags.contains(.maskCommand),
            hasControl: flags.contains(.maskControl)
        )
        let halfUnits = KeystrokeRules.halfUnits(
            for: keystroke,
            isChineseInputSource: inputSource.isChinese
        )
        store.record(halfUnits: halfUnits)
    }
}

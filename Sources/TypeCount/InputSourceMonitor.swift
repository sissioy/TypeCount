import Carbon
import Foundation
import TypeCountCore

final class InputSourceMonitor {
    private(set) var isChinese = false
    private var observer: NSObjectProtocol?

    init() {
        refresh()
        observer = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        if let observer {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    func refresh() {
        let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        var languages: [String] = []
        var identifiers: [String] = []

        if let pointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) {
            let value = Unmanaged<CFArray>.fromOpaque(pointer).takeUnretainedValue()
            languages = value as? [String] ?? []
        }

        for property in [kTISPropertyInputSourceID, kTISPropertyBundleID, kTISPropertyInputModeID] {
            if let pointer = TISGetInputSourceProperty(source, property) {
                let value = Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue()
                identifiers.append(value as String)
            }
        }

        isChinese = InputSourceClassifier.isChinese(languages: languages, identifiers: identifiers)
    }
}

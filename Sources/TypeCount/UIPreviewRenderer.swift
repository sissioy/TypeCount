import AppKit
import SwiftUI

@MainActor
enum UIPreviewRenderer {
    enum PreviewError: Error {
        case renderingFailed
        case encodingFailed
    }

    static func requestedOutputPath() -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "--render-ui-preview") else { return nil }
        let pathIndex = arguments.index(after: flagIndex)
        guard pathIndex < arguments.endIndex else { return nil }
        return arguments[pathIndex]
    }

    static func render(to path: String) throws {
        let suiteName = "TypeCount.UIPreview.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw PreviewError.renderingFailed
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let model = AppModel(defaults: defaults)
        model.store.record(halfUnits: 2_568)
        model.store.flush()

        let content = PopoverView(model: model)
            .environment(\.colorScheme, .dark)
        let hostingView = NSHostingView(rootView: content)
        hostingView.appearance = NSAppearance(named: .darkAqua)
        hostingView.frame = NSRect(origin: .zero, size: hostingView.fittingSize)
        hostingView.layoutSubtreeIfNeeded()

        guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw PreviewError.renderingFailed
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw PreviewError.encodingFailed
        }
        try pngData.write(to: URL(fileURLWithPath: path), options: .atomic)
    }
}

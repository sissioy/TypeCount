import AppKit

@main
struct TypeCountApplication {
    @MainActor
    static func main() {
        let application = NSApplication.shared

        if let previewPath = UIPreviewRenderer.requestedOutputPath() {
            do {
                try UIPreviewRenderer.render(to: previewPath)
            } catch {
                fputs("TypeCount preview failed: \(error)\n", stderr)
                exit(1)
            }
            return
        }

        let delegate = AppDelegate()
        application.delegate = delegate
        application.run()
    }
}

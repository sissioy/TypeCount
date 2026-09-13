import Foundation

public struct Keystroke: Equatable, Sendable {
    public let keyCode: UInt16
    public let hasCommand: Bool
    public let hasControl: Bool

    public init(keyCode: UInt16, hasCommand: Bool = false, hasControl: Bool = false) {
        self.keyCode = keyCode
        self.hasCommand = hasCommand
        self.hasControl = hasControl
    }
}

public enum KeystrokeRules {
    private static let letterKeyCodes: Set<UInt16> = [
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17,
        31, 32, 34, 35, 37, 38, 40, 45, 46
    ]

    private static let printableKeyCodes: Set<UInt16> = letterKeyCodes.union([
        18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 33, 39, 41,
        42, 43, 44, 47, 49, 50, 65, 67, 69, 75, 78, 81, 82, 83, 84, 85,
        86, 87, 88, 89, 91, 92, 93, 94, 95
    ])

    public static func halfUnits(for keystroke: Keystroke, isChineseInputSource: Bool) -> Int {
        guard !keystroke.hasCommand, !keystroke.hasControl else { return 0 }
        guard printableKeyCodes.contains(keystroke.keyCode) else { return 0 }

        if isChineseInputSource, letterKeyCodes.contains(keystroke.keyCode) {
            return 1
        }
        return 2
    }
}

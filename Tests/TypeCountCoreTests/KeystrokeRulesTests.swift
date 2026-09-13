import Testing
@testable import TypeCountCore

@Suite("Keystroke rules")
struct KeystrokeRulesTests {
    @Test func englishPrintableKeysCountOneCharacter() {
        #expect(KeystrokeRules.halfUnits(for: Keystroke(keyCode: 0), isChineseInputSource: false) == 2)
        #expect(KeystrokeRules.halfUnits(for: Keystroke(keyCode: 18), isChineseInputSource: false) == 2)
        #expect(KeystrokeRules.halfUnits(for: Keystroke(keyCode: 43), isChineseInputSource: false) == 2)
        #expect(KeystrokeRules.halfUnits(for: Keystroke(keyCode: 49), isChineseInputSource: false) == 2)
    }

    @Test func chineseLettersCountHalfAndOtherPrintableKeysCountOne() {
        #expect(KeystrokeRules.halfUnits(for: Keystroke(keyCode: 0), isChineseInputSource: true) == 1)
        #expect(KeystrokeRules.halfUnits(for: Keystroke(keyCode: 18), isChineseInputSource: true) == 2)
        #expect(KeystrokeRules.halfUnits(for: Keystroke(keyCode: 43), isChineseInputSource: true) == 2)
        #expect(KeystrokeRules.halfUnits(for: Keystroke(keyCode: 49), isChineseInputSource: true) == 2)
    }

    @Test func commandAndControlShortcutsAreIgnored() {
        #expect(
            KeystrokeRules.halfUnits(
                for: Keystroke(keyCode: 0, hasCommand: true),
                isChineseInputSource: false
            ) == 0
        )
        #expect(
            KeystrokeRules.halfUnits(
                for: Keystroke(keyCode: 0, hasControl: true),
                isChineseInputSource: true
            ) == 0
        )
    }

    @Test func navigationAndEditingKeysAreIgnored() {
        for keyCode: UInt16 in [36, 48, 51, 53, 123, 124, 125, 126] {
            #expect(
                KeystrokeRules.halfUnits(for: Keystroke(keyCode: keyCode), isChineseInputSource: false) == 0
            )
        }
    }

    @Test func repeatedKeyDownEventsEachCount() {
        let event = Keystroke(keyCode: 0)
        let total = (0..<5).reduce(0) { result, _ in
            result + KeystrokeRules.halfUnits(for: event, isChineseInputSource: false)
        }
        #expect(total == 10)
    }
}

@Suite("Input source classification")
struct InputSourceClassifierTests {
    @Test func commonChineseInputSources() {
        #expect(InputSourceClassifier.isChinese(
            languages: ["zh-Hans"],
            identifiers: ["com.apple.inputmethod.SCIM.ITABC"]
        ))
        #expect(InputSourceClassifier.isChinese(
            languages: [],
            identifiers: ["com.apple.inputmethod.SCIM.Shuangpin"]
        ))
        #expect(InputSourceClassifier.isChinese(
            languages: [],
            identifiers: ["com.tencent.inputmethod.wetype.pinyin"]
        ))
    }

    @Test func abcIsNotChinese() {
        #expect(!InputSourceClassifier.isChinese(
            languages: ["en"],
            identifiers: ["com.apple.keylayout.ABC"]
        ))
    }
}

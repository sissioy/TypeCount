import Foundation

public enum InputSourceClassifier {
    public static func isChinese(languages: [String], identifiers: [String]) -> Bool {
        if languages.contains(where: { language in
            let normalized = language.lowercased()
            return normalized == "zh" || normalized.hasPrefix("zh-") || normalized.hasPrefix("zh_")
        }) {
            return true
        }

        let markers = [
            "chinese", "pinyin", "shuangpin", "wetype", "sogou", "rime",
            "baidu", "scim"
        ]
        return identifiers.contains { identifier in
            let normalized = identifier.lowercased()
            return markers.contains(where: normalized.contains)
        }
    }
}

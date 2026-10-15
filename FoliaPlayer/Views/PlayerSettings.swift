import SwiftUI

@MainActor
final class PlayerSettings: ObservableObject {
    @Published var theme: PlayerTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "folia.settings.theme") }
    }
    @Published var lyricFontSize: Double {
        didSet { UserDefaults.standard.set(lyricFontSize, forKey: "folia.settings.lyricFontSize") }
    }

    init() {
        theme = PlayerTheme(rawValue: UserDefaults.standard.string(forKey: "folia.settings.theme") ?? "aurora") ?? .aurora
        let savedSize = UserDefaults.standard.object(forKey: "folia.settings.lyricFontSize") as? Double
        lyricFontSize = savedSize ?? 28
    }
}

enum PlayerTheme: String, CaseIterable, Identifiable {
    case aurora
    case midnight
    case ocean

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aurora: return "极光"
        case .midnight: return "午夜"
        case .ocean: return "深海"
        }
    }

    var colors: [Color] {
        switch self {
        case .aurora:
            return [Color(red: 0.15, green: 0.18, blue: 0.32), Color(red: 0.34, green: 0.18, blue: 0.38), Color(red: 0.08, green: 0.34, blue: 0.37)]
        case .midnight:
            return [Color(red: 0.04, green: 0.05, blue: 0.10), Color(red: 0.12, green: 0.13, blue: 0.20)]
        case .ocean:
            return [Color(red: 0.03, green: 0.20, blue: 0.34), Color(red: 0.06, green: 0.34, blue: 0.45), Color(red: 0.05, green: 0.12, blue: 0.26)]
        }
    }
}

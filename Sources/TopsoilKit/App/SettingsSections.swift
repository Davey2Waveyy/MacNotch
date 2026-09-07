import Foundation

enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case modules = "Modules"
    case design = "Design"
    case privacy = "Privacy"
    case shortcuts = "Shortcuts"
    case about = "About"

    var id: String { rawValue }
}

extension SettingsSection {
    var icon: String {
        switch self {
        case .general: "macbook"
        case .modules: "square.grid.2x2"
        case .design: "paintpalette"
        case .privacy: "hand.raised"
        case .shortcuts: "keyboard"
        case .about: "info.circle"
        }
    }

    var subtitle: String {
        switch self {
        case .general: "Settle into a workspace that feels like yours."
        case .modules: "Choose what earns a place in your notch."
        case .design: "Fine-tune the way your workspace looks and moves."
        case .privacy: "Your permissions, used when you need them."
        case .shortcuts: "Less reaching. More doing."
        case .about: "A quiet home for your everyday tools."
        }
    }
}

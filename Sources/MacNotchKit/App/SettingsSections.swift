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

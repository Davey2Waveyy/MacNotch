import SwiftUI

struct DesignSettingsView: View {
    @Binding var settings: AppSettings
    let onChange: (AppSettings) -> Void

    var body: some View {
        Form {
            Section("Preset") {
                Picker("Theme", selection: Binding(
                    get: { settings.appearance.preset },
                    set: { preset in
                        SettingsLogic.setAppearancePreset(&settings, preset: preset)
                        onChange(settings)
                    }
                )) {
                    ForEach(AppearancePreset.launchPresets, id: \.self) { preset in
                        Text(label(for: preset)).tag(preset)
                    }
                }
            }

            Section("Feel") {
                Picker("Accent Color", selection: Binding(
                    get: { settings.appearance.accentColor },
                    set: { accent in
                        SettingsLogic.setAccentColor(&settings, accentColor: accent)
                        onChange(settings)
                    }
                )) {
                    ForEach(AccentColorChoice.allCases, id: \.self) { accent in
                        Text(label(for: accent)).tag(accent)
                    }
                }

                Picker("Glass Intensity", selection: Binding(
                    get: { settings.appearance.glassIntensity },
                    set: { intensity in
                        SettingsLogic.setGlassIntensity(&settings, glassIntensity: intensity)
                        onChange(settings)
                    }
                )) {
                    Text("Subtle").tag(GlassIntensity.subtle)
                    Text("Balanced").tag(GlassIntensity.balanced)
                    Text("Vivid").tag(GlassIntensity.vivid)
                }

                Picker("Corner Style", selection: Binding(
                    get: { settings.appearance.cornerStyle },
                    set: { corner in
                        SettingsLogic.setCornerStyle(&settings, cornerStyle: corner)
                        onChange(settings)
                    }
                )) {
                    Text("Precise").tag(CornerStyle.precise)
                    Text("Soft").tag(CornerStyle.soft)
                    Text("Pill").tag(CornerStyle.pill)
                }

                Picker("Density", selection: Binding(
                    get: { settings.appearance.panelDensity },
                    set: { density in
                        SettingsLogic.setPanelDensity(&settings, density: density)
                        onChange(settings)
                    }
                )) {
                    Text("Compact").tag(PanelDensity.compact)
                    Text("Comfortable").tag(PanelDensity.comfortable)
                    Text("Spacious").tag(PanelDensity.spacious)
                }

                Picker("Motion", selection: Binding(
                    get: { settings.appearance.motionStyle },
                    set: { motion in
                        SettingsLogic.setMotionStyle(&settings, motionStyle: motion)
                        onChange(settings)
                    }
                )) {
                    Text("Expressive").tag(MotionStyle.expressive)
                    Text("Calm").tag(MotionStyle.calm)
                    Text("Reduced").tag(MotionStyle.reduced)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func label(for preset: AppearancePreset) -> String {
        switch preset {
        case .studioGlass: return "Studio Glass"
        case .minimalGraphite: return "Minimal Graphite"
        case .aurora: return "Aurora"
        case .terminal: return "Terminal"
        case .paper: return "Paper"
        }
    }

    private func label(for accent: AccentColorChoice) -> String {
        switch accent {
        case .cyan: return "Cyan"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .green: return "Green"
        case .amber: return "Amber"
        case .red: return "Red"
        }
    }
}

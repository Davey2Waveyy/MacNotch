import SwiftUI

struct OnboardingView: View {
    let onComplete: (OnboardingState) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Welcome to \(NotchBrand.productName)")
                .font(.system(size: 28, weight: .bold))
            Text("Your notch becomes a customizable command center for media, code, timers, reminders, files, and focused work.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                Text("Permissions are requested only when a module needs them.")
                Text("Calendar access powers upcoming events.")
                Text("Automation access powers Music and Spotify controls.")
                Text("Dropped files stay local through security-scoped bookmarks.")
                Text(NotchBrand.affiliationDisclaimer)
            }
            .font(.system(size: 12))
            Spacer()
            Button("Start Using \(NotchBrand.productName)") {
                onComplete(OnboardingState(hasCompletedFirstRun: true, completedVersion: AppCore.version))
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(28)
        .frame(width: 640, height: 480)
    }
}

import SwiftUI

struct ModuleEmptyStateView: View {
    @Environment(\.notchTokens) private var tokens
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(tokens.accent.opacity(0.85))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.90))
            Text(message)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct ModuleLoadingStateView: View {
    let message: String

    var body: some View {
        ProgressView(message)
            .progressViewStyle(.circular)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.75))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(message)
    }
}

struct ModulePermissionStateView: View {
    @Environment(\.notchTokens) private var tokens
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ModuleEmptyStateView(title: title, message: message, systemImage: "lock.shield")
            Button(actionTitle, action: action)
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 7).fill(tokens.accent.opacity(0.18)))
        }
    }
}

struct ModuleErrorStateView: View {
    let title: String
    let message: String
    let retry: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            ModuleEmptyStateView(title: title, message: message, systemImage: "exclamationmark.triangle")
            if let retry {
                Button("Retry", action: retry)
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .semibold))
            }
        }
    }
}

import SwiftUI

struct ModuleEmptyStateView: View {
    @Environment(\.notchTokens) private var tokens
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(tokens.accent.opacity(0.85))
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: tokens.controlCornerRadius + 2, style: .continuous)
                        .fill(.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: tokens.controlCornerRadius + 2, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 0.75)
                )
            VStack(spacing: 2) {
                Text(title)
                    .font(tokens.labelFont.weight(.semibold))
                    .foregroundStyle(tokens.textSecondary)
                Text(message)
                    .font(tokens.captionFont)
                    .foregroundStyle(tokens.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .frame(maxWidth: 200)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct ModuleLoadingStateView: View {
    @Environment(\.notchTokens) private var tokens
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
            Text(message)
                .font(tokens.captionFont)
                .foregroundStyle(tokens.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(message)
    }
}

struct ModulePermissionStateView: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ModuleEmptyStateView(title: title, message: message, systemImage: "lock.shield")
            Button(actionTitle, action: action)
                .buttonStyle(.notchSoft)
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
                    .buttonStyle(.notchGhost)
            }
        }
    }
}

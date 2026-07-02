import SwiftUI

struct NotchIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }
}

struct NotchSegmentedControl<Option: Hashable, Label: View>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> Label

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    label(option)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selection == option ? Color.white.opacity(0.14) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct NotchFocusRing: ViewModifier {
    let isFocused: Bool

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: NotchTheme.tileCornerRadius)
                .strokeBorder(isFocused ? NotchTheme.accent.opacity(0.85) : .clear, lineWidth: 1.5)
        )
    }
}

extension View {
    func notchFocusRing(isFocused: Bool) -> some View {
        modifier(NotchFocusRing(isFocused: isFocused))
    }
}

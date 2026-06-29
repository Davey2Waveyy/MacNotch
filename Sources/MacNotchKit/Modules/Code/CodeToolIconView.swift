import AppKit
import SwiftUI

struct CodeToolIcon: View {
    let tool: CodeCLITool
    var size: CGFloat = 14

    var body: some View {
        Group {
            if let image = CodeToolIconProvider.icon(for: tool) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: max(3, size * 0.22), style: .continuous))
            } else {
                Image(systemName: tool.systemImage)
                    .font(.system(size: size * 0.82, weight: .semibold))
                    .foregroundStyle(codeToolFallbackAccent(for: tool))
            }
        }
        .frame(width: size, height: size)
    }
}

enum CodeToolIconProvider {
    static func icon(for tool: CodeCLITool) -> NSImage? {
        for path in tool.appIconCandidatePaths where FileManager.default.fileExists(atPath: path) {
            let image = NSWorkspace.shared.icon(forFile: path)
            guard image.isValid else { continue }
            let copy = image.copy() as? NSImage ?? image
            copy.size = NSSize(width: 64, height: 64)
            return copy
        }
        return nil
    }
}

private func codeToolFallbackAccent(for tool: CodeCLITool) -> Color {
    switch tool {
    case .claude: return Color(red: 0.78, green: 0.52, blue: 1.00)
    case .codex: return Color(red: 0.36, green: 0.78, blue: 1.00)
    case .cursor: return Color(red: 0.27, green: 0.98, blue: 0.72)
    }
}

import Foundation
import MacNotchKit

func codeModuleCoreTests() {
    // ---- GitStatusParser ----
    test("git: parses branch, ahead/behind, and dirty flag") {
        let output = "## main...origin/main [ahead 1, behind 2]\n M file.swift\n?? new.txt"
        let status = GitStatusParser.parse(output)
        expect(status.branch == "main", "branch is main")
        expect(status.isDirty, "working tree is dirty")
        expectEqual(status.ahead, 1, "ahead count")
        expectEqual(status.behind, 2, "behind count")
    }

    test("git: clean repo with no upstream") {
        let status = GitStatusParser.parse("## feature/login")
        expect(status.branch == "feature/login", "branch parsed")
        expect(!status.isDirty, "clean")
        expectEqual(status.ahead, 0, "no ahead")
        expectEqual(status.behind, 0, "no behind")
    }

    test("git: detached HEAD has no branch") {
        let status = GitStatusParser.parse("## HEAD (no branch)\n M f.swift")
        expect(status.branch == nil, "no branch when detached")
        expect(status.isDirty, "dirty")
    }

    test("git: empty output is unknown") {
        expectEqual(GitStatusParser.parse(""), GitStatus.unknown, "empty parses to unknown")
    }

    // ---- LaunchCommandBuilder ----
    test("launch: editor command runs the editor CLI with the path") {
        let cmd = LaunchCommandBuilder.command(for: .editor, path: "/tmp/proj")
        expectEqual(cmd.executable, "/usr/bin/env", "uses env")
        expect(cmd.arguments == ["code", "/tmp/proj"], "code <path>")
    }

    test("launch: terminal and reveal use open") {
        expect(LaunchCommandBuilder.command(for: .terminal, path: "/tmp/p").arguments == ["-a", "Terminal", "/tmp/p"], "open -a Terminal")
        expect(LaunchCommandBuilder.command(for: .reveal, path: "/tmp/p").arguments == ["-R", "/tmp/p"], "open -R")
    }

    test("launch: claude code opens Terminal running claude in the path") {
        let cmd = LaunchCommandBuilder.command(for: .claudeCode, path: "/tmp/my proj")
        expectEqual(cmd.executable, "/usr/bin/osascript", "uses osascript")
        expect(cmd.arguments.first == "-e", "passes a script")
        let script = cmd.arguments.last ?? ""
        expect(script.contains("claude"), "runs claude")
        expect(script.contains("'/tmp/my proj'"), "cd's into the quoted path")
        expect(script.contains("do script"), "uses Terminal do script")
    }

    test("launch: shell single-quoting escapes embedded quotes") {
        expectEqual(LaunchCommandBuilder.shellSingleQuote("/a b"), "'/a b'", "spaces wrapped")
        expectEqual(LaunchCommandBuilder.shellSingleQuote("it's"), "'it'\\''s'", "apostrophe escaped")
    }

    // ---- CodeProjectStore ----
    func tempStoreURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    }
    func tempDir() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    test("code store: pin persists and resolves the folder") {
        let storeURL = tempStoreURL()
        let folder = tempDir()
        let a = CodeProjectStore(url: storeURL)
        a.add(folder)
        expect(a.projects.count == 1, "one project pinned")
        expect(a.projects.first?.name == folder.lastPathComponent, "name captured")

        let b = CodeProjectStore(url: storeURL)
        expect(b.projects.count == 1, "survives reload")
        expect(b.resolve(b.projects[0])?.standardizedFileURL.path == folder.standardizedFileURL.path, "resolves to folder")
    }

    test("code store: pinning the same folder twice is ignored") {
        let store = CodeProjectStore(url: tempStoreURL())
        let folder = tempDir()
        store.add(folder)
        store.add(folder)
        expect(store.projects.count == 1, "deduped")
    }

    test("code store: remove drops the project") {
        let store = CodeProjectStore(url: tempStoreURL())
        store.add(tempDir())
        store.remove(at: 0)
        expect(store.projects.isEmpty, "removed")
    }
}

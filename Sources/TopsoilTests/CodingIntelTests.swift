import Foundation
import TopsoilKit

func codingIntelTests() {
    test("github trends: request searches recent repositories sorted by stars") {
        let since = Date(timeIntervalSince1970: 1_803_124_800) // 2027-02-20 00:00:00Z
        let url = GitHubTrendingRequest.url(since: since, limit: 6)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let query = Dictionary(uniqueKeysWithValues: components?.queryItems?.map { ($0.name, $0.value ?? "") } ?? [])

        expectEqual(url.host, "api.github.com", "host")
        expectEqual(url.path, "/search/repositories", "path")
        expect(query["q"]?.contains("created:>=2027-02-20") == true, "uses created date qualifier")
        expectEqual(query["sort"], "stars", "sorts by stars")
        expectEqual(query["order"], "desc", "sort order")
        expectEqual(query["per_page"], "6", "limit")
    }

    test("github trends: parser keeps repo essentials") {
        let json = """
        {
          "items": [
            {
              "full_name": "owner/tool",
              "html_url": "https://github.com/owner/tool",
              "description": "A useful thing",
              "stargazers_count": 1234,
              "language": "Swift"
            }
          ]
        }
        """.data(using: .utf8)!

        let repos = (try? GitHubTrendingParser.parse(json)) ?? []
        expectEqual(repos.count, 1, "one repo")
        expectEqual(repos.first?.fullName, "owner/tool", "full name")
        expectEqual(repos.first?.stars, 1234, "stars")
        expectEqual(repos.first?.language, "Swift", "language")
    }

    test("skills: discovery lists skill folders per coding cli") {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let codex = root.appendingPathComponent("codex", isDirectory: true)
        let claude = root.appendingPathComponent("claude", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: codex.appendingPathComponent("reviewer", isDirectory: true),
            withIntermediateDirectories: true
        )
        try? FileManager.default.createDirectory(
            at: claude.appendingPathComponent("planner", isDirectory: true),
            withIntermediateDirectories: true
        )
        try? "ignore".write(
            to: codex.appendingPathComponent(".DS_Store"),
            atomically: true,
            encoding: .utf8
        )
        defer { try? FileManager.default.removeItem(at: root) }

        let roots = [
            SkillSearchRoot(cli: .codex, url: codex),
            SkillSearchRoot(cli: .claude, url: claude),
        ]
        let skills = CodingSkillDiscovery.discover(in: roots)

        expectEqual(skills.map(\.name), ["planner", "reviewer"], "names sorted")
        expect(skills.contains(InstalledCodingSkill(cli: .codex, name: "reviewer", sourcePath: codex.path)), "codex skill")
        expect(skills.contains(InstalledCodingSkill(cli: .claude, name: "planner", sourcePath: claude.path)), "claude skill")
    }

    test("skills: presentation leads with skill names and treats cli as source metadata") {
        let skills = [
            InstalledCodingSkill(cli: .codex, name: "brainstorming", sourcePath: "/tmp/codex"),
            InstalledCodingSkill(cli: .claude, name: "frontend-design", sourcePath: "/tmp/claude"),
            InstalledCodingSkill(cli: .cursor, name: "rules", sourcePath: "/tmp/cursor"),
        ]

        let items = InstalledSkillPresentation.displayItems(from: skills, limit: 2)

        expectEqual(items.map(\.name), ["brainstorming", "frontend-design"], "skill names are primary")
        expectEqual(items.map(\.sourceName), ["Codex", "Claude"], "cli labels are secondary source metadata")
        expectEqual(InstalledSkillPresentation.summaryLabel(total: skills.count, visible: items.count), "2 of 3 skills", "summary mentions skills")
    }
}

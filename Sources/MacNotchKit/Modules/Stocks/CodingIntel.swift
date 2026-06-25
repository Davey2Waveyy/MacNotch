import Foundation

public struct TrendingRepository: Equatable, Identifiable, Sendable {
    public var fullName: String
    public var url: URL
    public var description: String?
    public var stars: Int
    public var language: String?

    public init(fullName: String, url: URL, description: String?, stars: Int, language: String?) {
        self.fullName = fullName
        self.url = url
        self.description = description
        self.stars = stars
        self.language = language
    }

    public var id: String { fullName }
}

public enum GitHubTrendingRequest {
    public static func url(since: Date, limit: Int = 5) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = "/search/repositories"
        components.queryItems = [
            URLQueryItem(name: "q", value: "created:>=\(dayFormatter.string(from: since)) fork:false archived:false"),
            URLQueryItem(name: "sort", value: "stars"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "per_page", value: String(limit)),
        ]
        return components.url!
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

public enum GitHubTrendingParser {
    public static func parse(_ data: Data) throws -> [TrendingRepository] {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let items = json["items"] as? [[String: Any]]
        else { throw URLError(.cannotParseResponse) }

        return items.compactMap { item in
            guard
                let fullName = item["full_name"] as? String,
                let htmlURL = item["html_url"] as? String,
                let url = URL(string: htmlURL)
            else { return nil }

            return TrendingRepository(
                fullName: fullName,
                url: url,
                description: item["description"] as? String,
                stars: item["stargazers_count"] as? Int ?? 0,
                language: item["language"] as? String
            )
        }
    }
}

public enum GitHubTrendingFetcher {
    public static func fetch(now: Date = Date(), limit: Int = 5) async -> [TrendingRepository] {
        let since = Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: -1, to: now) ?? now
        let url = GitHubTrendingRequest.url(since: since, limit: limit)
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("MacNotch", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
            return (try? GitHubTrendingParser.parse(data)) ?? []
        } catch {
            return []
        }
    }
}

public struct SkillSearchRoot: Equatable, Sendable {
    public var cli: CodeCLITool
    public var url: URL

    public init(cli: CodeCLITool, url: URL) {
        self.cli = cli
        self.url = url
    }
}

public struct InstalledCodingSkill: Equatable, Identifiable, Sendable {
    public var cli: CodeCLITool
    public var name: String
    public var sourcePath: String

    public init(cli: CodeCLITool, name: String, sourcePath: String) {
        self.cli = cli
        self.name = name
        self.sourcePath = sourcePath
    }

    public var id: String { "\(cli.rawValue):\(sourcePath):\(name)" }
}

public enum CodingSkillDiscovery {
    public static func defaultRoots(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> [SkillSearchRoot] {
        [
            SkillSearchRoot(cli: .claude, url: homeDirectory.appendingPathComponent(".claude/skills", isDirectory: true)),
            SkillSearchRoot(cli: .claude, url: homeDirectory.appendingPathComponent(".claude/commands", isDirectory: true)),
            SkillSearchRoot(cli: .codex, url: homeDirectory.appendingPathComponent(".codex/skills", isDirectory: true)),
            SkillSearchRoot(cli: .codex, url: homeDirectory.appendingPathComponent(".agents/skills", isDirectory: true)),
            SkillSearchRoot(cli: .cursor, url: homeDirectory.appendingPathComponent(".cursor/rules", isDirectory: true)),
            SkillSearchRoot(
                cli: .cursor,
                url: homeDirectory
                    .appendingPathComponent("Library", isDirectory: true)
                    .appendingPathComponent("Application Support", isDirectory: true)
                    .appendingPathComponent("Cursor", isDirectory: true)
                    .appendingPathComponent("User", isDirectory: true)
                    .appendingPathComponent("rules", isDirectory: true)
            ),
        ]
    }

    public static func discover(in roots: [SkillSearchRoot] = defaultRoots()) -> [InstalledCodingSkill] {
        var seen = Set<String>()
        var skills: [InstalledCodingSkill] = []

        for root in roots {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: root.url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for item in contents {
                guard let name = skillName(for: item) else { continue }
                let key = "\(root.cli.rawValue):\(root.url.path):\(name)"
                guard seen.insert(key).inserted else { continue }
                skills.append(InstalledCodingSkill(cli: root.cli, name: name, sourcePath: root.url.path))
            }
        }

        return skills.sorted {
            if $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedSame {
                return $0.cli.rawValue < $1.cli.rawValue
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private static func skillName(for url: URL) -> String? {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
        if values?.isDirectory == true {
            return url.lastPathComponent
        }

        let allowedExtensions = ["md", "mdc", "markdown"]
        guard allowedExtensions.contains(url.pathExtension.lowercased()) else { return nil }
        return url.deletingPathExtension().lastPathComponent
    }
}

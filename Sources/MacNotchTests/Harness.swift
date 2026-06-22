import Foundation

public final class TestRunner: @unchecked Sendable {
    public static let shared = TestRunner()
    private var cases: [(String, () -> Void)] = []
    private(set) var checks = 0
    private(set) var failures = 0

    public func add(_ name: String, _ body: @escaping () -> Void) {
        cases.append((name, body))
    }

    public func record(_ pass: Bool, _ msg: String, _ file: String, _ line: Int) {
        checks += 1
        if pass {
            print("  ✓ \(msg)")
        } else {
            failures += 1
            print("  ✗ FAIL: \(msg)  [\(file):\(line)]")
        }
    }

    /// Runs every registered case; returns a process exit code (0 = all passed).
    public func runAll() -> Int {
        for (name, body) in cases {
            print("• \(name)")
            body()
        }
        print("\n\(checks) checks, \(failures) failure(s)")
        return failures == 0 ? 0 : 1
    }
}

public func test(_ name: String, _ body: @escaping () -> Void) {
    TestRunner.shared.add(name, body)
}

public func expect(_ condition: @autoclosure () -> Bool, _ message: String,
                   file: String = #fileID, line: Int = #line) {
    TestRunner.shared.record(condition(), message, file, line)
}

public func expectEqual<T: Equatable>(_ a: @autoclosure () -> T,
                                      _ b: @autoclosure () -> T,
                                      _ message: String,
                                      file: String = #fileID, line: Int = #line) {
    let av = a(), bv = b()
    TestRunner.shared.record(av == bv, "\(message) (\(av) == \(bv))", file, line)
}

import AppKit
import Foundation
import Combine

public enum PomodoroPhase: Equatable, Sendable {
    case focus
    case shortBreak
    case longBreak

    var label: String {
        switch self {
        case .focus: return "FOCUS"
        case .shortBreak: return "SHORT BREAK"
        case .longBreak: return "LONG BREAK"
        }
    }

    var color: String {
        switch self {
        case .focus: return "red"
        case .shortBreak: return "green"
        case .longBreak: return "blue"
        }
    }
}

@MainActor
public final class PomodoroStore: ObservableObject {
    // MARK: Config
    public var focusDuration: TimeInterval = 25 * 60
    public var shortBreakDuration: TimeInterval = 5 * 60
    public var longBreakDuration: TimeInterval = 15 * 60
    public let sessionsBeforeLongBreak = 4

    // MARK: State
    @Published public var phase: PomodoroPhase = .focus
    @Published public var isRunning = false
    @Published public var elapsed: TimeInterval = 0
    @Published public var completedSessions = 0
    @Published public var distractions: [String] = []

    private var timer: Timer?

    public init() {}

    public var duration: TimeInterval {
        switch phase {
        case .focus: return focusDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        }
    }

    public var remaining: TimeInterval { max(0, duration - elapsed) }
    public var progress: Double { duration > 0 ? min(1, elapsed / duration) : 0 }

    /// Which session (1–4) within the current long-break cycle we're on.
    public var sessionInCycle: Int { (completedSessions % sessionsBeforeLongBreak) + 1 }

    public func toggle() {
        if isRunning { pause() } else { start() }
    }

    public func start() {
        guard !isRunning else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    public func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    public func reset() {
        pause()
        elapsed = 0
    }

    public func skip() {
        pause()
        elapsed = 0
        advance()
    }

    public func logDistraction(_ note: String) {
        let entry = note.trimmingCharacters(in: .whitespaces)
        guard !entry.isEmpty else { return }
        distractions.insert(entry, at: 0)
        if distractions.count > 20 { distractions = Array(distractions.prefix(20)) }
    }

    private func tick() {
        elapsed += 1
        if elapsed >= duration {
            complete()
        }
    }

    private func complete() {
        pause()
        if phase == .focus {
            completedSessions += 1
            NSSound.beep()
        }
        elapsed = 0
        advance()
    }

    private func advance() {
        switch phase {
        case .focus:
            phase = completedSessions % sessionsBeforeLongBreak == 0 ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            phase = .focus
        }
    }
}

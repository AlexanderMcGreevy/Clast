import SwiftUI
import Combine

struct ActiveTimerState: Codable {
    let endTime: Date
    let totalDuration: Int // in seconds
    let breaksTaken: Int

    var isExpired: Bool {
        Date() >= endTime
    }

    var timeRemaining: Int {
        let remaining = Int(endTime.timeIntervalSince(Date()))
        return max(0, remaining)
    }
}

struct SessionData: Identifiable, Codable {
    let id: UUID
    let date: Date
    let duration: Int // in seconds
    let completed: Bool
    let breaksTaken: Int

    init(id: UUID = UUID(), date: Date = Date(), duration: Int, completed: Bool, breaksTaken: Int = 0) {
        self.id = id
        self.date = date
        self.duration = duration
        self.completed = completed
        self.breaksTaken = breaksTaken
    }

    var durationString: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var dateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let daysAgo = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            return "\(daysAgo) days ago"
        }
    }
}

@MainActor
class SessionManager: ObservableObject {
    @Published var sessions: [SessionData] = []
    @Published var activeTimer: ActiveTimerState?

    private let storageKey = "clast_sessions"
    private let activeTimerKey = "clast_active_timer"

    // Screen Time controller for app blocking (lazy to avoid simulator/preview crashes)
    lazy var focusController = ScreenTimeFocusController.shared

    init() {
        loadSessions()
        loadActiveTimer()
    }

    func addSession(_ session: SessionData) {
        sessions.insert(session, at: 0)
        saveSessions()
    }

    func logSession(duration: Int, completed: Bool, breaksTaken: Int) {
        let session = SessionData(
            duration: duration,
            completed: completed,
            breaksTaken: breaksTaken
        )
        addSession(session)
    }

    var totalSessions: Int {
        sessions.count
    }

    var successRate: Int {
        guard !sessions.isEmpty else { return 0 }
        let completedCount = sessions.filter { $0.completed }.count
        return Int((Double(completedCount) / Double(sessions.count)) * 100)
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([SessionData].self, from: data) {
            sessions = decoded
        }
    }

    func startTimer(duration: Int) async throws {
        let endTime = Date().addingTimeInterval(TimeInterval(duration))
        activeTimer = ActiveTimerState(
            endTime: endTime,
            totalDuration: duration,
            breaksTaken: 0
        )
        saveActiveTimer()

        // WIRING POINT: Start Screen Time blocking when timer starts
        // This will block the selected apps for the session duration
        let durationMinutes = duration / 60
        try await focusController.startFocus(durationMinutes: durationMinutes)
    }

    func updateTimerBreaks(breaksTaken: Int) {
        guard let timer = activeTimer else { return }
        activeTimer = ActiveTimerState(
            endTime: timer.endTime,
            totalDuration: timer.totalDuration,
            breaksTaken: breaksTaken
        )
        saveActiveTimer()
    }

    func clearActiveTimer() {
        activeTimer = nil
        UserDefaults.standard.removeObject(forKey: activeTimerKey)

        // WIRING POINT: Stop Screen Time blocking when timer ends
        // This will unblock all apps
        focusController.stopFocus()
    }

    private func saveActiveTimer() {
        if let timer = activeTimer,
           let encoded = try? JSONEncoder().encode(timer) {
            UserDefaults.standard.set(encoded, forKey: activeTimerKey)
        }
    }

    private func loadActiveTimer() {
        if let data = UserDefaults.standard.data(forKey: activeTimerKey),
           let decoded = try? JSONDecoder().decode(ActiveTimerState.self, from: data) {
            // Only restore if not expired
            if !decoded.isExpired {
                activeTimer = decoded
            } else {
                // Timer expired while app was closed - clear it
                UserDefaults.standard.removeObject(forKey: activeTimerKey)
            }
        }
    }
}

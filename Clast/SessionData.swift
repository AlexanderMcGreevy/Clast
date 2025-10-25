import SwiftUI
import Combine

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

    private let storageKey = "clast_sessions"

    init() {
        loadSessions()
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
}

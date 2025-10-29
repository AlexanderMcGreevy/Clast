import SwiftUI

@main
struct ClastApp: App {
    @StateObject private var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    /// Handle deep links from shield screen
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "clast" else { return }

        switch url.host {
        case "focus":
            // Deep link to focus session - handled by FocusHomeView
            // The active timer will automatically show the running session
            break

        default:
            break
        }
    }
}

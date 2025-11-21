import SwiftUI

struct ContentView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showCompletionScreen = false

    var body: some View {
        TabView {
            FocusHomeView()
                .tabItem {
                    Label("Focus", systemImage: "flame.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showCompletionScreen) {
            if let completedSession = sessionManager.pendingCompletionSession {
                SessionCompleteView(
                    session: completedSession,
                    onDismiss: {
                        sessionManager.clearPendingCompletion()
                        showCompletionScreen = false
                    }
                )
            }
        }
        .onAppear {
            // Check if there's a pending completion on app launch
            if sessionManager.pendingCompletionSession != nil {
                showCompletionScreen = true
            }
        }
        .onChange(of: sessionManager.pendingCompletionSession) { oldValue, newValue in
            // Show completion screen when a new pending completion is detected
            if newValue != nil && !showCompletionScreen {
                showCompletionScreen = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SessionManager())
}

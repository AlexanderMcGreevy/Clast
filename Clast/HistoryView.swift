import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var sessionManager: SessionManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Stats Summary
                    HStack(spacing: 20) {
                        StatCard(title: "Total Sessions", value: "\(sessionManager.totalSessions)")
                        StatCard(title: "Success Rate", value: "\(sessionManager.successRate)%")
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // History List
                    if sessionManager.sessions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "clock.badge.questionmark")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.3))
                            Text("No sessions yet")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Complete your first focus session to see it here")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(sessionManager.sessions) { session in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.dateString)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                        Text(session.durationString)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                    }

                                    Spacer()

                                    Text(session.completed ? "✓" : "✗")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(session.completed ? .green : .red)
                                }
                                .padding(.vertical, 8)
                                .listRowBackground(Color.white.opacity(0.05))
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

#Preview {
    HistoryView()
        .environmentObject(SessionManager())
        .preferredColorScheme(.dark)
}

import SwiftUI

struct SessionCompleteView: View {
    let session: SessionData?
    let onDismiss: (() -> Void)?

    // Legacy support for direct parameters
    let duration: Int?
    let breaksTaken: Int?
    let completed: Bool?

    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    // Convenience initializer for session object (preferred)
    init(session: SessionData, onDismiss: (() -> Void)? = nil) {
        self.session = session
        self.onDismiss = onDismiss
        self.duration = nil
        self.breaksTaken = nil
        self.completed = nil
    }

    // Legacy initializer for direct parameters
    init(duration: Int, breaksTaken: Int, completed: Bool) {
        self.session = nil
        self.onDismiss = nil
        self.duration = duration
        self.breaksTaken = breaksTaken
        self.completed = completed
    }

    // Computed properties to handle both init methods
    private var sessionDuration: Int {
        session?.duration ?? duration ?? 0
    }

    private var sessionBreaksTaken: Int {
        session?.breaksTaken ?? breaksTaken ?? 0
    }

    private var sessionCompleted: Bool {
        session?.completed ?? completed ?? false
    }

    var durationString: String {
        let hours = sessionDuration / 3600
        let minutes = (sessionDuration % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Success/Failure Icon
                VStack(spacing: 24) {
                    if sessionCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 12) {
                        Text(sessionCompleted ? "Session Complete!" : "Session Incomplete")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(sessionCompleted ? "Great work staying focused." : "Better luck next time.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                // Stats Display
                VStack(spacing: 20) {
                    StatRow(icon: "clock.fill", label: "Focus Time", value: durationString)
                    StatRow(icon: "pause.circle.fill", label: "Breaks Taken", value: "\(sessionBreaksTaken)")
                    StatRow(icon: "chart.line.uptrend.xyaxis", label: "Success Rate", value: "\(sessionManager.successRate)%")
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 40)

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    Button {
                        // Call custom onDismiss if provided, otherwise use default dismiss
                        if let onDismiss = onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text("Done")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(.white)
                            )
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Only log session if using legacy init (not from pending completion)
            // Pending completion sessions are already logged in SessionManager
            if session == nil && sessionCompleted {
                sessionManager.logSession(
                    duration: sessionDuration,
                    completed: true,
                    breaksTaken: sessionBreaksTaken
                )
            }
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 30)

            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    SessionCompleteView(duration: 1500, breaksTaken: 2, completed: true)
        .environmentObject(SessionManager())
        .preferredColorScheme(.dark)
}

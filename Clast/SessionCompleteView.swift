import SwiftUI

struct SessionCompleteView: View {
    let duration: Int // in seconds
    let breaksTaken: Int
    let completed: Bool

    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    var durationString: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60

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
                    if completed {
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
                        Text(completed ? "Session Complete!" : "Session Incomplete")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(completed ? "Great work staying focused." : "Better luck next time.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                // Stats Display
                VStack(spacing: 20) {
                    StatRow(icon: "clock.fill", label: "Focus Time", value: durationString)
                    StatRow(icon: "pause.circle.fill", label: "Breaks Taken", value: "\(breaksTaken)")
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
                        // Return to home
                        dismiss()
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
            // Log the session only if it was completed (early termination already logged)
            if completed {
                sessionManager.logSession(
                    duration: duration,
                    completed: true,
                    breaksTaken: breaksTaken
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

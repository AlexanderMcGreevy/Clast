import SwiftUI
import Combine

struct BreakUnlockedView: View {
    let maxBreakDuration: Int // Maximum earned duration in seconds
    let score: Double // Score 0.0-1.0
    let timeRemaining: Int?
    let onReturnToSession: (() -> Void)?
    let onBreakTaken: (() -> Void)?
    let onEndEarly: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showEndSessionAlert = false
    @State private var selectedBreakMinutes: Int
    @State private var breakTimeRemaining: Int
    @State private var isBreakActive = false

    init(
        breakDuration: Int = 300, // Default 5 minutes (for backwards compatibility)
        score: Double = 0.75,
        timeRemaining: Int? = nil,
        onReturnToSession: (() -> Void)? = nil,
        onBreakTaken: (() -> Void)? = nil,
        onEndEarly: (() -> Void)? = nil
    ) {
        self.maxBreakDuration = breakDuration
        self.score = score
        self.timeRemaining = timeRemaining
        self.onReturnToSession = onReturnToSession
        self.onBreakTaken = onBreakTaken
        self.onEndEarly = onEndEarly

        // Initialize selected break to max earned time (capped at available minutes)
        let maxMinutes = breakDuration / 60
        self._selectedBreakMinutes = State(initialValue: maxMinutes)
        self._breakTimeRemaining = State(initialValue: breakDuration)
    }

    /// Calculate maximum break time based on score (0-100% → 0-30 minutes)
    static func calculateMaxBreakTime(score: Double) -> Int {
        let percentage = max(0.0, min(1.0, score)) // Clamp 0-1
        let maxMinutes = Int(percentage * 30.0) // Scale to 0-30 minutes
        return maxMinutes * 60 // Convert to seconds
    }

    var breakDurationFormatted: String {
        let minutes = breakTimeRemaining / 60
        let seconds = breakTimeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var scorePercentage: Int {
        Int(score * 100)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Success Icon and Message
                VStack(spacing: 24) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(spacing: 12) {
                        Text("Break Unlocked!")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Score: \(scorePercentage)%")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.yellow)

                        Text("You've earned a well-deserved break.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                // Break Duration
                VStack(spacing: 12) {
                    Text(isBreakActive ? "Time Remaining" : "Break Time Earned")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                    Text(breakDurationFormatted)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(isBreakActive ? .green : .white)
                        .monospacedDigit()
                        .animation(.easeInOut, value: breakTimeRemaining)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    if isBreakActive {
                        Button {
                            // End break early
                            stopBreak()
                        } label: {
                            Text("End Break Early")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(.white, lineWidth: 2)
                                )
                        }
                    } else {
                        Button {
                            startBreak()
                        } label: {
                            Text("Start Break")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(
                                            .linearGradient(
                                                colors: [.yellow, .orange],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }

                    Button {
                        showEndSessionAlert = true
                    } label: {
                        Text("End Session Early")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(.red, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(timeRemaining == nil)
        .alert("End Session Early?", isPresented: $showEndSessionAlert) {
            Button("Cancel", role: .cancel) {}
            Button("End Session", role: .destructive) {
                onEndEarly?()
            }
        } message: {
            Text("This session will be marked as incomplete and added to your history.")
        }
        .toolbar {
            if let onReturnToSession = onReturnToSession, timeRemaining != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onReturnToSession()
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Return to Session")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if isBreakActive && breakTimeRemaining > 0 {
                breakTimeRemaining -= 1
                if breakTimeRemaining == 0 {
                    stopBreak()
                }
            }
        }
    }

    // MARK: - Break Timer Functions

    private func startBreak() {
        isBreakActive = true
        onBreakTaken?()
    }

    private func stopBreak() {
        isBreakActive = false
        onReturnToSession?()
        dismiss()
    }
}

#Preview {
    BreakUnlockedView()
        .preferredColorScheme(.dark)
}

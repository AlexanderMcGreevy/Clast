import SwiftUI

struct RunningSessionView: View {
    let hours: Int
    let minutes: Int

    @State private var timeRemaining: Int = 0
    @State private var totalTime: Int = 0
    @State private var isNavigatingToProofGate = false
    @State private var isNavigatingToSessionComplete = false
    @State private var breaksTaken = 0
    @State private var timer: Timer?

    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return Double(totalTime - timeRemaining) / Double(totalTime)
    }

    var timeString: String {
        let hours = timeRemaining / 3600
        let minutes = (timeRemaining % 3600) / 60
        let seconds = timeRemaining % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Timer Display
                VStack(spacing: 20) {
                    Text("Focus Session")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    // Large countdown timer
                    Text(timeString)
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }

                Spacer()

                // Progress Bar
                VStack(spacing: 16) {
                    Text("\(Int(progress * 100))% Complete")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.white.opacity(0.2))
                            .frame(height: 20)

                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white)
                                .frame(width: geometry.size.width * progress, height: 20)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 40)

                Spacer()

                // Action Button
                Button {
                    // Pause timer and go to proof gate
                    timer?.invalidate()
                    isNavigatingToProofGate = true
                } label: {
                    Text("Take a Break")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(.white, lineWidth: 2)
                        )
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Initialize timer
            totalTime = (hours * 3600) + (minutes * 60)
            timeRemaining = totalTime

            // Start countdown
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                    // Timer completed naturally - navigate to session complete
                    isNavigatingToSessionComplete = true
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .navigationDestination(isPresented: $isNavigatingToProofGate) {
            ProofGateView(
                timeRemaining: timeRemaining,
                onReturnToSession: {
                    // Resume timer when returning to session
                    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        if timeRemaining > 0 {
                            timeRemaining -= 1
                        } else {
                            timer?.invalidate()
                            isNavigatingToSessionComplete = true
                        }
                    }
                },
                onBreakTaken: {
                    breaksTaken += 1
                }
            )
        }
        .navigationDestination(isPresented: $isNavigatingToSessionComplete) {
            SessionCompleteView(duration: totalTime, breaksTaken: breaksTaken)
        }
    }
}

#Preview {
    RunningSessionView(hours: 0, minutes: 25)
        .preferredColorScheme(.dark)
}

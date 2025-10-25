import SwiftUI

struct BreakUnlockedView: View {
    let timeRemaining: Int?
    let onReturnToSession: (() -> Void)?
    let onBreakTaken: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    init(timeRemaining: Int? = nil, onReturnToSession: (() -> Void)? = nil, onBreakTaken: (() -> Void)? = nil) {
        self.timeRemaining = timeRemaining
        self.onReturnToSession = onReturnToSession
        self.onBreakTaken = onBreakTaken
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

                        Text("You've earned a well-deserved break.")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                // Break Duration (simulated)
                VStack(spacing: 12) {
                    Text("Break Time")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                    Text("5:00")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    Button {
                        // Increment break counter and start break timer (placeholder for now)
                        onBreakTaken?()
                    } label: {
                        Text("Take a Break")
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

                    Button {
                        // End session early - go back to home
                        dismiss()
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
    }
}

#Preview {
    BreakUnlockedView()
        .preferredColorScheme(.dark)
}

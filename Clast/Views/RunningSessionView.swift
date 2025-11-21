import SwiftUI

struct RunningSessionView: View {
    let hours: Int
    let minutes: Int

    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var stateManager = SessionStateManager.shared
    
    @State private var timeRemaining: Int = 0
    @State private var totalTime: Int = 0
    @State private var isNavigatingToProofGate = false
    @State private var isNavigatingToSessionComplete = false
    @State private var breaksTaken = 0
    @State private var timer: Timer?
    @State private var isRestoredSession = false
    @State private var showEndSessionAlert = false
    @State private var sessionEndedEarly = false
    @State private var showFocusError = false
    @State private var focusErrorMessage = ""
    @State private var showPermissionDeniedAlert = false
    @State private var showGoalInput = false

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

                // Action Buttons
                VStack(spacing: 16) {
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

                    Button {
                        showEndSessionAlert = true
                    } label: {
                        Text("End Session Early")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(.red.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
                }
            }
            .navigationBarBackButtonHidden(true)
            .alert("End Session Early?", isPresented: $showEndSessionAlert) {
            Button("Cancel", role: .cancel) {}
            Button("End Session", role: .destructive) {
                endSessionEarly()
            }
        } message: {
            Text("This session will be marked as incomplete and added to your history.")
        }
            .alert("Focus Error", isPresented: $showFocusError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(focusErrorMessage)
            }
            .onAppear {
                // Check if session state exists
                if stateManager.currentState == nil {
                    // Show goal input
                    showGoalInput = true
                } else {
                    // State exists, proceed with timer
                    initializeTimer()
                }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .navigationDestination(isPresented: $isNavigatingToProofGate) {
            AIProofGateView(
                timeRemaining: timeRemaining,
                onReturnToSession: {
                    // Resume timer when returning to session
                    startTimer()
                },
                onBreakTaken: {
                    breaksTaken += 1
                    sessionManager.updateTimerBreaks(breaksTaken: breaksTaken)
                },
                onEndEarly: {
                    endSessionEarly()
                }
            )
        }
            .navigationDestination(isPresented: $isNavigatingToSessionComplete) {
                SessionCompleteView(
                    duration: totalTime,
                    breaksTaken: breaksTaken,
                    completed: !sessionEndedEarly
                )
            }
            .sheet(isPresented: $showGoalInput) {
                SessionGoalInputView(isPresented: $showGoalInput) { goal in
                    stateManager.startNewSession(goal: goal)
                    showGoalInput = false
                    initializeTimer()
                }
            }

            // Permission denied overlay
            if showPermissionDeniedAlert {
                PermissionDeniedView(isPresented: $showPermissionDeniedAlert)
            }
        }
    }
    
    private func initializeTimer() {
        // Check if there's an active timer to restore
        if let activeTimer = sessionManager.activeTimer {
            // Restore from saved state
            isRestoredSession = true
            totalTime = activeTimer.totalDuration
            breaksTaken = activeTimer.breaksTaken

            // Note: If timer expired while app was closed, SessionManager already handled it
            // and cleared the activeTimer, so we won't reach here.
            // We only restore if timer is still running
            timeRemaining = activeTimer.timeRemaining
            startTimer()
        } else {
            // New timer - initialize and save
            totalTime = (hours * 3600) + (minutes * 60)
            timeRemaining = totalTime

            Task {
                do {
                    try await sessionManager.startTimer(duration: totalTime)
                    startTimer()
                } catch let error as FocusError {
                    if case .notAuthorized = error {
                        showPermissionDeniedAlert = true
                    } else {
                        focusErrorMessage = error.localizedDescription
                        showFocusError = true
                    }
                } catch {
                    focusErrorMessage = "Failed to start focus session: \(error.localizedDescription)"
                    showFocusError = true
                }
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()

                    // Create completed session
                    let completedSession = SessionData(
                        duration: totalTime,
                        completed: true,
                        breaksTaken: breaksTaken
                    )

                    // Set as pending completion (will show via ContentView)
                    sessionManager.pendingCompletionSession = completedSession

                    // Clear active timer and state
                    sessionManager.clearActiveTimer()
                    stateManager.clearState()

                    // Navigate to completion screen
                    isNavigatingToSessionComplete = true
                }
            }
        }
    }

    private func endSessionEarly() {
        timer?.invalidate()
        sessionEndedEarly = true

        // Create incomplete session
        let incompleteSession = SessionData(
            duration: totalTime - timeRemaining,
            completed: false,
            breaksTaken: breaksTaken
        )

        // Log immediately (early termination)
        sessionManager.addSession(incompleteSession)

        // Clear active timer and state
        sessionManager.clearActiveTimer()
        stateManager.clearState()

        // Set as pending to show completion screen
        sessionManager.pendingCompletionSession = incompleteSession

        // Navigate to completion screen
        isNavigatingToSessionComplete = true
    }
}

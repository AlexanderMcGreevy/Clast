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

    // Break state
    @State private var isOnBreak = false
    @State private var breakTimeRemaining: Int = 0

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

    var breakTimeString: String {
        let minutes = breakTimeRemaining / 60
        let seconds = breakTimeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
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

                    // Compact break timer overlay
                    if isOnBreak {
                        HStack(spacing: 12) {
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("On Break")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Apps unlocked")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Spacer()

                            Text(breakTimeString)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.1, green: 0.2, blue: 0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 40)
                        .padding(.top, 12)
                    }
                }

                Spacer()

                // Progress Bar
                VStack(spacing: 16) {
                    Text("\(Int(progress * 100))% Complete")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background bar
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white.opacity(0.2))
                                .frame(width: geometry.size.width, height: 20)

                            // Progress bar (on top)
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white)
                                .frame(width: geometry.size.width * progress, height: 20)
                        }
                    }
                    .frame(height: 20)
                }
                .padding(.horizontal, 40)

                Spacer()

                // Action Buttons
                VStack(spacing: 16) {
                    if isOnBreak {
                        // Show end break button when on break
                        Button {
                            endBreakEarly()
                        } label: {
                            Text("End Break Early")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(.green, lineWidth: 2)
                                )
                        }
                    } else {
                        // Show take break button when not on break
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
                    // Always resume timer when returning to session
                    // Timer handles both session countdown and break countdown
                    startTimer()
                },
                onBreakTaken: {
                    breaksTaken += 1
                    sessionManager.updateTimerBreaks(breaksTaken: breaksTaken)
                },
                onBreakStarted: { duration in
                    // Start break with selected duration
                    startBreak(duration: duration)
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
        print("⏱️ [RunningSessionView] Starting timer (isOnBreak: \(isOnBreak))")

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            Task { @MainActor in
                // Handle break timer
                if self.isOnBreak {
                    if self.breakTimeRemaining > 0 {
                        self.breakTimeRemaining -= 1
                    } else {
                        // Break ended, resume focus session
                        print("⏰ [RunningSessionView] Break time ended")
                        self.endBreak()
                    }
                }

                // Handle main session timer (always counts down)
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timer?.invalidate()

                    // Create completed session
                    let completedSession = SessionData(
                        duration: self.totalTime,
                        completed: true,
                        breaksTaken: self.breaksTaken
                    )

                    // Set as pending completion (will show via ContentView)
                    self.sessionManager.pendingCompletionSession = completedSession

                    // Clear active timer and state
                    self.sessionManager.clearActiveTimer()
                    self.stateManager.clearState()

                    // Navigate to completion screen
                    self.isNavigatingToSessionComplete = true
                }
            }
        }
    }

    private func startBreak(duration: Int) {
        isOnBreak = true
        breakTimeRemaining = duration

        // Disable Screen Time blocking during break
        sessionManager.focusController.endSession()

        print("🏖️ [RunningSessionView] Break started")
        print("   Duration: \(duration) seconds (\(duration/60) minutes)")
        print("   isOnBreak: \(isOnBreak)")
        print("   breakTimeRemaining: \(breakTimeRemaining)")
    }

    private func endBreak() {
        print("🛑 [RunningSessionView] Ending break")
        isOnBreak = false
        breakTimeRemaining = 0

        // Re-enable Screen Time blocking
        let remainingMinutes = timeRemaining / 60
        Task {
            do {
                try await sessionManager.focusController.startSession(durationMinutes: remainingMinutes)
                print("✅ [RunningSessionView] Break ended - blocking re-enabled for \(remainingMinutes) minutes")
            } catch {
                focusErrorMessage = "Failed to re-enable app blocking: \(error.localizedDescription)"
                showFocusError = true
            }
        }
    }

    private func endBreakEarly() {
        endBreak()
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

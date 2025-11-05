import SwiftUI
import FamilyControls

/*
 FocusControlView - Session Control & Diagnostics

 This view provides:
 - Authorization button
 - App/category picker
 - Session start/stop controls
 - Real-time diagnostics
 - Selection summary

 Use this view for testing and as a reference for integrating
 into your main app UI.

 Usage:
   NavigationView {
       FocusControlView()
   }
*/

struct FocusControlView: View {
    @StateObject private var focusController = FocusController.shared
    @StateObject private var selectionStore = SelectionStore.shared

    @State private var showPicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var sessionDuration = 25 // minutes

    var body: some View {
        List {
            // MARK: - Authorization Section
            Section("Authorization") {
                authorizationRow
            }

            // MARK: - Selection Section
            Section("Blocked Items") {
                selectionSummary
                pickButton
            }

            // MARK: - Session Control Section
            Section("Session Control") {
                durationPicker
                sessionControls
            }

            // MARK: - Diagnostics Section
            Section("Diagnostics") {
                diagnosticInfo
            }

            #if DEBUG
            Section("Debug Actions") {
                Button("Clear All Selections") {
                    selectionStore.clearSelection()
                }
                .foregroundColor(.red)
            }
            #endif
        }
        .navigationTitle("Focus Control")
        .familyActivityPicker(isPresented: $showPicker, selection: $selectionStore.selection)
        .onChange(of: selectionStore.selection) { oldValue, newValue in
            selectionStore.saveSelection(newValue)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Authorization Row

    private var authorizationRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Screen Time")
                    .font(.headline)
                Text(authStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if focusController.authorizationStatus != .approved {
                Button("Authorize") {
                    Task {
                        do {
                            try await focusController.requestAuthorization()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }

    private var authStatusText: String {
        switch focusController.authorizationStatus {
        case .notDetermined:
            return "Not requested"
        case .denied:
            return "Denied - check Settings"
        case .approved:
            return "Approved ✓"
        @unknown default:
            return "Unknown"
        }
    }

    // MARK: - Selection Summary

    private var selectionSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            if selectionStore.hasAnySelections {
                let counts = selectionStore.selectionCounts
                selectionRow(icon: "app.fill", label: "Apps", count: counts.apps)
                selectionRow(icon: "square.grid.2x2", label: "Categories", count: counts.categories)
                selectionRow(icon: "globe", label: "Domains", count: counts.domains)
            } else {
                Text("No items selected")
                    .foregroundColor(.secondary)
            }
        }
    }

    private func selectionRow(icon: String, label: String, count: Int) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text("\(count)")
                .foregroundColor(.secondary)
        }
    }

    private var pickButton: some View {
        Button(action: { showPicker = true }) {
            Label("Pick Apps & Categories", systemImage: "plus.circle.fill")
        }
    }

    // MARK: - Session Controls

    private var durationPicker: some View {
        Picker("Duration", selection: $sessionDuration) {
            Text("5 min").tag(5)
            Text("15 min").tag(15)
            Text("25 min").tag(25)
            Text("45 min").tag(45)
            Text("60 min").tag(60)
        }
        .pickerStyle(.segmented)
    }

    private var sessionControls: some View {
        VStack(spacing: 12) {
            if focusController.isSessionActive {
                // Session is active - show stop button
                Button(action: stopSession) {
                    Label("End Session", systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Text("Session active - shields applied")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                // Session not active - show start button
                Button(action: startSession) {
                    Label("Start Session", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!focusController.canStartSession)

                if !focusController.isAuthorized {
                    Text("Authorization required")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if !selectionStore.hasAnySelections {
                    Text("Select apps/categories first")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    // MARK: - Diagnostics

    private var diagnosticInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            diagnosticRow(label: "Authorization", value: focusController.isAuthorized ? "✓" : "✗")
            diagnosticRow(label: "Session Active", value: focusController.isSessionActive ? "Yes" : "No")
            diagnosticRow(label: "Can Start", value: focusController.canStartSession ? "Yes" : "No")
            diagnosticRow(label: "Selections", value: selectionStore.hasAnySelections ? "Yes" : "No")
        }
        .font(.system(.body, design: .monospaced))
    }

    private func diagnosticRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Actions

    private func startSession() {
        Task {
            do {
                try await focusController.startSession(durationMinutes: sessionDuration)
                print("✅ Session started successfully")
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func stopSession() {
        focusController.endSession()
        print("🛑 Session stopped")
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        FocusControlView()
    }
}

/*
 INTEGRATION NOTES:

 1. Add this view to your existing app flow:
    - As a new tab in TabView
    - As a sheet/modal from settings
    - Replace existing focus settings view

 2. To integrate into existing SessionManager:
    - Call FocusController.shared instead of ScreenTimeFocusController
    - Use SelectionStore.shared instead of FamilyActivitySelectionStore

 3. Suggested improvements for production:
    - Add haptic feedback on button taps
    - Show countdown timer during session
    - Add notification when session ends
    - Save session history to track progress
    - Add quick-select common apps (Instagram, TikTok, etc.)

 4. Testing checklist:
    ✓ Tap "Authorize" - should prompt for Screen Time
    ✓ Tap "Pick Apps" - should show FamilyActivityPicker
    ✓ Select categories AND individual apps
    ✓ Tap "Start Session" - should show success
    ✓ Open a blocked app - custom shield should appear
    ✓ Tap "Build On" button - should open your app
    ✓ Tap "End Session" - shields should clear
*/

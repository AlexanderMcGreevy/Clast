import Foundation
import Combine
import FamilyControls
import ManagedSettings
import DeviceActivity

/*
 FocusController - Unified Session Management

 This controller handles:
 - Screen Time authorization
 - Applying shields to BOTH categories and individual apps
 - Starting/stopping focus sessions
 - Persisting session state

 Setup Requirements:
 - App Target must have "Family Controls" capability
 - Extension Target must have "Managed Settings UI" capability
 - Both targets should share same team/bundle prefix

 Usage:
   let controller = FocusController.shared
   await controller.requestAuthorization()
   try await controller.startSession(durationMinutes: 25)
   controller.endSession()
*/

/// Typed errors for focus operations
enum FocusControllerError: Error, LocalizedError {
    case notAuthorized
    case noSelection
    case systemError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Screen Time permission required. Please enable in Settings."
        case .noSelection:
            return "No apps or categories selected. Configure blocked items first."
        case .systemError(let error):
            return "System error: \(error.localizedDescription)"
        }
    }
}

@MainActor
class FocusController: ObservableObject {
    static let shared = FocusController()

    // MARK: - Published State

    @Published private(set) var isSessionActive = false
    @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    // MARK: - Private Properties

    private let store = ManagedSettingsStore()
    private let selectionStore = SelectionStore.shared
    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("clastFocusSession")

    private init() {
        updateAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Request Screen Time authorization
    func requestAuthorization() async throws {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            updateAuthorizationStatus()

            if authorizationStatus != .approved {
                throw FocusControllerError.notAuthorized
            }
        } catch {
            updateAuthorizationStatus()
            throw FocusControllerError.notAuthorized
        }
    }

    /// Manually refresh authorization status (call when returning to app)
    func refreshAuthorizationStatus() {
        updateAuthorizationStatus()
    }

    private func updateAuthorizationStatus() {
        let newStatus = AuthorizationCenter.shared.authorizationStatus
        if newStatus != authorizationStatus {
            print("🔐 [FocusController] Authorization status changed: \(authorizationStatus) → \(newStatus)")
        }
        authorizationStatus = newStatus
    }

    // MARK: - Session Management

    /// Start a focus session with shields for ALL selected items (apps, categories, domains)
    /// - Parameter durationMinutes: Session duration in minutes
    /// - Throws: FocusControllerError if authorization denied or no items selected
    func startSession(durationMinutes: Int = 25) async throws {
        // Check authorization
        guard authorizationStatus == .approved else {
            throw FocusControllerError.notAuthorized
        }

        // Check if any items are selected
        guard selectionStore.hasAnySelections else {
            throw FocusControllerError.noSelection
        }

        // Apply shields to ALL types
        try applyShields()

        // Start device activity monitoring
        try startDeviceActivityMonitoring(durationMinutes: durationMinutes)

        isSessionActive = true

        print("✅ [FocusController] Session started")
        print("   Duration: \(durationMinutes) minutes")
        print("   Apps: \(selectionStore.selection.applicationTokens.count)")
        print("   Categories: \(selectionStore.selection.categoryTokens.count)")
        print("   Web Domains: \(selectionStore.selection.webDomainTokens.count)")
    }

    /// End the current focus session and clear all shields
    func endSession() {
        clearShields()
        stopDeviceActivityMonitoring()
        isSessionActive = false

        print("🛑 [FocusController] Session ended - all shields cleared")
    }

    // MARK: - Shield Application (THE KEY TO OPAL-LIKE BEHAVIOR)

    private func applyShields() throws {
        let selection = selectionStore.selection

        print("🛡️ [FocusController] Applying shields...")

        // CRITICAL: Set shields for BOTH individual apps AND categories
        // This ensures custom shield UI appears for all blocked items

        // Individual applications
        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
            print("   ✓ Apps shielded: \(selection.applicationTokens.count)")
        }

        // Application categories - KEY: Use .specific() policy
        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(selection.categoryTokens)
            print("   ✓ Categories shielded: \(selection.categoryTokens.count)")
        }

        // Web domains (optional)
        if !selection.webDomainTokens.isEmpty {
            store.shield.webDomains = selection.webDomainTokens
            print("   ✓ Web domains shielded: \(selection.webDomainTokens.count)")
        }

        print("   ✅ All shields applied successfully")
    }

    private func clearShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        print("   🧹 All shields cleared")
    }

    // MARK: - Device Activity Monitoring

    private func startDeviceActivityMonitoring(durationMinutes: Int) throws {
        let endTime = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))
        let calendar = Calendar.current

        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents([.hour, .minute], from: Date()),
            intervalEnd: calendar.dateComponents([.hour, .minute], from: endTime),
            repeats: false
        )

        try center.startMonitoring(activityName, during: schedule)
        print("   ⏱️ Device activity monitoring started")
    }

    private func stopDeviceActivityMonitoring() {
        center.stopMonitoring([activityName])
        print("   ⏱️ Device activity monitoring stopped")
    }

    // MARK: - Computed Properties

    var isAuthorized: Bool {
        authorizationStatus == .approved
    }

    var canStartSession: Bool {
        isAuthorized && selectionStore.hasAnySelections && !isSessionActive
    }

    var currentSelectionSummary: String {
        let apps = selectionStore.selection.applicationTokens.count
        let cats = selectionStore.selection.categoryTokens.count
        let domains = selectionStore.selection.webDomainTokens.count

        var parts: [String] = []
        if apps > 0 { parts.append("\(apps) app\(apps == 1 ? "" : "s")") }
        if cats > 0 { parts.append("\(cats) categor\(cats == 1 ? "y" : "ies")") }
        if domains > 0 { parts.append("\(domains) domain\(domains == 1 ? "" : "s")") }

        return parts.isEmpty ? "Nothing selected" : parts.joined(separator: ", ")
    }
}

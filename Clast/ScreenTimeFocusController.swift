import Foundation
import Combine
import FamilyControls
import ManagedSettings
import DeviceActivity

/// Typed errors for focus session operations
enum FocusError: Error, LocalizedError {
    case notAuthorized
    case noSelection
    case systemError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Screen Time permission not granted. Please enable in Settings."
        case .noSelection:
            return "No apps selected. Please configure blocked apps in Focus Settings."
        case .systemError(let error):
            return "System error: \(error.localizedDescription)"
        }
    }
}

/// Manages app blocking for focus sessions using Screen Time API
@MainActor
class ScreenTimeFocusController: ObservableObject {
    static let shared = ScreenTimeFocusController()

    @Published private(set) var isFocusActive = false

    private let store = ManagedSettingsStore()
    private let selectionStore = FamilyActivitySelectionStore.shared
    private let authorization = ScreenTimeAuthorization.shared
    private let center = DeviceActivityCenter()

    // DeviceActivity monitoring name
    private let activityName = DeviceActivityName("clastFocus")

    private init() {}

    /// Start focus session with app blocking
    /// - Parameter durationMinutes: Session duration in minutes (default: 25)
    /// - Throws: FocusError if authorization denied or no apps selected
    func startFocus(durationMinutes: Int = 25) async throws {
        // Check authorization
        if !authorization.isAuthorized {
            if authorization.authorizationState == .notDetermined {
                // Attempt authorization
                do {
                    try await authorization.requestAuthorization()
                } catch {
                    throw FocusError.notAuthorized
                }
            }

            // Recheck after potential authorization
            if !authorization.isAuthorized {
                throw FocusError.notAuthorized
            }
        }

        // Check if any apps are selected
        guard selectionStore.hasAnySelectedApps else {
            throw FocusError.noSelection
        }

        // Apply shields
        do {
            try applyShields()
            try startDeviceActivityMonitoring(durationMinutes: durationMinutes)
            isFocusActive = true
        } catch {
            throw FocusError.systemError(underlying: error)
        }
    }

    /// Stop focus session and unblock apps
    func stopFocus() {
        clearShields()
        stopDeviceActivityMonitoring()
        isFocusActive = false
    }

    // MARK: - Private Helpers

    private func applyShields() throws {
        let selection = selectionStore.selection

        // Shield selected applications
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil :
            ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    private func clearShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    private func startDeviceActivityMonitoring(durationMinutes: Int) throws {
        // Calculate end time for this session
        let endTime = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))
        let calendar = Calendar.current
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        let sessionSchedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents([.hour, .minute], from: Date()),
            intervalEnd: endComponents,
            repeats: false
        )

        try center.startMonitoring(activityName, during: sessionSchedule)
    }

    private func stopDeviceActivityMonitoring() {
        center.stopMonitoring([activityName])
    }

    // MARK: - Convenience Methods

    /// Prepare and start focus with automatic authorization handling
    /// Call this from your session start flow
    func prepareAndStartFocus(durationMinutes: Int) async -> Result<Void, FocusError> {
        do {
            try await startFocus(durationMinutes: durationMinutes)
            return .success(())
        } catch let error as FocusError {
            return .failure(error)
        } catch {
            return .failure(.systemError(underlying: error))
        }
    }

    /// Computed property for easy access to selection state
    var hasAnySelectedApps: Bool {
        selectionStore.hasAnySelectedApps
    }

    /// Current authorization state
    var authorizationState: ScreenTimeAuthorizationState {
        authorization.authorizationState
    }
}

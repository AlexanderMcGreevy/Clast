import Foundation
import Combine
import FamilyControls

/// Authorization state for Screen Time API
enum ScreenTimeAuthorizationState {
    case notDetermined
    case authorized
    case denied
}

/// Lightweight helper to manage Screen Time authorization
@MainActor
class ScreenTimeAuthorization: ObservableObject {
    static let shared = ScreenTimeAuthorization()

    @Published private(set) var authorizationState: ScreenTimeAuthorizationState = .notDetermined

    private let authorizationCenter = AuthorizationCenter.shared

    private init() {
        updateAuthorizationState()
    }

    /// Request authorization from the user
    func requestAuthorization() async throws {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            updateAuthorizationState()
        } catch {
            updateAuthorizationState()
            throw error
        }
    }

    /// Check current authorization status
    var isAuthorized: Bool {
        authorizationState == .authorized
    }

    private func updateAuthorizationState() {
        switch authorizationCenter.authorizationStatus {
        case .notDetermined:
            authorizationState = .notDetermined
        case .approved:
            authorizationState = .authorized
        case .denied:
            authorizationState = .denied
        @unknown default:
            authorizationState = .notDetermined
        }
    }
}

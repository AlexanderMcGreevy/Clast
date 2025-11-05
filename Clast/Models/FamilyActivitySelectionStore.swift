import Foundation
import Combine
import FamilyControls
import ManagedSettings

/// Codable wrapper for FamilyActivitySelection to enable persistence
struct FamilyActivitySelectionData: Codable {
    let applicationTokens: Set<ApplicationToken>
    let categoryTokens: Set<ActivityCategoryToken>
    let webDomainTokens: Set<WebDomainToken>

    init(from selection: FamilyActivitySelection) {
        self.applicationTokens = selection.applicationTokens
        self.categoryTokens = selection.categoryTokens
        self.webDomainTokens = selection.webDomainTokens
    }

    func toSelection() -> FamilyActivitySelection {
        var selection = FamilyActivitySelection()
        selection.applicationTokens = applicationTokens
        selection.categoryTokens = categoryTokens
        selection.webDomainTokens = webDomainTokens
        return selection
    }
}

/// Manages persistence of blocked app selections
@MainActor
class FamilyActivitySelectionStore: ObservableObject {
    static let shared = FamilyActivitySelectionStore()

    @Published var selection = FamilyActivitySelection()

    private let storageKey = "clast_family_activity_selection"

    private init() {
        loadSelection()
    }

    /// Save current selection to UserDefaults
    func saveSelection(_ newSelection: FamilyActivitySelection) {
        selection = newSelection
        let data = FamilyActivitySelectionData(from: newSelection)
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    /// Load selection from UserDefaults
    func loadSelection() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(FamilyActivitySelectionData.self, from: data) else {
            return
        }
        selection = decoded.toSelection()
    }

    /// Check if any apps are selected
    var hasAnySelectedApps: Bool {
        !selection.applicationTokens.isEmpty ||
        !selection.categoryTokens.isEmpty ||
        !selection.webDomainTokens.isEmpty
    }

    /// Get count of selected items for display
    var selectedItemCount: Int {
        selection.applicationTokens.count +
        selection.categoryTokens.count +
        selection.webDomainTokens.count
    }
}

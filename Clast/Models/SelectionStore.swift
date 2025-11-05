import Foundation
import Combine
import FamilyControls
import ManagedSettings

/*
 SelectionStore - Persistent Storage for Blocked Items

 Stores and persists user selections from FamilyActivityPicker:
 - Individual application tokens
 - Application category tokens
 - Web domain tokens (optional)

 This data is saved to UserDefaults and loaded on app launch.
 The FocusController reads from this store when applying shields.

 Setup Requirements:
 - None (uses UserDefaults by default)
 - Optional: Can be migrated to App Group for extension sharing

 Usage:
   let store = SelectionStore.shared
   store.saveSelection(pickerSelection)
   print(store.hasAnySelections) // true/false
*/

/// Codable wrapper for FamilyActivitySelection to enable persistence
struct SelectionData: Codable {
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

@MainActor
class SelectionStore: ObservableObject {
    static let shared = SelectionStore()

    // MARK: - Published State

    @Published var selection = FamilyActivitySelection()

    // MARK: - Private Properties

    private let storageKey = "clast_selection_store"

    // Optional: Use App Group for extension sharing
    // private let defaults = UserDefaults(suiteName: "group.com.alex.clast")!

    private init() {
        loadSelection()
    }

    // MARK: - Public Methods

    /// Save a new selection from FamilyActivityPicker
    func saveSelection(_ newSelection: FamilyActivitySelection) {
        selection = newSelection

        let data = SelectionData(from: newSelection)
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
            print("💾 [SelectionStore] Saved selection:")
            print("   Apps: \(newSelection.applicationTokens.count)")
            print("   Categories: \(newSelection.categoryTokens.count)")
            print("   Domains: \(newSelection.webDomainTokens.count)")
        }
    }

    /// Clear all selections
    func clearSelection() {
        selection = FamilyActivitySelection()
        UserDefaults.standard.removeObject(forKey: storageKey)
        print("🧹 [SelectionStore] Cleared all selections")
    }

    // MARK: - Private Methods

    private func loadSelection() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(SelectionData.self, from: data) else {
            print("ℹ️ [SelectionStore] No saved selection found")
            return
        }

        selection = decoded.toSelection()
        print("📂 [SelectionStore] Loaded selection:")
        print("   Apps: \(selection.applicationTokens.count)")
        print("   Categories: \(selection.categoryTokens.count)")
        print("   Domains: \(selection.webDomainTokens.count)")
    }

    // MARK: - Computed Properties

    /// Check if any items are selected
    var hasAnySelections: Bool {
        !selection.applicationTokens.isEmpty ||
        !selection.categoryTokens.isEmpty ||
        !selection.webDomainTokens.isEmpty
    }

    /// Total count of selected items
    var totalSelectionCount: Int {
        selection.applicationTokens.count +
        selection.categoryTokens.count +
        selection.webDomainTokens.count
    }

    /// Detailed counts for UI display
    var selectionCounts: (apps: Int, categories: Int, domains: Int) {
        (
            apps: selection.applicationTokens.count,
            categories: selection.categoryTokens.count,
            domains: selection.webDomainTokens.count
        )
    }
}

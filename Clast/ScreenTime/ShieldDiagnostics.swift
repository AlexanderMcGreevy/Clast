import Foundation
import ManagedSettings
import FamilyControls

/*
 Shield Diagnostics Helper

 Use this to debug why shields might not be appearing.
 Call ShieldDiagnostics.shared.runDiagnostics() to check configuration.
 */

class ShieldDiagnostics {
    static let shared = ShieldDiagnostics()

    private init() {}

    func runDiagnostics() {
        print("🔍 [Shield Diagnostics] Running shield configuration checks...")

        // Check 1: Screen Time Authorization
        let authStatus = AuthorizationCenter.shared.authorizationStatus
        print("✓ Authorization Status: \(authStatus)")

        if authStatus != .approved {
            print("❌ ERROR: Screen Time not authorized. Status: \(authStatus)")
            print("   Solution: User must approve Screen Time permission")
        }

        // Check 2: App Selection
        let store = SelectionStore.shared
        print("✓ Has selected apps: \(store.hasAnySelections)")
        print("   - Applications: \(store.selection.applicationTokens.count)")
        print("   - Categories: \(store.selection.categoryTokens.count)")
        print("   - Web Domains: \(store.selection.webDomainTokens.count)")

        if !store.hasAnySelections {
            print("❌ ERROR: No apps selected for blocking")
            print("   Solution: Configure blocked apps in Focus Settings")
        }

        // Check 3: Shield Extension Bundle
        let extensionIdentifier = "com.GroovyGears.Clast.ClastShieldConfiguration"
        if let extensionURL = Bundle.main.url(forResource: extensionIdentifier, withExtension: "appex", subdirectory: "PlugIns") {
            print("✓ Shield Extension Found: \(extensionURL.lastPathComponent)")
        } else {
            print("⚠️  WARNING: Shield extension not found at expected path")
            print("   Extension Identifier: \(extensionIdentifier)")
            print("   Solution: Ensure ClastShieldConfiguration extension is built and embedded")
        }

        // Check 4: ManagedSettings Store
        _ = ManagedSettingsStore()
        print("✓ ManagedSettings Store Created")

        // Check 5: Focus Controller State
        let focusController = FocusController.shared
        print("✓ Focus Active: \(focusController.isSessionActive)")

        // Check 6: Device Type
        #if targetEnvironment(simulator)
        print("❌ ERROR: Running in Simulator")
        print("   Solution: Test on a real iOS device. Shields don't work in simulator.")
        #else
        print("✓ Running on real device")
        #endif

        print("\n📋 Summary:")
        print("   To see shields, ensure:")
        print("   1. Running on real device (not simulator)")
        print("   2. Screen Time permission granted")
        print("   3. Apps selected for blocking")
        print("   4. Focus session is active")
        print("   5. ClastShieldConfiguration extension is built")
        print("\n")
    }

    func printActiveShields() {
        let store = ManagedSettingsStore()
        print("🛡️ [Active Shields]")
        print("   Applications shielded: \(store.shield.applications != nil)")
        print("   Categories shielded: \(store.shield.applicationCategories != nil)")
        print("   Web domains shielded: \(store.shield.webDomains != nil)")
    }
}

// MARK: - Usage
/*
 Add to your app to debug shield issues:

 // In FocusHomeView or RunningSessionView
 #if DEBUG
 Button("Run Shield Diagnostics") {
     ShieldDiagnostics.shared.runDiagnostics()
 }
 #endif
 */

import Foundation
import DeviceActivity
import ManagedSettings

/*
 IMPORTANT SETUP INSTRUCTIONS:

 This file needs to be added to a DeviceActivity Monitor Extension, not the main app target.

 Steps to add the extension:
 1. In Xcode: File → New → Target
 2. Choose "Device Activity Monitor Extension"
 3. Name it "ClastMonitor"
 4. Move this file to that extension target
 5. Enable Family Controls capability for both main app AND the extension target
 6. Ensure both targets have the same App Group (if using shared data)

 The monitor extension runs in the background and automatically clears shields
 when the DeviceActivity interval ends.

 For now, this file is included in the main target for reference but won't execute
 until properly configured in an extension target.
*/

// MARK: - DeviceActivityMonitor Extension
// This class must be in the Monitor Extension target, not the main app

@available(iOS 15.0, *)
nonisolated class ClastActivityMonitor: DeviceActivityMonitor {
    nonisolated let store = ManagedSettingsStore()

    /// Called when the monitoring interval ends (focus session completes)
    nonisolated override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Clear all shields when session ends
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    /// Called when the monitoring interval starts
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Optional: Add any logging or additional setup here
    }
}

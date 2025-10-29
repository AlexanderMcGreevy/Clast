# Screen Time Integration Setup Guide

This guide walks you through setting up the Screen Time (FamilyControls) integration for the Clast app.

## Overview

The Screen Time integration allows users to:
1. Select apps to block during focus sessions
2. Automatically block selected apps when starting a session
3. Automatically unblock apps when the session ends or is terminated early
4. Configure blocked apps from Settings or before first session

## Files Created

### Core Implementation Files
- `ScreenTimeAuthorization.swift` - Handles Screen Time permission requests
- `FamilyActivitySelectionStore.swift` - Persists blocked app selections
- `ScreenTimeFocusController.swift` - Manages app blocking/unblocking
- `FocusSettingsView.swift` - UI for selecting apps to block
- `ClastActivityMonitor.swift` - DeviceActivity monitor extension (see setup below)

### Modified Files
- `SessionData.swift` - Added Screen Time controller integration
- `RunningSessionView.swift` - Added error handling for focus start
- `FocusHomeView.swift` - Added routing to settings if no apps configured
- `SettingsView.swift` - Added "Blocked Apps" configuration link

## Required Capabilities

### 1. Enable Family Controls Capability
In Xcode:
1. Select the Clast project
2. Select the Clast target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Family Controls"

**IMPORTANT**: You'll need to add this capability to BOTH:
- Main app target (Clast)
- Monitor extension target (see next section)

## Device Activity Monitor Extension Setup

The DeviceActivity Monitor Extension runs in the background and automatically clears app shields when the session interval ends.

### Creating the Extension

1. **Add New Target**
   - In Xcode: File → New → Target
   - Search for "Device Activity Monitor Extension"
   - Name it: `ClastMonitor`
   - Click "Finish"
   - When prompted to activate scheme, click "Activate"

2. **Move Monitor File**
   - Delete the default DeviceActivityMonitor.swift file created in the extension
   - Move `ClastActivityMonitor.swift` to the ClastMonitor target
   - Ensure it's ONLY in the extension target, not the main app

3. **Enable Family Controls for Extension**
   - Select ClastMonitor target
   - Go to "Signing & Capabilities"
   - Add "Family Controls" capability

4. **Configure Info.plist**
   The extension's Info.plist should have:
   ```xml
   <key>NSExtension</key>
   <dict>
       <key>NSExtensionPointIdentifier</key>
       <string>com.apple.deviceactivity.monitor</string>
       <key>NSExtensionPrincipalClass</key>
       <string>$(PRODUCT_MODULE_NAME).ClastActivityMonitor</string>
   </dict>
   ```

## Testing Requirements

### Device Requirements
- **Real iOS device running iOS 15.0+** is REQUIRED
- Screen Time features do NOT work in the iOS Simulator
- The device must have Screen Time enabled in Settings

### Test Flow

1. **First Launch**
   - App requests Screen Time authorization
   - User is prompted to grant permission
   - User is routed to Focus Settings to select apps

2. **Configure Apps**
   - Tap "Select Apps to Block"
   - FamilyActivityPicker shows all installed apps
   - Select apps to block
   - Tap "Done"

3. **Start Session**
   - Set duration in Focus tab
   - Tap "Start Focus Session"
   - Selected apps are immediately blocked
   - Timer begins countdown

4. **During Session**
   - Blocked apps show Screen Time shield
   - Timer continues in background
   - Apps remain blocked if user navigates away

5. **End Session**
   - Session completes → apps automatically unblock
   - OR tap "End Session Early" → apps immediately unblock

## Integration Points

### Starting a Session with Blocking

In `SessionData.swift:111-124`:
```swift
func startTimer(duration: Int) async throws {
    // ... timer setup ...

    // Start Screen Time blocking
    let durationMinutes = duration / 60
    try await focusController.startFocus(durationMinutes: durationMinutes)
}
```

### Stopping Blocking

In `SessionData.swift:136-143`:
```swift
func clearActiveTimer() {
    activeTimer = nil
    UserDefaults.standard.removeObject(forKey: activeTimerKey)

    // Stop Screen Time blocking
    focusController.stopFocus()
}
```

### Routing to Settings

In `FocusHomeView.swift:90-97`:
```swift
Button {
    // Check if apps are configured
    if !focusController.hasAnySelectedApps {
        isNavigatingToSettings = true  // Route to Focus Settings
    } else {
        isNavigatingToSession = true   // Start session
    }
}
```

### Error Handling

In `RunningSessionView.swift:158-172`:
```swift
Task {
    do {
        try await sessionManager.startTimer(duration: totalTime)
        startTimer()
    } catch let error as FocusError {
        // Handle authorization denied or no apps selected
        focusErrorMessage = error.localizedDescription
        showFocusError = true
    }
}
```

## Error Types

The `FocusError` enum provides typed errors:

- `.notAuthorized` - User denied Screen Time permission
- `.noSelection` - No apps configured (routes to settings)
- `.systemError(Error)` - Underlying system error

## Architecture Notes

### Persistence
- Blocked app selections stored in UserDefaults as Codable Data
- Active timer state persists across app restarts
- Focus blocking state syncs with timer state

### Threading
- All Screen Time APIs run on MainActor
- Authorization requests are async
- Shield operations are synchronous but fast

### State Management
- `FamilyActivitySelectionStore` is a singleton with `@Published` selection
- `ScreenTimeFocusController` maintains `isFocusActive` state
- Changes propagate automatically via Combine

## Customization Options

### Shield Configuration (Optional)
In `ScreenTimeFocusController.swift`, you can customize the shield appearance:

```swift
let shieldConfig = ShieldConfiguration(
    backgroundBlurStyle: .systemMaterial,
    backgroundColor: .black,
    icon: UIImage(systemName: "flame.fill"),
    title: ShieldConfiguration.Label(
        text: "Clast Focus Active",
        color: .white
    ),
    subtitle: ShieldConfiguration.Label(
        text: "Complete your session to unblock",
        color: .lightGray
    )
)

store.shield.applicationCategories?.shieldConfiguration = shieldConfig
```

### Default Duration
Change the default in `ScreenTimeFocusController.swift:29`:
```swift
func startFocus(durationMinutes: Int = 25) async throws {
```

## Troubleshooting

### "Permission Denied" Errors
- Ensure Family Controls capability is enabled
- Check device Settings → Screen Time is enabled
- Try deleting and reinstalling the app

### Apps Not Blocking
- Verify app is running on a real device (not simulator)
- Check that apps are selected in Focus Settings
- Ensure DeviceActivity Monitor extension is properly configured
- Check extension is signed with same team ID as main app

### Extension Not Executing
- Verify extension Info.plist is correct
- Check extension has Family Controls capability
- Ensure ClastActivityMonitor.swift is in extension target only
- Try cleaning build folder (Cmd+Shift+K)

### Shield Not Clearing
- Check monitor extension's `intervalDidEnd` is called
- Verify `stopFocus()` is called when timer ends
- Manually call `focusController.stopFocus()` if needed

## Production Considerations

1. **Privacy Policy**: App Store requires disclosure of Screen Time API usage
2. **Parental Controls**: Handle devices with parental controls enabled
3. **Error Messaging**: Provide clear user guidance for permission denials
4. **Graceful Degradation**: Consider allowing sessions without blocking if authorization fails
5. **Testing**: Thoroughly test on multiple iOS versions and device types

## Next Steps

1. Create the DeviceActivity Monitor Extension target
2. Move ClastActivityMonitor.swift to extension
3. Enable Family Controls on both targets
4. Test on a physical iOS device
5. Configure blocked apps in Focus Settings
6. Start a focus session and verify apps are blocked
7. Complete or end session and verify apps unblock

## Support

For issues with FamilyControls APIs:
- [Apple Developer Documentation](https://developer.apple.com/documentation/familycontrols)
- [Screen Time API Forums](https://developer.apple.com/forums/tags/screen-time-api)

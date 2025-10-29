# Custom Shield UI Setup Guide

This guide walks you through setting up the custom Clast shield screen that appears when users try to open blocked apps during focus sessions.

## Overview

The custom shield UI provides:
- **Clast branding** with flame icon and custom messaging
- **Deep linking** to return to the app from blocked screens
- **Analytics tracking** for shield impressions and button taps
- **Localization** support for multiple languages
- **Accessibility** features (VoiceOver, Dynamic Type, high contrast)

## Files Created

### Extension Files (Must be in ClastShieldConfiguration target)
- `ShieldConfigurationExtension.swift` - Defines shield appearance
- `ShieldActionExtension.swift` - Handles button tap actions
- `ShieldAnalytics.swift` - Analytics tracking helper
- `Localizable.strings` - Localized text strings

### Main App Files
- Updated `ClastApp.swift` - Deep link URL handling

## Step-by-Step Setup

### 1. Create ManagedSettings UI Extension

1. **Add New Target**
   - In Xcode: File → New → Target
   - Search for "Managed Settings UI Extension"
   - Name it: `ClastShieldConfiguration`
   - Click "Finish"
   - When prompted to activate scheme, click "Activate"

2. **Delete Default Files**
   - Delete the default `ShieldConfigurationExtension.swift` that Xcode creates
   - We'll use our custom implementation instead

### 2. Add Files to Extension Target

Move/add these files to the `ClastShieldConfiguration` target:
- `ShieldConfigurationExtension.swift`
- `ShieldActionExtension.swift`
- `ShieldAnalytics.swift`
- `Localizable.strings`

**IMPORTANT**: Ensure these files are ONLY in the extension target, not the main app.

### 3. Enable Capabilities

Both the **main app** and **extension** need capabilities:

1. Select `ClastShieldConfiguration` target
2. Go to "Signing & Capabilities"
3. Add "Family Controls" capability

### 4. Configure URL Scheme

The shield screen uses `clast://focus` to deep link back to the app.

1. Select the **Clast** (main app) target
2. Go to "Info" tab
3. Expand "URL Types"
4. Add a new URL Type:
   - **Identifier**: `com.GroovyGears.Clast`
   - **URL Schemes**: `clast`
   - **Role**: Editor

### 5. Configure Extension Info.plist

The extension's `Info.plist` should have:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.managed-settings-ui.shield-configuration</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).ShieldConfigurationExtension</string>
</dict>
```

### 6. Add Shield Action Handler

In the extension's `Info.plist`, also add:

```xml
<key>NSExtension</key>
<dict>
    <!-- ... existing keys ... -->
    <key>NSExtensionAttributes</key>
    <dict>
        <key>ShieldActionDelegateClassName</key>
        <string>$(PRODUCT_MODULE_NAME).ShieldActionExtension</string>
    </dict>
</dict>
```

### 7. Build and Test

1. **Build the extension target** first: Cmd+B with extension selected
2. **Build the main app**: Switch to Clast scheme and build
3. **Test on a real device** (shields don't work in simulator)

## How It Works

### Shield Appearance Flow

1. User tries to open a blocked app
2. iOS calls `ShieldConfigurationExtension.configuration(shielding:)`
3. Returns custom `ShieldConfiguration` with:
   - Clast flame icon
   - "Clast Focus Active" title
   - Encouraging subtitle
   - "Open Clast" and "Back" buttons

### Button Action Flow

1. User taps "Open Clast" button
2. iOS calls `ShieldActionExtension.handle(action:)`
3. Analytics logged: `trackOpenClastTapped()`
4. Returns `.defer` with `clast://focus` URL
5. iOS opens Clast app with deep link
6. `ClastApp.handleDeepLink()` processes URL
7. User sees their active focus session

### Deep Link Handling

When `clast://focus` is opened:
- App launches (or comes to foreground)
- `onOpenURL` handler in `ClastApp.swift` is called
- `FocusHomeView` automatically shows running session if `activeTimer != nil`
- User can view progress, take a break, or end session early

## Shield Configuration Details

### Visual Design

```swift
ShieldConfiguration(
    backgroundBlurStyle: .systemUltraThinMaterial,  // Subtle blur
    backgroundColor: .black,                         // Dark background
    icon: UIImage(systemName: "flame.fill"),        // Clast flame
    title: "Clast Focus Active",                     // Bold title
    subtitle: "Stay focused on your session",        // Encouraging text
    primaryButtonLabel: "Open Clast",                // Red button
    primaryButtonBackgroundColor: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0),
    secondaryButtonLabel: "Back"                     // Outlined button
)
```

### Customization Options

To customize the shield appearance, edit `ShieldConfigurationExtension.swift`:

**Change icon:**
```swift
icon: UIImage(named: "CustomShieldIcon")  // Use custom asset
```

**Change colors:**
```swift
primaryButtonBackgroundColor: UIColor.systemBlue  // Different color
```

**Add random encouragement:**
```swift
let encouragements = [
    "You're doing great!",
    "Stay strong!",
    "Keep going!"
]
subtitle: ShieldConfiguration.Label(
    text: encouragements.randomElement() ?? "Stay focused",
    color: .lightGray
)
```

## Analytics Integration

The shield tracks three event types:
1. **Impressions** - When shield is shown
2. **Primary Button** - "Open Clast" tapped
3. **Secondary Button** - "Back" tapped

### Adding Firebase Analytics

In `ShieldAnalytics.swift`, replace the TODO with:

```swift
import FirebaseAnalytics

private func logToConsole(_ eventName: String, properties: [String: String]) {
    Analytics.logEvent(eventName, parameters: properties)
}
```

### Adding Custom Analytics

```swift
private func logToConsole(_ eventName: String, properties: [String: String]) {
    // Your analytics SDK
    MyAnalytics.track(eventName, properties: properties)
}
```

## Localization

To add more languages:

1. Select `Localizable.strings` in Xcode
2. Open File Inspector (⌥⌘1)
3. Click "Localize..."
4. Add language (e.g., Spanish)
5. Translate strings in new `.strings` file

Example Spanish translation:

```strings
"shield.title.blocked" = "Enfoque Clast Activo";
"shield.subtitle.app" = "Mantén el enfoque en tu sesión";
"shield.button.primary" = "Abrir Clast";
"shield.button.secondary" = "Volver";
```

## Accessibility

The shield configuration automatically supports:

### VoiceOver
- Icon labeled as "Clast flame icon"
- Buttons have descriptive labels
- Title and subtitle are read aloud

### Dynamic Type
- Text scales with user's font size preference
- Layout adjusts automatically

### High Contrast
- Colors adjust for reduced transparency
- Button borders become more prominent

### Testing Accessibility

1. Enable VoiceOver: Settings → Accessibility → VoiceOver
2. Test shield navigation with swipe gestures
3. Verify all elements are reachable and labeled
4. Test Dynamic Type: Settings → Display & Brightness → Text Size

## Troubleshooting

### Shield Not Appearing

**Issue**: Default system shield shows instead of custom one

**Solutions**:
- Verify extension has Family Controls capability
- Check extension is built and embedded in app
- Ensure `ShieldConfigurationExtension` class name matches Info.plist
- Clean build folder (Cmd+Shift+K) and rebuild

### Deep Link Not Working

**Issue**: Tapping "Open Clast" does nothing

**Solutions**:
- Verify URL scheme `clast` is registered in main app Info.plist
- Check `onOpenURL` handler in `ClastApp.swift`
- Ensure app is not already in foreground
- Test URL scheme: `xcrun simctl openurl booted clast://focus`

### Analytics Not Logging

**Issue**: Events not appearing in analytics dashboard

**Solutions**:
- Check `ShieldAnalytics.logToConsole()` implementation
- Verify analytics SDK is initialized
- Enable debug logging to see events in console
- Ensure extension has network permissions (if needed)

### Extension Crashes

**Issue**: Shield causes app or extension to crash

**Solutions**:
- Check crash logs in ~/Library/Logs/DiagnosticReports
- Verify all assets (icons, images) exist
- Ensure ShieldConfiguration properties are valid
- Test on device (extensions don't work in simulator)

## Testing Checklist

- [ ] Extension builds without errors
- [ ] Main app builds with extension embedded
- [ ] Shield appears when blocked app is opened
- [ ] Custom icon and branding visible
- [ ] "Open Clast" button opens app
- [ ] Deep link navigates to running session
- [ ] "Back" button dismisses shield
- [ ] Analytics events logged correctly
- [ ] VoiceOver reads all elements
- [ ] Dynamic Type scales text
- [ ] Localization works for multiple languages
- [ ] Shield appearance matches dark/light mode

## Advanced Customization

### Time-Based Messages

Show remaining time on shield:

```swift
// In ShieldConfigurationExtension.swift
let defaults = UserDefaults(suiteName: "group.com.GroovyGears.Clast")
if let endTime = defaults?.object(forKey: "sessionEndTime") as? Date {
    let remaining = Int(endTime.timeIntervalSinceNow)
    let minutes = remaining / 60
    subtitle = ShieldConfiguration.Label(
        text: "\(minutes) minutes remaining",
        color: .lightGray
    )
}
```

### Context-Specific Shields

Different shields for different apps:

```swift
override func configuration(shielding application: Application) -> ShieldConfiguration {
    // Check app bundle ID (if accessible)
    let isSocialMedia = checkIfSocialMedia(application)

    return ShieldConfiguration(
        // ... standard config ...
        subtitle: ShieldConfiguration.Label(
            text: isSocialMedia
                ? "Social media can wait!"
                : "Stay focused on your session",
            color: .lightGray
        )
    )
}
```

## Production Considerations

1. **Privacy**: Shield doesn't collect personal data or app-specific info
2. **Performance**: Keep shield configuration lightweight
3. **Battery**: Analytics should be efficient and batch events
4. **Network**: Consider offline analytics queue
5. **Testing**: Test on multiple iOS versions and device types
6. **App Store**: Disclose Screen Time API usage in privacy policy

## Resources

- [Apple Family Controls Documentation](https://developer.apple.com/documentation/familycontrols)
- [ManagedSettings Documentation](https://developer.apple.com/documentation/managedsettings)
- [ManagedSettingsUI Documentation](https://developer.apple.com/documentation/managedsettingsui)
- [URL Scheme Programming Guide](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)

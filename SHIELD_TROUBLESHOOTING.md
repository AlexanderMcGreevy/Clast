# Shield Not Appearing - Troubleshooting Guide

If the custom Clast shield isn't showing when you open blocked apps, follow this checklist:

## Quick Checklist

- [ ] Testing on a **real iOS device** (not simulator)
- [ ] **Screen Time permission** granted
- [ ] **Apps selected** in Focus Settings
- [ ] **Focus session active** (timer running)
- [ ] **Extension built** and embedded in app

## Detailed Troubleshooting

### 1. Running on Real Device?

**Issue**: Shields don't work in iOS Simulator

**Check**:
```swift
#if targetEnvironment(simulator)
print("❌ Simulator detected - shields won't work")
#endif
```

**Solution**:
- Connect a real iPhone/iPad
- Select device in Xcode (top bar)
- Build and run on physical device

---

### 2. Screen Time Permission Granted?

**Issue**: App doesn't have Screen Time authorization

**Check**:
```swift
let status = AuthorizationCenter.shared.authorizationStatus
print("Auth Status: \(status)")
// Should be .approved
```

**Solution**:
1. Open **Settings** app
2. Go to **Screen Time**
3. Scroll to bottom → **Apps**
4. Find **Clast**
5. Enable **App & Website Activity**

---

### 3. Apps Selected for Blocking?

**Issue**: No apps configured in Focus Settings

**Check**:
```swift
let store = FamilyActivitySelectionStore.shared
print("Apps selected: \(store.hasAnySelectedApps)")
print("Count: \(store.selectedItemCount)")
```

**Solution**:
1. Open **Clast** app
2. Go to **Settings** tab
3. Tap **Blocked Apps**
4. Select apps to block
5. Tap **Done**

---

### 4. Focus Session Active?

**Issue**: Session not started, so shields not applied

**Check**:
```swift
let controller = ScreenTimeFocusController.shared
print("Focus active: \(controller.isFocusActive)")
```

**Solution**:
1. Go to **Focus** tab
2. Set duration
3. Tap **Start Focus Session**
4. Verify timer is counting down

---

### 5. Extension Target Created?

**Issue**: ClastShieldConfiguration extension doesn't exist

**Check in Xcode**:
1. Project Navigator (⌘1)
2. Look for **ClastShieldConfiguration** folder
3. Check **targets** in project settings

**Solution**: Create the extension target

```
File → New → Target → Managed Settings UI Extension
Name: ClastShieldConfiguration
```

---

### 6. Extension Files in Correct Target?

**Issue**: Shield files in main app instead of extension

**Check**:
1. Select `ShieldConfigurationExtension.swift`
2. File Inspector (⌥⌘1)
3. Check **Target Membership**

**Should be**:
- ✅ ClastShieldConfiguration
- ❌ Clast (main app)

**Solution**:
1. Select all shield files:
   - ShieldConfigurationExtension.swift
   - ShieldActionExtension.swift
   - ShieldAnalytics.swift
2. File Inspector → Target Membership
3. ✅ Check ClastShieldConfiguration
4. ❌ Uncheck Clast

---

### 7. Extension Built and Embedded?

**Issue**: Extension not compiled or embedded in app bundle

**Check**:
```bash
# After building, check app bundle
ls ~/Library/Developer/Xcode/DerivedData/Clast-*/Build/Products/Debug-iphoneos/Clast.app/PlugIns/
# Should see: ClastShieldConfiguration.appex
```

**Solution**:
1. Select **ClastShieldConfiguration** scheme
2. Build (⌘B)
3. Select **Clast** scheme
4. Clean Build Folder (⇧⌘K)
5. Build (⌘B)
6. Verify extension embedded

---

### 8. Info.plist Configured?

**Issue**: Extension Info.plist missing configuration

**Check ClastShieldConfiguration Info.plist**:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.managed-settings-ui.shield-configuration</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).ShieldConfigurationExtension</string>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>ShieldActionDelegateClassName</key>
        <string>$(PRODUCT_MODULE_NAME).ShieldActionExtension</string>
    </dict>
</dict>
```

**Solution**:
1. Select extension target
2. Info tab
3. Add keys above if missing

---

### 9. Family Controls Capability?

**Issue**: Extension missing Family Controls capability

**Check**:
1. Select **ClastShieldConfiguration** target
2. Signing & Capabilities tab
3. Look for **Family Controls**

**Solution**:
1. Click **+ Capability**
2. Add **Family Controls**
3. Rebuild extension

---

### 10. Bundle Identifier Correct?

**Issue**: Extension bundle ID doesn't match app

**Check**:
- Main app: `com.GroovyGears.Clast`
- Extension should be: `com.GroovyGears.Clast.ClastShieldConfiguration`

**Solution**:
1. Select extension target
2. General tab → Identity
3. Bundle Identifier should be: `$(APP_BUNDLE_ID).ClastShieldConfiguration`

---

## Using Shield Diagnostics

Add this button to your app for debugging:

```swift
// In FocusHomeView.swift
#if DEBUG
Button("🔍 Run Shield Diagnostics") {
    ShieldDiagnostics.shared.runDiagnostics()
}
.padding()
#endif
```

This will print:
- Authorization status
- Selected apps count
- Extension bundle presence
- Device type (simulator vs real)
- Focus active state

---

## Testing Shield Appearance

### Test Steps:

1. **Start a session**:
   - Open Clast
   - Configure blocked apps (e.g., Safari, Mail)
   - Start 5-minute focus session

2. **Try to open blocked app**:
   - Press Home button
   - Tap blocked app icon (e.g., Safari)

3. **Expected behavior**:
   - App icon dims/grays out
   - Shield screen appears with:
     - Clast flame icon
     - "Clast Focus Active" title
     - "Stay focused" subtitle
     - "Open Clast" button (red)
     - "Back" button

4. **If default shield appears**:
   - You see generic iOS shield (not Clast branded)
   - Extension not loaded properly
   - Follow steps above to fix

5. **If app opens normally**:
   - Shields not applied
   - Check authorization and app selection
   - Verify focus session is active

---

## Common Errors

### "Extension not found"

**Symptom**: Shield diagnostics shows extension missing

**Fix**:
```bash
# Check if extension exists
ls ClastShieldConfiguration/
# Should show: ShieldConfigurationExtension.swift, etc.

# Rebuild extension
xcodebuild -target ClastShieldConfiguration -configuration Debug
```

### "Authorization failed"

**Symptom**: Shield diagnostics shows `.denied` or `.notDetermined`

**Fix**:
1. Delete app from device
2. Reinstall
3. When prompted, **Allow** Screen Time access
4. Try again

### "Shields not applying"

**Symptom**: Apps open normally during focus session

**Fix**:
```swift
// Add logging to ScreenTimeFocusController
print("🛡️ Applying shields...")
print("Applications: \(selectionStore.selection.applicationTokens)")
store.shield.applications = selection.applicationTokens
print("✅ Shields applied")
```

Check console output when starting session.

---

## Advanced Debugging

### Enable Verbose Logging

In `ScreenTimeFocusController.swift`:

```swift
func startFocus(durationMinutes: Int = 25) async throws {
    print("📍 Starting focus session...")
    print("   Duration: \(durationMinutes) minutes")
    print("   Authorization: \(authorization.authorizationState)")
    print("   Has apps: \(selectionStore.hasAnySelectedApps)")

    // ... rest of method
}
```

### Check Shield Extension Logs

Shield extensions log to system console:

```bash
# View extension logs
log stream --predicate 'process == "ClastShieldConfiguration"' --level debug
```

Then trigger shield by opening blocked app.

### Inspect Managed Settings

```swift
let store = ManagedSettingsStore()
print("Shield Applications: \(store.shield.applications)")
print("Shield Categories: \(store.shield.applicationCategories)")
```

---

## Still Not Working?

If shields still aren't appearing after following all steps:

1. **Clean everything**:
   - Product → Clean Build Folder (⇧⌘K)
   - Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/Clast-*`
   - Delete app from device

2. **Rebuild from scratch**:
   - Build ClastShieldConfiguration scheme
   - Build Clast scheme
   - Install on device

3. **Reset Screen Time**:
   - Settings → Screen Time → Turn Off Screen Time
   - Restart device
   - Settings → Screen Time → Turn On Screen Time
   - Reinstall Clast
   - Grant permission again

4. **Check iOS version**:
   - Shields require iOS 15.0+
   - Settings → General → About → iOS Version

5. **Create minimal test**:
   ```swift
   // Simple test in a new project
   let store = ManagedSettingsStore()
   store.shield.applications = [/* single app token */]
   // Try to open that app
   ```

---

## Need More Help?

1. **Check Apple Forums**: Search for "ManagedSettings shield not appearing"
2. **Review Sample Code**: Apple's ScreenTime API samples
3. **File Feedback**: https://feedbackassistant.apple.com
4. **Stack Overflow**: Tag `ios`, `screen-time-api`, `family-controls`

Remember: Shields are a system-level feature and can be finicky. Patience and systematic debugging will get them working!

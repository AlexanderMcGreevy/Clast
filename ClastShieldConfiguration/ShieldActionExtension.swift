import Foundation
import ManagedSettings
import ManagedSettingsUI

/*
 ShieldActionExtension - Handle Shield Button Actions

 This extension handles what happens when users tap buttons on the shield screen.

 Button Actions:
 - Primary Button ("Build On"): Opens Clast app with focus deep link
 - Secondary Button ("Give Up"): Opens Clast app with home deep link

 Both buttons open the app, giving users a chance to reflect on their choice.

 Setup Requirements:
 - Must be in ClastShieldConfiguration extension target
 - Works for ALL shield types (apps, categories, domains)

 Deep Link Setup:
 - Add URL scheme "clast" to app's Info.plist
 - Handle deep links in your app with .onOpenURL modifier
*/

class ShieldActionExtension: ShieldActionDelegate {

    // MARK: - Individual App Actions

    func handle(action: ShieldAction, for application: Application, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, itemType: .application, completionHandler: completionHandler)
    }

    // MARK: - Category App Actions (Also Important!)

    func handle(action: ShieldAction, for application: Application, in category: ActivityCategory, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, itemType: .categoryApp, completionHandler: completionHandler)
    }

    // MARK: - Web Domain Actions

    func handle(action: ShieldAction, for webDomain: WebDomain, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, itemType: .webDomain, completionHandler: completionHandler)
    }

    // MARK: - Category Web Domain Actions

    func handle(action: ShieldAction, for webDomain: WebDomain, in category: ActivityCategory, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleAction(action, itemType: .categoryDomain, completionHandler: completionHandler)
    }

    // MARK: - Shared Action Handler

    private enum ItemType {
        case application
        case categoryApp
        case webDomain
        case categoryDomain

        var analyticsType: ShieldAnalyticsEvent.EntityType {
            switch self {
            case .application, .categoryApp:
                return .application
            case .webDomain, .categoryDomain:
                return .webDomain
            }
        }
    }

    private func handleAction(_ action: ShieldAction, itemType: ItemType, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // "Build On" button pressed - open Clast app
            handlePrimaryButton(itemType: itemType, completionHandler: completionHandler)

        case .secondaryButtonPressed:
            // "Go Back" button pressed - just close shield
            handleSecondaryButton(itemType: itemType, completionHandler: completionHandler)

        @unknown default:
            // Future-proof for new action types
            completionHandler(.close)
        }
    }

    private func handlePrimaryButton(itemType: ItemType, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Track analytics (optional)
        ShieldAnalytics.shared.trackOpenClastTapped(for: itemType.analyticsType)

        // Open Clast app with deep link
        // The URL will be handled by your app's .onOpenURL modifier
        if URL(string: "clast://focus") != nil {
            // .defer tells iOS to attempt opening the URL
            // The system will open your app if the URL scheme is registered
            completionHandler(.defer)
        } else {
            // Fallback: just close the shield
            completionHandler(.close)
        }
    }

    private func handleSecondaryButton(itemType: ItemType, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Track analytics (optional)
        ShieldAnalytics.shared.trackBackTapped(for: itemType.analyticsType)

        // "Give Up" - Open Clast app to home screen
        // This gives the user a moment to reflect before accessing the blocked app
        if URL(string: "clast://home") != nil {
            completionHandler(.defer)
        } else {
            // Fallback: just close the shield
            completionHandler(.close)
        }
    }
}

/*
 NOTES:

 1. ShieldActionResponse options:
    - .defer: Attempts to open URL (for deep linking to your app)
    - .close: Closes the shield and returns to home screen
    - .none: Does nothing (rare use case)

 2. Deep Link Setup in Main App:
    Add to your Info.plist:
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>clast</string>
            </array>
        </dict>
    </array>

 3. Handle Deep Links in SwiftUI:
    .onOpenURL { url in
        if url.scheme == "clast" {
            switch url.host {
            case "focus":
                // "Build On" button - navigate to focus screen
                // User wants to continue their session
            case "home":
                // "Give Up" button - navigate to home screen
                // User is giving up, show reflection/stats
            default:
                break
            }
        }
    }

 4. Button Behavior:
    - "Build On": Opens app to focus screen (clast://focus)
    - "Give Up": Opens app to home screen (clast://home)

    Both buttons open the app, creating a "speed bump" that:
    - Forces user to consciously decide
    - Allows app to show consequences (stats, streak loss, etc.)
    - Provides intervention opportunity
*/

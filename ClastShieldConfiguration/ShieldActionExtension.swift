import ManagedSettings
import ManagedSettingsUI

/*
 Shield Action Handler Extension

 This extension handles user actions when they tap buttons on the shield screen.
 Must be in the ClastShieldConfiguration extension target.
 */

class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction, for application: Application, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // Track analytics
            ShieldAnalytics.shared.trackOpenClastTapped(for: .application)

            // User tapped "Open Clast" - open app with deep link
            if let url = URL(string: "clast://focus") {
                completionHandler(.defer)
                // The system will attempt to open the URL
            } else {
                completionHandler(.close)
            }

        case .secondaryButtonPressed:
            // Track analytics
            ShieldAnalytics.shared.trackBackTapped(for: .application)

            // User tapped "Back" - just close the shield
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomain, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            ShieldAnalytics.shared.trackOpenClastTapped(for: .webDomain)

            // User tapped "Open Clast" - open app with deep link
            if let url = URL(string: "clast://focus") {
                completionHandler(.defer)
            } else {
                completionHandler(.close)
            }

        case .secondaryButtonPressed:
            ShieldAnalytics.shared.trackBackTapped(for: .webDomain)

            // User tapped "Back" - just close the shield
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategory, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            ShieldAnalytics.shared.trackOpenClastTapped(for: .category)

            if let url = URL(string: "clast://focus") {
                completionHandler(.defer)
            } else {
                completionHandler(.close)
            }

        case .secondaryButtonPressed:
            ShieldAnalytics.shared.trackBackTapped(for: .category)
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }
}

import ManagedSettings
import ManagedSettingsUI
import UIKit

/*
 ShieldConfigurationExtension - Custom Shield UI

 THIS IS THE KEY TO OPAL-LIKE BEHAVIOR!

 By implementing ALL FOUR shield configuration methods and returning
 the same custom configuration, we ensure our custom shield appears
 whether the block came from:
 - An individually selected app
 - An app in a blocked category
 - A web domain
 - A web domain category

 Setup Requirements:
 - Extension target must have "Managed Settings UI" capability
 - Info.plist NSExtensionPrincipalClass must match this class name
 - Extension bundle ID must be: [APP_BUNDLE_ID].ClastShieldConfiguration

 The custom shield will show:
 - Title: "Build Castles, Not CARDinal"
 - Subtitle: Motivational quote
 - Icon: Castle emoji 🏰
 - Primary button: "Build On"
 - Dark blur background
*/

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // MARK: - Individual App Shield
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return customShieldConfiguration()
    }

    // MARK: - Category-Based App Shield (THE MISSING PIECE!)
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return customShieldConfiguration()
    }

    // MARK: - Web Domain Shield
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return customShieldConfiguration()
    }

    // MARK: - Category-Based Web Domain Shield
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return customShieldConfiguration()
    }

    // MARK: - Shared Custom Configuration

    private func customShieldConfiguration() -> ShieldConfiguration {
        // Get a random motivational quote each time shield appears
        let quote = ShieldQuotes.randomQuote()

        // Create custom shield with your branding
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0),
            icon: UIImage(systemName: "brain.head.profile"),
            title: ShieldConfiguration.Label(
                text: "Stay Focused",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: quote.formatted,
                color: .white.withAlphaComponent(0.8)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Build On",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor.systemIndigo,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Give Up",
                color: .white.withAlphaComponent(0.7)
            )
        )
    }
}

/*
 NOTES:

 1. All four methods return the SAME configuration - this is intentional!
    It ensures consistent branding regardless of how the app was blocked.

 2. The primaryButton ("Build On") can trigger a ShieldActionExtension
    to open your app or show a breathing exercise.

 3. The secondaryButton just closes the shield and returns to home screen.

 4. You can customize:
    - backgroundBlurStyle: .systemMaterialDark, .systemUltraThinMaterial, etc.
    - backgroundColor: Any UIColor
    - icon: UIImage (system symbol or custom image)
    - title/subtitle: Text and colors
    - button labels and colors

 5. To use emoji icon instead of SF Symbol, use:
    icon: UIImage(systemName: "face.smiling") or similar

 6. This approach works on iOS 16+ with the latest ScreenTime APIs
*/

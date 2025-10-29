import Foundation

/*
 Shield Analytics Helper

 Provides non-identifying analytics hooks for shield impressions and actions.
 This tracks usage patterns without collecting personal data.
 */

enum ShieldAnalyticsEvent {
    case shieldImpression(entityType: EntityType)
    case primaryButtonTapped(entityType: EntityType)
    case secondaryButtonTapped(entityType: EntityType)

    enum EntityType: String {
        case application
        case webDomain
        case category
    }
}

class ShieldAnalytics {
    static let shared = ShieldAnalytics()

    private init() {}

    /// Log a shield analytics event
    /// - Parameter event: The event to log
    func logEvent(_ event: ShieldAnalyticsEvent) {
        // TODO: Integrate with your analytics provider (e.g., Firebase Analytics, Mixpanel)
        // Example implementation:
        switch event {
        case .shieldImpression(let entityType):
            logToConsole("Shield Impression", properties: ["entity_type": entityType.rawValue])

        case .primaryButtonTapped(let entityType):
            logToConsole("Shield Primary Button", properties: ["entity_type": entityType.rawValue])

        case .secondaryButtonTapped(let entityType):
            logToConsole("Shield Secondary Button", properties: ["entity_type": entityType.rawValue])
        }
    }

    private func logToConsole(_ eventName: String, properties: [String: String]) {
        #if DEBUG
        print("📊 [Shield Analytics] \(eventName): \(properties)")
        #endif

        // In production, replace this with actual analytics calls:
        // Analytics.logEvent(eventName, parameters: properties)
    }
}

// MARK: - Usage in Shield Extensions
extension ShieldAnalytics {
    func trackShieldShown(for entityType: ShieldAnalyticsEvent.EntityType) {
        logEvent(.shieldImpression(entityType: entityType))
    }

    func trackOpenClastTapped(for entityType: ShieldAnalyticsEvent.EntityType) {
        logEvent(.primaryButtonTapped(entityType: entityType))
    }

    func trackBackTapped(for entityType: ShieldAnalyticsEvent.EntityType) {
        logEvent(.secondaryButtonTapped(entityType: entityType))
    }
}

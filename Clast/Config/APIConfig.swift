//
//  APIConfig.swift
//  Clast
//
//  Configuration for Cloud Run API endpoint
//

import Foundation

struct APIConfig {
    // MARK: - Cloud Run Configuration

    /// Your Cloud Run endpoint URL
    static let cloudRunURL = "https://clast-productivity-972161315816.us-east1.run.app"

    /// Verification endpoint path
    static let verificationPath = "/verify-progress"

    /// Full verification endpoint URL
    static var verificationEndpoint: String {
        "\(cloudRunURL)\(verificationPath)"
    }

    // MARK: - Request Configuration

    /// Request timeout in seconds
    static let timeoutInterval: TimeInterval = 30

    // MARK: - Validation

    /// Check if API is properly configured
    static var isConfigured: Bool {
        !cloudRunURL.contains("YOUR-CLOUD-RUN-URL")
    }

    /// Get configuration status message
    static var configurationStatus: String {
        if isConfigured {
            return "✅ API configured: \(cloudRunURL)"
        } else {
            return "⚠️ API not configured. Update cloudRunURL in APIConfig.swift"
        }
    }
}

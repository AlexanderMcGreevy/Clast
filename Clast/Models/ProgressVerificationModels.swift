//
//  ProgressVerificationModels.swift
//  Clast
//
//  Created by Alexander McGreevy on 11/13/25.
//

import Foundation

// MARK: - Request Models

struct ProgressVerificationRequest: Codable {
    let sessionGoal: String
    let sessionStateSummary: String
    let userProgressNote: String
    let scrapedTextDelta: String
}

// MARK: - Response Models

struct ProgressVerificationResponse: Codable {
    let score: Double
    let allowBreak: Bool
    let reason: String
    let updatedSummary: String

    /// Calculate break duration in seconds based on score
    /// Score range: 0.0-1.0 (0-100%) maps to 0-30 minutes
    var breakDuration: Int {
        guard allowBreak else { return 0 }

        // Linear scaling: 0-100% → 0-30 minutes
        let percentage = max(0.0, min(1.0, score)) // Clamp to 0-1
        let maxMinutes = Int(percentage * 30.0) // Scale to 0-30 minutes
        return maxMinutes * 60 // Convert to seconds
    }

    /// Formatted break duration string (e.g., "5:00")
    var breakDurationFormatted: String {
        let minutes = breakDuration / 60
        let seconds = breakDuration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Session State

struct SessionProgressState: Codable {
    let sessionGoal: String
    var stateSummary: String
    var breakNumber: Int
    var lastScrapedText: String
    
    init(sessionGoal: String) {
        self.sessionGoal = sessionGoal
        self.stateSummary = "Session just started. No progress has been made yet."
        self.breakNumber = 0
        self.lastScrapedText = ""
    }
}

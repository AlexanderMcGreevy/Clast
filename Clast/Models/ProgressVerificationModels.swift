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
    var breakDuration: Int {
        guard allowBreak else { return 0 }

        switch score {
        case 0.0..<0.6:
            return 0 // No break earned
        case 0.6..<0.7:
            return 3 * 60 // 3 minutes
        case 0.7..<0.85:
            return 5 * 60 // 5 minutes
        case 0.85...1.0:
            return 10 * 60 // 10 minutes
        default:
            return 5 * 60 // Default 5 minutes
        }
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

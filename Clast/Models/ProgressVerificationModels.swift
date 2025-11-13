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

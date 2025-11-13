//
//  SessionStateManager.swift
//  Clast
//
//  Created by Alexander McGreevy on 11/13/25.
//

import Foundation

@MainActor
class SessionStateManager: ObservableObject {
    static let shared = SessionStateManager()
    
    @Published private(set) var currentState: SessionProgressState?
    
    private let stateKey = "clast_session_progress_state"
    
    private init() {
        loadState()
    }
    
    // MARK: - State Management
    
    func startNewSession(goal: String) {
        currentState = SessionProgressState(sessionGoal: goal)
        saveState()
    }
    
    func updateState(newSummary: String, scrapedText: String) {
        guard var state = currentState else { return }
        
        state.stateSummary = newSummary
        state.breakNumber += 1
        state.lastScrapedText = scrapedText
        
        currentState = state
        saveState()
    }
    
    func clearState() {
        currentState = nil
        UserDefaults.standard.removeObject(forKey: stateKey)
    }
    
    func getScrapedTextDelta(newText: String) -> String {
        guard let state = currentState else { return newText }
        
        // Simple delta: return only new content
        // For more sophisticated diffing, you could use a diff algorithm
        if state.lastScrapedText.isEmpty {
            return newText
        }
        
        // If new text contains old text, return what's new
        if newText.contains(state.lastScrapedText) {
            return newText.replacingOccurrences(of: state.lastScrapedText, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Otherwise return all new text
        return newText
    }
    
    // MARK: - Persistence
    
    private func saveState() {
        guard let state = currentState else { return }
        
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: stateKey)
        }
    }
    
    private func loadState() {
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let decoded = try? JSONDecoder().decode(SessionProgressState.self, from: data) else {
            return
        }
        
        currentState = decoded
    }
}

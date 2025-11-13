import Foundation

class ProgressVerificationService {
    static let shared = ProgressVerificationService()
    
    private let apiEndpoint = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-20250514"
    
    private init() {}
    
    // MARK: - System Prompt
    
    private let systemPrompt = """
    You are a productivity verification assistant for a focus session app. Your role is to evaluate whether a user has made meaningful progress toward their stated session goal.

    You will receive four pieces of information:
    1. **sessionGoal**: The user's original goal/plan for this focus session
    2. **sessionStateSummary**: A running summary of what has been accomplished so far
    3. **userProgressNote**: The user's description of what they just accomplished (may say "User provided images only" if they only submitted photos/screenshots)
    4. **scrapedTextDelta**: New text content extracted from the user's documents or screenshots since the last check (may be empty or irrelevant)

    Your task:
    1. Compare the new progress against the original session goal
    2. Consider the running summary to understand what was already completed
    3. Evaluate the scraped text delta carefully:
       - If it contains code, designs, writing, or other work artifacts, this is strong evidence of progress
       - If it's just UI text or irrelevant content, de-weight it
       - Screenshots of completed work (code editors, designs, documents) should be valued highly
    4. Assign a score from 0.0 to 1.0:
       - 0.0-0.3: Very little or no meaningful progress
       - 0.3-0.6: Some progress but minor/incomplete
       - 0.6-1.0: Strong, meaningful progress toward the goal
    5. Set allowBreak to true only if the progress meaningfully advances the session plan (generally score >= 0.6)
    6. Provide a short, direct explanation (1-2 sentences max)
    7. Generate an updated state summary (1-3 sentences) capturing:
       - What tasks appear completed
       - What progress was made in this interval
       - What remains to be done

    CRITICAL: Respond ONLY with valid JSON in this exact format:
    {
      "score": 0.75,
      "allowBreak": true,
      "reason": "Completed the authentication flow implementation as planned. Screenshot shows working login code.",
      "updatedSummary": "User completed authentication flow with OAuth integration. Database schema designed. Next: implement user profile API endpoints."
    }

    No markdown, no explanations outside the JSON, no code blocks. Just raw JSON.
    
    Be generous but fair: If the user provides screenshots of real work (code, designs, documents), that's strong evidence even without detailed written descriptions. However, screenshots of random apps or unrelated content don't count as progress.
    """
    
    // MARK: - Main Verification Method
    
    func verifyProgress(
        sessionGoal: String,
        currentSummary: String,
        userNote: String,
        scrapedDelta: String
    ) async throws -> ProgressVerificationResponse {
        
        let request = ProgressVerificationRequest(
            sessionGoal: sessionGoal,
            sessionStateSummary: currentSummary,
            userProgressNote: userNote,
            scrapedTextDelta: scrapedDelta
        )
        
        let userMessage = formatUserMessage(request)
        
        let response = try await callClaudeAPI(
            systemPrompt: systemPrompt,
            userMessage: userMessage
        )
        
        return try parseResponse(response)
    }
    
    // MARK: - API Communication
    
    private func callClaudeAPI(systemPrompt: String, userMessage: String) async throws -> String {
        guard let url = URL(string: apiEndpoint) else {
            throw VerificationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": userMessage
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw VerificationError.apiError("HTTP error")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw VerificationError.invalidResponse
        }
        
        return text
    }
    
    // MARK: - Message Formatting
    
    private func formatUserMessage(_ request: ProgressVerificationRequest) -> String {
        return """
        sessionGoal: \(request.sessionGoal)
        
        sessionStateSummary: \(request.sessionStateSummary)
        
        userProgressNote: \(request.userProgressNote)
        
        scrapedTextDelta: \(request.scrapedTextDelta.isEmpty ? "(No new document content)" : request.scrapedTextDelta)
        """
    }
    
    // MARK: - Response Parsing
    
    private func parseResponse(_ responseText: String) throws -> ProgressVerificationResponse {
        // Strip any potential markdown code blocks
        let cleaned = responseText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleaned.data(using: .utf8) else {
            throw VerificationError.invalidResponse
        }
        
        do {
            let response = try JSONDecoder().decode(ProgressVerificationResponse.self, from: data)
            
            // Validate response
            guard response.score >= 0.0 && response.score <= 1.0 else {
                throw VerificationError.invalidScore
            }
            
            return response
        } catch {
            print("Failed to parse Claude response: \(cleaned)")
            throw VerificationError.parsingFailed(error)
        }
    }
}

// MARK: - Error Types

enum VerificationError: LocalizedError {
    case invalidURL
    case apiError(String)
    case invalidResponse
    case invalidScore
    case parsingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API endpoint"
        case .apiError(let message):
            return "API error: \(message)"
        case .invalidResponse:
            return "Invalid response from verification service"
        case .invalidScore:
            return "Score out of valid range (0.0-1.0)"
        case .parsingFailed(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        }
    }
}
```

## Summary of All Files

### Project Structure:
```
Clast/
├── Models/
│   ├── ProgressVerificationModels.swift          (ADD)
│   └── SessionStateManager.swift                 (ADD)
├── ScreenTime/
│   ├── ProgressVerificationService.swift         (UPDATE - enhanced prompt)
│   └── TextRecognitionService.swift              (ADD)
├── Views/
│   ├── AIProofGateView.swift                     (REPLACE)
│   ├── ImagePicker.swift                         (ADD)
│   ├── RunningSessionView.swift                  (from previous response)
│   └── SessionGoalInputView.swift                (from previous response)

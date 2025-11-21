import Foundation

class ProgressVerificationService {
    static let shared = ProgressVerificationService()

    // MARK: - Configuration
    // All configuration is now in APIConfig.swift
    private var apiEndpoint: String {
        APIConfig.verificationEndpoint
    }

    private init() {
        // Print configuration status on initialization
        print("📡 [ProgressVerificationService] \(APIConfig.configurationStatus)")
    }

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

        // Call Cloud Run endpoint which handles Gemini API
        return try await callVerificationAPI(request: request)
    }
    
    // MARK: - API Communication

    private func callVerificationAPI(request: ProgressVerificationRequest) async throws -> ProgressVerificationResponse {
        // Validate configuration
        guard APIConfig.isConfigured else {
            throw VerificationError.notConfigured
        }

        guard let url = URL(string: apiEndpoint) else {
            throw VerificationError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = APIConfig.timeoutInterval

        // Send request directly to Cloud Run
        // Cloud Run will handle Gemini API call with its own API key
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VerificationError.apiError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to extract error message from Cloud Run
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = json["error"] as? String {
                throw VerificationError.apiError("Server error: \(errorMessage)")
            }
            throw VerificationError.apiError("HTTP \(httpResponse.statusCode)")
        }

        // Parse direct JSON response from Cloud Run
        do {
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(ProgressVerificationResponse.self, from: data)

            // Validate score range
            guard apiResponse.score >= 0.0 && apiResponse.score <= 1.0 else {
                throw VerificationError.invalidScore
            }

            return apiResponse
        } catch let decodingError as DecodingError {
            print("❌ [ProgressVerificationService] Failed to decode response: \(decodingError)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Response: \(responseString)")
            }
            throw VerificationError.parsingFailed(decodingError)
        } catch {
            throw VerificationError.parsingFailed(error)
        }
    }
}

// MARK: - Error Types

enum VerificationError: LocalizedError {
    case notConfigured
    case invalidURL
    case apiError(String)
    case invalidResponse
    case invalidScore
    case parsingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "API not configured. Please update cloudRunURL in APIConfig.swift with your Cloud Run endpoint."
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

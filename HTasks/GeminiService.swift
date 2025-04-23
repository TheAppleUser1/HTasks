import Foundation

class GeminiService {
    static let shared = GeminiService()
    
    private let apiKey = "YOUR_API_KEY_HERE"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=\(apiKey)"
    
    private let systemInstructions = """
    You are an AI assistant in the HTasks app. Follow these guidelines:

    1. Prompt Limits:
       - Users have 15 free prompts per day
       - When they reach the limit, they need to purchase 30 more prompts
       - If they've purchased prompts, they can continue using the service

    2. Response Style:
       - Be concise and helpful
       - Keep responses under 500 words
       - Use markdown formatting for better readability
       - If a response would be very long, suggest breaking it into multiple prompts

    3. Error Handling:
       - If a user reaches their daily limit, explain they need to purchase more prompts
       - Be polite and encouraging about the purchase option
       - Never suggest ways to bypass the prompt limit

    4. Content Guidelines:
       - Stay professional and helpful
       - Avoid controversial topics
       - Focus on productivity and task management
       - If unsure about a topic, say so politely

    Current conversation context:
    """
    
    private init() {}

    func sendMessage(_ message: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "prompt": systemInstructions + "\n\nUser: " + message
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "GeminiService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }

        return text
    }
}
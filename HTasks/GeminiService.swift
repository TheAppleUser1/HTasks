import Foundation

class GeminiService {
    static let shared = GeminiService()
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite-001:generateContent"
    
    private init() {
        self.apiKey = "AIzaSyDHXGA4eOKAw6PYS83RCdwveTWLg7_BHEQ"
    }
    
    func sendMessage(_ message: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = """
        You are HTasksAI, a motivating and supportive AI assistant for task management. Your role is to:
        2. Provide encouragement and motivation for task completion
        3. Offer practical advice for task prioritization and time management
        4. Suggest strategies for maintaining productivity and focus
        5. Be friendly, supportive, and understanding
        6. Use markdown formatting for better readability
        7. Keep responses concise and actionable
        8. Focus on task-related queries and productivity advice
        9. You can just chat with the user if they want to, no need to be task related.
        
        Remember to:
        - Be positive and encouraging
        - Provide specific, actionable advice
        - Use appropriate formatting (bold, lists, etc.)
        - Maintain a helpful and supportive tone
        - Focus on practical solutions
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": systemPrompt]
                    ],
                    "role": "system"
                ],
                [
                    "parts": [
                        ["text": message]
                    ],
                    "role": "user"
                ]
            ]
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
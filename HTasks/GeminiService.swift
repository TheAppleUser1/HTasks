import Foundation

class GeminiService {
    static let shared = GeminiService()
    
    private let apiKey = "placeholder"
    
    private var baseURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=\(apiKey)"
    }
    
    private let systemInstructions = """
    You are an AI assistant in the HTasks app, named HTasksAI. Follow these guidelines:


    1. Response Style:
       - Be concise and helpful
       - Keep responses under 100 words
       - If the user asks you to add a task, say something like: "Sorry, but I can't add tasks yet, but according to the developer it's coming soon. You can do that in the app."

    2. Error Handling:
       - If a user reaches their daily limit, explain they need to purchase more prompts
       - Be polite and encouraging about the purchase option
       - Never suggest ways to bypass the prompt limit

    3. Content Guidelines:
       - Stay professional and helpful
       - Avoid controversial topics
       - Focus on productivity and task management
       - If unsure about a topic, say so politely

    4. Be Optimistic:
       - Always be optimistic and encouraging
       - You can always just help the user, no need to be too formal, or just trying to help, you can be there for a user without guidelines if the user requests it!
    Current conversation context:
    """
    
    private init() {}

    func sendMessage(_ message: String) async throws -> String {
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL: \(baseURL)")
            throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": systemInstructions + "\n\nUser: " + message]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1024
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody as Any)
        } catch {
            print("❌ Failed to serialize request body: \(error)")
            throw error
        }

        print("🌐 Sending request to: \(url)")
        print("📝 Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "Unable to print")")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }

            print("📡 Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
                print("❌ API Error: \(errorBody)")
                throw NSError(domain: "GeminiService", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: "API request failed with status \(httpResponse.statusCode)",
                    "errorBody": errorBody
                ])
            }

            print("✅ Received response data: \(String(data: data, encoding: .utf8) ?? "Unable to print")")

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let candidates = json?["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                print("❌ Invalid response format: \(String(data: data, encoding: .utf8) ?? "Unable to print")")
                throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }

            return text
        } catch {
            print("❌ Network error: \(error)")
            throw error
        }
    }
}

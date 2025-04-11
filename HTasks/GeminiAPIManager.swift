import Foundation

class GeminiAPIManager {
    static let shared = GeminiAPIManager()
    private let apiKey = "AIzaSyDHXGA4eOKAw6PYS83RCdwveTWLg7_BHEQ"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite"
    
    private let systemInstructions = """
    You are a helpful AI model named "HTasksAI". Your purpose is to assist users with their tasks and questions. 
    Always be friendly, professional, and concise in your responses. 
    If you're unsure about something, be honest about it.
    Try to provide practical and actionable advice when possible.
    """
    
    private init() {}
    
    func canMakeRequest() -> Bool {
        return SecureStorageManager.shared.getRemainingMessages() > 0
    }
    
    func sendRequest(prompt: String) async throws -> String {
        guard canMakeRequest() else {
            throw GeminiError.rateLimitExceeded
        }
        
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": systemInstructions],
                        ["text": "\n\nUser: \(prompt)"]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topP": 0.8,
                "topK": 40
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                _ = SecureStorageManager.shared.decrementMessages()
                return geminiResponse.candidates.first?.content.parts.first?.text ?? "No response"
            case 429:
                throw GeminiError.apiRateLimitExceeded
            case 400:
                throw GeminiError.invalidRequest
            case 401:
                throw GeminiError.unauthorized
            default:
                throw GeminiError.serverError(statusCode: httpResponse.statusCode)
            }
        } catch let error as GeminiError {
            throw error
        } catch {
            throw GeminiError.networkError(error)
        }
    }
}

enum GeminiError: Error {
    case rateLimitExceeded
    case apiRateLimitExceeded
    case invalidResponse
    case invalidRequest
    case unauthorized
    case serverError(statusCode: Int)
    case networkError(Error)
    
    var localizedDescription: String {
        switch self {
        case .rateLimitExceeded:
            return "You have reached your daily message limit"
        case .apiRateLimitExceeded:
            return "API rate limit exceeded. Please try again later"
        case .invalidResponse:
            return "Received an invalid response from the server"
        case .invalidRequest:
            return "Invalid request. Please check your input"
        case .unauthorized:
            return "Unauthorized access. Please check your API key"
        case .serverError(let statusCode):
            return "Server error (Status code: \(statusCode))"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
    }
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String
    }
} 
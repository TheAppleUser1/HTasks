import Foundation

class GeminiService {
    private let apiKey: String
    private let baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    private func makeRequest(prompt: String) async throws -> String {
        let url = URL(string: "\(baseUrl)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw NSError(domain: "GeminiService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        return text
    }
    
    func suggestPriority(for title: String, context: TaskStats) async throws -> TaskPriority {
        let prompt = """
        Based on this task title: "\(title)" and the following context:
        - Total tasks: \(context.totalTasks)
        - Completed tasks: \(context.completedTasks)
        - Category distribution: \(context.categoryDistribution)
        - Priority distribution: \(context.priorityDistribution)
        
        Suggest a priority level for this task. Only respond with one of these exact words: Easy, Medium, or Difficult.
        Consider the task complexity, urgency, and how it fits with existing tasks.
        """
        
        let response = try await makeRequest(prompt: prompt)
        let priority = response.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        switch priority {
        case "easy": return .low
        case "medium": return .medium
        case "difficult": return .high
        default: return .medium
        }
    }
    
    func suggestTasks(context: TaskStats) async throws -> [String]? {
        let prompt = """
        Based on the following task statistics:
        - Total tasks: \(context.totalTasks)
        - Completed tasks: \(context.completedTasks)
        - Category distribution: \(context.categoryDistribution)
        - Priority distribution: \(context.priorityDistribution)
        
        Suggest 3 new tasks that would be relevant and helpful. Consider:
        1. Balance across categories
        2. Current workload
        3. Completion patterns
        
        Format your response as a simple list of 3 task titles, one per line, without numbers or bullets.
        """
        
        let response = try await makeRequest(prompt: prompt)
        let suggestions = response
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
        
        return Array(suggestions)
    }
    
    func generateMotivationalMessage(for title: String) async throws -> String? {
        let prompt = """
        Create a short, motivational message (maximum 100 characters) for this task: "\(title)"
        The message should be encouraging and specific to the task.
        Focus on the positive impact of completing the task.
        """
        
        let response = try await makeRequest(prompt: prompt)
        let message = response.trimmingCharacters(in: .whitespacesAndNewlines)
        return message.isEmpty ? nil : message
    }
} 
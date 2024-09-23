import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}

class NetworkService {
    static let shared = NetworkService()
    private init() {}
    
    private let baseURL = "https://openrouter.ai/api/v1"
    private let apiKey = "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" // Replace with your actual API key
    
    func sendMessage(prompt: String, model: String) -> AnyPublisher<String, APIError> {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<String, APIError> in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    return Fail(error: APIError.networkError(NSError(domain: "HTTP Error", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: nil))).eraseToAnyPublisher()
                }
                
                return Just(data)
                    .decode(type: OpenAIResponse.self, decoder: JSONDecoder())
                    .mapError { APIError.decodingError($0) }
                    .compactMap { $0.choices.first?.message.content }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}

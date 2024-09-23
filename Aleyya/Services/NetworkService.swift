import Foundation
import Combine
import UIKit

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case imageEncodingError
    case apiError(String)
}

class NetworkService {
    static var shared: NetworkService!
    
    private let baseURL = "https://openrouter.ai/api/v1"
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessage(prompt: String, model: String, image: UIImage? = nil) -> AnyPublisher<String, APIError> {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        var messages: [[String: Any]] = [
            ["role": "user", "content": prompt]
        ]
        
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            let base64Image = imageData.base64EncodedString()
            messages[0]["content"] = [
                ["type": "text", "text": prompt],
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
            ]
        }
        
        let body: [String: Any] = [
            "model": model,
            "messages": messages
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: APIError.imageEncodingError).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { APIError.networkError($0) }
            .flatMap { data, response -> AnyPublisher<String, APIError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: APIError.networkError(NSError(domain: "Invalid Response", code: 0, userInfo: nil))).eraseToAnyPublisher()
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    return Fail(error: APIError.apiError("HTTP \(httpResponse.statusCode): \(errorMessage)")).eraseToAnyPublisher()
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

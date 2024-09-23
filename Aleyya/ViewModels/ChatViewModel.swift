import Foundation
import Combine
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var selectedModel: ChatModel = .sonnet35
    @Published var selectedImage: UIImage?
    @Published var errorMessage: String?
    @Published var apiKey: String = UserDefaults.standard.string(forKey: "OpenRouterAPIKey") ?? "" {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "OpenRouterAPIKey")
            NetworkService.shared = NetworkService(apiKey: apiKey)
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NetworkService.shared = NetworkService(apiKey: apiKey)
    }
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil else { return }
        guard !apiKey.isEmpty else {
            errorMessage = "Please enter your API key in the settings."
            return
        }
        
        let userMessage = ChatMessage(content: inputMessage, isUser: true, image: selectedImage)
        messages.append(userMessage)
        
        isLoading = true
        errorMessage = nil
        
        NetworkService.shared.sendMessage(prompt: inputMessage, model: selectedModel.rawValue, image: selectedImage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    print("Error: \(error)")
                }
            } receiveValue: { [weak self] response in
                let botMessage = ChatMessage(content: response, isUser: false)
                self?.messages.append(botMessage)
            }
            .store(in: &cancellables)
        
        inputMessage = ""
        selectedImage = nil
    }
    
    func startNewChat() {
        messages.removeAll()
        inputMessage = ""
        isLoading = false
        selectedImage = nil
        errorMessage = nil
    }
    
    func setImage(_ image: UIImage) {
        selectedImage = resizeImage(image)
    }
    
    private func resizeImage(_ image: UIImage) -> UIImage {
        let maxSize: CGFloat = 512
        let aspectRatio = image.size.width / image.size.height
        var newSize: CGSize
        
        if image.size.width > maxSize || image.size.height > maxSize {
            if aspectRatio > 1 {
                newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
            } else {
                newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
            }
        } else {
            return image // No need to resize
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
    let image: UIImage?
    
    init(content: String, isUser: Bool, image: UIImage? = nil) {
        self.content = content
        self.isUser = isUser
        self.image = image
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.isUser == rhs.isUser &&
        lhs.timestamp == rhs.timestamp &&
        lhs.image == rhs.image
    }
}

enum ChatModel: String, CaseIterable, Identifiable {
    case gpt4o = "openai/chatgpt-4o-latest"
    case sonnet35 = "anthropic/claude-3.5-sonnet"
    case opus = "anthropic/claude-3-opus"
    case qwen = "qwen/qwen-2.5-72b-instruct"
    case mistral = "mistralai/mistral-7b-instruct"
    case llama = "meta-llama/llama-3.1-8b-instruct"
    case gemini = "google/gemini-flash-1.5"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .gpt4o: return "OpenAI: ChatGPT-4o"
        case .sonnet35: return "Anthropic: Claude 3.5 Sonnet"
        case .opus: return "Anthropic: Claude 3 Opus"
        case .qwen: return "Qwen2.5 72B Instruct"
        case .mistral: return "Mistral 7B Instruct"
        case .llama: return "Llama 3.1 8B Instruct"
        case .gemini: return "Gemini Flash 1.5"
        }
    }
    
    var supportsImageUpload: Bool {
        switch self {
        case .gpt4o, .gemini, .sonnet35:
            return true
        default:
            return false
        }
    }
}

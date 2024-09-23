import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var selectedModel: ChatModel = .sonnet35
    
    private var cancellables = Set<AnyCancellable>()
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(content: inputMessage, isUser: true)
        messages.append(userMessage)
        
        isLoading = true
        
        NetworkService.shared.sendMessage(prompt: inputMessage, model: selectedModel.rawValue)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    print("Error: \(error)")
                    // Handle error (e.g., show an alert)
                }
            } receiveValue: { [weak self] response in
                let botMessage = ChatMessage(content: response, isUser: false)
                self?.messages.append(botMessage)
            }
            .store(in: &cancellables)
        
        inputMessage = ""
    }
    
    func startNewChat() {
        messages.removeAll()
        inputMessage = ""
        isLoading = false
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.isUser == rhs.isUser &&
        lhs.timestamp == rhs.timestamp
    }
}

enum ChatModel: String, CaseIterable, Identifiable {
    case gpt4o = "openai/gpt-4-0613"
    case sonnet35 = "anthropic/claude-2.0"
    case opus = "anthropic/claude-2.1"
    case qwen = "qwen/qwen1.5-7b-chat"
    case mistral = "mistralai/mistral-7b-instruct-v0.1"
    case llama = "meta-llama/llama-2-13b-chat"
    case gemini = "google/gemini-pro"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .gpt4o: return "GPT-4o"
        case .sonnet35: return "Sonnet 3.5"
        case .opus: return "Opus"
        case .qwen: return "Qwen 2 7B Instruct"
        case .mistral: return "Mistral 7B Instruct"
        case .llama: return "Llama 3.1 8B Instruct"
        case .gemini: return "Gemini Flash 1.5"
        }
    }
}
import Foundation

enum MessageType: String, Codable {
    case text
    case image
    case voice
}

class Message: Identifiable, ObservableObject {
    let id: String
    let type: MessageType
    @Published var content: String  // 使用 @Published 使其可观察
    let timestamp: Date
    let isUser: Bool
    var imageBase64: String?
    var imageUrl: String?
    var voiceUrl: String?
    
    init(id: String, type: MessageType, content: String, timestamp: Date, isUser: Bool, imageUrl: String? = nil, imageBase64: String? = nil, voiceUrl: String? = nil) {
        self.id = id
        self.type = type
        self.content = content
        self.timestamp = timestamp
        self.isUser = isUser
        self.imageUrl = imageUrl
        self.imageBase64 = imageBase64
        self.voiceUrl = voiceUrl
    }
}

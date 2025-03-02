import Foundation
import UIKit

enum MessageType {
    case text
    case image
    case voice
}

class Message: Identifiable, ObservableObject {
    let id: String
    let type: MessageType
    @Published var content: String
    let timestamp: Date
    let isUser: Bool
    var imageUrl: String?
    var imageBase64: String?
    var voiceUrl: String?
    var transcribedText: String?
    var localImage: UIImage? // 添加本地图片属性
    
    init(id: String, type: MessageType, content: String, timestamp: Date, isUser: Bool, imageUrl: String? = nil, imageBase64: String? = nil, voiceUrl: String? = nil, transcribedText: String? = nil, localImage: UIImage? = nil) {
        self.id = id
        self.type = type
        self.content = content
        self.timestamp = timestamp
        self.isUser = isUser
        self.imageUrl = imageUrl
        self.imageBase64 = imageBase64
        self.voiceUrl = voiceUrl
        self.transcribedText = transcribedText
        self.localImage = localImage
    }
}

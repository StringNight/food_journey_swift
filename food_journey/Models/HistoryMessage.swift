struct HistoryMessage: Codable {
    let content: String
    let is_user: Bool
    let created_at: String
    let voice_url: String?
    let image_url: String?
    let transcribed_text: String?
    
    // 添加自定义解码器，处理可能的类型不匹配问题
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 解码 content
        content = try container.decode(String.self, forKey: .content)
        
        // 解码 is_user
        is_user = try container.decode(Bool.self, forKey: .is_user)
        
        // 解码 created_at
        created_at = try container.decode(String.self, forKey: .created_at)
        
        // 解码可选字段
        voice_url = try container.decodeIfPresent(String.self, forKey: .voice_url)
        image_url = try container.decodeIfPresent(String.self, forKey: .image_url)
        transcribed_text = try container.decodeIfPresent(String.self, forKey: .transcribed_text)
    }
    
    // 添加便捷初始化方法
    init(content: String, is_user: Bool, created_at: String, voice_url: String? = nil, image_url: String? = nil, transcribed_text: String? = nil) {
        self.content = content
        self.is_user = is_user
        self.created_at = created_at
        self.voice_url = voice_url
        self.image_url = image_url
        self.transcribed_text = transcribed_text
    }
}
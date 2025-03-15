import Foundation
import UIKit

/// 网络服务类
class NetworkService: NSObject, URLSessionDelegate {
    static let shared = NetworkService()
    
    // 使用HTTPS协议，确保安全连接
    let baseURL = "https://infsols.com:8000/api/v1"
    
    // 创建URLSession实例
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.waitsForConnectivity = true  // 等待网络连接
        
        // 添加网络连接调试
        if #available(iOS 17.0, *) {
            config.networkServiceType = .responsiveData
        }
        
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    private override init() {
        super.init()
        print("NetworkService初始化完成，使用HTTPS连接")
        print("服务器URL: \(baseURL)")
    }
    
    // 实现URLSessionDelegate方法，允许接受自签名证书
    // 在NetworkService类中添加或修改URLSessionDelegate方法
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    // 检查服务器域名是否是我们的开发服务器
    if let serverTrust = challenge.protectionSpace.serverTrust,
       challenge.protectionSpace.host == "infsols.com" {
        print("接受自签名证书: \(challenge.protectionSpace.host)")
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    } else {
    // 对于其他域名，使用默认处理
    completionHandler(.performDefaultHandling, nil)
    }
    }
    func request<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = false,
        contentType: String = "application/json",
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.cachePolicy = cachePolicy // 应用缓存策略
        
        if requiresAuth {
            if let token = UserDefaults.standard.string(forKey: "auth_token") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        if let body = body {
            request.httpBody = body
            if let jsonString = String(data: body, encoding: .utf8) {
                print("Request Body: \(jsonString)")
            }
        }
        
        print("发送请求: \(method) \(url.absoluteString)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response Data: \(jsonString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = try? JSONDecoder().decode(FoodJourneyModels.ErrorResponse.self, from: data) {
                    print("Error Response: \(errorResponse.detail)")
                    
                    // 处理验证错误，提取具体错误信息
                    if httpResponse.statusCode == 422 && errorResponse.type == "validation_error" && errorResponse.errors != nil && !errorResponse.errors!.isEmpty {
                        // 获取第一个验证错误的具体信息
                        let firstError = errorResponse.errors!.first!
                        throw NetworkError.validationError(firstError.message)
                    }
                    
                    throw NetworkError.serverError(errorResponse.detail)
                }
                throw NetworkError.serverError("请求失败: \(httpResponse.statusCode)")
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                if let date = self.dateFormatter.date(from: dateString) {
                    return date
                }
                
                let fallbackFormatter = DateFormatter()
                fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
                fallbackFormatter.locale = Locale(identifier: "en_US_POSIX")
                
                if let date = fallbackFormatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }
            
            do {
                let decodedResponse = try decoder.decode(T.self, from: data)
                
                // 添加调试输出，查看是否含有avatar_url属性
                if let jsonData = try? JSONSerialization.data(withJSONObject: try JSONSerialization.jsonObject(with: data, options: []), options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    if jsonString.contains("avatar_url") {
                        print("包含avatar_url的响应: \(jsonString)")
                    }
                }
                
                return decodedResponse
            } catch {
                print("解码错误: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("原始JSON数据: \(jsonString)")
                }
                throw error
            }
        } catch {
            print("网络请求失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func decodeAuthResponse(data: Data) throws -> FoodJourneyModels.AuthResponse {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let response = try decoder.decode(FoodJourneyModels.AuthResponse.self, from: data)
            print("成功解码 AuthResponse:")
            print("- access_token: \(response.token_info.access_token)")
            print("- token_type: \(response.token_info.token_type)")
            print("- user.id: \(response.user.id)")
            print("- user.username: \(response.user.username)")
            // print("- user.email: \(response.user.email)")
            print("- user.created_at: \(response.user.created_at)")
            if let avatarUrl = response.user.avatar_url {
                print("- user.avatar_url: \(avatarUrl)")
            }
            return response
        } catch let DecodingError.dataCorrupted(context) {
            print("数据损坏: \(context)")
            throw NetworkError.decodingError("数据损坏: \(context)")
        } catch let DecodingError.keyNotFound(key, context) {
            print("未找到键 \(key): \(context)")
            throw NetworkError.decodingError("未找到键 \(key)")
        } catch let DecodingError.valueNotFound(value, context) {
            print("未找到值 \(value): \(context)")
            throw NetworkError.decodingError("未找到值 \(value)")
        } catch let DecodingError.typeMismatch(type, context) {
            print("类型不匹配 \(type): \(context)")
            throw NetworkError.decodingError("类型不匹配 \(type)")
        } catch {
            print("其他解码错误: \(error)")
            throw NetworkError.decodingError("解码失败: \(error.localizedDescription)")
        }
    }
    
    func sendChatMessage(_ message: String) async throws -> FoodJourneyModels.MessageResponse {
        let request = FoodJourneyModels.ChatTextRequest(message: message)
        return try await self.request(
            endpoint: "/chat/text",
            method: "POST",
            body: try JSONEncoder().encode(request),
            requiresAuth: true
        )
    }
    
    func sendChatImage(_ imageBase64: String) async throws -> FoodJourneyModels.MessageResponse {
        let request = FoodJourneyModels.ChatImageRequest(file: imageBase64)
        return try await self.request(
            endpoint: "/chat/image",
            method: "POST",
            body: try JSONEncoder().encode(request),
            requiresAuth: true
        )
    }
    
    func sendChatVoice(_ voiceUrl: String) async throws -> FoodJourneyModels.MessageResponse {
        let request = FoodJourneyModels.ChatVoiceRequest(voice_url: voiceUrl)
        return try await self.request(
            endpoint: "/chat/voice",
            method: "POST",
            body: try JSONEncoder().encode(request),
            requiresAuth: true
        )
    }
    
    // 修改上传文件方法，适配后端返回的用户信息格式
    private func uploadFile(_ fileData: Data, filename: String, mimeType: String, endpoint: String) async throws -> String {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        print("准备上传文件到: \(url.absoluteString)")
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("已添加认证令牌")
        } else {
            print("警告: 未找到认证令牌")
        }
        
        var body = Data()
        
        // 添加文件数据
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("开始上传文件，请求体大小: \(body.count) 字节")
        
        do {
            let (responseData, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("无效的HTTP响应")
                throw NetworkError.invalidResponse
            }
            
            print("收到HTTP响应，状态码: \(httpResponse.statusCode)")
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let responseString = String(data: responseData, encoding: .utf8) {
                    print("错误响应内容: \(responseString)")
                }
                throw NetworkError.serverError("上传失败，状态码: \(httpResponse.statusCode)")
            }
            
            // 打印响应内容，帮助调试
            if let responseString = String(data: responseData, encoding: .utf8) {
                print("响应内容: \(responseString)")
            }
            
            // 尝试解析为UserProfile格式（与后端auth.py中的avatar端点返回格式匹配）
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                
                // 解析为包含用户信息的响应，使用已定义的UserProfile结构体
                let userResponse: FoodJourneyModels.UserProfile = try decoder.decode(FoodJourneyModels.UserProfile.self, from: responseData)
                if let avatarUrl = userResponse.avatar_url {
                    print("成功解析用户响应，头像URL: \(avatarUrl)")
                    return avatarUrl
                } else {
                    print("用户响应中没有头像URL")
                    throw NetworkError.decodingError("用户响应中没有头像URL")
                }
            } catch {
                print("解析为UserProfile失败: \(error.localizedDescription)")
                
                // 尝试解析为简单的JSON对象
                if let json = try? JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                    // 尝试从用户对象中获取avatar_url
                    if let user = json["user"] as? [String: Any],
                       let avatarUrl = user["avatar_url"] as? String {
                        print("从JSON中获取到头像URL: \(avatarUrl)")
                        return avatarUrl
                    }
                    
                    // 直接尝试获取avatar_url
                    if let avatarUrl = json["avatar_url"] as? String {
                        print("从JSON中获取到头像URL: \(avatarUrl)")
                        return avatarUrl
                    }
                    
                    print("JSON中没有找到avatar_url字段，完整JSON: \(json)")
                }
                
                throw NetworkError.decodingError("无法解析头像上传响应")
            }
        } catch {
            print("上传过程中发生错误: \(error.localizedDescription)")
            throw error
        }
    }
    
    // 修改上传图片方法，增加更多错误处理
    func uploadImage(_ image: UIImage, endpoint: String) async throws -> String {
        print("开始上传图片到 \(endpoint)")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("无法将图片转换为JPEG数据")
            throw NetworkError.serverError("图片处理失败")
        }
        
        print("图片已转换为JPEG数据，大小: \(imageData.count) 字节")
        
        do {
            let url = try await uploadFile(imageData, filename: "image.jpg", mimeType: "image/jpeg", endpoint: endpoint)
            print("图片上传成功，返回URL: \(url)")
            return url
        } catch {
            print("图片上传失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    func uploadAudio(_ audioData: Data, filename: String, endpoint: String) async throws -> FoodJourneyModels.AudioUploadResponse {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 构建请求体，完全匹配 Python 的 files 参数格式
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        print(body)
        
        let (responseData, response) = try await session.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            if let errorString = String(data: responseData, encoding: .utf8) {
                print("上传失败: \(errorString)")
            }
            throw NetworkError.serverError("音频上传失败: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        print("Response Data: \(String(data: responseData, encoding:.utf8)!)")
        return try decoder.decode(FoodJourneyModels.AudioUploadResponse.self, from: responseData)
    }
    
    func uploadAudioAndStream(
        _ audioData: Data,
        filename: String,
        endpoint: String,
        requiresAuth: Bool = true
    ) async throws -> AsyncStream<StreamData> {
        return AsyncStream<StreamData> { continuation in
            Task {
                do {
                    guard let url = URL(string: baseURL + endpoint) else {
                        throw NetworkError.invalidURL
                    }
                    
                    // 创建 multipart/form-data 请求
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    
                    let boundary = "Boundary-\(UUID().uuidString)"
                    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                    
                    if requiresAuth {
                        if let token = UserDefaults.standard.string(forKey: "auth_token") {
                            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                        }
                    }
                    
                    // 构建请求体
                    var body = Data()
                    
                    // 添加文件数据
                    body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                    body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
                    body.append(audioData)
                    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
                    
                    request.httpBody = body
                    
                    // 发送请求并处理流式响应
                    let (bytes, _) = try await session.bytes(for: request)
                    
                    for try await line in bytes.lines {
                        print("接收到数据行: \(line)")
                        
                        // 确保行以 "data:" 开头
                        guard line.hasPrefix("data:") else { continue }
                        
                        // 提取 JSON 部分
                        let jsonString = line.dropFirst("data:".count).trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !jsonString.isEmpty else { continue }
                        
                        // 解析 JSON
                        if let data = jsonString.data(using: .utf8) {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                                
                                if let type = json?["type"] as? String {
                                    if type == "message", let messageData = json?["data"] as? String {
                                        // 处理消息类型
                                        continuation.yield(.message(messageData))
                                    } else if type == "history", let historyData = json?["data"] as? [[String: Any]] {
                                        // 将 history 数组转换为 JSON Data
                                        let historyJson = try JSONSerialization.data(withJSONObject: historyData, options: [])
                                        // 解码为 [ChatHistory]
                                        let histories = try JSONDecoder().decode([ChatHistory].self, from: historyJson)
                                        continuation.yield(.history(histories))
                                    }
                                }
                            } catch {
                                print("JSON 解析错误: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    print("上传音频并获取流式响应失败: \(error.localizedDescription)")
                    continuation.finish()
                }
            }
        }
    }
    
    func uploadImageAndStream(_ image: UIImage, endpoint: String) async throws -> AsyncStream<StreamData> {
    // 将图片转换为JPEG数据
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        throw NetworkError.invalidResponse
    }
    
    // 创建请求
    guard let url = URL(string: baseURL + endpoint) else {
        throw NetworkError.invalidURL
    }
    
    // 创建一个唯一的边界字符串
    let boundary = "Boundary-\(UUID().uuidString)"
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    // 添加认证头
    if let token = UserDefaults.standard.string(forKey: "auth_token") {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    
    // 构建请求体
    var body = Data()
    
    // 添加文件数据
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(imageData)
    body.append("\r\n".data(using: .utf8)!)
    
    // 添加可选的caption字段
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
    body.append("".data(using: .utf8)!) // 空caption
    body.append("\r\n".data(using: .utf8)!)
    
    // 结束boundary
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    
    // 设置请求体
    request.httpBody = body
    
    // 直接使用请求对象发送请求，而不是通过streamRequest方法
    return AsyncStream<StreamData> { continuation in
        Task {
            do {
                // 发送请求并处理流式响应
                let (bytes, _) = try await session.bytes(for: request)
                
                for try await line in bytes.lines {
                    print("接收到数据行: \(line)")
                    
                    // 确保行以 "data:" 开头
                    guard line.hasPrefix("data:") else { continue }
                    
                    // 提取 JSON 部分
                    let jsonString = line.dropFirst("data:".count).trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !jsonString.isEmpty else { continue }
                    
                    // 解析 JSON
                    if let data = jsonString.data(using: .utf8) {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                            
                            if let type = json?["type"] as? String {
                                if type == "message", let messageData = json?["data"] as? String {
                                    // 处理消息类型
                                    continuation.yield(.message(messageData))
                                } else if type == "history", let historyData = json?["data"] as? [[String: Any]] {
                                    // 将 history 数组转换为 JSON Data
                                    let historyJson = try JSONSerialization.data(withJSONObject: historyData, options: [])
                                    // 解码为 [ChatHistory]
                                    let histories = try JSONDecoder().decode([ChatHistory].self, from: historyJson)
                                    continuation.yield(.history(histories))
                                }
                            }
                        } catch {
                            print("JSON 解析错误: \(error.localizedDescription)")
                        }
                    }
                }
                
                continuation.finish()
            } catch {
                print("上传图片并获取流式响应失败: \(error.localizedDescription)")
                continuation.finish()
            }
        }
    }
}
    
    func transferImageToBase64(_ image: UIImage) async throws -> String {
        guard let base64String = image.jpegData(compressionQuality: 1)?.base64EncodedString() else {
            throw NetworkError.serverError("图片处理失败")
        }
        return base64String
    }
    
    struct ChatHistory: Codable {
        let content: String
        let is_user: Bool
        let created_at: String
        let voice_url: String?
        let image_url: String?
        let transcribed_text: String?
    }
    
    /// 流式响应中可能的数据类型
    enum StreamData {
        case message(String)
        case history([ChatHistory])
    }
    
    
    func parseStreamData(from jsonString: String) -> StreamData? {
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("无法将字符串转换为 Data")
            return nil
        }
        
        do {
            // 先转换为字典，判断 type
            if let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let type = dict["type"] as? String {
                
                if type == "message", let message = dict["data"] as? String {
                    return .message(message)
                }
                else if type == "history", let historyArray = dict["data"] as? [[String: Any]] {
                    // 将 history 数组再次转换为 JSON Data，再解码为 [ChatHistory]
                    let jsonHistoryData = try JSONSerialization.data(withJSONObject: historyArray, options: [])
                    let histories = try JSONDecoder().decode([ChatHistory].self, from: jsonHistoryData)
                    return .history(histories)
                }
            }
        } catch {
            print("解析 JSON 时出错: \(error)")
        }
        return nil
    }
    
    
    
    // 修改 streamRequest 方法，参考文本消息处理的方式
    // 修改 streamRequest 方法，使用最简单直接的方式处理流式数据
    func streamRequest(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = false,
        contentType: String = "application/json"
    ) async throws -> AsyncStream<StreamData> {
        return AsyncStream<StreamData> { continuation in
            Task {
                do {
                    guard let url = URL(string: baseURL + endpoint) else {
                        throw NetworkError.invalidURL
                    }
                    
                    var request = URLRequest(url: url)
                    request.httpMethod = method
                    request.setValue(contentType, forHTTPHeaderField: "Content-Type")
                    
                    if requiresAuth {
                        if let token = UserDefaults.standard.string(forKey: "auth_token") {
                            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                        }
                    }
                    
                    if let body = body {
                        request.httpBody = body
                        if let jsonString = String(data: body, encoding: .utf8) {
                            print("Request Body: \(jsonString)")
                        }
                    }
                    
                    let (bytes, _) = try await session.bytes(for: request)
                    
                    for try await line in bytes.lines {
                        print("接收到数据行: \(line)")
                        
                        // 确保行以 "data:" 开头
                        guard line.hasPrefix("data:") else { continue }
                        
                        // 提取 JSON 部分
                        let jsonString = line.dropFirst("data:".count).trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !jsonString.isEmpty else { continue }
                        
                        // 解析 JSON
                        if let data = jsonString.data(using: .utf8) {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                                
                                if let type = json?["type"] as? String {
                                    if type == "message", let messageData = json?["data"] as? String {
                                        // 处理消息类型
                                        continuation.yield(.message(messageData))
                                    } else if type == "history", let historyData = json?["data"] as? [[String: Any]] {
                                        // 将 history 数组转换为 JSON Data
                                        let historyJson = try JSONSerialization.data(withJSONObject: historyData, options: [])
                                        // 解码为 [ChatHistory]
                                        let histories = try JSONDecoder().decode([ChatHistory].self, from: historyJson)
                                        continuation.yield(.history(histories))
                                    }
                                }
                            } catch {
                                print("JSON 解析错误: \(error.localizedDescription), 原始数据: \(jsonString)")
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    print("流请求错误: \(error.localizedDescription)")
                    continuation.finish()
                }
            }
        }
    }
    
    // 创建包含图片的表单数据，返回(数据, boundary)元组
    func createImageFormData(_ image: UIImage, fieldName: String, filename: String = "image.jpg") async throws -> (Data, String) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.serverError("图片处理失败")
        }
        
        let boundary = UUID().uuidString
        var body = Data()
        
        // 添加文件数据
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // 打印上传URL
        print("上传头像URL: \(baseURL + "/auth/avatar")")
        
        return (body, boundary)
    }
}

// 将NetworkError和扩展移到类外部的文件级别
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case noData
    case serverError(String)
    case decodingError(String)
    case validationError(String)
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .invalidResponse:
            return "服务器返回了无效的响应"
        case .noData:
            return "服务器没有返回数据"
        case .serverError(let message):
            return message
        case .decodingError(let message):
            return "数据解析错误: \(message)"
        case .validationError(let message):
            return message
        }
    }
}

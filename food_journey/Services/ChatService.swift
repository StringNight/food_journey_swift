import Foundation
import UIKit
import AVFoundation

@MainActor
class ChatService: ObservableObject {
    static let shared = ChatService()
    private let networkService = NetworkService.shared
    
    @Published var messages: [Message] = []
    @Published var isRecording = false
    private var audioRecorder: AVAudioRecorder?
    private var _audioPlayer: AVAudioPlayer?
    // 存储录音文件的本地路径映射
    private var localAudioFiles: [String: URL] = [:]
    
    var audioPlayer: AVAudioPlayer? {
        return _audioPlayer
    }
    
    private init() {}
    
    // 发送文本消息
    func sendTextMessage(_ text: String) async throws -> Message {
        let request = FoodJourneyModels.ChatTextRequest(message: text)
        
        let userMessage = Message(
            id: UUID().uuidString,
            type: .text,
            content: text,
            timestamp: Date(),
            isUser: true
        )
        
        let botMessage = Message(
            id: UUID().uuidString,
            type: .text,
            content: "",
            timestamp: Date(),
            isUser: false
        )
        
        await MainActor.run {
            messages.append(contentsOf: [userMessage, botMessage])
        }
        
        var accumulatedContent = ""
        
        // 使用 streamRequest 处理流式响应
        for try await streamData in try await networkService.streamRequest(
            endpoint: "/chat/stream",
            method: "POST",
            body: try JSONEncoder().encode(request),
            requiresAuth: true
        ) {
            switch streamData {
            case .message(let message):
                accumulatedContent += message
                await MainActor.run {
                    botMessage.content = accumulatedContent
                    // 更新数组中的消息
                    if let index = messages.firstIndex(where: { $0.id == botMessage.id }) {
                        messages[index] = botMessage
                    }
                }
            case .history:
                break
            }
        }
        return botMessage
    }
        
        // 发送图片消息
        func sendImageMessage(_ image: UIImage) async throws -> Message {
            let imageBase64 = try await networkService.transferImageToBase64(image)
            let request = FoodJourneyModels.ChatImageRequest(file: imageBase64)
            
            let response: FoodJourneyModels.MessageResponse = try await networkService.request(
                endpoint: "/chat/image",
                method: "POST",
                body: try JSONEncoder().encode(request),
                requiresAuth: true,
                contentType: "multipart/form-data"
            )
            
            let userMessage = Message(
                id: UUID().uuidString,
                type: .image,
                content: "",
                timestamp: Date(),
                isUser: true,
                imageBase64: imageBase64
            )
            
            let botMessage = Message(
                id: UUID().uuidString,
                type: .text,
                content: response.message,
                timestamp: Date(),
                isUser: false
            )
            
            messages.append(contentsOf: [userMessage, botMessage])
            return botMessage
        }
        
        // 开始录音
        func startRecording() throws {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentPath.appendingPathComponent("\(UUID().uuidString).m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
        }
        
        // 停止录音并发送
        // 停止录音并发送
        func stopRecordingAndSend() async throws -> Message? {
            guard let recorder = audioRecorder else { return nil }
            
            recorder.stop()
            isRecording = false
            
            let audioUrl = recorder.url
            let audioData = try Data(contentsOf: audioUrl)
            
            // 创建一个唯一标识符用于关联本地文件
            let localFileId = UUID().uuidString
            
            // 保存本地文件路径
            localAudioFiles[localFileId] = audioUrl
            
            let userMessage = Message(
                id: UUID().uuidString,
                type: .voice,
                content: "",  // 将由语音识别结果填充
                timestamp: Date(),
                isUser: true,
                voiceUrl: localFileId  // 使用本地文件ID而不是服务器URL
            )
            
            let botMessage = Message(
                id: UUID().uuidString,
                type: .text,
                content: "",
                timestamp: Date(),
                isUser: false
            )
            
            await MainActor.run {
                messages.append(contentsOf: [userMessage, botMessage])
            }
            
            // 直接发送语音文件并获取流式响应
            var accumulatedContent = ""
            
            // 使用 multipart/form-data 上传语音文件
            for try await streamData in try await networkService.uploadAudioAndStream(
                audioData,
                filename: audioUrl.lastPathComponent,
                endpoint: "/chat/voice"
            ) {
                switch streamData {
                case .message(let message):
                    accumulatedContent += message
                    await MainActor.run {
                        botMessage.content = accumulatedContent
                        if let index = messages.firstIndex(where: { $0.id == botMessage.id }) {
                            messages[index] = botMessage
                        }
                    }
                case .history(let history):
                    // 查找最后一条用户语音消息
                    for historyMessage in history {
                        if historyMessage.is_user && historyMessage.voice_url != nil {
                            await MainActor.run {
                                // 更新用户消息的内容，但保留本地文件ID作为voiceUrl
                                userMessage.content = historyMessage.transcribed_text ?? ""
                                // 不覆盖voiceUrl，保持使用本地文件ID
                                
                                if let index = messages.firstIndex(where: { $0.id == userMessage.id }) {
                                    messages[index] = userMessage
                                }
                            }
                            break
                        }
                    }
                }
            }
            
            return botMessage
        }
        
        // 播放语音消息
        func playVoiceMessage(url: String) async throws {
            // 检查是否是本地文件ID
            if let localFileURL = localAudioFiles[url] {
                // 播放本地文件
                print("播放本地录音文件: \(localFileURL.path)")
                
                do {
                    // 配置音频会话
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.playback, mode: .default)
                    try audioSession.setActive(true)
                    
                    // 创建并配置音频播放器
                    _audioPlayer = try AVAudioPlayer(contentsOf: localFileURL)
                    _audioPlayer?.prepareToPlay()
                    _audioPlayer?.volume = 1.0
                    
                    // 播放音频
                    if let player = _audioPlayer, player.play() {
                        print("本地音频开始播放")
                    } else {
                        print("本地音频播放失败")
                        throw NSError(domain: "ChatService", code: 1002, userInfo: [NSLocalizedDescriptionKey: "音频播放失败"])
                    }
                } catch {
                    print("本地音频播放错误: \(error.localizedDescription)")
                    throw error
                }
            } else {
                // 如果不是本地文件ID，尝试作为文件路径处理
                if url.hasPrefix("/") || url.hasPrefix("file://") {
                    // 本地文件路径
                    let fileURL: URL
                    if url.hasPrefix("file://") {
                        guard let urlObj = URL(string: url) else {
                            throw NSError(domain: "ChatService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "无效的文件URL"])
                        }
                        fileURL = urlObj
                    } else {
                        fileURL = URL(fileURLWithPath: url)
                    }
                    
                    print("播放本地文件: \(fileURL.path)")
                    
                    do {
                        // 配置音频会话
                        let audioSession = AVAudioSession.sharedInstance()
                        try audioSession.setCategory(.playback, mode: .default)
                        try audioSession.setActive(true)
                        
                        // 创建并配置音频播放器
                        _audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
                        _audioPlayer?.prepareToPlay()
                        _audioPlayer?.volume = 1.0
                        
                        // 播放音频
                        if let player = _audioPlayer, player.play() {
                            print("本地音频开始播放")
                        } else {
                            print("本地音频播放失败")
                            throw NSError(domain: "ChatService", code: 1002, userInfo: [NSLocalizedDescriptionKey: "音频播放失败"])
                        }
                    } catch {
                        print("本地音频播放错误: \(error.localizedDescription)")
                        throw error
                    }
                } else {
                    // 作为远程URL处理（保留原有逻辑，以防需要）
                    print("尝试播放远程音频: \(url)")
                    throw NSError(domain: "ChatService", code: 1003, userInfo: [NSLocalizedDescriptionKey: "不支持播放远程音频"])
                }
            }
        }
        
        // 取消录音
        func cancelRecording() {
            audioRecorder?.stop()
            audioRecorder?.deleteRecording()
            isRecording = false
        }
        
        // 清空消息历史
        func clearMessages() {
            messages.removeAll()
            // 同时清空本地音频文件映射
            localAudioFiles.removeAll()
        }
    }


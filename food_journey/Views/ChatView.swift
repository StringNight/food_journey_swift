import SwiftUI
import AVFoundation

struct ChatView: View {
    @StateObject private var chatService = ChatService.shared
    @State private var inputText = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isShowingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatService.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // 添加这行
                .onChange(of: chatService.messages.count) { _ in
                    if let lastMessage = chatService.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // 输入区域
            HStack(spacing: 8) {
                // 语音按钮
                Button(action: handleVoiceButton) {
                    Image(systemName: chatService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(chatService.isRecording ? .red : .blue)
                        .shadow(color: chatService.isRecording ? Color.red.opacity(0.5) : Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
                }
                .disabled(isLoading)
                
                // 图片按钮
                Button(action: { showImagePicker = true }) {
                    Image(systemName: "photo.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.blue)
                        .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
                }
                .disabled(isLoading || chatService.isRecording)
                
                // 文本输入框
                TextField("输入消息...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(chatService.isRecording)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // 发送按钮 - 改为小一点的正方形图标按钮
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(inputText.isEmpty || isLoading || chatService.isRecording ? Color.blue.opacity(0.5) : Color.blue)
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
                }
                .disabled(inputText.isEmpty || isLoading || chatService.isRecording)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 添加这行
        .navigationTitle("聊天")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                Task {
                    await sendImage(image)
                }
            }
        }
        .alert("错误", isPresented: $isShowingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleVoiceButton() {
        if chatService.isRecording {
            Task {
                await stopRecording()
            }
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        do {
            try chatService.startRecording()
        } catch {
            isShowingError = true
            errorMessage = error.localizedDescription
        }
    }
    
    private func stopRecording() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await chatService.stopRecordingAndSend()
        } catch {
            isShowingError = true
            errorMessage = error.localizedDescription
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let text = inputText
        inputText = ""
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                try await chatService.sendTextMessage(text)
            } catch {
                isShowingError = true
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func sendImage(_ image: UIImage) async {
        isLoading = true
        defer {
            isLoading = false
            selectedImage = nil
        }
        
        do {
            try await chatService.sendImageMessage(image)
        } catch {
            isShowingError = true
            errorMessage = error.localizedDescription
        }
    }
}

struct MessageView: View {
    @ObservedObject var message: Message  // 改为 ObservedObject
    @StateObject private var chatService = ChatService.shared
    @State private var isPlayingVoice = false
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading) {
                switch message.type {
                case .text:
                    Text(message.content)
                        .padding()
                        .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(message.isUser ? .white : .primary)
                        .cornerRadius(16)
                        .animation(.easeInOut(duration: 0.2), value: message.content)
                        .transition(.opacity)
                        .shadow(color: message.isUser ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), radius: 3, x: 0, y: 2)
                
                // 在MessageView中修改图片显示部分
                case .image:
                    if let localImage = message.localImage {
                        // 优先使用本地图片
                        Image(uiImage: localImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    } else if let imageUrl = message.imageUrl {
                        // 如果没有本地图片，则使用URL加载
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 200)
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                            case .failure:
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                
                case .voice:
                    if let voiceUrl = message.voiceUrl {
                        Button(action: {
                            Task {
                                await playVoice(voiceUrl)
                            }
                        }) {
                            HStack {
                                Image(systemName: isPlayingVoice ? "stop.circle.fill" : "play.circle.fill")
                                Text(message.content)
                            }
                            .padding()
                            .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(message.isUser ? .white : .primary)
                            .cornerRadius(16)
                        }
                        .shadow(color: message.isUser ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                }
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
    
    private func playVoice(_ url: String) async {
        do {
            isPlayingVoice = true
            try await chatService.playVoiceMessage(url: url)
            
            // 等待音频播放完成
            if let player = chatService.audioPlayer {
                // 添加一个延迟，等待音频播放完成
                let duration = player.duration
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            }
            
            isPlayingVoice = false
        } catch {
            isPlayingVoice = false
            print("播放语音失败: \(error.localizedDescription)")
            // 可以在这里添加一个提示，告诉用户播放失败
        }
    }
}

#Preview {
    NavigationView {
        ChatView()
    }
}

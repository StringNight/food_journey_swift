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
        // 简化主视图结构，使用属性分解
        MessagesContainerView(
            chatService: chatService,
            inputText: $inputText,
            showImagePicker: $showImagePicker,
            selectedImage: $selectedImage,
            isShowingError: $isShowingError,
            errorMessage: $errorMessage,
            isLoading: $isLoading,
            sendMessageHandler: sendMessage,
            handleVoiceButtonAction: handleVoiceButton,
            sendImageHandler: sendImage
        )
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
            _ = try await chatService.stopRecordingAndSend()
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
                _ = try await chatService.sendTextMessage(text)
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
            _ = try await chatService.sendImageMessage(image)
        } catch {
            isShowingError = true
            errorMessage = error.localizedDescription
        }
    }
}

// 将主视图拆分为更小的组件
struct MessagesContainerView: View {
    @ObservedObject var chatService: ChatService
    @Binding var inputText: String
    @Binding var showImagePicker: Bool
    @Binding var selectedImage: UIImage?
    @Binding var isShowingError: Bool
    @Binding var errorMessage: String
    @Binding var isLoading: Bool
    var sendMessageHandler: () -> Void
    var handleVoiceButtonAction: () -> Void
    var sendImageHandler: (UIImage) async -> Void
    
    var body: some View {
        VStack {
            // 聊天消息列表
            messageListView
            
            Divider()
            
            // 输入区域
            inputBarView
        }
        .navigationTitle("聊天")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { oldImage, newImage in
            if let image = newImage {
                Task {
                    await sendImageHandler(image)
                }
            }
        }
        .onChange(of: showImagePicker) { oldValue, newValue in
            if !newValue {
                selectedImage = nil
            }
        }
        .alert("错误", isPresented: $isShowingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // 消息列表视图组件
    private var messageListView: some View {
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
            .onChange(of: chatService.messages) { oldValue, newValue in
                scrollToBottom(proxy: proxy)
            }
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    // 输入栏视图组件
    private var inputBarView: some View {
        HStack(spacing: 8) {
            // 语音按钮
            Button(action: handleVoiceButtonAction) {
                Image(systemName: chatService.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(chatService.isRecording ? .red : .blue)
            }
            .disabled(isLoading)
            
            // 图片按钮
            Button(action: { showImagePicker = true }) {
                Image(systemName: "photo.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.blue)
            }
            .disabled(isLoading || chatService.isRecording)
            
            // 文本输入框
            TextField("输入消息...", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(chatService.isRecording)
            
            // 发送按钮
            Button(action: sendMessageHandler) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(inputText.isEmpty || isLoading || chatService.isRecording ? Color(UIColor.systemBlue).opacity(0.5) : Color(UIColor.systemBlue))
                    )
            }
            .disabled(inputText.isEmpty || isLoading || chatService.isRecording)
        }
        .padding()
        .padding(.top, -10)
    }
    
    // 滚动到底部方法
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = chatService.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// 消息视图
struct MessageView: View {
    @ObservedObject var message: Message
    @StateObject private var chatService = ChatService.shared
    @StateObject private var authService = AuthService.shared
    @State private var isPlayingVoice = false
    @State private var isAnimated = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 非用户消息左侧显示AI头像
            if !message.isUser {
                Image("cat")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.leading, -5)
            }
            
            // 消息内容
            VStack(alignment: message.isUser ? .trailing : .leading) {
                switch message.type {
                case .text:
                    Text(message.content)
                        .padding()
                        .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(message.isUser ? .white : .primary)
                        .cornerRadius(16)
                
                case .image:
                    if let localImage = message.localImage {
                        Image(uiImage: localImage)
                            .resizable()
                            .scaledToFit()
                        .frame(maxWidth: min(200, UIScreen.main.bounds.width * 0.7)) // 限制图片宽度
                            .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    } else if let imageUrl = message.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: min(200, UIScreen.main.bounds.width * 0.7))
                                    .cornerRadius(16)
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
                                isPlayingVoice.toggle()
                                // 打印URL以实际使用变量
                                print("播放音频: \(voiceUrl)")
                            }
                        }) {
                            HStack {
                                Image(systemName: isPlayingVoice ? "stop.circle.fill" : "play.circle.fill")
                                Text(message.content)
                            }
                        }
                        .padding()
                        .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(message.isUser ? .white : .primary)
                        .cornerRadius(16)
                    }
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.82, alignment: message.isUser ? .trailing : .leading)
            .scaleEffect(isAnimated ? 1.0 : (message.isUser ? 0.8 : 1.0))
            .opacity(isAnimated ? 1.0 : (message.isUser ? 0.0 : 1.0))
            .offset(x: isAnimated ? 0 : (message.isUser ? 20 : 0))
            
            // 用户消息右侧显示用户头像
            if message.isUser {
                userAvatarView
                    .padding(.trailing, -5)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .onAppear {
            // 动画处理
            if message.isUser {
                withAnimation(.spring(response: 0.48, dampingFraction: 0.7)) {
                    isAnimated = true
                }
            } else {
                isAnimated = true
            }
        }
    }
    
    // 用户头像视图
    private var userAvatarView: some View {
        Group {
            if let user = authService.currentUser, let avatarUrl = user.avatar_url, !avatarUrl.isEmpty {
                let fullUrl = getFullAvatarUrl(avatarUrl)
                if let cachedImage = authService.getCachedAvatar(for: fullUrl) {
                    Image(uiImage: cachedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    AsyncImage(url: URL(string: fullUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 32, height: 32)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onAppear {
                                    if let uiImage = ImageRenderer(content: image).uiImage {
                                        authService.cacheAvatar(uiImage, for: fullUrl)
                                    }
                                }
                        case .failure:
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.gray)
                                .frame(width: 32, height: 32)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
                    .frame(width: 32, height: 32)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

#Preview {
    NavigationView {
        ChatView()
    }
}

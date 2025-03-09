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
                .contentShape(Rectangle()) // 添加这行，确保整个区域可点击
                .onTapGesture {
                    // 点击空白区域时隐藏键盘
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
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
                        .frame(width: 34, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(inputText.isEmpty || isLoading || chatService.isRecording ? Color.blue.opacity(0.5) : Color.blue)
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
                }
                .disabled(inputText.isEmpty || isLoading || chatService.isRecording)
            }
            .padding()
            .padding(.top, -10)
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
    @ObservedObject var message: Message
    @StateObject private var chatService = ChatService.shared
    @StateObject private var authService = AuthService.shared
    @State private var isPlayingVoice = false
    @State private var isAnimated = false // 添加动画状态变量
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // 非用户消息左侧显示AI头像
            if !message.isUser {
                Image("cat")
                    .resizable() // 添加这行使图片可调整大小
                    .scaledToFill() // 添加这行确保图片填充框架
                    .frame(width: 32, height: 32)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.leading, -5)
            }
            
            // 消息气泡
            messageContent
                .frame(maxWidth: UIScreen.main.bounds.width * 0.82, alignment: message.isUser ? .trailing : .leading)
                .scaleEffect(isAnimated ? 1.0 : (message.isUser ? 0.8 : 1.0)) // 用户消息有缩放效果
                .opacity(isAnimated ? 1.0 : (message.isUser ? 0.0 : 1.0)) // 用户消息有透明度效果
                .offset(x: isAnimated ? 0 : (message.isUser ? 20 : 0)) // 用户消息有位移效果
            
            // 用户消息右侧显示用户头像
            if message.isUser {
                userAvatar
                    .padding(.trailing, -5)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .contentShape(Rectangle()) // 添加这行，确保整个区域可点击
        .onTapGesture {
            // 点击消息时隐藏键盘
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            // 仅对用户消息应用动画
            if message.isUser {
                withAnimation(.spring(response: 0.48, dampingFraction: 0.7)) { // 将动画时间从0.4增加到0.48，慢20%
                    isAnimated = true
                }
            } else {
                isAnimated = true // 非用户消息直接设置为已动画状态
            }
        }
    }
    
    // 消息内容视图
    private var messageContent: some View {
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
                                .frame(maxWidth: min(200, UIScreen.main.bounds.width * 0.7)) // 限制图片宽度
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
                    }
                    .padding()
                    .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
                    .animation(.easeInOut(duration: 0.2), value: message.content)
                    .transition(.opacity)
                    .shadow(color: message.isUser ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), radius: 3, x: 0, y: 2)
                }
            }
        }
    }
    
    // 用户头像视图
    private var userAvatar: some View {
        Group {
            if let user = authService.currentUser, let avatarUrl = user.avatar_url, !avatarUrl.isEmpty {
                let fullUrl = getFullAvatarUrl(avatarUrl)
                if let cachedImage = authService.getCachedAvatar(for: fullUrl) {
                    Image(uiImage: cachedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8)) // 改为圆角矩形
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
                                .clipShape(RoundedRectangle(cornerRadius: 8)) // 改为圆角矩形
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
                    .clipShape(RoundedRectangle(cornerRadius: 8)) // 改为圆角矩形
            }
        }
    }
    
    // 保持原有的播放语音方法
    private func playVoice(_ url: String) async {
        // 原有代码保持不变
    }
}

#Preview {
    NavigationView {
        ChatView()
    }
}

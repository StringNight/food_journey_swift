import SwiftUI

// 定义聊天消息的数据结构
struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let content: String
    let isSent: Bool
    let avatar: Image
    let isSending: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// 聊天界面，显示聊天记录和输入框
struct ContentView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    
    var body: some View {
        VStack {
            // 头部区域：显示机器人信息
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.clear.shadow(.drop(radius: 6)))
                        .frame(width: 50, height: 50)
                    Image("cat") // 机器人头像
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding(.leading, 24)
                        .padding(.trailing, 8)
                        .compositingGroup()
                        .shadow(radius: 4)
                }
                VStack(alignment: .leading) {
                    Text("Food Journey") // 机器人名称
                        .font(.headline)
                        .foregroundColor(.black)
                    Text("Your best cook") // 机器人描述
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                // 更多按钮
                Button(action: {
                    // 处理更多按钮的点击事件
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, -4)
            
            Divider()
                .padding(.top, 2)
                .shadow(radius: 3, y: 5)
            
            // 聊天记录显示区域
            ScrollView {
                if !messages.isEmpty {
                    ForEach(messages, id: \ .self) { message in
                        HStack {
                            if message.isSent {
                                Spacer()
                                Text(message.content)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color.pink.opacity(0.75))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            } else {
                                if message.isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                        .frame(width: 30, height: 30)
                                } else {
                                    Text(message.content)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(12)
                                    Spacer()
                                }
                            }
                        }
                    }
                } else {
                    Spacer()
                        .padding(.bottom, 150)
                    ZStack(alignment: .center) {
                        Image("ollama") // 机器人头像占位
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 180, height: 180)
                            .clipShape(Circle())
                            .compositingGroup()
                    }
                }
            }
            .padding(.top, 6)
            .padding(.horizontal, 12)
            
            // 快捷操作栏
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // 快捷按钮：杭椒牛柳
                    Button(action: {
                        inputText = "杭椒牛柳的做法"
                        Task {
                            await sendMessage()
                        }
                    }) {
                        Image(systemName: "fork.knife")
                            .padding(.trailing, -2)
                        Text("杭椒牛柳")
                    }
                    .controlSize(.mini)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.gray.opacity(0.05))
                    .foregroundColor(.black)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                    
                    // 快捷按钮：宫保鸡丁
                    Button(action: {
                        inputText = "宫保鸡丁的做法"
                        Task {
                            await sendMessage()
                        }
                    }) {
                        Image(systemName: "fork.knife")
                            .padding(.trailing, -2)
                        Text("宫保鸡丁")
                    }
                    .controlSize(.mini)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.gray.opacity(0.05))
                    .foregroundColor(.black)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))
                }
            }
            .padding(.vertical, 5)
            
            // 输入区域
            HStack {
                TextField("请输入聊天内容", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    Task {
                        await sendMessage()
                    }
                }) {
                    Text("发送")
                }
            }
            .padding()
        }
        .navigationBarHidden(true)
    }
    
    // 发送消息的方法
    func sendMessage() async {
        isSending = true
        defer { isSending = false }
        // 模拟发送延时
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        messages.append(ChatMessage(content: inputText, isSent: true, avatar: Image("cat"), isSending: false))
        inputText = ""
    }
}

// 预览视图
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 
import SwiftUI

struct ChatList: View {
    var body: some View {
        NavigationSplitView {
            List {
                // 修改目标视图为 ChatView，避免与已有 ContentView 重定义
                NavigationLink(destination: ChatView()) {
                    ChatRow()
                }
            }
            .navigationTitle("Chat")
        } detail: {
            Text("Select a Landmark")
        }
    }
}

struct ChatList_Previews: PreviewProvider {
    static var previews: some View {
        ChatList()
    }
} 
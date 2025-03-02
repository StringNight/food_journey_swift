import SwiftUI

struct MainView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                TabView {
                    NavigationView {
                        ChatView()
                    }
                    .tabItem {
                        Label("聊天", systemImage: "message.fill")
                    }
                    
                    NavigationView {
                        HealthTrackView()
                    }
                    .tabItem {
                        Label("健身追踪", systemImage: "heart.fill")
                    }
                    
                    NavigationView {
                        AccountView()
                    }
                    .tabItem {
                        Label("账户", systemImage: "person.crop.circle.fill")
                    }
                }
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    MainView()
}

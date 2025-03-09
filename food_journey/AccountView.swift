import SwiftUI

struct AccountView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @AppStorage("use_biometric") private var useBiometric = false
    @State private var showChangePassword = false
    @State private var showingAboutSheet = false
    
    var body: some View {
            VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        // 用户资料部分
                        UserProfileSection(
                            authService: authService,
                            showImagePicker: $showImagePicker,
                            isUploading: $isUploading,
                            selectedImage: $selectedImage
                        )
                        .padding(.top, 40)
                        
                        // 安全设置部分
                        VStack(alignment: .leading, spacing: 16) {
                            Text("安全设置")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                if BiometricAuthUtil.shared.biometricType != .none {
                                    HStack {
                                        Label(
                                            BiometricAuthUtil.shared.biometricType == .faceID ? "使用 Face ID" : "使用 Touch ID",
                                            systemImage: BiometricAuthUtil.shared.biometricType == .faceID ? "faceid" : "touchid"
                                        )
                                        Spacer()
                                        Toggle("", isOn: $useBiometric)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                    Divider()
                                }
                                
                                NavigationLink(destination: ChangePasswordView()) {
                                    HStack {
                                        Label("修改密码", systemImage: "lock")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground))
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 50) // 添加一个弹性空间，推动退出登录按钮到底部
                        
                        // 退出登录部分
                        Button(action: logout) {
                            Text("退出登录")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 80) // 增加底部间距
                    }
                    .frame(minHeight: UIScreen.main.bounds.height - 150) // 设置最小高度，确保内容足够高
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("账户")
            .navigationBarTitleDisplayMode(.automatic)
            .navigationBarItems(trailing: 
                Button(action: {
                    showingAboutSheet = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            )
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $showingAboutSheet) {
                AboutView()
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    Task {
                        await uploadAvatar(image)
                    }
                }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("错误"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
    }
    
    private func uploadAvatar(_ image: UIImage) async {
        isUploading = true
        defer { isUploading = false }
        
        do {
            try await authService.uploadAvatar(image: image)
            selectedImage = nil
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    private func logout() {
        authService.logout()
    }
}


struct UserProfileSection: View {
    @ObservedObject var authService: AuthService
    @Binding var showImagePicker: Bool
    @Binding var isUploading: Bool
    @Binding var selectedImage: UIImage?
    
    var body: some View {
        VStack {
            // 头像部分
            ZStack {
                // 显示头像或默认图片
                if let selectedImage = selectedImage {
                    // 显示选择的图片（尚未上传）
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                } else if let user = authService.currentUser, let avatarUrl = user.avatar_url, !avatarUrl.isEmpty {
                    // 显示已上传的头像
                    let fullUrl = getFullAvatarUrl(avatarUrl)
                    AsyncImage(url: URL(string: fullUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .onAppear {
                                    print("正在加载头像: \(fullUrl)")
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .onAppear {
                                    print("头像加载成功")
                                }
                        case .failure(let error):
                            // 加载失败时显示默认头像
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                                .onAppear {
                                    print("头像加载失败: \(error.localizedDescription), URL: \(fullUrl)")
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                } else {
                    // 没有头像时显示默认头像
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .onAppear {
                            if let user = authService.currentUser {
                                print("用户没有头像URL: \(String(describing: user.avatar_url))")
                            } else {
                                print("当前用户为空")
                            }
                        }
                }
                
                // 上传按钮
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showImagePicker = true
                        }) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .disabled(isUploading)
                    }
                }
                .frame(width: 100, height: 100)
                
                // 上传中指示器
                if isUploading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .background(Color.black.opacity(0.5))
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity) // 添加这一行使头像居中
            
            
            // 用户信息
            if let user = authService.currentUser {
                Text(user.username)
                    .font(.headline)
                    .padding(.top, 8)
            }
        }
    }
}

// 添加一个扩展来检查字符串是否为空或nil
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self == nil || self!.isEmpty
    }
}

func getFullAvatarUrl(_ avatarUrl: String?) -> String {
    guard let url = avatarUrl, !url.isEmpty else {
        return ""
    }
    
    // 如果已经是完整URL（以http开头），直接返回
    if url.hasPrefix("http") {
        return url
    }
    
    // 获取服务器基础URL
    let baseURL = NetworkService.shared.baseURL
    // 移除URL中的api/v1前缀
    let serverBaseURL = baseURL.replacingOccurrences(of: "/api/v1", with: "")
    
    // 如果avatarUrl以/开头，删除第一个/以避免双斜杠问题
    let cleanUrl = url.hasPrefix("/") ? String(url.dropFirst()) : url
    
    return "\(serverBaseURL)/\(cleanUrl)"
}

public func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.string(from: date)
}

#Preview {
    AccountView()
}

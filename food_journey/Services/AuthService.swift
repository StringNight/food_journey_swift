import Foundation
import UIKit
import SwiftUI

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    // 添加头像缓存
    @Published var cachedAvatars: [String: UIImage] = [:]
    private let networkService = NetworkService.shared
    
    @Published var isAuthenticated = false
    @Published var currentUser: FoodJourneyModels.UserProfile?
    @AppStorage("auth_token") private var authToken: String = ""
    @AppStorage("remember_username") private var rememberedUsername: String = ""
    @AppStorage("use_biometric") private var useBiometric: Bool = false
    
    private init() {
        isAuthenticated = !authToken.isEmpty
        if isAuthenticated {
            Task {
                await fetchUserProfile()
            }
        }
    }
    
    func login(username: String, password: String, rememberMe: Bool = false) async throws {
        let loginRequest = FoodJourneyModels.LoginRequest(username: username, password: password)
        let response: FoodJourneyModels.AuthResponse = try await networkService.request(
            endpoint: "/auth/login/json",
            method: "POST",
            body: try JSONEncoder().encode(loginRequest)
        )
        
        authToken = response.token_info.access_token
        currentUser = response.user
        isAuthenticated = true
        
        if rememberMe {
            rememberedUsername = username
            try await storeCredentials(username: username, password: password)
        }
    }
    
    // 将 loginWithBiometrics 改为 loginWithBiometric 以匹配调用
    func loginWithBiometric() async throws {
        guard !rememberedUsername.isEmpty else {
            throw AuthError.noBiometricCredentials
        }
        
        // 验证生物识别
        try await BiometricAuthUtil.shared.authenticate()
        
        // 获取保存的密码
        guard let password = try? KeychainManager.shared.get(for: rememberedUsername) else {
            throw AuthError.noBiometricCredentials
        }
        
        // 使用保存的凭证登录
        try await login(username: rememberedUsername, password: password, rememberMe: true)
    }
    
    func register(username: String, password: String) async throws {
        print("开始注册用户: \(username)")
        
        let registerRequest = FoodJourneyModels.RegisterRequest(
            username: username,
            password: password,
            confirm_password: password
        )
        
        do {
            let jsonData = try JSONEncoder().encode(registerRequest)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("注册请求JSON: \(jsonString)")
            }
            
            let response: FoodJourneyModels.AuthResponse = try await networkService.request(
                endpoint: "/auth/register",
                method: "POST",
                body: jsonData
            )
            
            print("注册响应成功")
            authToken = response.token_info.access_token
            currentUser = response.user
            isAuthenticated = true
            
        } catch {
            print("注册失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        let request = FoodJourneyModels.ChangePasswordRequest(
            current_password: currentPassword,
            new_password: newPassword
        )
        let _: FoodJourneyModels.EmptyResponse = try await networkService.request(
            endpoint: "/auth/change-password",
            method: "POST",
            body: try JSONEncoder().encode(request),
            requiresAuth: true
        )
    }
    
    func uploadAvatar(image: UIImage) async throws {
        do {
            print("开始处理头像图片...")
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("无法将图片转换为JPEG数据")
                throw NetworkError.serverError("图片处理失败")
            }
            
            print("头像图片处理完成，大小: \(imageData.count) 字节")
            let url = try await networkService.uploadImage(image, endpoint: "/auth/avatar")
            print("头像上传成功，返回URL: \(url)")
            
            // 获取更新后的用户信息
            await fetchUserProfile()
            
            // 打印更新后的头像URL
            if let avatarUrl = currentUser?.avatar_url {
                print("更新后的头像URL: \(avatarUrl)")
                print("完整的头像URL: \(getFullAvatarUrl(avatarUrl))")
            } else {
                print("更新后的用户信息中没有头像URL")
            }
        } catch {
            print("上传头像失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    func logout() {
        authToken = ""
        currentUser = nil
        isAuthenticated = false
        
        if !rememberedUsername.isEmpty {
            try? KeychainManager.shared.delete(for: rememberedUsername)
            rememberedUsername = ""
        }
    }
    
    private func fetchUserProfile() async {
        do {
            let profile: FoodJourneyModels.UserProfile = try await networkService.request(
                endpoint: "/auth/profile",
                method: "GET",
                requiresAuth: true
            )
            currentUser = profile
        } catch {
            logout()
        }
    }
    
    private func storeCredentials(username: String, password: String) async throws {
        try KeychainManager.shared.save(password, for: username)
    }
    
    // 添加获取缓存头像的方法
    // 获取缓存头像的方法
    func getCachedAvatar(for url: String) -> UIImage? {
        return cachedAvatars[url]
    }
    
    // 缓存头像的方法
    func cacheAvatar(_ image: UIImage, for url: String) {
        cachedAvatars[url] = image
    }
    
    // 添加一个公共方法来检查是否有保存的凭证
    func hasSavedCredentials() -> Bool {
        return !rememberedUsername.isEmpty
    }
}

enum AuthError: LocalizedError {
    case noBiometricCredentials
    case biometricAuthFailed
    case invalidCredentials
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .noBiometricCredentials:
            return "没有找到生物识别凭证"
        case .biometricAuthFailed:
            return "生物识别认证失败"
        case .invalidCredentials:
            return "用户名或密码错误"
        case .networkError:
            return "网络连接失败"
        }
    }
}

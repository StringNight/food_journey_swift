import LocalAuthentication
import Foundation

enum BiometricType {
    case none
    case touchID
    case faceID
    
    var description: String {
        switch self {
        case .none:
            return "不支持"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        }
    }
}

enum BiometricError: LocalizedError {
    case notAvailable
    case notEnrolled
    case canceled
    case failed
    case lockout
    case passcodeNotSet
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "设备不支持生物认证"
        case .notEnrolled:
            return "未设置生物认证"
        case .canceled:
            return "用户取消认证"
        case .failed:
            return "认证失败"
        case .lockout:
            return "由于多次失败，生物识别已被锁定"
        case .passcodeNotSet:
            return "设备未设置密码"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
}

@MainActor
class BiometricAuthUtil {
    static let shared = BiometricAuthUtil()
    
    // 每次认证使用新的 context 实例
    private func createContext() -> LAContext {
        let context = LAContext()
        context.localizedCancelTitle = "取消"
        context.localizedFallbackTitle = "使用密码"
        return context
    }
    
    private init() {}
    
    var biometricType: BiometricType {
        let context = createContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error as? LAError {
                print("生物识别检测错误: \(error.localizedDescription), 错误代码: \(error.code.rawValue)")
            }
            return .none
        }
        
        switch context.biometryType {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        default:
            return .none
        }
    }
    
    func authenticate() async throws {
        let context = createContext()
        var error: NSError?
        
        print("开始生物识别认证")
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error as? LAError {
                print("生物识别检测错误: \(error.localizedDescription), 错误代码: \(error.code.rawValue)")
                switch error.code {
                case .biometryNotAvailable:
                    throw BiometricError.notAvailable
                case .biometryNotEnrolled:
                    throw BiometricError.notEnrolled
                case .passcodeNotSet:
                    throw BiometricError.passcodeNotSet
                default:
                    throw BiometricError.unknown("错误代码: \(error.code.rawValue)")
                }
            }
            throw BiometricError.failed
        }
        
        let reason = "使用\(biometricType.description)快速登录"
        print("请求生物识别: \(reason)")
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            print("生物识别结果: \(success)")
        } catch let error as LAError {
            print("生物识别失败: \(error.localizedDescription), 错误代码: \(error.code.rawValue)")
            switch error.code {
            case .userCancel:
                throw BiometricError.canceled
            case .biometryNotAvailable:
                throw BiometricError.notAvailable
            case .biometryNotEnrolled:
                throw BiometricError.notEnrolled
            case .biometryLockout:
                throw BiometricError.lockout
            case .passcodeNotSet:
                throw BiometricError.passcodeNotSet
            default:
                throw BiometricError.unknown("错误代码: \(error.code.rawValue)")
            }
        } catch {
            print("其他错误: \(error.localizedDescription)")
            throw BiometricError.failed
        }
    }
    
    // 添加备用方法，允许使用设备密码
    func authenticateWithFallback() async throws {
        let context = createContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let error = error as? LAError {
                print("设备认证检测错误: \(error.localizedDescription)")
                throw BiometricError.failed
            }
            throw BiometricError.failed
        }
        
        let reason = "使用\(biometricType.description)或密码快速登录"
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            print("认证结果: \(success)")
        } catch {
            print("认证失败: \(error.localizedDescription)")
            throw BiometricError.failed
        }
    }
}
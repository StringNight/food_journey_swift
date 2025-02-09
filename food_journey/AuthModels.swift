import Foundation

extension FoodJourneyModels {
    struct LoginRequest: Codable {
        let username: String
        let password: String
    }

    struct RegisterRequest: Codable {
        let username: String
        let password: String
        let confirm_password: String
    }

    struct AuthResponse: Codable {
        let token_info: TokenInfo
        let user: UserProfile
        
        enum CodingKeys: String, CodingKey { // TODO: 更改后端返回结构
            case token_info = "token"
            case user = "user"
        }
    }

    struct UserProfile: Codable {
        let id: String
        let username: String
//        let email: String
        let created_at: Date
        let avatar_url: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "id"
            case username = "username"
//            case email = "email"
            case created_at = "created_at"
            case avatar_url = "avatar_url"
        }
    }
    
    struct TokenInfo: Codable {
        let access_token: String
        let token_type: String
        
        enum CodingKeys: String, CodingKey {
            case access_token = "access_token"
            case token_type = "token_type"
        }
    }

    struct ErrorResponse: Codable {
        let detail: String
    }
} 

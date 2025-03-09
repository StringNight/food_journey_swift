import Foundation

extension FoodJourneyModels {
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
        let type: String?
        let errors: [ValidationError]?
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            detail = try container.decode(String.self, forKey: .detail)
            type = try container.decodeIfPresent(String.self, forKey: .type)
            errors = try container.decodeIfPresent([ValidationError].self, forKey: .errors)
        }
        
        enum CodingKeys: String, CodingKey {
            case detail, type, errors
        }
    }
    
    struct ValidationError: Codable {
        let field: String
        let field_path: String
        let message: String
        let type: String
    }
} 

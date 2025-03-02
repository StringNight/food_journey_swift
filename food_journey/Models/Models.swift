import Foundation

public enum FoodJourneyModels {
    // MARK: - 响应模型
    public struct EmptyResponse: Codable {}

//    public struct ErrorResponse: Codable {
//        public let detail: String
//    }

    public struct FileUploadResponse: Codable {
        public let url: String
    }

    public struct ChatResponse: Codable {
        public let response: String
        public let success: Bool
    }

    public struct AudioUploadResponse: Codable {
        public let url: String
    }

    public struct MessageResponse: Codable {
        public let message: String
        public let suggestions: [String]?
        public let image_url: String?
        public let voice_url: String?
    }

    public struct RecipeSearchResponse: Codable {
        public let recipes: [Recipe]
        public let total: Int
        public let page: Int
        public let total_pages: Int
        
        enum CodingKeys: String, CodingKey {
            case recipes
            case total
            case page
            case total_pages = "total_pages"
        }
    }

    // 添加更新响应模型
    public struct UpdateResponse: Codable {
        public let schema_version: String
        public let message: String
        public let updated_fields: [String]?
        
        enum CodingKeys: String, CodingKey {
            case schema_version = "schema_version"
            case message
            case updated_fields = "updated_fields"
        }
    }

    // 添加运动记录响应模型
    public struct ExerciseSet: Codable {
        public let reps: Int
        public let weight: Double?
        public let duration: Int?
        public let distance: Double?
    }
    
    public struct ExerciseResponse: Codable {
        public let id: String
        public let user_id: String
        public let exercise_name: String
        public let exercise_type: String
        public let sets: [ExerciseSet]
        public let calories_burned: Double?
        public let notes: String?
        public let recorded_at: String
        public let created_at: String
        public let updated_at: String
        
        enum CodingKeys: String, CodingKey {
            case id, user_id, exercise_name, exercise_type, sets
            case calories_burned = "calories_burned"
            case notes, recorded_at, created_at, updated_at
        }
    }

    // 添加饮食记录响应模型
    public struct FoodItem: Codable {
        public let food_name: String
        public let portion: Double
        public let calories: Double
        public let protein: Double?
        public let carbs: Double?
        public let fat: Double?
        
        enum CodingKeys: String, CodingKey {
            case food_name = "food_name"
            case portion
            case calories
            case protein
            case carbs
            case fat
        }
    }
    
    public struct MealResponse: Codable {
        public let id: String
        public let user_id: String
        public let meal_type: String
        public let food_items: [FoodItem]
        public let total_calories: Double
        public let notes: String?
        public let recorded_at: String
        public let created_at: String
        public let updated_at: String
        
        enum CodingKeys: String, CodingKey {
            case id, user_id, meal_type
            case food_items = "food_items"
            case total_calories = "total_calories"
            case notes, recorded_at, created_at, updated_at
        }
    }

    // MARK: - 请求模型
    public struct ChatTextRequest: Codable {
        public let message: String
        
        public init(message: String) {
            self.message = message
        }
    }

    public struct ChatImageRequest: Codable {
        public let file: String
        
        public init(file: String) {
            self.file = file
        }
    }

    public struct ChatVoiceRequest: Codable {
        public let voice_url: String
        
        public init(voice_url: String) {
            self.voice_url = voice_url
        }
    }

    public struct RecipeRatingRequest: Codable {
        public let rating: Int
        public let comment: String?
        
        public init(rating: Int, comment: String?) {
            self.rating = rating
            self.comment = comment
        }
    }

    public struct PasswordResetRequest: Codable {
        public let email: String
        
        public init(email: String) {
            self.email = email
        }
    }

    public struct ChangePasswordRequest: Codable {
        public let current_password: String
        public let new_password: String
        
        public init(current_password: String, new_password: String) {
            self.current_password = current_password
            self.new_password = new_password
        }
    }
    
    public struct RecipeCreate: Codable {
            let title: String
            let ingredients: [Ingredient]
            let steps: [Step]
            let nutrition: Nutrition
            let cooking_time: Int
            let difficulty: String
            let tags: [String]?
    }
        
    struct RecipeResponse: Codable {
        let schema_version: String
        let recipe: Recipe?
    }

}

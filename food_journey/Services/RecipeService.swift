import Foundation

@MainActor
class RecipeService: ObservableObject {
    static let shared = RecipeService()
    private let networkService = NetworkService.shared
    
    @Published var recipes: [Recipe] = []
    @Published var favoriteRecipes: [Recipe] = []
    @Published var searchResults: [Recipe] = []
    @Published var isSearching = false
    
    private init() {}
    
    struct RecipeResponse: Codable {
        let schema_version: String
        let recipes: [Recipe]
        let pagination: Pagination
        
        struct Pagination: Codable {
            let total: Int
            let page: Int
            let per_page: Int
            let pages: Int
        }
    }
    
    /// 获取所有菜谱信息
    /// 通过访问 "/recipes" 接口来获取菜谱数据，用户需已认证
    func fetchRecipes() async throws {
        let response: RecipeResponse = try await networkService.request(
            endpoint: "/recipes",
            requiresAuth: true
        )
        recipes = response.recipes
    }
    
    /// 获取用户收藏的菜谱
    /// 通过访问 "/favorites" 接口来获取收藏的菜谱数据，用户需已认证
    func fetchFavoriteRecipes() async throws {
        let response: [Recipe] = try await networkService.request(
            endpoint: "/favorites",
            requiresAuth: true
        )
        favoriteRecipes = response
    }
    
    /// 搜索菜谱
    /// 根据传入的查询关键字调用 "/recipes/search" 接口返回搜索结果
    func searchRecipes(query: String, page: Int = 1, limit: Int = 20) async throws {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        defer { isSearching = false }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let response: FoodJourneyModels.RecipeSearchResponse = try await networkService.request(
            endpoint: "/recipes/search?query=\(encodedQuery)&page=\(page)&limit=\(limit)",
            requiresAuth: true
        )
        
        if page == 1 {
            searchResults = response.recipes
        } else {
            searchResults.append(contentsOf: response.recipes)
        }
    }
    
    /// 将菜谱加入收藏
    /// 通过 POST 请求 "/recipes/{recipeId}/favorite" 接口将菜谱添加到用户收藏中
    func addToFavorites(recipeId: String) async throws {
        let _: FoodJourneyModels.EmptyResponse = try await networkService.request(
            endpoint: "/recipes/\(recipeId)/favorite",
            method: "POST",
            requiresAuth: true
        )
        // 更新本地收藏列表
        if let recipe = recipes.first(where: { recipe in recipe.id == recipeId }) {
            favoriteRecipes.append(recipe)
        }
    }
    
    /// 从收藏中移除菜谱
    /// 通过 DELETE 请求 "/recipes/{recipeId}/favorite" 接口来移除用户收藏中的菜谱
    func removeFromFavorites(recipeId: String) async throws {
        let _: FoodJourneyModels.EmptyResponse = try await networkService.request(
            endpoint: "/recipes/\(recipeId)/favorite",
            method: "DELETE",
            requiresAuth: true
        )
        // 从本地收藏列表中移除
        favoriteRecipes.removeAll { $0.id == recipeId }
    }
    
    /// 对菜谱进行评分
    /// 通过 POST 请求 "/recipes/{recipeId}/rate" 接口提交用户评分及评论
    func rateRecipe(recipeId: String, rating: Int, comment: String?) async throws {
        let ratingData = FoodJourneyModels.RecipeRatingRequest(rating: rating, comment: comment)
        let _: FoodJourneyModels.EmptyResponse = try await networkService.request(
            endpoint: "/recipes/\(recipeId)/rate",
            method: "POST",
            body: try JSONEncoder().encode(ratingData),
            requiresAuth: true
        )
    }
    
    /// 创建新菜谱
    /// 通过 POST 请求 "/recipes" 接口创建新的菜谱，成功后会将新菜谱插入本地列表
    func createRecipe(_ recipe: FoodJourneyModels.RecipeCreate) async throws {
        let response: FoodJourneyModels.RecipeResponse = try await networkService.request(
            endpoint: "/recipes",
            method: "POST",
            body: try JSONEncoder().encode(recipe),
            requiresAuth: true
        )
        // 添加新创建的菜谱到列表
        if let newRecipe = response.recipe {
            recipes.insert(newRecipe, at: 0)
        }
    }
}
